enum ModelModality { text, vision }

class AIModel {
  final int id;
  final String name;
  final String filename;
  final String download;
  final String size;
  final String parameters;
  final List<ModelModality> modalities;

  const AIModel({
    required this.id,
    required this.filename,
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
    id: 1,
    name: "Gemma e2B",
    filename: "gemma-4-E2B-it.litertlm",
    download:
        "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm",
    size: "2.59 GB",
    parameters: "2B",
    modalities: [ModelModality.text],
  ),
  "gemma-4-e4b": AIModel(
    id: 2,
    name: "Gemma e4B",
    filename: "gemma-4-E4B-it.litertlm",
    download:
        "https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm",
    size: "3.66 GB",
    parameters: "4B",
    modalities: [ModelModality.text],
  ),
  "llama-3.2-1b": AIModel(
    id: 3,
    name: "Llama3 1B",
    filename: "llama3_2_1b_mixed_int4_gpu.litertlm",
    download:
        "https://huggingface.co/litert-community/Llama-3.2-1B/resolve/main/llama3_2_1b_mixed_int4_gpu.litertlm",
    size: "964 MB",
    parameters: "1B",
    modalities: [ModelModality.text],
  ),
  "qwen3-0.6b": AIModel(
    id: 4,
    name: "Qwen3 6B",
    filename: "qwen3_0_6b_mixed_int4.litertlm",
    download:
        "https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/qwen3_0_6b_mixed_int4.litertlm",
    size: "498 MB",
    parameters: "0.6B",
    modalities: [ModelModality.text],
  ),
  "qwen2-vl-2b": AIModel(
    id: 5,
    name: "Qwen Vision 2B",
    filename: "Qwen2-VL-2B.litertlm",
    download:
        "https://huggingface.co/litert-community/Qwen2-VL-2B/resolve/main/Qwen2-VL-2B.litertlm",
    size: "1.78 GB",
    parameters: "2B",
    modalities: [ModelModality.text, ModelModality.vision],
  ),
  "internvl3-1b": AIModel(
    id: 6,
    name: "InternVL3 1B",
    filename: "InternVL3-1B.litertlm",
    download:
        "https://huggingface.co/litert-community/InternVL3-1B/resolve/main/InternVL3-1B.litertlm",
    size: "738 MB",
    parameters: "1B",
    modalities: [ModelModality.text, ModelModality.vision],
  ),
};
