// lib/controllers/voice_clone_controller.dart

import 'dart:io';

import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twyns/controllers/audio_visualizer_controller.dart';
import 'package:twyns/controllers/auth_controller.dart';
import 'package:twyns/utils/fonts/satoshi_font.dart';

class VoiceCloneController extends GetxController {
  final isAccordionOpen = false.obs;
  final recordingState = RecordingState.initial.obs;
  final isProcessing = false.obs;

  File? recordedFile;
  final Trimmer trimmer = Trimmer();

  final startValue = 0.0.obs;
  final endValue = 0.0.obs;
  final isPlaying = false.obs;
  final isTrimmerLoading = false.obs;
  final isTrimmerReady = false.obs;

  void toggleAccordion() {
    isAccordionOpen.value = !isAccordionOpen.value;
  }

  Future<void> startRecording() async {
    try {
      debugPrint('🎤 Starting recording...');
      recordingState.value = RecordingState.recording;

      final visualizerController = Get.find<OnboardingController>();
      await visualizerController.startRecording();

      debugPrint('✅ Recording started successfully');
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      recordingState.value = RecordingState.initial;
      Get.snackbar(
        'Error',
        'Failed to start recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      debugPrint('🎤 Stopping recording...');

      final visualizerController = Get.find<OnboardingController>();
      final recorderPath = await visualizerController.recorder.stopRecording();

      debugPrint('🎤 Recorder returned path: $recorderPath');

      if (recorderPath == null || recorderPath.isEmpty) {
        debugPrint('❌ No recording path returned from recorder');
        recordingState.value = RecordingState.initial;
        Get.snackbar(
          'Error',
          'Failed to save recording',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      recordedFile = File(recorderPath);

      if (!await recordedFile!.exists()) {
        debugPrint('❌ File does not exist at path: $recorderPath');
        recordingState.value = RecordingState.initial;
        Get.snackbar(
          'Error',
          'Recording file not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final fileSize = await recordedFile!.length();
      debugPrint('✅ Recording saved at: $recorderPath');
      debugPrint('✅ File size: $fileSize bytes');

      recordingState.value = RecordingState.recorded;
      await loadTrimmer();
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      recordingState.value = RecordingState.initial;
      Get.snackbar(
        'Error',
        'Failed to stop recording: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> loadTrimmer() async {
    if (recordedFile == null) {
      debugPrint('❌ No recorded file to load');
      return;
    }

    try {
      isTrimmerLoading.value = true;
      isTrimmerReady.value = false;

      debugPrint('📂 Loading audio file: ${recordedFile!.path}');
      await trimmer.loadAudio(audioFile: recordedFile!);
      await Future.delayed(const Duration(milliseconds: 500));

      isTrimmerReady.value = true;
      debugPrint('✅ Trimmer loaded and ready');
    } catch (e) {
      debugPrint('❌ Error loading trimmer: $e');
      Get.snackbar(
        'Error',
        'Failed to load audio file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      recordingState.value = RecordingState.initial;
      isTrimmerReady.value = false;
    } finally {
      isTrimmerLoading.value = false;
    }
  }

  void resetRecording() {
    debugPrint('🔄 Resetting recording');
    recordedFile = null;
    recordingState.value = RecordingState.initial;
    startValue.value = 0.0;
    endValue.value = 0.0;
    isPlaying.value = false;
    isTrimmerReady.value = false;
    trimmer.dispose();
  }

  Future<void> togglePlayback() async {
    if (!isTrimmerReady.value) {
      debugPrint('⚠️ Trimmer not ready for playback');
      return;
    }

    try {
      final playbackState = await trimmer.audioPlaybackControl(
        startValue: startValue.value,
        endValue: endValue.value,
      );
      isPlaying.value = playbackState;
    } catch (e) {
      debugPrint('❌ Error toggling playback: $e');
    }
  }

  /// Custom trim using FFmpeg directly
  Future<String?> _customTrimAudio(
    String inputPath,
    double startSeconds,
    double endSeconds,
  ) async {
    try {
      final directory = Directory.systemTemp;
      final outputPath =
          '${directory.path}/voice_clone_trimmed_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final duration = endSeconds - startSeconds;

      debugPrint('🎬 FFmpeg Custom Trim:');
      debugPrint('   Input: $inputPath');
      debugPrint('   Output: $outputPath');
      debugPrint('   Start: ${startSeconds}s, Duration: ${duration}s');

      // FFmpeg command to trim M4A without re-encoding (fast, no quality loss)
      final command =
          '-i "$inputPath" -ss $startSeconds -t $duration -c copy "$outputPath"';

      debugPrint('🎬 FFmpeg Command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('✅ FFmpeg trim successful');

        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final size = await outputFile.length();
          debugPrint(
            '✅ Trimmed file created: ${(size / 1024).toStringAsFixed(2)} KB',
          );
          return outputPath;
        }
      } else {
        final logs = await session.getOutput();
        debugPrint('❌ FFmpeg failed with code: $returnCode');
        debugPrint('❌ FFmpeg logs: $logs');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Custom trim error: $e');
      return null;
    }
  }

  Future<void> processDone() async {
    if (recordedFile == null || !isTrimmerReady.value) {
      debugPrint('⚠️ Cannot process: file or trimmer not ready');
      return;
    }

    isProcessing.value = true;

    try {
      final authController = Get.find<AuthController>();

      // Print collected data before saving
      // authController.printOnboardingData();

      String? finalAudioPath;

      // Check if user actually trimmed the audio
      final audioDuration = await trimmer.audioPlayer?.getDuration();
      final fullDuration = audioDuration?.inMilliseconds.toDouble() ?? 0.0;

      final isTrimmed =
          startValue.value > 0 ||
          (endValue.value > 0 && endValue.value < fullDuration / 1000.0);

      if (isTrimmed) {
        debugPrint('✂️ User trimmed audio, processing...');

        // Use custom FFmpeg trim (keeps M4A format)
        finalAudioPath = await _customTrimAudio(
          recordedFile!.path,
          startValue.value,
          endValue.value > 0 ? endValue.value : fullDuration / 1000.0,
        );

        if (finalAudioPath == null) {
          debugPrint('⚠️ Trim failed, using original file');
          Get.snackbar(
            'Info',
            'Using full recording',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          finalAudioPath = recordedFile!.path;
        }
      } else {
        debugPrint('📁 Using full recording (no trim)');
        finalAudioPath = recordedFile!.path;
      }

      // Upload and complete
      await _uploadAndComplete(authController, finalAudioPath);
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing audio: $e');
      debugPrint('Stack trace: $stackTrace');
      isProcessing.value = false;

      Get.snackbar(
        'Error',
        'Failed to complete onboarding: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _uploadAndComplete(
    AuthController authController,
    String? outputPath,
  ) async {
    if (outputPath == null) {
      debugPrint('❌ No audio file to upload');
      isProcessing.value = false;
      return;
    }

    debugPrint('✅ Audio file ready: $outputPath');

    // Save to AuthController
    authController.voiceRecordingPath.value = outputPath;

    // Upload to Supabase Storage
    debugPrint('📤 Uploading to Supabase...');
    final uploadedUrl = await authController.uploadVoiceRecording(
      File(outputPath),
    );

    if (uploadedUrl == null) {
      isProcessing.value = false;
      return;
    }

    // Save all data to Supabase
    debugPrint('💾 Saving to Supabase database...');
    final success = await authController.completeOnboarding(uploadedUrl);

    isProcessing.value = false;

    if (success) {
      debugPrint('✅ Onboarding completed successfully!');

      // Print final collected data
      debugPrint('═══════════════════════════════════════');
      debugPrint('🎉 FINAL ONBOARDING DATA');
      debugPrint('═══════════════════════════════════════');
      debugPrint('👤 Name: ${authController.name.value}');
      debugPrint('📅 DOB: ${authController.dob.value}');
      debugPrint('🎭 Avatar Path: ${authController.avatarPath.value}');
      debugPrint(
        '🎤 Audio Path (Local): ${authController.voiceRecordingPath.value}',
      );
      debugPrint('🌐 Audio URL (Supabase): $uploadedUrl');
      debugPrint('🆔 UID: ${authController.uid.value}');
      debugPrint('═══════════════════════════════════════');

      // Navigate to home
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/home');
    }
  }

  @override
  void onClose() {
    trimmer.dispose();
    super.onClose();
  }
}

enum RecordingState { initial, recording, recorded }

class VoiceCloneWidget extends StatelessWidget {
  const VoiceCloneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoiceCloneController());

    return Obx(() {
      if (controller.isProcessing.value) {
        return _buildProcessingState();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAccordion(controller),
          const SizedBox(height: 16),
          _buildMainContent(controller),
        ],
      );
    });
  }

  Widget _buildProcessingState() {
    return Container(
      height: 250,
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Completing onboarding...',
            style: Satoshi.font(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing your voice and saving data',
            style: Satoshi.font(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordion(VoiceCloneController controller) {
    return GestureDetector(
      onTap: controller.toggleAccordion,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              controller.isAccordionOpen.value
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'View Example',
                style: Satoshi.font(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(VoiceCloneController controller) {
    return Obx(() {
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            if (controller.isAccordionOpen.value) ...[
              _buildExampleContainer(),
              const SizedBox(height: 16),
            ],

            if (controller.recordingState.value == RecordingState.initial)
              _buildRecordButton(controller)
            else if (controller.recordingState.value ==
                RecordingState.recording)
              _buildRecordButton(controller)
            else if (controller.recordingState.value == RecordingState.recorded)
              _buildTrimmerSection(controller),
          ],
        ),
      );
    });
  }

  Widget _buildRecordButton(VoiceCloneController controller) {
    return Obx(() {
      final isRecording =
          controller.recordingState.value == RecordingState.recording;

      return GestureDetector(
        onTap: () {
          if (isRecording) {
            controller.stopRecording();
          } else {
            controller.startRecording();
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isRecording ? Colors.red : Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Colors.red : Colors.red.shade600)
                    .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRecording) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                isRecording ? 'Stop Recording' : 'Start Recording',
                style: Satoshi.font(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildExampleContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.blueAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "I'm recording my voice so my Twyn can sound just like me. This is going to be awesome—I'm excited to hear the result!",
              style: Satoshi.font(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimmerSection(VoiceCloneController controller) {
    return Obx(() {
      if (controller.isTrimmerLoading.value ||
          !controller.isTrimmerReady.value) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Loading audio...',
                style: Satoshi.font(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trim Audio (Optional)',
                  style: Satoshi.font(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: controller.resetRecording,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TrimViewer
            TrimViewer(
              trimmer: controller.trimmer,
              viewerHeight: 80,
              viewerWidth: Get.width - 64,
              maxAudioLength: const Duration(seconds: 30),
              durationStyle: DurationStyle.FORMAT_MM_SS,
              backgroundColor: Colors.grey.shade800,
              barColor: Colors.white,
              durationTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              allowAudioSelection: true,
              editorProperties: TrimEditorProperties(
                circleSize: 12,
                borderPaintColor: Colors.blueAccent,
                borderWidth: 3,
                borderRadius: 8,
                circlePaintColor: Colors.blue.shade700,
              ),
              areaProperties: TrimAreaProperties.edgeBlur(blurEdges: true),
              onChangeStart: (value) => controller.startValue.value = value,
              onChangeEnd: (value) => controller.endValue.value = value,
              onChangePlaybackState: (value) =>
                  controller.isPlaying.value = value,
            ),

            const SizedBox(height: 16),

            // Play/Pause Button
            Center(
              child: GestureDetector(
                onTap: controller.togglePlayback,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Green Done Button
            GestureDetector(
              onTap: controller.processDone,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: Satoshi.font(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
