import 'package:background_downloader/background_downloader.dart';

class Downloader {
  static Future<void> downloadFile(String url, String fileName) async {
    final task = DownloadTask(
      url: url,
      filename: fileName,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: 'models',
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
    );

    await FileDownloader().enqueue(task);
  }

  static void listenToDownloads() {
    FileDownloader().updates.listen((update) async {
      if (update is TaskStatusUpdate && update.status == TaskStatus.complete) {
        final path = await getDownloadedFilePath(update.task.filename);

        print('Downloaded file path: $path');
      }
      if (update is TaskStatusUpdate) {
        print(
          'Download status: ${update.status} '
          '| File: ${update.task.filename}',
        );
      }

      if (update is TaskProgressUpdate) {
        print(
          'Download progress: '
          '${(update.progress * 100).toStringAsFixed(1)}%',
        );
      }
    });
  }

  static Future<String?> getDownloadedFilePath(String fileName) async {
    final tasks = await FileDownloader().database.allRecords();

    for (final record in tasks) {
      if (record.task.filename == fileName &&
          record.status == TaskStatus.complete) {
        return await record.task.filePath();
      }
    }

    return null;
  }

  static Future<List<String>> getAllDownloadedFiles() async {
    final records = await FileDownloader().database.allRecords();

    final completedRecords = records
        .where((record) => record.status == TaskStatus.complete)
        .toList();

    return await Future.wait(
      completedRecords.map((record) => record.task.filePath()),
    );
  }
}
