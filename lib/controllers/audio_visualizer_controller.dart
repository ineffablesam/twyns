// lib/controllers/onboarding_controller.dart

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mic_stream_recorder/mic_stream_recorder.dart';

/// Audio source types for the visualizer
enum AudioSource { none, microphone, stepAudio }

class OnboardingController extends GetxController
    with GetTickerProviderStateMixin {
  // Shader programs
  ui.FragmentProgram? mainProgram;
  ui.FragmentProgram? bufferProgram;

  // Animation
  late final Ticker ticker;
  Duration elapsed = Duration.zero;

  // Textures and buffers
  ui.Image? bufferAImage;
  ui.Image? audioTexture;

  // State observables
  final isInitialized = false.obs;
  final isRecording = false.obs;
  final showSettings = false.obs;
  final isUpdatingBuffer = false.obs;

  // Current audio source
  final activeAudioSource = AudioSource.none.obs;

  // Audio recording (microphone)
  final MicStreamRecorder recorder = MicStreamRecorder();
  StreamSubscription<double>? amplitudeSubscription;

  // Step audio amplitude (from StepAudioController)
  double _stepAudioAmplitude = 0.0;

  // Audio processing
  static const int kAudioTextureWidth = 512;
  static const int kAudioTextureHeight = 2;
  Float32List frequencyData = Float32List(kAudioTextureWidth);
  Float32List smoothedData = Float32List(kAudioTextureWidth);

  static const int kTargetFPS = 60;
  static const int kMinFrameTimeMs = 1000 ~/ kTargetFPS;
  int lastUpdateTime = 0;
  Size? lastRenderSize;

  // Shader control parameters (Microphone)
  final warpStrength = 0.3.obs;
  final colorIntensity = 1.3.obs;
  final glowFalloff = 3.0.obs;
  final smoothness = 2.0.obs;
  final audioResponse = 0.7.obs;
  final smoothingFactor = 0.5.obs;
  final noiseThreshold = 0.1.obs;
  final audioBoost = 0.8.obs;

  // Step Audio control parameters (separate for tuning)
  final stepAudioResponse = 0.7.obs;
  final stepSmoothingFactor = 0.5.obs;
  final stepAudioBoost = 1.0.obs;
  final stepWaveSpeed = 2.0.obs;
  final stepWaveScale1 = 0.4.obs;
  final stepWaveScale2 = 0.3.obs;
  final stepWaveScale3 = 0.2.obs;
  final stepDecayRate = 0.85.obs;

  @override
  void onInit() {
    super.onInit();
    _setupAmplitudeListener();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  void _setupAmplitudeListener() {
    recorder.amplitudeStream.listen((amplitude) {
      if (isRecording.value) {
        final filteredAmplitude = amplitude > noiseThreshold.value
            ? (amplitude - noiseThreshold.value) / (1.0 - noiseThreshold.value)
            : 0.0;

        if (filteredAmplitude > 0.01) {
          debugPrint('🎤 Filtered: ${filteredAmplitude.toStringAsFixed(3)}');
        }

        _processAmplitude(filteredAmplitude, AudioSource.microphone);
      }
    });
  }

  /// Called by StepAudioController to send amplitude data
  void onStepAudioAmplitude(double amplitude) {
    // Only process if not recording from microphone
    if (!isRecording.value) {
      _stepAudioAmplitude = amplitude;
      activeAudioSource.value = amplitude > 0.01
          ? AudioSource.stepAudio
          : AudioSource.none;
      _processAmplitude(amplitude, AudioSource.stepAudio);
    }
  }

  Future<void> initialize() async {
    try {
      await _loadShaders();
      await _createInitialAudioTexture();

      isInitialized.value =
          mainProgram != null && bufferProgram != null && audioTexture != null;

      if (isInitialized.value) {
        _startAnimation();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _loadShaders() async {
    try {
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset('shaders/audio_visualizer.frag'),
        ui.FragmentProgram.fromAsset('shaders/buffer_a.frag'),
      ]);

      mainProgram = results[0];
      bufferProgram = results[1];
    } catch (e) {
      debugPrint('Error loading shaders: $e');
      rethrow;
    }
  }

  Future<void> _createInitialAudioTexture() async {
    final initialData = Float32List(kAudioTextureWidth);
    for (int i = 0; i < kAudioTextureWidth; i++) {
      initialData[i] = 0.01;
    }
    await _updateAudioTexture(initialData);
  }

  Future<void> startRecording() async {
    try {
      await recorder.startRecording(null);
      isRecording.value = true;
      activeAudioSource.value = AudioSource.microphone;
    } catch (e) {
      debugPrint('Recording start error: $e');
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
      await recorder.stopRecording();
      isRecording.value = false;
      activeAudioSource.value = AudioSource.none;

      // Fade out
      smoothedData = Float32List(kAudioTextureWidth);
      for (int i = 0; i < kAudioTextureWidth; i++) {
        smoothedData[i] = 0.01;
      }
      await _updateAudioTexture(smoothedData);
    } catch (e) {
      debugPrint('Recording stop error: $e');
    }
  }

  void toggleSettings() {
    showSettings.value = !showSettings.value;
  }

  String getSensitivityLabel(double threshold) {
    if (threshold >= 0.7) return 'Very High';
    if (threshold >= 0.5) return 'High';
    if (threshold >= 0.3) return 'Medium';
    return 'Low';
  }

  Color getSensitivityColor(double threshold) {
    if (threshold >= 0.7) return Colors.red;
    if (threshold >= 0.5) return Colors.orange;
    if (threshold >= 0.3) return Colors.yellow;
    return Colors.green;
  }

  void _processAmplitude(double rawAmplitude, AudioSource source) {
    // Skip if wrong source is active
    if (source == AudioSource.microphone && !isRecording.value) return;
    if (source == AudioSource.stepAudio && isRecording.value) return;

    // Use different parameters based on source
    final bool isStepAudio = source == AudioSource.stepAudio;

    final currentAudioResponse = isStepAudio
        ? stepAudioResponse.value
        : audioResponse.value;
    final currentSmoothingFactor = isStepAudio
        ? stepSmoothingFactor.value
        : smoothingFactor.value;
    final currentAudioBoost = isStepAudio
        ? stepAudioBoost.value
        : audioBoost.value;
    final currentDecayRate = isStepAudio ? stepDecayRate.value : 0.85;

    final filteredAmplitude = isStepAudio
        ? rawAmplitude // Step audio is already processed
        : (rawAmplitude > noiseThreshold.value
              ? (rawAmplitude - noiseThreshold.value) /
                    (1.0 - noiseThreshold.value)
              : 0.0);

    if (filteredAmplitude < 0.02) {
      // Decay existing data
      for (int i = 0; i < kAudioTextureWidth; i++) {
        smoothedData[i] *= currentDecayRate;
      }
      _updateAudioTexture(smoothedData);
      return;
    }

    final responseAdjustedAmplitude = filteredAmplitude * currentAudioResponse;
    final boostedAmplitude =
        pow(responseAdjustedAmplitude, 0.8).toDouble() * currentAudioBoost;
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Use separate wave parameters for step audio
    final waveSpeed = isStepAudio ? stepWaveSpeed.value : 4.0;
    final waveScale1 = isStepAudio ? stepWaveScale1.value : 0.4;
    final waveScale2 = isStepAudio ? stepWaveScale2.value : 0.3;
    final waveScale3 = isStepAudio ? stepWaveScale3.value : 0.2;

    for (int i = 0; i < kAudioTextureWidth; i++) {
      final normalizedPos = i / kAudioTextureWidth.toDouble();
      final wave1 =
          sin(normalizedPos * 6.0 * pi + time * waveSpeed) * waveScale1;
      final wave2 =
          cos(normalizedPos * 3.0 * pi + time * (waveSpeed * 0.5)) * waveScale2;
      final wave3 =
          sin(normalizedPos * 9.0 * pi + time * (waveSpeed * 0.375)) *
          waveScale3;
      final combinedWave = (wave1 + wave2 + wave3) * 0.8 + 0.5;
      final rawValue = (boostedAmplitude * combinedWave).clamp(0.0, 1.0);

      frequencyData[i] = rawValue;
      smoothedData[i] =
          smoothedData[i] * currentSmoothingFactor +
          frequencyData[i] * (1.0 - currentSmoothingFactor);
    }

    // Edge blending for circular wrapping
    const blendWidth = 5;
    for (int i = 0; i < blendWidth; i++) {
      final t = i / blendWidth.toDouble();
      final leftIndex = i;
      final rightIndex = kAudioTextureWidth - blendWidth + i;
      final blendedValue =
          smoothedData[leftIndex] * (1.0 - t) + smoothedData[rightIndex] * t;
      smoothedData[leftIndex] = blendedValue;
      smoothedData[rightIndex] = blendedValue;
    }

    _updateAudioTexture(smoothedData);
  }

  Future<void> _updateAudioTexture(Float32List audioData) async {
    if (audioData.length != kAudioTextureWidth) return;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..isAntiAlias = false;

      for (int y = 0; y < kAudioTextureHeight; y++) {
        for (int x = 0; x < kAudioTextureWidth; x++) {
          final value = audioData[x].clamp(0.0, 1.0);
          final colorValue = (value * 255).toInt();
          paint.color = Color.fromRGBO(colorValue, colorValue, colorValue, 1.0);
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
            paint,
          );
        }
      }

      final picture = recorder.endRecording();
      final newTexture = await picture.toImage(
        kAudioTextureWidth,
        kAudioTextureHeight,
      );

      final oldTexture = audioTexture;
      audioTexture = newTexture;

      // SchedulerBinding.instance.addPostFrameCallback((_) {
      //   if (oldTexture != null && oldTexture != audioTexture) {
      //     oldTexture.dispose();
      //   }
      // });
    } catch (e) {
      debugPrint('Error updating audio texture: $e');
    }
  }

  void _startAnimation() {
    ticker = createTicker(_onTick);
    ticker.start();
  }

  void _onTick(Duration elapsedTime) {
    if (!isInitialized.value) return;

    final now = elapsedTime.inMilliseconds;
    final deltaTime = now - lastUpdateTime;

    if (deltaTime < kMinFrameTimeMs) return;

    lastUpdateTime = now;
    elapsed = elapsedTime;
    update();

    updateBufferA();
  }

  Future<void> updateBufferA() async {
    if (isUpdatingBuffer.value ||
        bufferProgram == null ||
        audioTexture == null) {
      return;
    }

    isUpdatingBuffer.value = true;

    try {
      final size = lastRenderSize;
      if (size == null || !_isValidSize(size)) return;

      final newBuffer = await _renderBufferPass(size);

      if (newBuffer != null) {
        final oldBuffer = bufferAImage;
        bufferAImage = newBuffer;
        update();

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (oldBuffer != null && oldBuffer != bufferAImage) {
            oldBuffer.dispose();
          }
        });
      }
    } catch (e) {
      debugPrint('Buffer update error: $e');
    } finally {
      isUpdatingBuffer.value = false;
    }
  }

  bool _isValidSize(Size size) {
    return size.width > 0 &&
        size.height > 0 &&
        size.width.isFinite &&
        size.height.isFinite;
  }

  Future<ui.Image?> _renderBufferPass(Size size) async {
    try {
      final shader = bufferProgram!.fragmentShader();

      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, elapsed.inMilliseconds / 1000.0);
      shader.setImageSampler(0, audioTexture!);
      shader.setImageSampler(1, bufferAImage ?? audioTexture!);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = shader,
      );

      final picture = recorder.endRecording();
      final scale = _calculateOptimalScale(size);
      final image = await picture.toImage(
        (size.width * scale).toInt(),
        (size.height * scale).toInt(),
      );

      return image;
    } catch (e) {
      debugPrint('Buffer render error: $e');
      return null;
    }
  }

  double _calculateOptimalScale(Size size) {
    const maxDimension = 512.0;
    final largest = max(size.width, size.height);
    if (largest <= maxDimension) return 1.0;
    return maxDimension / largest;
  }

  void updateRenderSize(Size size) {
    if (lastRenderSize == null || _shouldResetBuffer(size)) {
      lastRenderSize = size;
      bufferAImage?.dispose();
      bufferAImage = null;
    }
  }

  bool _shouldResetBuffer(Size size) {
    if (lastRenderSize == null) return true;
    return (size.width - lastRenderSize!.width).abs() > 2 ||
        (size.height - lastRenderSize!.height).abs() > 2;
  }

  @override
  void onClose() {
    ticker.dispose();
    amplitudeSubscription?.cancel();
    bufferAImage?.dispose();
    audioTexture?.dispose();
    super.onClose();
  }
}
