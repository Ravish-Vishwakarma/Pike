import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Services/config.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ==================== VARIABLES ==================== //
  String model_name = "";
  getModelName() async {
    final name = await getSelectedModelName();
    setState(() {
      model_name = name;
    });
  }

  // ==================== INIT STATE ==================== //
  @override
  void initState() {
    super.initState();
    getModelName();
  }

  // ==================== BUILDER ==================== //
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: const Text("MODELS", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: () async {},
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectedModelWidget(modelName: model_name),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Divider(),
            ),
            ElevatedButton(
              child: Text("Change"),
              onPressed: () {
                setState(() {
                  model_name = "New One";
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedModelWidget extends StatefulWidget {
  final String modelName;
  const SelectedModelWidget({super.key, required this.modelName});

  @override
  State<SelectedModelWidget> createState() => _SelectedModelWidgetState();
}

class _SelectedModelWidgetState extends State<SelectedModelWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Selected Model: ",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          Text(widget.modelName),
        ],
      ),
    );
  }
}
