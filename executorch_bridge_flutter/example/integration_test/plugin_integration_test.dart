import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ExecutorchBridge can be instantiated', (
    WidgetTester tester,
  ) async {
    final executorch = ExecutorchBridge();
    expect(executorch, isNotNull);
  });

  testWidgets('Model loading returns failure with invalid paths', (
    WidgetTester tester,
  ) async {
    final executorch = ExecutorchBridge();

    final result = await executorch.loadModel(
      ModelConfig(
        modelPath: '/invalid/path/model.pte',
        tokenizerPath: '/invalid/path/tokenizer.bin',
      ),
    );

    expect(result.success, false);
    expect(result.error, isNotNull);
  });

  testWidgets('isModelLoaded returns false initially', (
    WidgetTester tester,
  ) async {
    final executorch = ExecutorchBridge();
    final isLoaded = await executorch.isModelLoaded();
    expect(isLoaded, false);
  });

  testWidgets('validateFilePath returns false for invalid path', (
    WidgetTester tester,
  ) async {
    final executorch = ExecutorchBridge();
    final isValid = await executorch.validateFilePath('/invalid/path.pte');
    expect(isValid, false);
  });

  testWidgets('getMemoryInfo returns valid memory data', (
    WidgetTester tester,
  ) async {
    final executorch = ExecutorchBridge();
    final memory = await executorch.getMemoryInfo();

    expect(memory.usedMemoryMB, greaterThanOrEqualTo(0));
    expect(memory.availableMemoryMB, greaterThanOrEqualTo(0));
  });
}
