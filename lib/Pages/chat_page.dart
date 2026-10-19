import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Services/local_chat_service.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/model_not_downloaded_navigator.dart';

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
  final LocalChatService _chatService = LocalChatService();
  final List<_ChatMessage> _messages = [];

  StreamSubscription<LiteLmMessage>? _responseSubscription;
  Completer<void>? _responseCompleter;
  String _loadedModelName = 'none';
  String? _modelError;
  bool _isModelSelected = false;
  bool _isModelLoading = false;
  bool _isGenerating = false;
  int _modelGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    selectedModelNameNotifier.addListener(_onSelectedModelChanged);
    unawaited(_loadSelectedModelName());
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
    final responseSubscription = _responseSubscription;
    _responseSubscription = null;
    _responseCompleter?.complete();
    _responseCompleter = null;

    setState(() {
      _isModelSelected = modelName != 'none';
      _isModelLoading = _isModelSelected;
      _isGenerating = false;
      _modelError = null;
      _messages.clear();
    });

    unawaited(_loadModel(modelName, generation, responseSubscription));
  }

  Future<void> _loadModel(
    String modelName,
    int generation,
    StreamSubscription<LiteLmMessage>? previousResponse,
  ) async {
    await previousResponse?.cancel();
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
    unawaited(_loadModel(_loadedModelName, generation, null));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
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
        ..add(_ChatMessage(isUser: true, text: text))
        ..add(reply);
      _isGenerating = true;
    });
    _scrollToBottom();
    final completer = Completer<void>();
    _responseCompleter = completer;
    StreamSubscription<LiteLmMessage>? subscription;
    try {
      subscription = _chatService
          .sendMessage(text)
          .listen(
            (delta) {
              if (!mounted || generation != _modelGeneration) return;
              setState(() => reply.text += delta.text);
              _scrollToBottom();
            },
            onError: (Object error) {
              if (mounted && generation == _modelGeneration) {
                setState(() {
                  _isGenerating = false;
                  if (reply.text.isEmpty) {
                    _messages.remove(reply);
                    _modelError = 'Could not generate a response: $error';
                  } else {
                    reply.error = true;
                    reply.text += '\n\nResponse interrupted: $error';
                  }
                });
              }
              _completeResponse(completer);
            },
            onDone: () {
              if (mounted && generation == _modelGeneration) {
                setState(() {
                  _isGenerating = false;
                  if (reply.text.isEmpty) {
                    _messages.remove(reply);
                    _modelError = 'The model returned an empty response.';
                  }
                });
              }
              _completeResponse(completer);
            },
          );
      _responseSubscription = subscription;
    } catch (error) {
      if (mounted && generation == _modelGeneration) {
        setState(() {
          _isGenerating = false;
          _messages.remove(reply);
          _modelError = 'Could not generate a response: $error';
        });
      }
      _completeResponse(completer);
    }
    await completer.future;
    if (identical(_responseCompleter, completer)) {
      _responseCompleter = null;
    }
    if (identical(_responseSubscription, subscription)) {
      _responseSubscription = null;
    }
  }

  void _completeResponse(Completer<void> completer) {
    if (!completer.isCompleted) completer.complete();
    if (identical(_responseCompleter, completer)) {
      _responseCompleter = null;
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
    _responseCompleter?.complete();
    _responseCompleter = null;
    _responseSubscription?.cancel();
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
        title: _isModelSelected
            ? TextFormField(
                controller: _chatNameController,
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ChatHistoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
      body: !_isModelSelected
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled:
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
                              !_isModelLoading &&
                                  _modelError == null &&
                                  !_isGenerating
                              ? _sendMessage
                              : null,
                          icon: const Icon(Icons.send),
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
  bool error = false;

  _ChatMessage({required this.isUser, required this.text});
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
            : SelectableText(message.text),
      ),
    );
  }
}
