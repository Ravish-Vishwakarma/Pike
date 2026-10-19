import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Utilities/models.dart';

class LocalChatService {
  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  int _loadGeneration = 0;
  bool _disposed = false;

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

    final engine = await LiteLmEngine.create(
      LiteLmEngineConfig(modelPath: modelPath, backend: LiteLmBackend.cpu),
    );
    if (_disposed || generation != _loadGeneration) {
      await engine.dispose();
      return;
    }

    try {
      final conversation = await engine.createConversation(
        const LiteLmConversationConfig(
          systemInstruction: 'You are a helpful assistant. Be concise.',
          samplerConfig: LiteLmSamplerConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
          ),
        ),
      );
      if (_disposed || generation != _loadGeneration) {
        await conversation.dispose();
        await engine.dispose();
        return;
      }
      _engine = engine;
      _conversation = conversation;
    } catch (_) {
      await engine.dispose();
      rethrow;
    }
  }

  Stream<LiteLmMessage> sendMessage(String text) {
    final conversation = _conversation;
    if (conversation == null) {
      throw StateError('The selected model is not ready.');
    }
    return conversation.sendMessageStream(text);
  }

  Future<void> unload() async {
    _loadGeneration++;
    await _disposeSession();
  }

  Future<void> _disposeSession() async {
    final conversation = _conversation;
    final engine = _engine;
    _conversation = null;
    _engine = null;

    try {
      if (conversation != null) await conversation.dispose();
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
