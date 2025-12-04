import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartOptions: DartOptions(),
  swiftOut:
      'ios/executorch_bridge_flutter/Sources/executorch_bridge_flutter/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/example/executorch_bridge_flutter/Messages.g.kt',
  kotlinOptions: KotlinOptions(),
))

/// Configuration for model loading
class ModelConfig {
  String? modelPath;
  String? tokenizerPath;
  List<String?>? specialTokens;
}

/// Configuration for text generation
class GenerationConfig {
  int? sequenceLength;
  int? maximumNewTokens;
  double? temperature;
  double? topP;
}

/// Response from model operations
class ModelResponse {
  bool? success;
  String? error;
  String? message;
  double? loadTime;
}

/// Token generation callback data
class TokenData {
  String? token;
  int? tokenCount;
  double? tokensPerSecond;
}

/// Memory usage information
class MemoryInfo {
  int? usedMemoryMB;
  int? availableMemoryMB;
}

/// Platform interface for ExecuTorch operations
@HostApi()
abstract class ExecutorchApi {
  /// Initialize the ExecuTorch runner with model and tokenizer
  @async
  ModelResponse loadModel(ModelConfig config);

  /// Check if model is currently loaded
  bool isModelLoaded();

  /// Unload the current model
  void unloadModel();

  /// Generate text from prompt
  @async
  ModelResponse generateText(String prompt, GenerationConfig config);

  /// Stop ongoing text generation
  void stopGeneration();

  /// Get current memory usage
  MemoryInfo getMemoryInfo();

  /// Validate if file exists at path
  bool validateFilePath(String path);
}

/// Flutter interface for receiving callbacks from platform
@FlutterApi()
abstract class ExecutorchFlutterApi {
  /// Called when a new token is generated
  void onTokenGenerated(TokenData token);

  /// Called when generation is complete
  void onGenerationComplete(String fullText, int totalTokens);

  /// Called when an error occurs
  void onError(String error);
}
