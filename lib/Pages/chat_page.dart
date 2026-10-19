import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Services/local_chat_service.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/model_not_downloaded_navigator.dart';
import 'package:pike/Utilities/models.dart';

class ChatPage extends StatefulWidget {
  final ValueChanged<int> onChangeIndex;

  const ChatPage({super.key, required this.onChangeIndex});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _chatNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final LocalChatService _chatService = LocalChatService();
  final List<_ChatMessage> _messages = [];

  Uint8List? _selectedImageBytes;
  String _loadedModelName = 'none';
  String? _modelError;
  bool _isModelSelected = false;
  bool _isModelLoading = false;
  bool _isGenerating = false;
  int _modelGeneration = 0;
  int? _chatId;
  String _chatTitle = 'New chat';
  bool get _supportsVision => allModels.values.any(
    (model) => model.name == _loadedModelName && model.supportsVision,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    selectedModelNameNotifier.addListener(_onSelectedModelChanged);
    chatHistoryClearedNotifier.addListener(_onChatHistoryCleared);
    unawaited(_loadSelectedModelName());
  }

  void _onChatHistoryCleared() {
    ++_modelGeneration;
    _chatService.startNewChat();
    setState(() {
      _chatId = null;
      _chatTitle = 'New chat';
      _chatNameController.text = _chatTitle;
      _messages.clear();
      _selectedImageBytes = null;
      _isGenerating = false;
    });
  }

