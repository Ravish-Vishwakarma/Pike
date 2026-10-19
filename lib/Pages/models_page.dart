import 'package:flutter/material.dart';
import 'package:pike/Services/models_page_controller.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/models.dart';
import 'package:pike/Widgets/models/downloaded_model_list.dart';
import 'package:pike/Widgets/models/model_download_card.dart';
import 'package:pike/Widgets/models/models_section_header.dart';
import 'package:pike/Widgets/models/selected_model_widget.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage>
    with AutomaticKeepAliveClientMixin {
  late final ModelsPageController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = ModelsPageController()..addListener(_onControllerChanged);
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _controller.initialize();
    } catch (error) {
      _showError('Could not load models: $error');
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _downloadModel(AIModel model) async {
    try {
      await _controller.downloadModel(model);
    } catch (error) {
      _showError('Could not start ${model.name}: $error');
    }
  }

  Future<void> _cancelDownload(AIModel model) async {
    try {
      final cancelled = await _controller.cancelDownload(model);
      if (!cancelled) _showError('Could not cancel ${model.name}.');
    } catch (error) {
      _showError('Could not cancel ${model.name}: $error');
    }
  }

  Future<void> _selectModel(int? id) async {
    try {
      await _controller.selectModel(id);
    } catch (error) {
      _showError('Could not select model: $error');
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
      await _controller.deleteModel(model);
    } catch (error) {
      _showError('Could not delete ${model.name}: $error');
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: const Text('MODELS', style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await _controller.refreshModels();
              } catch (error) {
                _showError('Could not refresh models: $error');
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SelectedModelWidget(modelName: _controller.selectedModelName),
            const ModelsSectionHeader(title: 'Available'),
            DownloadedModelList(
              models: _controller.availableModels,
              selectedModelId: _controller.selectedModelId,
              onSelect: _selectModel,
              onDelete: _deleteModel,
            ),
            const ModelsSectionHeader(title: 'Downloadable'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.downloadableModels.length,
              itemBuilder: (context, index) {
                final model = _controller.downloadableModels[index];
                return ModelDownloadCard(
                  model: model,
                  downloadState: _controller.modelStates[model.id],
                  onDownload: () => _downloadModel(model),
                  onCancel: () => _cancelDownload(model),
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
