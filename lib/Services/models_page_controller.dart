import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pike/Services/config.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Utilities/models.dart';

class ModelsPageController extends ChangeNotifier {
  final List<AIModel> models = allModels.values.toList();
  final Map<int, ModelDownloadState> modelStates = {};
  List<AIModel> availableModels = [];
  List<AIModel> downloadableModels = [];
  String selectedModelName = 'none';
  int? selectedModelId;
  StreamSubscription<TaskUpdate>? _downloadSubscription;
  bool _disposed = false;

  Future<void> initialize() async {
    _downloadSubscription = Downloader.downloadUpdates.listen(_handleUpdate);
    await Future.wait([refreshModels(), _loadSelectedModel()]);
  }

  Future<void> _loadSelectedModel() async {
    final name = await getSelectedModelName();
    if (_disposed) return;

    selectedModelName = name;
    selectedModelId = models
        .where((model) => model.name == name)
        .firstOrNull
        ?.id;
    notifyListeners();
  }

  Future<void> refreshModels() async {
    final files = await Downloader.getAllDownloadedFiles();
    final records = await Downloader.getAllDownloadRecords();
    if (_disposed) return;

    final fileNames = files.map(p.basename).toSet();
    final updatedStates = <int, ModelDownloadState>{};

    for (final model in models) {
      if (fileNames.contains(model.filename)) {
        updatedStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.available,
          progress: 1,
        );
        continue;
      }

      final matchingRecords =
          records
              .where((record) => record.task.filename == model.filename)
              .toList()
            ..sort(
              (a, b) => b.task.creationTime.compareTo(a.task.creationTime),
            );

      if (matchingRecords.isEmpty) {
        updatedStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.notDownloaded,
        );
        continue;
      }

      final record = matchingRecords.first;
      updatedStates[model.id] = switch (record.status) {
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
    }

    modelStates
      ..clear()
      ..addAll(updatedStates);
    availableModels = models
        .where((model) => fileNames.contains(model.filename))
        .toList();
    downloadableModels = models
        .where((model) => !fileNames.contains(model.filename))
        .toList();
    notifyListeners();
  }

  void _handleUpdate(TaskUpdate update) {
    final model = models
        .where((item) => item.filename == update.task.filename)
        .firstOrNull;
    if (model == null || _disposed) return;

    if (update is TaskProgressUpdate) {
      if (!update.progress.isFinite) return;
      modelStates[model.id] = ModelDownloadState(
        status: ModelDownloadStatus.downloading,
        progress: update.progress.clamp(0.0, 1.0),
      );
      notifyListeners();
      return;
    }

    if (update is! TaskStatusUpdate) return;
    switch (update.status) {
      case TaskStatus.complete:
        unawaited(refreshModels());
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
      case TaskStatus.paused:
        modelStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.downloading,
        );
        notifyListeners();
      case TaskStatus.failed:
      case TaskStatus.notFound:
        modelStates[model.id] = ModelDownloadState(
          status: ModelDownloadStatus.failed,
          error: update.exception?.description ?? 'Download failed.',
        );
        notifyListeners();
      case TaskStatus.canceled:
        modelStates[model.id] = const ModelDownloadState(
          status: ModelDownloadStatus.notDownloaded,
        );
        notifyListeners();
    }
  }

  Future<void> downloadModel(AIModel model) async {
    modelStates[model.id] = const ModelDownloadState(
      status: ModelDownloadStatus.downloading,
    );
    notifyListeners();

    try {
      await Downloader.downloadFile(model.download, model.filename);
    } catch (error) {
      modelStates[model.id] = ModelDownloadState(
        status: ModelDownloadStatus.failed,
        error: error.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> cancelDownload(AIModel model) {
    return Downloader.cancelDownload(model.filename);
  }

  Future<void> selectModel(int? id) async {
    final model = models.where((item) => item.id == id).firstOrNull;
    if (model == null) return;

    await changeConfigSelectedModelName(model.name);
    selectedModelId = model.id;
    selectedModelName = model.name;
    notifyListeners();
  }

  Future<void> deleteModel(AIModel model) async {
    await Downloader.deleteModel(model.filename);
    await refreshModels();

    if (selectedModelId == model.id ||
        selectedModelName == model.name ||
        availableModels.isEmpty) {
      await changeConfigSelectedModelName('none');
      selectedModelId = null;
      selectedModelName = 'none';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _downloadSubscription?.cancel();
    super.dispose();
  }
}
