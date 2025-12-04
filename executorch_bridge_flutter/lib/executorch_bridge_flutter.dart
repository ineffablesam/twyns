library executorch_bridge_flutter;

export 'src/executorch_bridge.dart';
export 'src/models/generation_config.dart';
export 'src/models/model_config.dart';
export 'src/models/token_stream.dart';

/// A Flutter plugin for ExecuTorch LLM inference on mobile devices.
///
/// This plugin provides a bridge to ExecuTorch's native iOS and Android
/// implementations, enabling on-device LLM inference with models like
/// LLaMA, Qwen, Phi-4, and others.
///
/// Example usage:
/// ```dart
/// final executorch = ExecutorchBridge();
///
/// await executorch.loadModel(
///   ModelConfig(
///     modelPath: '/path/to/model.pte',
///     tokenizerPath: '/path/to/tokenizer.bin',
///   ),
/// );
///
/// executorch.generateText('Hello, how are you?').listen((token) {
///   print(token.text);
/// });
/// ```
