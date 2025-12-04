import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:twyns/modules/pulse/pulse_engine.dart';

class PulseAudioController extends GetxController
    with GetTickerProviderStateMixin {
  // Animation
  late final Ticker ticker;
  Duration elapsed = Duration.zero;

  // State observables
  final isInitialized = true.obs;
  final isRecording = false.obs;
  final isListening = false.obs;

  // Speech to text
  late stt.SpeechToText speech;
  final transcribedText = ''.obs;
  final partialText = ''.obs;

  // ADDED: Internal flag to prevent updates after stopping
  bool _isStopping = false;

  // Audio recording
  final MicStreamRecorder recorder = MicStreamRecorder();

  // Chat controller reference
  PulseChatController? _chatController;

  @override
  void onInit() {
    super.onInit();
    ticker = createTicker((elapsed) {
      this.elapsed = elapsed;
    });
    _initializeSpeechToText();
    _setupChatIntegration();
  }

  void _setupChatIntegration() {
    // Try to find chat controller
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        _chatController = Get.find<PulseChatController>();
        debugPrint('✅ Chat controller found and connected');

        // Setup listeners for real-time updates
        // FIXED: Only update if not stopping
        ever(partialText, (text) {
          if (_isStopping) return; // Ignore updates while stopping

          debugPrint('📝 Partial text updated: $text');
          if (isRecording.value && text.isNotEmpty) {
            _chatController?.addTemporaryMessage(text);
          }
        });

        ever(transcribedText, (text) {
          if (_isStopping) return; // Ignore updates while stopping

          debugPrint('✅ Final transcription: $text');
          if (isRecording.value && text.isNotEmpty) {
            _chatController?.addTemporaryMessage(text);
          }
        });
      } catch (e) {
        debugPrint('⚠️ Chat controller not found yet: $e');
      }
    });
  }

  Future<void> _initializeSpeechToText() async {
    speech = stt.SpeechToText();
    final available = await speech.initialize(
      onError: (error) {
        debugPrint('❌ Speech error: $error');
      },
      onStatus: (status) {
        debugPrint('🎤 Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
    );

    if (!available) {
      debugPrint('❌ Speech recognition not available');
      Get.snackbar(
        'Speech Recognition',
        'Not available on this device',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      debugPrint('✅ Speech recognition initialized');
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    try {
      debugPrint('🎙️ Starting recording...');

      // Clear flags and previous text
      _isStopping = false;
      partialText.value = '';
      transcribedText.value = '';

      // Initialize speech if not already
      if (!speech.isAvailable) {
        debugPrint('🔄 Re-initializing speech...');
        bool available = await speech.initialize(
          onStatus: (status) {
            debugPrint('🎤 Speech status: $status');
            if (status == 'done' || status == 'notListening') {
              isListening.value = false;
            }
          },
          onError: (error) {
            debugPrint('❌ Speech error: $error');
            Get.snackbar(
              'Speech Error',
              error.toString(),
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        );

        if (!available) {
          debugPrint('❌ Speech not available');
          Get.snackbar(
            'Error',
            'Speech recognition not available on this device.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      // Start microphone recording
      await recorder.startRecording(null);
      isRecording.value = true;
      debugPrint('✅ Microphone started');

      // Start speech recognition
      isListening.value = true;
      await speech.listen(
        onResult: (SpeechRecognitionResult result) {
          // FIXED: Don't process results if we're stopping
          if (_isStopping) {
            debugPrint('⏸️ Ignoring result during stop');
            return;
          }

          debugPrint(
            '🗣️ Speech result - Final: ${result.finalResult}, Words: ${result.recognizedWords}',
          );

          if (result.finalResult) {
            // Final result - update transcribed text
            transcribedText.value = result.recognizedWords;
            partialText.value = '';
            debugPrint('✅ Final transcription: ${transcribedText.value}');
          } else {
            // Partial result - update in real-time
            partialText.value = result.recognizedWords;
            debugPrint('📝 Partial: ${partialText.value}');
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          onDevice: false,
          enableHapticFeedback: true,
        ),
        listenFor: const Duration(minutes: 2),
        cancelOnError: true,
      );

      debugPrint('✅ Speech recognition started');
    } catch (e, stack) {
      debugPrint('❌ Recording start error: $e');
      debugPrintStack(stackTrace: stack);
      Get.snackbar(
        'Error',
        'Failed to start recording: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<String> stopRecording() async {
    try {
      debugPrint('⏸️ Stopping recording...');

      // FIXED: Set stopping flag FIRST to prevent reactive updates
      _isStopping = true;

      // Capture final text BEFORE stopping
      final capturedText = transcribedText.value.isNotEmpty
          ? transcribedText.value
          : partialText.value;

      debugPrint('📦 Captured text before stop: "$capturedText"');

      await recorder.stopRecording();

      // Stop speech recognition
      if (speech.isListening) {
        await speech.stop();
        isListening.value = false;
      }

      // Give a moment for final result to come through
      await Future.delayed(const Duration(milliseconds: 150));

      // Update recording state
      isRecording.value = false;

      // Return the final text (could have been updated by speech recognition)
      final finalText = transcribedText.value.isNotEmpty
          ? transcribedText.value
          : capturedText;

      debugPrint('✅ Recording stopped. Returning text: "$finalText"');
      return finalText;
    } catch (e) {
      debugPrint('❌ Recording stop error: $e');
      return '';
    } finally {
      // Reset stopping flag after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _isStopping = false;
      });
    }
  }

  @override
  void onClose() {
    ticker.dispose();
    speech.stop();
    recorder.stopRecording();
    super.onClose();
  }
}
