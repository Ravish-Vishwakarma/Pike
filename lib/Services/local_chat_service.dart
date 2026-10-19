import 'package:litertlm/litertlm.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Utilities/models.dart';

class LocalChatService {
  Engine? _engine;
  Conversation? _activeConversation;
  final List<Message> _history = [];
  int _loadGeneration = 0;
  bool _disposed = false;
  bool _isSending = false;

  void restoreHistory(List<ChatMessage> messages) {
    _history.clear();
    ChatMessage? pendingUserMessage;
    for (final message in messages) {
      if (message.isAI) {
        final userMessage = pendingUserMessage;
        if (userMessage != null) {
          _history
            ..add(Message.user(userMessage.text))
            ..add(Message.modelText(message.text));
          pendingUserMessage = null;
        }
      } else {
        pendingUserMessage = message;
      }
    }
  }

  void startNewChat() {
    _history.clear();
  }

  Future<void> loadModel(String modelName) async {
    final generation = ++_loadGeneration;
    await _disposeSession();
    if (_disposed || generation != _loadGeneration) return;

    final model = allModels.values
        .where((item) => item.name == modelName)
        .firstOrNull;
    if (model == null) {
      throw StateError('The selected model "$modelName" is not recognized.');
    }

    final modelPath = await Downloader.getDownloadedFilePath(model.filename);
    if (modelPath == null) {
      throw StateError(
        '${model.name} is not downloaded. Download it from the Models page.',
      );
    }
    if (_disposed || generation != _loadGeneration) return;

    final engine = Engine(
      engineConfig: EngineConfig(
        modelPath: modelPath,
        backend: const Backend.cpu(),
      ),
    );
    try {
      await engine.initialize();
      if (_disposed || generation != _loadGeneration) {
        await engine.dispose();
        return;
      }

      _engine = engine;
    } catch (_) {
      await engine.dispose();
      rethrow;
    }
  }

  Stream<Message> sendMessage(String text) async* {
    final engine = _engine;
    if (engine == null) {
      throw StateError('The selected model is not ready.');
    }
    if (_isSending) {
      throw StateError('A response is already being generated.');
    }

    _isSending = true;
    Conversation? conversation;
    final generation = _loadGeneration;
    final responseText = StringBuffer();
    var completed = false;
    try {
      conversation = await engine.createConversation(
        ConversationConfig(
          systemMessage: Message.system(
            'You are a helpful assistant. Answer the latest user message '
            'directly and concisely. Earlier messages are context only: do '
            'not answer or continue an earlier question unless the latest '
            'message explicitly asks you to.',
          ),
          initialMessages: List.unmodifiable(_history),
          sessionConfig: SessionConfig(
            samplerConfig: SamplerConfig(
              temperature: 0.7,
              topK: 40,
              topP: 0.95,
            ),
          ),
        ),
      );
      if (_disposed ||
          generation != _loadGeneration ||
          !identical(engine, _engine)) {
        throw StateError('The selected model changed before generation.');
      }
      _activeConversation = conversation;

      await for (final message in conversation.sendMessageStream(
        Message.user(text),
      )) {
        if (message.isEmpty) continue;
        responseText.write(message.text);
        yield message;
      }
      completed = true;

      if (responseText.toString().trim().isEmpty) {
        throw StateError('The model returned an empty response.');
      }
      _history
        ..add(Message.user(text))
        ..add(Message.modelText(responseText.toString().trim()));
    } finally {
      try {
        if (conversation != null) {
          if (identical(conversation, _activeConversation)) {
            _activeConversation = null;
          }
          if (!completed) await conversation.cancel();
          await conversation.dispose();
        }
      } finally {
        _isSending = false;
      }
    }
  }

  Future<void> unload() async {
    _loadGeneration++;
    await _disposeSession();
  }

  Future<void> _disposeSession() async {
    final engine = _engine;
    final conversation = _activeConversation;
    _engine = null;
    _activeConversation = null;
    _history.clear();
    try {
      if (conversation != null) {
        try {
          await conversation.cancel();
        } finally {
          await conversation.dispose();
        }
      }
    } finally {
      if (engine != null) await engine.dispose();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _loadGeneration++;
    await _disposeSession();
  }
}
