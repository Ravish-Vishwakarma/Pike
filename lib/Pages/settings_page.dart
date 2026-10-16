import 'package:flutter/material.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/model_not_downloaded_navigator.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<int> onChangeIndex;

  const SettingsPage({super.key, required this.onChangeIndex});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // -------------------- VARIABLES -------------------- //
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
        title: Text("SETTINGS", style: TextStyle(color: MyColors.textLight)),
        backgroundColor: MyColors.primary,
      ),
      body: isModelSelected
          ? SingleChildScrollView(
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
            )
          : PleaseDownloadModelWidget(
              changePageToChat: () {
                widget.onChangeIndex(1);
              },
            ),
    );
  }
}
