import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Services/config.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  String model_name = "";
  changeModelName() async {
    final name = await getSelectedModelName();
    setState(() {
      model_name = name;
    });
  }

  @override
  void initState() {
    super.initState();
    changeModelName();
  }

  @override
  Widget build(BuildContext context) {
    // final models = allModels.values.toList();
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
      body: Text(model_name),
    );
  }
}
