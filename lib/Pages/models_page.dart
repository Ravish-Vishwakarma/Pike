import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:pike/Utilities/models.dart';
import 'package:pike/Widgets/download_indicator.dart';

class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  final ModelManager _modelManager = ModelManager.instance;
  String? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _modelManager.initialize();
    _refreshSelection();
  }

  Future<void> _refreshSelection() async {
    final selected = await _modelManager.selectedModel();
    if (!mounted) return;
    setState(() => _selectedModelId = selected?.id);
  }

  @override
  Widget build(BuildContext context) {
    final models = allModels.values.toList();
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        title: const Text("MODELS", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.primary,
        actions: [
          IconButton(
            onPressed: () async {
              await _modelManager.refreshStatuses();
              await _refreshSelection();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: ValueListenableBuilder<Map<String, ModelDownloadStatus>>(
        valueListenable: _modelManager.downloadStates,
        builder: (context, statuses, _) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              final status =
                  statuses[model.id] ??
                  const ModelDownloadStatus(state: DownloadState.notDownloaded);
              return ModelsTile(
                model: model,
                isDownloaded: status.isDownloaded,
                isSelected: _selectedModelId == model.id,
                state: status.state,
                progress: status.progress,
                error: status.error,
                onDownload: () async {
                  await _modelManager.downloadModel(model);
                  await _refreshSelection();
                },
                onDelete: () async {
                  await _modelManager.deleteModel(model);
                  await _refreshSelection();
                },
                onSelect: () async {
                  await _modelManager.saveSelectedModel(model.id);
                  await _refreshSelection();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ModelsTile extends StatelessWidget {
  final AIModel model;
  final bool isDownloaded;
  final bool isSelected;
  final DownloadState state;
  final double progress;
  final String? error;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  const ModelsTile({
    super.key,
    required this.model,
    required this.isDownloaded,
    required this.isSelected,
    required this.state,
    required this.progress,
    this.error,
    required this.onDownload,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = state == DownloadState.downloading;
    final isFailed = state == DownloadState.failed;
    final isActive = isBusy || isFailed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected
              ? MyColors.primary
              : isFailed
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
          width: isSelected || isFailed ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: MyColors.primary.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: isSelected ? null : onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildMeta(isActive: isActive),
              if (isBusy) ...[
                const SizedBox(height: 10),
                _buildDownloadProgress(),
              ],
              if (isFailed) ...[
                const SizedBox(height: 8),
                _buildError(),
              ],
              if (isDownloaded && !isActive) ...[
                const SizedBox(height: 4),
                _buildDownloadedActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: MyColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            model.parameters,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MyColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            model.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isSelected)
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        if (isDownloaded && !isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ready',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeta({bool isActive = false}) {
    return Row(
      children: [
        Icon(Icons.storage_rounded, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(model.size, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(width: 12),
        ...model.modalities.map((m) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m == ModelModality.text ? 'text' : 'vision',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            )),
        const Spacer(),
        if (state == DownloadState.notDownloaded)
          TextButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download'),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        if (isDownloaded && !isActive)
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.grey.shade500),
            style: IconButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Row(
      children: [
        DownloadProgressIndicator(
          progress: progress,
          state: DownloadIndicatorState.downloading,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              '${model.size} model',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error != null ? 'Download failed' : 'Download failed',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: onDownload,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedActions() {
    return Row(
      children: [
        if (!isSelected)
          TextButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Use model'),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const Spacer(),
        Text(
          'Downloaded',
          style: TextStyle(fontSize: 11, color: Colors.green.shade600),
        ),
      ],
    );
  }
}
