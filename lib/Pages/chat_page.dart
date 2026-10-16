import 'package:flutter/material.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Utilities/model_not_downloaded_navigator.dart';

class ChatPage extends StatefulWidget {
  final ValueChanged<int> onChangeIndex;
  const ChatPage({super.key, required this.onChangeIndex});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // -------------------- VARIABLES -------------------- //
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

  // -------------------- INIT STATE -------------------- //
  @override
  void initState() {
    super.initState();
    checkModelSelected();
  }

  // -------------------- BUILDER -------------------- //
  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            : Text("Chat", style: TextStyle(color: Colors.white)),
        // centerTitle: true,
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
