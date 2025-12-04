import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';

class PulseModeController extends GetxController {
  // Page index for navigation
  final currentPageIndex = 0.obs;

  // Rotating texts for Page 2
  final texts = [
    "Booting Neural Core…",
    "Calibrating vocal matrix…",
    "Optimizing audio streams…",
    "Almost there…",
    "Pulse Mode Online!",
  ];

  // Texts when voice cloning is in progress
  final cloningTexts = [
    "Booting Neural Core…",
    "Calibrating vocal matrix…",
    "Analyzing your voice signature…",
    "Cloning your unique voice…",
    "Finalizing voice profile…",
    "Optimizing audio streams…",
    "Almost there…",
    "Pulse Mode Online!",
  ];

  final currentText = "Booting Neural Core…".obs;
  final currentTextIndex = 0.obs;
  final isCloningVoice = false.obs;
  Timer? _timer;

  // Navigate to loading page and start text rotation with voice cloning check
  Future<void> startPulseMode() async {
    currentPageIndex.value = 1;

    await Future.delayed(const Duration(milliseconds: 500));

    // Check if voice cloning is needed
    final authController = Get.find<AuthController>();

    if (!authController.isCloned.value) {
      debugPrint(
        '🎙️ Voice not cloned, starting clone process with animations',
      );
      await startTextRotationWithCloning();
    } else {
      debugPrint('✅ Voice already cloned, showing normal animations');
      startTextRotation();
    }
  }

  // Start rotating texts with voice cloning
  Future<void> startTextRotationWithCloning() async {
    isCloningVoice.value = true;
    currentTextIndex.value = 0;
    currentText.value = cloningTexts[0];

    _timer?.cancel();

    // Start the cloning process in parallel
    final authController = Get.find<AuthController>();
    bool cloningSuccess = false;
    bool cloningComplete = false;

    // Start voice cloning
    authController
        .cloneUserVoice()
        .then((success) {
          cloningSuccess = success;
          cloningComplete = true;
          debugPrint('🎤 Voice cloning completed: $success');
        })
        .catchError((error) {
          debugPrint('❌ Voice cloning error: $error');
          cloningSuccess = false;
          cloningComplete = true;
        });

    // Animate through texts while waiting for cloning
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      // Check if we should wait for cloning to complete
      if (currentTextIndex.value == cloningTexts.length - 3) {
        // We're at "Almost there…" - wait for cloning if not done
        if (!cloningComplete) {
          debugPrint('⏳ Waiting for voice cloning to complete...');
          // Stay on this text until cloning is done
          return;
        }
      }

      currentTextIndex.value++;

      if (currentTextIndex.value >= cloningTexts.length) {
        _timer?.cancel();
        isCloningVoice.value = false;

        // Show result message
        if (cloningSuccess) {
          debugPrint('✅ Voice cloning successful! Proceeding to Pulse Mode');
        } else {
          debugPrint('⚠️ Voice cloning failed, but proceeding to Pulse Mode');
          Get.snackbar(
            'Notice',
            'Continuing without voice cloning',
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.TOP,
          );
        }

        // Navigate to ready page after all texts are shown
        Future.delayed(const Duration(milliseconds: 500), () {
          currentPageIndex.value = 2;
        });
        return;
      }

      currentText.value = cloningTexts[currentTextIndex.value];
    });
  }

  // Start rotating texts (when voice already cloned)
  void startTextRotation() {
    currentTextIndex.value = 0;
    currentText.value = texts[0];

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      currentTextIndex.value++;
      if (currentTextIndex.value >= texts.length) {
        _timer?.cancel();
        // Navigate to ready page after all texts are shown
        Future.delayed(const Duration(milliseconds: 500), () {
          currentPageIndex.value = 2;
        });
        return;
      }
      currentText.value = texts[currentTextIndex.value];
    });
  }

  // Stop rotation
  void stopTextRotation() {
    _timer?.cancel();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
