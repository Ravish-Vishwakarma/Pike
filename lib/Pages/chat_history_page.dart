import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.primary,
        title: Text(
          "Chat History",
          style: TextStyle(color: MyColors.textLight),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: MyColors.textLight),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ChatHistoryCard(date: "Date", title: "TItle", id: 10);
        },
      ),
    );
  }
}

class ChatHistoryCard extends StatelessWidget {
  final String date;
  final String title;
  final int id;
  const ChatHistoryCard({
    super.key,
    required this.date,
    required this.title,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 0.0,
        ),
        title: Text(title),
        subtitle: Text(date),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            // _handleMenuSelection(context, value);
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(value: 'open', child: Text('Open')),
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Rename'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
