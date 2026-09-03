import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pike/Services/config.dart';

enum ModelModality { text, vision }

class AIModel {
  final String id;
  final String name;
  final String download;
  final String size;
  final String parameters;
  final List<ModelModality> modalities;

  const AIModel({
    required this.id,
    required this.name,
    required this.download,
    required this.size,
    required this.parameters,
    required this.modalities,
  });

  bool get supportsVision => modalities.contains(ModelModality.vision);
  bool get supportsText => modalities.contains(ModelModality.text);
}

extension AIModelStorage on AIModel {
  String get filename => "$id.litertlm";
}

const Map<String, AIModel> allModels = {
  "gemma-4-e2b": AIModel(
    id: "gemma-4-e2b",
    name: "Gemma",
    download:
        "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm",
    size: "2.59 GB",
    parameters: "2B",
    modalities: [ModelModality.text],
  ),
  "gemma-4-e4b": AIModel(
    id: "gemma-4-e4b",
    name: "Gemma",
    download:
        "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm",
    size: "3.66 GB",
    parameters: "4B",
    modalities: [ModelModality.text],
  ),
  "llama-3.2-1b": AIModel(
    id: "llama-3.2-1b",
    name: "Llama",
    download:
        "https://huggingface.co/litert-community/Llama-3.2-1B/resolve/main/llama3_2_1b_mixed_int4_gpu.litertlm",
    size: "964 MB",
    parameters: "1B",
    modalities: [ModelModality.text],
  ),
  "qwen3-0.6b": AIModel(
    id: "qwen3-0.6b",
    name: "Qwen",
    download:
        "https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/qwen3_0_6b_mixed_int4.litertlm",
    size: "498 MB",
    parameters: "0.6B",
    modalities: [ModelModality.text],
  ),
  "qwen2-vl-2b": AIModel(
    id: "qwen2-vl-2b",
    name: "Qwen Vision",
    download:
        "https://huggingface.co/litert-community/Qwen2-VL-2B/resolve/main/Qwen2-VL-2B.litertlm",
    size: "1.78 GB",
    parameters: "2B",
    modalities: [ModelModality.text, ModelModality.vision],
  ),
  "internvl3-1b": AIModel(
    id: "internvl3-1b",
    name: "InternVL",
    download:
        "https://huggingface.co/litert-community/InternVL3-1B/resolve/main/InternVL3-1B.litertlm",
    size: "738 MB",
    parameters: "1B",
    modalities: [ModelModality.text, ModelModality.vision],
  ),
};

enum DownloadState { notDownloaded, downloading, downloaded, failed }

class ModelDownloadStatus {
  final DownloadState state;
  final double progress;
  final String? error;

  const ModelDownloadStatus({required this.state, this.progress = 0.0, this.error});

  bool get isDownloaded => state == DownloadState.downloaded;
}

