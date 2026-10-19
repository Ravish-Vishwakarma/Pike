import 'package:flutter/material.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Utilities/models.dart';
import 'package:path/path.dart' as p;

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // -------------------- VARIABLES -------------------- //
  String modelName = "";
  int? selectedModelId = 1;
  final models = allModels.values.toList();
  List<AIModel> availableModels = [];
  List<AIModel> downloadableModel = [];

  // ------------------- Functions -------------------- //
  Future<void> getModelName() async {
    final name = await getSelectedModelName();

    if (!mounted) return;

    setState(() {
      modelName = name;
    });
  }

  Future<void> loadModelsList() async {
    final files = await Downloader.getAllDownloadedFiles();

    final fileNames = files.map((file) => p.basename(file)).toSet();

    final downloaded = models.where((model) {
      return fileNames.contains(model.filename);
    }).toList();

    final available = models.where((model) {
      return !fileNames.contains(model.filename);
    }).toList();

    if (!mounted) return;

    setState(() {
      availableModels = downloaded;
      downloadableModel = available;
    });
  }

  // -------------------- INIT STATE -------------------- //
  @override
  void initState() {
    super.initState();
    getModelName();
    loadModelsList();
  }

  // -------------------- BUILDER -------------------- //
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
            ElevatedButton(
              onPressed: () {
                for (var mo in availableModels) {
                  print(mo.filename);
                }
              },
              child: Text("getAllDownloadedFiles"),
            ),
            SelectedModelWidget(modelName: modelName),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Row(
                spacing: 4,
                children: [
                  Expanded(child: Divider()),
                  Text("Available"),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            DownloadedModelWidget(
              models: availableModels,
              selectedModelChange: (id) {
                setState(() {
                  selectedModelId = id;
                });
                print('Selected model ID: $id');
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Row(
                spacing: 4,
                children: [
                  Expanded(child: Divider()),
                  Text("Downloadable"),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: downloadableModel.length,
              itemBuilder: (context, index) {
                final model = downloadableModel[index];
                return ModelDownloadCard(model: model);
              },
            ),

            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== //
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

// ====================================================================== //
class ModelDownloadCard extends StatelessWidget {
  final AIModel model;

  const ModelDownloadCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Card(
        child: ExpansionTile(
          shape: const Border(),
          title: Text(model.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${model.parameters} parameters - ${model.size}'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 5,
                children: [
                  if (model.supportsVision) _capabilityBadge('Vision'),

                  if (model.supportsText) _capabilityBadge('Text'),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Text('file: ${model.filename}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Downloader.downloadFile(model.download, model.filename);
                    },
                    child: const Text('Download Model'),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- WIDGETS -------------------- //
  Widget _capabilityBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        border: Border.all(color: Colors.grey.shade400, width: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ====================================================================== //

class DownloadedModelWidget extends StatefulWidget {
  final ValueChanged<int?> selectedModelChange;
  final List<AIModel> models;

  const DownloadedModelWidget({
    super.key,
    required this.selectedModelChange,
    required this.models,
  });

  @override
  State<DownloadedModelWidget> createState() => _DownloadedModelWidgetState();
}

class _DownloadedModelWidgetState extends State<DownloadedModelWidget> {
  int? selectedModelId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioGroup<int>(
          groupValue: selectedModelId,
          onChanged: (value) {
            setState(() {
              selectedModelId = value;
            });

            widget.selectedModelChange(value);
          },
          child: widget.models.isNotEmpty
              ? Column(
                  children: widget.models.map((model) {
                    return RadioListTile<int>(
                      title: Text(model.name),
                      subtitle: Text("${model.parameters} - ${model.size}"),
                      value: model.id,
                      secondary: IconButton(
                        onPressed: () {
                          Downloader.deleteModel(model.filename);
                        },
                        icon: Icon(Icons.delete),
                      ),
                    );
                  }).toList(),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: MyColors.surfaceLight.withAlpha(130),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "No Model Downloaded\nPlease download a model to select",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
