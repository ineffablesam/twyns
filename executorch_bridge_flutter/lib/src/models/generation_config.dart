import '../messages.g.dart' as pigeon;

/// Configuration for text generation parameters
class GenerationConfig {
  /// Maximum sequence length for the model
  ///
  /// Default values:
  /// - LLaMA/Phi-4: 128
  /// - LLaVA/Gemma3/Qwen3: 768
  final int? sequenceLength;

  /// Maximum number of new tokens to generate
  ///
  /// If not specified, generation continues until end token or sequence length
  final int? maximumNewTokens;

  /// Temperature for sampling (0.0 to 1.0)
  ///
  /// Higher values make output more random, lower values more deterministic
  final double? temperature;

  /// Top-p (nucleus) sampling parameter
  ///
  /// Only tokens with cumulative probability <= topP are considered
  final double? topP;

  GenerationConfig({
    this.sequenceLength,
    this.maximumNewTokens,
    this.temperature,
    this.topP,
  });

  /// Create a config optimized for LLaMA models
  factory GenerationConfig.llama({
    int sequenceLength = 128,
    int? maximumNewTokens,
  }) {
    return GenerationConfig(
      sequenceLength: sequenceLength,
      maximumNewTokens: maximumNewTokens,
    );
  }

  /// Create a config optimized for Qwen models
  factory GenerationConfig.qwen({
    int sequenceLength = 768,
    int? maximumNewTokens,
  }) {
    return GenerationConfig(
      sequenceLength: sequenceLength,
      maximumNewTokens: maximumNewTokens,
    );
  }

  /// Create a config optimized for Phi-4 models
  factory GenerationConfig.phi4({
    int sequenceLength = 128,
    int? maximumNewTokens,
  }) {
    return GenerationConfig(
      sequenceLength: sequenceLength,
      maximumNewTokens: maximumNewTokens,
    );
  }

  /// Convert to Pigeon message format
  pigeon.GenerationConfig toPigeon() {
    return pigeon.GenerationConfig(
      sequenceLength: sequenceLength,
      maximumNewTokens: maximumNewTokens,
      temperature: temperature,
      topP: topP,
    );
  }

  @override
  String toString() {
    return 'GenerationConfig(sequenceLength: $sequenceLength, maximumNewTokens: $maximumNewTokens, temperature: $temperature, topP: $topP)';
  }
}
