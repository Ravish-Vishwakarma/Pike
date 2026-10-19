import 'package:flutter/material.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Utilities/colors.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  late Future<List<ChatSession>> _chats;

  @override
  void initState() {
    super.initState();
    _refreshChats();
  }

  void _refreshChats() {
    _chats = getAllChats();
  }

  Future<void> _renameChat(ChatSession chat) async {
    final controller = TextEditingController(text: chat.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(context, value),
          decoration: const InputDecoration(labelText: 'Chat name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;

    try {
      await renameChat(chat.id, title);
      if (!mounted) return;
      setState(_refreshChats);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not rename chat: $error')),
        );
      }
    }
  }

  Future<void> _deleteChat(ChatSession chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text('“${chat.title}” and its messages will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await deleteChat(chat.id);
      if (!mounted) return;
      setState(_refreshChats);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete chat: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.primary,
        title: Text(
          'Chat History',
          style: TextStyle(color: MyColors.textLight),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: MyColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ChatSession>>(
        future: _chats,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load chats: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(
              child: Text('Your saved chats will appear here.'),
            );
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatHistoryCard(
                chat: chat,
                onOpen: () => Navigator.pop(context, chat),
                onRename: () => _renameChat(chat),
                onDelete: () => _deleteChat(chat),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatHistoryCard extends StatelessWidget {
  final ChatSession chat;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ChatHistoryCard({
    super.key,
    required this.chat,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = chat.updatedAt.toLocal();
    final dateLabel =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        onTap: onOpen,
        title: Text(chat.title),
        subtitle: Text(dateLabel),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
