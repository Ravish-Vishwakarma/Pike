import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
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
  int? selectedModelId;
  final models = allModels.values.toList();
  List<AIModel> availableModels = [];
  List<AIModel> downloadableModel = [];
  Map<int, ModelDownloadState> modelStates = {};
  StreamSubscription<TaskUpdate>? downloadSubscription;
  // ------------------- Functions -------------------- //
  Future<void> getModelName() async {
    final name = await getSelectedModelName();

    if (!mounted) return;

    setState(() {
      modelName = name;
      selectedModelId = models
          .where((model) => model.name == name)
          .firstOrNull
          ?.id;
    });
  }

  Future<void> loadModelsList() async {
    final files = await Downloader.getAllDownloadedFiles();
    final records = await Downloader.getAllDownloadRecords();

    if (!mounted) return;

    final fileNames = files.map((file) => p.basename(file)).toSet();

    final newStates = <int, ModelDownloadState>{};

    for (final model in models) {
      if (fileNames.contains(model.filename)) {
        newStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.available,
          progress: 1.0,
        );
        continue;
      }

      // Find a saved record for this model.
      final matchingRecords =
          records
              .where((record) => record.task.filename == model.filename)
              .toList()
            ..sort(
              (a, b) => b.task.creationTime.compareTo(a.task.creationTime),
            );

      if (matchingRecords.isNotEmpty) {
        final record = matchingRecords.first;
        newStates[model.id] = switch (record.status) {
          TaskStatus.enqueued ||
          TaskStatus.running ||
          TaskStatus.waitingToRetry ||
          TaskStatus.paused => ModelDownloadState(
            status: ModelDownloadStatus.downloading,
            progress: record.progress.clamp(0.0, 1.0),
          ),
          TaskStatus.failed || TaskStatus.notFound => ModelDownloadState(
            status: ModelDownloadStatus.failed,
            error: record.exception?.description ?? 'Download failed.',
          ),
          _ => const ModelDownloadState(
            status: ModelDownloadStatus.notDownloaded,
          ),
        };
      } else {
        newStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.notDownloaded,
        );
      }
    }

    setState(() {
      modelStates = newStates;

      availableModels = models
          .where((model) => fileNames.contains(model.filename))
          .toList();

      downloadableModel = models
          .where((model) => !fileNames.contains(model.filename))
          .toList();
    });
  }

  void listenToDownloads() {
    downloadSubscription = Downloader.downloadUpdates.listen((update) {
      final model = models
          .where((m) => m.filename == update.task.filename)
          .firstOrNull;

      if (model == null || !mounted) return;

      if (update is TaskProgressUpdate) {
        if (!update.progress.isFinite) return;
        setState(() {
          modelStates[model.id] = ModelDownloadState(
            status: ModelDownloadStatus.downloading,
            progress: update.progress.clamp(0.0, 1.0),
          );
        });
      } else if (update is TaskStatusUpdate) {
        switch (update.status) {
          case TaskStatus.complete:
            unawaited(loadModelsList());
          case TaskStatus.enqueued:
          case TaskStatus.running:
          case TaskStatus.waitingToRetry:
          case TaskStatus.paused:
            setState(() {
              modelStates[model.id] = const ModelDownloadState(
                status: ModelDownloadStatus.downloading,
              );
            });
          case TaskStatus.failed:
          case TaskStatus.notFound:
            setState(() {
              modelStates[model.id] = ModelDownloadState(
                status: ModelDownloadStatus.failed,
                error: update.exception?.description ?? 'Download failed.',
              );
            });
          case TaskStatus.canceled:
            setState(() {
              modelStates[model.id] = const ModelDownloadState(
                status: ModelDownloadStatus.notDownloaded,
              );
            });
        }
      }
    });
  }

  Future<void> _downloadModel(AIModel model) async {
    setState(() {
      modelStates[model.id] = const ModelDownloadState(
        status: ModelDownloadStatus.downloading,
      );
    });

    try {
      await Downloader.downloadFile(model.download, model.filename);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        modelStates[model.id] = ModelDownloadState(
          status: ModelDownloadStatus.failed,
          error: error.toString(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start ${model.name}: $error')),
      );
    }
  }

  Future<void> _cancelDownload(AIModel model) async {
    try {
      final cancelled = await Downloader.cancelDownload(model.filename);
      if (!cancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel ${model.name}.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel ${model.name}: $error')),
      );
    }
  }

  Future<void> _selectModel(int? id) async {
    final selectedModel = models.where((model) => model.id == id).firstOrNull;
    if (selectedModel == null) return;

    try {
      await changeConfigSelectedModelName(selectedModel.name);
      if (!mounted) return;
      setState(() {
        selectedModelId = id;
        modelName = selectedModel.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select ${selectedModel.name}: $error'),
        ),
      );
    }
  }

  Future<void> _deleteModel(AIModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete downloaded model?'),
        content: Text('Remove ${model.name} from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Downloader.deleteModel(model.filename);
      if (selectedModelId == model.id) {
        await changeConfigSelectedModelName('none');
      }
      if (!mounted) return;
      setState(() {
        if (selectedModelId == model.id) {
          selectedModelId = null;
          modelName = 'none';
        }
      });
      await loadModelsList();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete ${model.name}: $error')),
      );
    }
  }

  // -------------------- INIT STATE -------------------- //
  @override
  void initState() {
    super.initState();
    getModelName();
    loadModelsList();
    listenToDownloads();
  }

  // -------------------- DISPOSE -------------------- //
  @override
  void dispose() {
    downloadSubscription?.cancel();
    super.dispose();
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
            onPressed: loadModelsList,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
              selectedModelId: selectedModelId,
              selectedModelChange: _selectModel,
              onDeleteModel: _deleteModel,
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

                return ModelDownloadCard(
                  model: model,
                  downloadState: modelStates[model.id],
                  onDownload: () => _downloadModel(model),
                  onCancel: () => _cancelDownload(model),
                );
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
  final ModelDownloadState? downloadState;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  const ModelDownloadCard({
    super.key,
    required this.model,
    required this.downloadState,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        downloadState?.status == ModelDownloadStatus.downloading;
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
                  if (isDownloading) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      child: LinearProgressIndicator(
                        value: downloadState!.progress,
                      ),
                    ),
                    Text(
                      'Downloading ${(downloadState!.progress * 100).toStringAsFixed(0)}%',
                    ),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel download'),
                    ),
                  ] else
                    Column(
                      children: [
                        if (downloadState?.status == ModelDownloadStatus.failed)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              downloadState?.error ?? 'Download failed.',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download),
                          label: Text(
                            downloadState?.status == ModelDownloadStatus.failed
                                ? 'Retry download'
                                : 'Download model',
                          ),
                        ),
                      ],
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
  final int? selectedModelId;
  final ValueChanged<AIModel> onDeleteModel;

  const DownloadedModelWidget({
    super.key,
    required this.selectedModelChange,
    required this.models,
    required this.selectedModelId,
    required this.onDeleteModel,
  });

  @override
  State<DownloadedModelWidget> createState() => _DownloadedModelWidgetState();
}

class _DownloadedModelWidgetState extends State<DownloadedModelWidget> {
  int? selectedModelId;

  @override
  void didUpdateWidget(covariant DownloadedModelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedModelId != widget.selectedModelId) {
      selectedModelId = widget.selectedModelId;
    }
  }

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
                        onPressed: () => widget.onDeleteModel(model),
                        icon: const Icon(Icons.delete),
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
