import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

// ================================ CONFIG ================================ //

const String configFileName = "config.json";

Future<File> _getConfigFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$configFileName');
}

// Initilize Config File
Future<void> initConfig() async {
  final file = await _getConfigFile();
  if (!await file.exists()) {
    await createConfig();
  }
}

// Create Config File
Future<void> createConfig() async {
  final file = await _getConfigFile();
  final defaultConfig = {'selected_model': 'none'};

  await file.writeAsString(jsonEncode(defaultConfig), flush: true);
}

// Reads the config file as json
Future<Map<String, dynamic>> loadConfig() async {
  final file = await _getConfigFile();
  if (!await file.exists()) {
    await createConfig();
  }
  final text = await file.readAsString();
  return jsonDecode(text) as Map<String, dynamic>;
}

// Changes the whole json
Future<void> saveConfig(Map<String, dynamic> config) async {
  final file = await _getConfigFile();

  await file.writeAsString(jsonEncode(config), flush: true);
}

// ================================ MODEL NAME ================================ //
// Changes selected model name
Future<void> changeConfigSelectedModelName(String modelName) async {
  final config = await loadConfig();
  config['selected_model'] = modelName;
  await saveConfig(config);
}

// Get Selected Model Name
Future<String> getSelectedModelName() async {
  final config = await loadConfig();
  return config['selected_model'];
}
