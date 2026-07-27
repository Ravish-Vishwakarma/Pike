import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

const String configFileName = "config.json";

Future<File> _getConfigFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$configFileName');
}

Future<void> initConfig() async {
  final file = await _getConfigFile();
  if (!await file.exists()) {
    await createConfig();
  }
}

Future<void> createConfig() async {
  final file = await _getConfigFile();
  final defaultConfig = {'selected_model': 'None'};

  await file.writeAsString(jsonEncode(defaultConfig), flush: true);
}

Future<Map<String, dynamic>> loadConfig() async {
  final file = await _getConfigFile();
  if (!await file.exists()) {
    await createConfig();
  }
  final text = await file.readAsString();
  return jsonDecode(text) as Map<String, dynamic>;
}

Future<void> saveConfig(Map<String, dynamic> config) async {
  final file = await _getConfigFile();

  await file.writeAsString(jsonEncode(config), flush: true);
}
