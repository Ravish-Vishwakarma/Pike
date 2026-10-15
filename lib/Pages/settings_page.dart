import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: Text("SETTINGS", style: TextStyle(color: MyColors.textLight)),
        backgroundColor: MyColors.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text("Model: "),
            //       DropdownMenuFormField(
            //         dropdownMenuEntries: [
            //           DropdownMenuEntry(value: '1', label: "Kimi"),
            //           DropdownMenuEntry(value: '2', label: "DeepSeek"),
            //           DropdownMenuEntry(value: '3', label: "Gemma"),
            //           DropdownMenuEntry(value: '4', label: "BigPickle"),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            Text("Settings"),
          ],
        ),
      ),
    );
  }
}
