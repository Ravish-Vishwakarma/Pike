import 'package:flutter/material.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Services/config.dart';

class ChatPage extends StatefulWidget {
  final ValueChanged<int> onChangeIndex;
  const ChatPage({super.key, required this.onChangeIndex});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController chat_name_controller = TextEditingController();
  bool isModelSelected = false;

  void checkModelSelected() async {
    final modelName = await getSelectedModelName();
    if (modelName == "none") {
      isModelSelected = false;
    } else {
      isModelSelected = true;
    }
  }

  @override
  void initState() {
    super.initState();
    checkModelSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: isModelSelected
            ? TextFormField(
                controller: chat_name_controller,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: "Chat Name",
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : null,
        centerTitle: true,
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
      body: isModelSelected
          ? Text("Chat Page")
          : Center(
              child: PleaseDownloadModelWidget(
                changePageToChat: () {
                  widget.onChangeIndex(1);
                },
              ),
            ),
    );
  }
}

class PleaseDownloadModelWidget extends StatelessWidget {
  final VoidCallback changePageToChat;
  const PleaseDownloadModelWidget({super.key, required this.changePageToChat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "No Model Is Downloaded\nPlease Download a Model!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: changePageToChat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Download"),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
