import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatEntry> _messages = [
    const _ChatEntry('Hello! I can help with your local models.', true),
  ];
  final ModelManager _modelManager = ModelManager.instance;
  AIModel? _selectedModel;
  bool _isGenerating = false;
  StreamSubscription<String>? _generationSub;

  @override
  void initState() {
    super.initState();
    _modelManager.initialize();
    _reloadModel();
  }

  Future<void> _reloadModel() async {
    final model = await _modelManager.selectedModel();
    if (!mounted) return;
    setState(() => _selectedModel = model);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatEntry(text, false));
      _textController.clear();
      _isGenerating = true;
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    _messages.add(_ChatEntry('', true));

    _generationSub = _modelManager
        .runInferenceStream(text, modelId: _selectedModel?.id)
        .listen(
          (delta) {
            buffer.write(delta);
            if (!mounted) return;
            setState(() {
              _messages.last = _ChatEntry(buffer.toString(), true);
            });
            _scrollToBottom();
          },
          onDone: () {
            if (!mounted) return;
            setState(() => _isGenerating = false);
            _scrollToBottom();
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _messages.last = _ChatEntry('Error: $error', true);
              _isGenerating = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _generationSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: const Text("CHAT", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: _reloadModel,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
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
      body: Column(
        children: [
          _buildModelBar(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildModelBar() {
    if (_selectedModel == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.orange.shade50,
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              'No model selected — go to Models tab',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: MyColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedModel!.parameters,
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: MyColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedModel!.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
          const SizedBox(width: 4),
          Text(
            'Active',
            style: TextStyle(fontSize: 11, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Start a conversation',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isLastAI = message.isAI && index == _messages.length - 1;
        return ChatMessageWidget(
          message: message.text,
          isAI: message.isAI,
          showCursor: _isGenerating && isLastAI && message.text.isEmpty,
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 4, top: 6, bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isGenerating,
              textInputAction: TextInputAction.send,
              onSubmitted: _isGenerating ? null : (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isGenerating ? 'Generating...' : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: _isGenerating
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    color: MyColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: MyColors.primary.withAlpha(20),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final String text;
  final bool isAI;

  const _ChatEntry(this.text, this.isAI);
}

class ChatMessageWidget extends StatelessWidget {
  final String message;
  final bool isAI;
  final bool showCursor;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isAI,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: MyColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAI ? Colors.white : MyColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(16),
                  bottomRight: isAI ? const Radius.circular(16) : const Radius.circular(4),
                ),
                border: isAI ? Border.all(color: Colors.grey.shade200) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: message.isEmpty && showCursor
                  ? _buildCursor()
                  : SelectableText(
                      message,
                      style: TextStyle(
                        color: isAI ? Colors.black87 : Colors.white,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (!isAI) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCursor() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}
