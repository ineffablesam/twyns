import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/auth_controller.dart';

class SplashController extends GetxController {
  // Observables
  var isDownloading = false.obs;
  var downloadProgress = 0.0.obs;
  var downloadStatus = "Initialising...".obs;
  var currentFileIndex = 0.obs;
  var hasError = false.obs;
  var currentFactIndex = 0.obs;

  final bool forceRedownload = true;

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;

  // Server configuration
  final String baseUrl = "http://192.168.1.157:8000";

  // Files to download
  final List<Map<String, String>> filesToDownload = [
    {"name": "tokenizer.model", "filename": "tokenizer.model"},
    {"name": "llama-squint.pte", "filename": "llama-squint.pte"},
  ];

  // Did you know facts
  final List<String> didYouKnowFacts = [
    "The World Runs on ARM\nARM chips power over 250 billion devices globally — from smartphones to Mars rovers.",
    "95% of Mobile AI Runs on ARM\nAlmost all mobile AI workloads run on ARM architecture due to efficiency and low power consumption.",
    "Apple's M-Series & iPhones Run on ARM\nARM architecture is the foundation behind Apple Silicon's breakthrough performance.",
    "ARM = Efficiency King\nARM processors deliver 3× more performance per watt compared to traditional desktop CPUs.",
    "Your App Is Future-Proof\nMost upcoming laptops (Windows & Mac) are shifting to ARM — this app is already optimized.",
    "ARM = AI Everywhere\nFrom drones to medical devices — ARM makes AI portable and affordable.",
    "ARM's First Chip Was Made in 1990\nAnd today ARM powers 70% of the world's digital devices.",
  ];

  Dio dio = Dio();
  Timer? factTimer;

  @override
  void onInit() {
    super.onInit();
    _startSplashSequence();
  }

  @override
  void onClose() {
    factTimer?.cancel();
    super.onClose();
  }

  /// Start splash sequence
  void _startSplashSequence() async {
    // Wait for initial animations to complete
    await Future.delayed(const Duration(seconds: 3));
    final authController = Get.find<AuthController>();

    // Check if user is authenticated
    await authController.checkAuthStatus();
    try {
      // Check if user has completed onboarding
      final authController = Get.find<AuthController>();

      if (authController.isAuthenticated.value) {
        debugPrint('✅ User already authenticated, going to home');
        Get.offAllNamed('/home');
        return;
      }

      // Check if files already exist
      bool filesExist = await _checkFilesExist();

      if (filesExist && !forceRedownload) {
        debugPrint('✅ Files exist, going to onboarding');
        Get.offAllNamed('/onboarding');
      } else {
        // Start downloading UI
        isDownloading.value = true;

        // Start cycling through facts
        _startFactRotation();

        // Start actual download process
        await _downloadFiles();
      }
    } catch (e) {
      debugPrint('❌ Error in splash sequence: $e');
      // If error checking auth, proceed to onboarding
      Get.offAllNamed('/onboarding');
    }
  }

  /// Check if files already exist
  Future<bool> _checkFilesExist() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String modelDir = '${appDocDir.path}/models';

      bool allFilesExist = true;

      for (var file in filesToDownload) {
        String filePath = '$modelDir/${file['filename']}';
        File f = File(filePath);

        if (forceRedownload) {
          // Delete if exists
          if (await f.exists()) {
            await f.delete();
            debugPrint("🧹 Deleted old file: ${file['filename']}");
          }
          allFilesExist = false; // force it to re-download
          continue;
        }

        if (!await f.exists()) {
          allFilesExist = false;
        }
      }

      return allFilesExist;
    } catch (e) {
      debugPrint('❌ Error checking files: $e');
      return false;
    }
  }

  /// Download all files sequentially
  Future<void> _downloadFiles() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String modelDir = '${appDocDir.path}/models';

      // Create models directory if it doesn't exist
      await Directory(modelDir).create(recursive: true);

      for (int i = 0; i < filesToDownload.length; i++) {
        currentFileIndex.value = i;
        var file = filesToDownload[i];

        String downloadUrl = '$baseUrl/download/${file['filename']}';
        String savePath = '$modelDir/${file['filename']}';

        // Reset progress for new file
        downloadProgress.value = 0.0;
        downloadStatus.value = i == 0
            ? "Initialising..."
            : "Downloading ${file['name']}...";

        await _downloadFile(downloadUrl, savePath);
      }

      // All files downloaded successfully
      downloadStatus.value = "Complete!";
      await Future.delayed(const Duration(milliseconds: 800));

      // Navigate to onboarding
      Get.offAllNamed('/onboarding');
    } catch (e) {
      hasError.value = true;
      downloadStatus.value = "Download failed";
      debugPrint("❌ Download error: $e");
    }
  }

  /// Download single file with progress tracking and auto-retry
  Future<void> _downloadFile(String url, String savePath) async {
    String tempPath = '$savePath.tmp';
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        hasError.value = false;

        // Download to temporary file first
        await dio.download(
          url,
          tempPath,
          deleteOnError: true,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              double progress = received / total;
              downloadProgress.value = progress;

              if (progress < 1.0) {
                String percentStr = (progress * 100).toStringAsFixed(1);
                String receivedMB = (received / (1024 * 1024)).toStringAsFixed(
                  1,
                );
                String totalMB = (total / (1024 * 1024)).toStringAsFixed(1);

                if (currentFileIndex.value == 0 && progress < 0.3) {
                  downloadStatus.value = "Initialising...";
                } else {
                  String retryText = retryCount > 0
                      ? " (Retry $retryCount/$maxRetries)"
                      : "";
                  downloadStatus.value =
                      "Downloading $receivedMB MB / $totalMB MB ($percentStr%)$retryText";
                }
              }
            }
          },
          options: Options(
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(minutes: 10),
          ),
        );

        // Rename to final file if download completed successfully
        File tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.rename(savePath);
        }

        return;
      } catch (e) {
        retryCount++;

        // Clean up temporary file
        File tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        if (retryCount <= maxRetries) {
          int delaySeconds = retryDelaySeconds * retryCount;
          downloadStatus.value =
              "Connection lost. Retrying in $delaySeconds seconds... ($retryCount/$maxRetries)";
          await Future.delayed(Duration(seconds: delaySeconds));
          downloadProgress.value = 0.0;
        } else {
          hasError.value = true;
          downloadStatus.value = "Download failed after $maxRetries attempts";
          throw e;
        }
      }
    }
  }

  /// Retry download
  void retryDownload() async {
    hasError.value = false;
    downloadProgress.value = 0.0;
    await _downloadFiles();
  }

  /// Start rotating facts
  void _startFactRotation() {
    factTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (currentFactIndex.value < didYouKnowFacts.length - 1) {
        currentFactIndex.value++;
      } else {
        currentFactIndex.value = 0;
      }
    });
  }
}
