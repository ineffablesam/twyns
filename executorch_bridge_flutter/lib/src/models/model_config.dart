import '../messages.g.dart' as pigeon;

/// Configuration for loading an ExecuTorch model
class ModelConfig {
  /// Path to the model file (.pte)
  final String modelPath;

  /// Path to the tokenizer file (.bin, .model, or .json)
  final String tokenizerPath;

  /// Optional list of special tokens for the model
  ///
  /// For LLaMA models, this typically includes tokens like:
  /// - '<|begin_of_text|>'
  /// - '<|end_of_text|>'
  /// - '<|start_header_id|>'
  /// - '<|end_header_id|>'
  /// - '<|eot_id|>'
  final List<String>? specialTokens;

  ModelConfig({
    required this.modelPath,
    required this.tokenizerPath,
    this.specialTokens,
  });

  /// Create a ModelConfig for LLaMA models with default special tokens
  factory ModelConfig.llama({
    required String modelPath,
    required String tokenizerPath,
  }) {
    return ModelConfig(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      specialTokens: [
        '<|begin_of_text|>',
        '<|end_of_text|>',
        '<|reserved_special_token_0|>',
        '<|reserved_special_token_1|>',
        '<|finetune_right_pad_id|>',
        '<|step_id|>',
        '<|start_header_id|>',
        '<|end_header_id|>',
        '<|eom_id|>',
        '<|eot_id|>',
        '<|python_tag|>',
        ...List.generate(254, (i) => '<|reserved_special_token_${i + 2}|>'),
      ],
    );
  }

  /// Create a ModelConfig for Qwen models
  factory ModelConfig.qwen({
    required String modelPath,
    required String tokenizerPath,
  }) {
    return ModelConfig(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
    );
  }

  /// Create a ModelConfig for Phi-4 models
  factory ModelConfig.phi4({
    required String modelPath,
    required String tokenizerPath,
  }) {
    return ModelConfig(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
    );
  }

  /// Convert to Pigeon message format
  pigeon.ModelConfig toPigeon() {
    return pigeon.ModelConfig(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
      specialTokens: specialTokens,
    );
  }

  @override
  String toString() {
    return 'ModelConfig(modelPath: $modelPath, tokenizerPath: $tokenizerPath, specialTokens: ${specialTokens?.length ?? 0})';
  }
}
