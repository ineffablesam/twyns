// import 'package:flutter_test/flutter_test.dart';
// import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';
// import 'package:executorch_bridge_flutter/executorch_bridge_flutter_platform_interface.dart';
// import 'package:executorch_bridge_flutter/executorch_bridge_flutter_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockExecutorchBridgeFlutterPlatform
//     with MockPlatformInterfaceMixin
//     implements ExecutorchBridgeFlutterPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final ExecutorchBridgeFlutterPlatform initialPlatform = ExecutorchBridgeFlutterPlatform.instance;
//
//   test('$MethodChannelExecutorchBridgeFlutter is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelExecutorchBridgeFlutter>());
//   });
//
//   test('getPlatformVersion', () async {
//     ExecutorchBridgeFlutter executorchBridgeFlutterPlugin = ExecutorchBridgeFlutter();
//     MockExecutorchBridgeFlutterPlatform fakePlatform = MockExecutorchBridgeFlutterPlatform();
//     ExecutorchBridgeFlutterPlatform.instance = fakePlatform;
//
//     expect(await executorchBridgeFlutterPlugin.getPlatformVersion(), '42');
//   });
// }
