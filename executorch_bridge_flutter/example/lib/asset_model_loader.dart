import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetModelLoader {
  /// Copy model and tokenizer from assets to local storage
  /// Returns the local file paths
  static Future<ModelPaths> loadFromAssets({
    required String modelAssetPath,
    required String tokenizerAssetPath,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    // Create models directory
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // Copy model file
    final modelFileName = modelAssetPath.split('/').last;
    final modelFile = File('${modelsDir.path}/$modelFileName');

    if (!await modelFile.exists()) {
      print('Copying model from assets...');
      final modelData = await rootBundle.load(modelAssetPath);
      await modelFile.writeAsBytes(
        modelData.buffer.asUint8List(
          modelData.offsetInBytes,
          modelData.lengthInBytes,
        ),
      );
      print('Model copied to: ${modelFile.path}');
    } else {
      print('Model already exists at: ${modelFile.path}');
    }

    // Copy tokenizer file
    final tokenizerFileName = tokenizerAssetPath.split('/').last;
    final tokenizerFile = File('${modelsDir.path}/$tokenizerFileName');

    if (!await tokenizerFile.exists()) {
      print('Copying tokenizer from assets...');
      final tokenizerData = await rootBundle.load(tokenizerAssetPath);
      await tokenizerFile.writeAsBytes(
        tokenizerData.buffer.asUint8List(
          tokenizerData.offsetInBytes,
          tokenizerData.lengthInBytes,
        ),
      );
      print('Tokenizer copied to: ${tokenizerFile.path}');
    } else {
      print('Tokenizer already exists at: ${tokenizerFile.path}');
    }

    return ModelPaths(
      modelPath: modelFile.path,
      tokenizerPath: tokenizerFile.path,
    );
  }

  /// Check if model files already exist in local storage
  static Future<bool> isModelCached({
    required String modelAssetPath,
    required String tokenizerAssetPath,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');

    final modelFileName = modelAssetPath.split('/').last;
    final tokenizerFileName = tokenizerAssetPath.split('/').last;

    final modelFile = File('${modelsDir.path}/$modelFileName');
    final tokenizerFile = File('${modelsDir.path}/$tokenizerFileName');

    return await modelFile.exists() && await tokenizerFile.exists();
  }

  /// Clear cached model files
  static Future<void> clearCache() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');

    if (await modelsDir.exists()) {
      await modelsDir.delete(recursive: true);
      print('Model cache cleared');
    }
  }
}

class ModelPaths {
  final String modelPath;
  final String tokenizerPath;

  ModelPaths({required this.modelPath, required this.tokenizerPath});
}
