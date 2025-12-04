import 'dart:async';

import 'package:flutter/foundation.dart';

import 'messages.g.dart' as pigeon;
import 'models/generation_config.dart' as models;
import 'models/model_config.dart' as models;
import 'models/token_stream.dart';

/// Main bridge class for ExecuTorch operations
class ExecutorchBridge implements pigeon.ExecutorchFlutterApi {
  ExecutorchBridge() {
    pigeon.ExecutorchFlutterApi.setup(this);
  }

  final pigeon.ExecutorchApi _api = pigeon.ExecutorchApi();

  StreamController<TokenStreamData>? _tokenController;
  final _generationCompleteController =
      StreamController<GenerationResult>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  /// Stream of generation completion events
  Stream<GenerationResult> get generationComplete =>
      _generationCompleteController.stream;

  /// Stream of error events
  Stream<String> get errors => _errorController.stream;

  /// Load a model with the specified configuration
  ///
  /// Returns a [ModelLoadResult] with success status and optional error message.
  ///
  /// Example:
  /// ```dart
  /// final result = await executorch.loadModel(
  ///   ModelConfig.llama(
  ///     modelPath: '/path/to/llama.pte',
  ///     tokenizerPath: '/path/to/tokenizer.bin',
  ///   ),
  /// );
  ///
  /// if (result.success) {
  ///   print('Model loaded in ${result.loadTime}s');
  /// }
  /// ```
  Future<ModelLoadResult> loadModel(models.ModelConfig config) async {
    try {
      final pigeonConfig = config.toPigeon();
      final response = await _api.loadModel(pigeonConfig);

      return ModelLoadResult(
        success: response.success ?? false,
        error: response.error,
        message: response.message,
        loadTime: response.loadTime,
      );
    } catch (e) {
      return ModelLoadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if a model is currently loaded
  Future<bool> isModelLoaded() async {
    try {
      return await _api.isModelLoaded();
    } catch (e) {
      debugPrint('Error checking model status: $e');
      return false;
    }
  }

  /// Unload the current model and free resources
  Future<void> unloadModel() async {
    try {
      await _api.unloadModel();
    } catch (e) {
      debugPrint('Error unloading model: $e');
    }
  }

  /// Generate text from a prompt with streaming token output
  ///
  /// Returns a [Stream<TokenStreamData>] that emits tokens as they're generated.
  ///
  /// Example:
  /// ```dart
  /// final stream = executorch.generateText(
  ///   'What is the capital of France?',
  ///   config: GenerationConfig.llama(sequenceLength: 128),
  /// );
  ///
  /// await for (final token in stream) {
  ///   print('${token.text} (${token.tokensPerSecond} t/s)');
  /// }
  /// ```
  Stream<TokenStreamData> generateText(
    String prompt, {
    models.GenerationConfig? config,
  }) {
    _tokenController?.close();
    _tokenController = StreamController<TokenStreamData>();

    _generateTextInternal(prompt, config ?? models.GenerationConfig());

    return _tokenController!.stream;
  }

  Future<void> _generateTextInternal(
    String prompt,
    models.GenerationConfig config,
  ) async {
    try {
      final pigeonConfig = config.toPigeon();
      await _api.generateText(prompt, pigeonConfig);
    } catch (e) {
      _tokenController?.addError(e);
      _tokenController?.close();
      _tokenController = null;
    }
  }

  /// Stop the current text generation
  Future<void> stopGeneration() async {
    try {
      await _api.stopGeneration();
    } catch (e) {
      debugPrint('Error stopping generation: $e');
    }
  }

  /// Get current memory usage information
  ///
  /// Returns [MemoryUsage] with used and available memory in MB.
  Future<MemoryUsage> getMemoryInfo() async {
    try {
      final info = await _api.getMemoryInfo();
      return MemoryUsage(
        usedMemoryMB: info.usedMemoryMB ?? 0,
        availableMemoryMB: info.availableMemoryMB ?? 0,
      );
    } catch (e) {
      debugPrint('Error getting memory info: $e');
      return MemoryUsage(usedMemoryMB: 0, availableMemoryMB: 0);
    }
  }

  /// Validate if a file exists at the specified path
  Future<bool> validateFilePath(String path) async {
    try {
      return await _api.validateFilePath(path);
    } catch (e) {
      debugPrint('Error validating file path: $e');
      return false;
    }
  }

  // ExecutorchFlutterApi implementation
  @override
  void onTokenGenerated(pigeon.TokenData token) {
    if (_tokenController != null && !_tokenController!.isClosed) {
      _tokenController!.add(TokenStreamData(
        text: token.token ?? '',
        tokenCount: token.tokenCount ?? 0,
        tokensPerSecond: token.tokensPerSecond ?? 0.0,
      ));
    }
  }

  @override
  void onGenerationComplete(String fullText, int totalTokens) {
    _tokenController?.close();
    _tokenController = null;

    _generationCompleteController.add(
      GenerationResult(
        text: fullText,
        totalTokens: totalTokens,
      ),
    );
  }

  @override
  void onError(String error) {
    _tokenController?.addError(error);
    _tokenController?.close();
    _tokenController = null;

    _errorController.add(error);
  }

  /// Dispose of resources
  void dispose() {
    _tokenController?.close();
    _generationCompleteController.close();
    _errorController.close();
  }
}

/// Result of model loading operation
class ModelLoadResult {
  final bool success;
  final String? error;
  final String? message;
  final double? loadTime;

  ModelLoadResult({
    required this.success,
    this.error,
    this.message,
    this.loadTime,
  });
}

/// Memory usage information
class MemoryUsage {
  final int usedMemoryMB;
  final int availableMemoryMB;

  MemoryUsage({
    required this.usedMemoryMB,
    required this.availableMemoryMB,
  });

  @override
  String toString() =>
      'MemoryUsage(used: ${usedMemoryMB}MB, available: ${availableMemoryMB}MB)';
}

/// Result of text generation
class GenerationResult {
  final String text;
  final int totalTokens;

  GenerationResult({
    required this.text,
    required this.totalTokens,
  });
}
