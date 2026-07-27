import 'package:flutter/material.dart';
import 'package:pike/Pages/chat_history_page.dart';
import 'package:pike/Utilities/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: Text("CHAT", style: TextStyle(color: MyColors.textLight)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add, color: MyColors.textLight),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => ChatHistoryPage(),
                ),
              );
            },
            icon: Icon(Icons.menu, color: MyColors.textLight),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ChatMessageWidget(message: "Hi", isAI: false),
                  ChatMessageWidget(
                    message: "Hi, How can I Help You?",
                    isAI: true,
                  ),
                  ChatMessageWidget(message: "Is Loon a animal?", isAI: false),
                  ChatMessageWidget(
                    message: "Yes Loon is a bird, it looks like a duck",
                    isAI: true,
                  ),
                ],
              ),
            ),
          ),

          // Fixed at the bottom
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(onPressed: () {}, icon: Icon(Icons.send_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String message;
  final bool isAI;
  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isAI,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAI ? MyColors.surfaceDark : MyColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1),
          ),
          child: SelectableText(message),
        ),
      ],
    );
  }
}
