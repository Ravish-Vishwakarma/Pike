import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Utilities/colors.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<int> onChangeIndex;

  const SettingsPage({super.key, required this.onChangeIndex});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<ChatSession>> _chatHistoryFuture;
  bool _isClearingChats = false;
  String? _modelLoadError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _chatHistoryFuture = getAllChats();
    chatListChangesNotifier.addListener(_onChatListChanged);
    unawaited(_loadSelectedModelName());
  }

  void _onChatListChanged() {
    if (!mounted) return;
    setState(() {
      _chatHistoryFuture = getAllChats();
    });
  }

  Future<void> _loadSelectedModelName() async {
    try {
      await getSelectedModelName();
    } catch (error) {
      if (mounted) {
        setState(() => _modelLoadError = error.toString());
      }
    }
  }

  Future<void> _clearAllChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all chat history?'),
        content: const Text(
          'All saved chats and their messages will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearingChats = true);
    try {
      await deleteAllChats();
      if (!mounted) return;
      setState(() => _isClearingChats = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chat history has been cleared.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isClearingChats = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear chat history: $error')),
      );
    }
  }

  @override
  void dispose() {
    chatListChangesNotifier.removeListener(_onChatListChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: Text('SETTINGS', style: TextStyle(color: MyColors.textLight)),
        backgroundColor: MyColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'MODEL',
            child: Column(
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: selectedModelNameNotifier,
                  builder: (context, modelName, child) => ListTile(
                    leading: const Icon(Icons.memory),
                    title: const Text('Selected model'),
                    subtitle: Text(
                      _modelLoadError ??
                          (modelName == 'none'
                              ? 'No model selected'
                              : modelName),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onChangeIndex(1),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const ListTile(
                  leading: Icon(Icons.cloud_download_outlined),
                  title: Text('Model downloads'),
                  subtitle: Text(
                    'All models are downloaded from Hugging Face.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'CHAT DATA',
            child: FutureBuilder<List<ChatSession>>(
              future: _chatHistoryFuture,
              builder: (context, snapshot) {
                final chats = snapshot.data;
                final subtitle = snapshot.hasError
                    ? 'Could not load saved chats: ${snapshot.error}'
                    : chats == null
                    ? 'Loading saved chats...'
                    : '${chats.length} saved '
                          '${chats.length == 1 ? 'chat' : 'chats'}';

                return ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear all chat history'),
                  subtitle: Text(subtitle),
                  trailing: _isClearingChats
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: chats != null && chats.isNotEmpty && !_isClearingChats
                      ? _clearAllChats
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'PRIVACY',
            child: ListTile(
              leading: Icon(Icons.phone_android),
              title: Text('On-device data'),
              subtitle: Text(
                'Chats and settings are stored locally on this device.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: MyColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: child),
      ],
    );
  }
}