  Future<void> _loadSelectedModelName() async {
    try {
      await getSelectedModelName();
      if (mounted) {
        _onSelectedModelChanged();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _modelError = 'Could not load selection: $error');
      }
    }
  }

  void _onSelectedModelChanged() {
    final modelName = selectedModelNameNotifier.value;
    if (modelName == _loadedModelName || !mounted) return;

    _loadedModelName = modelName;
    final generation = ++_modelGeneration;
    setState(() {
      _isModelSelected = modelName != 'none';
      _isModelLoading = _isModelSelected;
      _isGenerating = false;
      _modelError = null;
      _chatId = null;
      _chatTitle = 'New chat';
      _chatNameController.text = _chatTitle;
      _messages.clear();
    });

    unawaited(_loadModel(modelName, generation));
  }

  Future<void> _loadModel(String modelName, int generation) async {
    try {
      if (modelName != 'none') {
        await _chatService.loadModel(modelName);
      } else {
        await _chatService.unload();
      }
      if (!mounted || generation != _modelGeneration) return;
      setState(() => _isModelLoading = false);
    } catch (error) {
      if (!mounted || generation != _modelGeneration) return;
      setState(() {
        _isModelLoading = false;
        _modelError = error.toString();
      });
    }
  }

  void _retryModelLoad() {
    final generation = ++_modelGeneration;
    setState(() {
      _isModelLoading = _loadedModelName != 'none';
      _modelError = null;
      _messages.clear();
    });
    unawaited(_loadModel(_loadedModelName, generation));
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('The selected image is empty.');
      }
      if (!mounted) return;
      setState(() => _selectedImageBytes = bytes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load image: $error')));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final imageBytes = _selectedImageBytes;
    if ((text.isEmpty && imageBytes == null) ||
        _isModelLoading ||
        _isGenerating ||
        _modelError != null) {
      return;
    }

    _messageController.clear();
    final reply = _ChatMessage(isUser: false, text: '');
    final generation = _modelGeneration;
    setState(() {
      _messages
        ..add(_ChatMessage(isUser: true, text: text, imageBytes: imageBytes))
        ..add(reply);
      _selectedImageBytes = null;
      _isGenerating = true;
    });
    _scrollToBottom();
    try {
      var chatId = _chatId;
      if (chatId == null) {
        chatId = await createChat(modelName: _loadedModelName);
        if (!mounted || generation != _modelGeneration) return;
        final chat = await getChat(chatId);
        if (chat == null) {
          throw StateError('The new chat could not be loaded.');
        }
        setState(() {
          _chatId = chatId;
          _chatTitle = chat.title;
          _chatNameController.text = chat.title;
        });
      }
      await addChatMessage(
        chatId: chatId,
        isAI: false,
        text: text,
        imageBytes: imageBytes,
      );

      await for (final delta in _chatService.sendMessage(
        text,
        imageBytes: imageBytes,
      )) {
        if (!mounted || generation != _modelGeneration) break;
        if (delta.text.isEmpty) continue;
        setState(() => reply.text += delta.text);
        _scrollToBottom();
      }
      if (!mounted || generation != _modelGeneration) return;
      setState(() {
        _isGenerating = false;
        if (reply.text.trim().isEmpty) {
          reply
            ..error = true
            ..text = 'The model returned an empty response.';
        }
      });
      if (reply.text.trim().isNotEmpty) {
        await addChatMessage(
          chatId: chatId,
          isAI: true,
          text: reply.text.trim(),
        );
      }
      _scrollToBottom();
    } catch (error) {
      if (mounted && generation == _modelGeneration) {
        setState(() {
          _isGenerating = false;
          reply.error = true;
          reply.text = reply.text.isEmpty
              ? 'Could not generate a response: $error'
              : '${reply.text}\n\nCould not save response: $error';
        });
      }
    }
  }

  Future<void> _startNewChat() async {
    if (_isGenerating) return;
    _chatService.startNewChat();
    setState(() {
      _chatId = null;
      _chatTitle = 'New chat';
      _chatNameController.text = _chatTitle;
      _messages.clear();
      _selectedImageBytes = null;
      _modelError = null;
    });
  }

  Future<void> _openChatHistory() async {
    final chat = await Navigator.push<ChatSession>(
      context,
      MaterialPageRoute<ChatSession>(
        builder: (context) => const ChatHistoryPage(),
      ),
    );
    if (chat == null || !mounted) return;

    try {
      final history = await getChatMessages(chat.id);
      if (!mounted) return;
      _chatService.restoreHistory(history);
      setState(() {
        _selectedImageBytes = null;
        _chatId = chat.id;
        _chatTitle = chat.title;
        _chatNameController.text = chat.title;
        _messages
          ..clear()
          ..addAll(
            history.map(
              (message) => _ChatMessage(
                isUser: !message.isAI,
                text: message.text,
                imageBytes: message.imageBytes,
              ),
            ),
          );
        _modelError = null;
      });
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open chat: $error')));
      }
    }
  }

  Future<void> _renameCurrentChat(String title) async {
    final chatId = _chatId;
    final trimmedTitle = title.trim();
    if (chatId == null || trimmedTitle.isEmpty || trimmedTitle == _chatTitle) {
      _chatNameController.text = _chatTitle;
      return;
    }
    try {
      await renameChat(chatId, trimmedTitle);
      if (!mounted || chatId != _chatId) return;
      setState(() => _chatTitle = trimmedTitle);
    } catch (error) {
      _chatNameController.text = _chatTitle;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not rename chat: $error')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    selectedModelNameNotifier.removeListener(_onSelectedModelChanged);
    chatHistoryClearedNotifier.removeListener(_onChatHistoryCleared);
    unawaited(_chatService.dispose());
    _messageController.dispose();
    _chatNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: _isModelSelected || _chatId != null
            ? TextFormField(
                controller: _chatNameController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _renameCurrentChat,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Chat Name',
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : const Text('Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.primary,
        actions: [
          if (_chatId != null || _messages.isNotEmpty)
            IconButton(
              onPressed: _isGenerating ? null : _startNewChat,
              tooltip: 'New chat',
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          IconButton(
            onPressed: _isGenerating ? null : _openChatHistory,
            tooltip: 'Chat history',
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
      body: !_isModelSelected && _messages.isEmpty
          ? Center(
              child: PleaseDownloadModelWidget(
                changePageToChat: () => widget.onChangeIndex(1),
              ),
            )
          : Column(
              children: [
                if (_isModelLoading)
                  const LinearProgressIndicator()
                else if (_modelError case final error?)
                  MaterialBanner(
                    content: Text(error),
                    leading: const Icon(Icons.error_outline),
                    actions: [
                      TextButton(
                        onPressed: _retryModelLoad,
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: () => widget.onChangeIndex(1),
                        child: const Text('Models'),
                      ),
                    ],
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            _isModelLoading
                                ? 'Loading $_loadedModelName...'
                                : _modelError == null
                                ? 'Type a message to start chatting.'
                                : 'Model is not ready.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _MessageBubble(
                              message: message,
                              isGenerating:
                                  _isGenerating &&
                                  identical(message, _messages.last) &&
                                  !message.isUser,
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedImageBytes case final imageBytes?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      imageBytes,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: IconButton.filledTonal(
                                      tooltip: 'Remove image',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(
                                        () => _selectedImageBytes = null,
                                      ),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_supportsVision)
                              IconButton(
                                onPressed:
                                    !_isModelSelected ||
                                        _isModelLoading ||
                                        _modelError != null ||
                                        _isGenerating
                                    ? null
                                    : _pickImage,
                                tooltip: 'Attach image',
                                icon: const Icon(Icons.image_outlined),
                              ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                enabled:
                                    _isModelSelected &&
                                    !_isModelLoading &&
                                    _modelError == null &&
                                    !_isGenerating,
                                minLines: 1,
                                maxLines: 5,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: const InputDecoration(
                                  hintText: 'Message',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed:
                                  _isModelSelected &&
                                      !_isModelLoading &&
                                      _modelError == null &&
                                      !_isGenerating
                                  ? _sendMessage
                                  : null,
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  String text;
  final Uint8List? imageBytes;
  bool error = false;

  _ChatMessage({required this.isUser, required this.text, this.imageBytes});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isGenerating;

  const _MessageBubble({required this.message, required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? MyColors.surfaceLight.withAlpha(150)
              : message.error
              ? Theme.of(context).colorScheme.errorContainer
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isGenerating && message.text.isEmpty
            ? const SizedBox(
                width: 28,
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageBytes case final imageBytes?)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: message.text.isEmpty ? 0 : 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          imageBytes,
                          width: 240,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text('Could not display this image.'),
                        ),
                      ),
                    ),
                  if (message.text.isNotEmpty) SelectableText(message.text),
                ],
              ),
      ),
    );
  }
}
