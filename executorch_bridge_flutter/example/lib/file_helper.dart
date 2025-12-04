import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileHelper {
  /// Return the path EXACTLY as picked. No copying, no modifying.
  /// This keeps the tokenizer binary 100% intact.
  static Future<String> keepOriginalPath(String sourcePath) async {
    final file = File(sourcePath);

    if (!await file.exists()) {
      throw Exception("File not found: $sourcePath");
    }

    print("Using original file path (no copying): $sourcePath");
    return sourcePath;
  }

  static Future<String> copyToDocuments(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: $sourcePath');
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = sourcePath.split('/').last;
      final destinationPath = '${documentsDir.path}/$fileName';

      print('📋 Copying file:');
      print('   From: $sourcePath');
      print('   To: $destinationPath');

      // Check if file already exists and delete it
      final destinationFile = File(destinationPath);
      if (await destinationFile.exists()) {
        await destinationFile.delete();
        print('🗑️ Deleted existing file: $destinationPath');
      }

      // Copy the file
      await sourceFile.copy(destinationPath);

      // Verify the copy
      final copiedFile = File(destinationPath);
      final sourceSize = await sourceFile.length();
      final copiedSize = await copiedFile.length();

      print('✅ File copied successfully:');
      print('   Source size: $sourceSize bytes');
      print('   Copied size: $copiedSize bytes');
      print('   Files match: ${sourceSize == copiedSize}');

      return destinationPath;
    } catch (e, stackTrace) {
      print('❌ Error copying file: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Minimal validation – only checks that file exists.
  /// DO NOT inspect bytes, DO NOT read content (prevents corruption).
  static Future<bool> validateFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      print("❌ File does not exist: $filePath");
      return false;
    }

    print("✅ File exists: $filePath");
    return true;
  }

  /// Tokenizer must be .model
  static bool isValidTokenizerFile(String name) {
    return path.extension(name).toLowerCase() == ".model" ||
        path.extension(name).toLowerCase() == ".json";
  }

  /// Model must be .pte
  static bool isValidModelFile(String name) {
    return path.extension(name).toLowerCase() == ".pte";
  }

  /// These are now no-ops
  static Future<String> getModelsDirectory() async => "";
  static Future<void> cleanupOldFiles() async {}
}
