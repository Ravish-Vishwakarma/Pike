import 'package:flutter/material.dart';
import 'package:pike/Pages/home_page.dart';
import 'package:pike/Services/config.dart';
import 'package:pike/Services/db.dart';
import 'package:pike/Services/downloader.dart';
import 'package:pike/Utilities/colors.dart';
import 'package:background_downloader/background_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------- Downloader --------- //
  await FileDownloader().start(autoCleanDatabase: true);
  await FileDownloader().configure(
    androidConfig: [(Config.runInForeground, Config.always)],
  );
  FileDownloader().configureNotification(
    running: const TaskNotification('Downloading', '{filename}'),
    complete: const TaskNotification('Download complete', '{filename}'),
    error: const TaskNotification('Download failed', '{filename}'),
    progressBar: true,
  );
  Downloader.listenToDownloads();

  // ----------- Config ----------- //
  await initConfig();
  final config = await loadConfig();
  print(config['selected_model']);

  // ---------- Database ---------- //
  await initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: MyColors.primary),
      ),
      home: const HomePage(),
    );
  }
}
