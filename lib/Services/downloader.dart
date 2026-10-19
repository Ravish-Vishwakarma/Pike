import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Downloader {
  static final StreamController<TaskUpdate> _downloadUpdates =
      StreamController<TaskUpdate>.broadcast();
  static StreamSubscription<TaskUpdate>? _updatesSubscription;
  static final Set<String> _enqueuingFiles = {};

  static Stream<TaskUpdate> get downloadUpdates => _downloadUpdates.stream;

  static Future<List<TaskRecord>> getAllDownloadRecords() async {
    return FileDownloader().database.allRecords();
  }

  static Future<void> downloadFile(String url, String fileName) async {
    if (!_enqueuingFiles.add(fileName)) {
      throw StateError('A download is already being started for $fileName');
    }

    try {
      final records = await getAllDownloadRecords();
      if (records.any(
        (record) =>
            record.task.filename == fileName && record.status.isNotFinalState,
      )) {
        throw StateError('A download is already active for $fileName');
      }

      final task = DownloadTask(
        url: url,
        filename: fileName,
        baseDirectory: BaseDirectory.applicationSupport,
        directory: 'models',
        updates: Updates.statusAndProgress,
        allowPause: true,
        retries: 3,
      );

      final enqueued = await FileDownloader().enqueue(task);
      if (!enqueued) {
        throw StateError('The download could not be queued for $fileName');
      }
    } finally {
      _enqueuingFiles.remove(fileName);
    }
  }

  static void listenToDownloads() {
    if (_updatesSubscription != null) return;

    _updatesSubscription = FileDownloader().updates.listen(
      _downloadUpdates.add,
    );
  }

  static Future<bool> cancelDownload(String fileName) async {
    final records = await getAllDownloadRecords();
    final activeTaskIds = records
        .where(
          (record) =>
              record.task.filename == fileName && record.status.isNotFinalState,
        )
        .map((record) => record.task.taskId)
        .toList();

    if (activeTaskIds.isEmpty) {
      throw StateError('No active download found for $fileName');
    }

    return FileDownloader().cancelTasksWithIds(activeTaskIds);
  }

  static Future<String?> getDownloadedFilePath(String fileName) async {
    final file = await _modelFile(fileName);
    return await file.exists() ? file.path : null;
  }

  static Future<List<String>> getAllDownloadedFiles() async {
    final directory = await _modelsDirectory();
    if (!await directory.exists()) return [];

    final files = await directory
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is File &&
              p.extension(entity.path).toLowerCase() == '.litertlm',
        )
        .map((entity) => entity.path)
        .toList();
    return files;
  }

  static Future<void> deleteModel(String fileName) async {
    final file = await _modelFile(fileName);
    if (await file.exists()) await file.delete();
  }

  static Future<File> _modelFile(String fileName) async {
    if (p.basename(fileName) != fileName) {
      throw ArgumentError.value(fileName, 'fileName', 'Must be a file name');
    }
    final directory = await _modelsDirectory();
    return File(p.join(directory.path, fileName));
  }

  static Future<Directory> _modelsDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory(p.join(supportDirectory.path, 'models'));
  }
}

enum ModelDownloadStatus { notDownloaded, downloading, available, failed }

class ModelDownloadState {
  final ModelDownloadStatus status;
  final double progress;
  final String? error;

  const ModelDownloadState({
    required this.status,
    this.progress = 0.0,
    this.error,
  });
}