class ModelStorage {
  Future<Directory> get _directory async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/models');
  }

  Future<File> fileFor(AIModel model) async {
    final directory = await _directory;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/${model.filename}');
  }

  Future<bool> isDownloaded(AIModel model) async {
    return (await fileFor(model)).exists();
  }

  Future<void> delete(AIModel model) async {
    final file = await fileFor(model);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class ModelManager {
  ModelManager._();

  static final ModelManager instance = ModelManager._();

  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<Map<String, ModelDownloadStatus>> downloadStates =
      ValueNotifier<Map<String, ModelDownloadStatus>>({});

  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  String? _loadedModelId;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
    await refreshStatuses();
  }

  Future<void> refreshStatuses() async {
    final statuses = <String, ModelDownloadStatus>{};
    for (final entry in allModels.entries) {
      final model = entry.value;
      final file = await ModelStorage().fileFor(model);
      if (await file.exists()) {
        statuses[model.id] = const ModelDownloadStatus(
          state: DownloadState.downloaded,
          progress: 1.0,
        );
      } else {
        statuses[model.id] = const ModelDownloadStatus(
          state: DownloadState.notDownloaded,
          progress: 0.0,
        );
      }
    }
    downloadStates.value = statuses;
  }

  Future<void> downloadModel(AIModel model) async {
    final file = await ModelStorage().fileFor(model);
    if (await file.exists()) {
      _updateStatus(
        model.id,
        const ModelDownloadStatus(state: DownloadState.downloaded, progress: 1.0),
      );
      return;
    }

    _updateStatus(
      model.id,
      const ModelDownloadStatus(state: DownloadState.downloading, progress: 0.0),
    );
    await _showNotification(model, 'Starting download', ongoing: true, progress: 0);

    try {
      await _dio.download(
        model.download,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            _updateStatus(
              model.id,
              ModelDownloadStatus(
                state: DownloadState.downloading,
                progress: progress,
              ),
            );
            _showNotification(
              model,
              'Downloading ${model.name}',
              ongoing: true,
              progress: (progress * 100).round(),
            );
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 20)),
      );
      _updateStatus(
        model.id,
        const ModelDownloadStatus(state: DownloadState.downloaded, progress: 1.0),
      );
      await _showNotification(model, 'Download complete', ongoing: false, progress: 100);
    } catch (error) {
      _updateStatus(
        model.id,
        ModelDownloadStatus(
          state: DownloadState.failed,
          progress: 0.0,
          error: error.toString(),
        ),
      );
      await _showNotification(model, 'Download failed', ongoing: false, progress: 0);
    }
  }

  Future<void> deleteModel(AIModel model) async {
    final file = await ModelStorage().fileFor(model);
    if (await file.exists()) {
      await file.delete();
    }
    _updateStatus(
      model.id,
      const ModelDownloadStatus(state: DownloadState.notDownloaded, progress: 0.0),
    );

    if (_loadedModelId == model.id) {
      await _disposeEngine();
      _loadedModelId = null;
    }
  }

  Future<void> saveSelectedModel(String modelId) async {
    final config = await loadConfig();
    config['selected_model'] = modelId;
    await saveConfig(config);
  }

  Future<AIModel?> selectedModel() async {
    final config = await loadConfig();
    final selected = config['selected_model'];
    if (selected is String && selected.isNotEmpty && selected != 'None') {
      return allModels[selected];
    }
    return null;
  }

  String? get activeModelId => _loadedModelId;

  Future<String> loadModel({required String modelId}) async {
    if (_loadedModelId == modelId && _engine != null) return '';

    await _disposeEngine();

    final model = allModels[modelId];
    if (model == null) return 'Unknown model ID.';

    final file = await ModelStorage().fileFor(model);
    if (!await file.exists()) {
      return '${model.name} is not downloaded.';
    }

    try {
      _engine = await LiteLmEngine.create(
        LiteLmEngineConfig(
          modelPath: file.path,
          backend: LiteLmBackend.cpu,
        ),
      );

      _conversation = await _engine!.createConversation(
        LiteLmConversationConfig(
          systemInstruction: 'You are a helpful assistant. Be concise and friendly.',
          samplerConfig: const LiteLmSamplerConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
          ),
        ),
      );

      _loadedModelId = modelId;
      return '';
    } catch (error) {
      await _disposeEngine();
      return 'Failed to load model: $error';
    }
  }

  Future<String> runInference(String prompt, {String? modelId}) async {
    final id = modelId ?? (await selectedModel())?.id;
    if (id == null) return 'Select a model from the Models screen first.';

    final model = allModels[id];
    if (model == null) return 'Unknown model.';

    final loadError = await loadModel(modelId: id);
    if (loadError.isNotEmpty) return loadError;
    if (_conversation == null) return 'Model failed to initialize.';

    try {
      final reply = await _conversation!.sendMessage(prompt);
      return reply.text;
    } catch (error) {
      return 'Inference error: $error';
    }
  }

  Stream<String> runInferenceStream(String prompt, {String? modelId}) async* {
    final id = modelId ?? (await selectedModel())?.id;
    if (id == null) {
      yield 'Select a model from the Models screen first.';
      return;
    }

    final loadError = await loadModel(modelId: id);
    if (loadError.isNotEmpty) {
      yield loadError;
      return;
    }
    if (_conversation == null) {
      yield 'Model failed to initialize.';
      return;
    }

    try {
      await for (final delta in _conversation!.sendMessageStream(prompt)) {
        yield delta.text;
      }
    } catch (error) {
      yield 'Inference error: $error';
    }
  }

  Future<void> _disposeEngine() async {
    await _conversation?.dispose();
    _conversation = null;
    await _engine?.dispose();
    _engine = null;
  }

  void _updateStatus(String modelId, ModelDownloadStatus status) {
    final current = Map<String, ModelDownloadStatus>.from(downloadStates.value);
    current[modelId] = status;
    downloadStates.value = current;
  }

  Future<void> _showNotification(
    AIModel model,
    String body, {
    required bool ongoing,
    required int progress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'model_downloads',
      'Model downloads',
      channelDescription: 'Progress updates for local model downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress.clamp(0, 100),
      indeterminate: ongoing && progress == 0,
      onlyAlertOnce: true,
      ongoing: ongoing,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
    await _notifications.show(
      model.id.hashCode,
      'Model download',
      '$body • ${model.name}',
      details,
    );
  }
}
