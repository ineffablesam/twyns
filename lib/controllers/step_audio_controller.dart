// lib/controllers/step_audio_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../modules/onboarding/models/transcription_model.dart';

/// Callback type for amplitude updates
typedef AmplitudeCallback = void Function(double amplitude);

class StepAudioController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // All onboarding steps
  late final List<OnboardingStep> steps;

  // Current state
  final currentStepIndex = 0.obs;
  final audioPosition = Duration.zero.obs;
  final audioDuration = Duration.zero.obs;
  final isPlaying = false.obs;
  final isAudioLoaded = false.obs;
  final activeSegmentIndex = (-1).obs;

  // NEW: Track if current step audio has completed
  final isAudioCompleted = false.obs;

  // For smooth text animation
  final segmentProgress = 0.0.obs;

  // Navigation direction for shared axis animation
  final isNavigatingForward = true.obs;

  // Audio amplitude for visualizer
  final currentAmplitude = 0.0.obs;
  AmplitudeCallback? _amplitudeCallback;

  // Amplitude simulation for audio playback
  double _simulatedAmplitude = 0.0;
  DateTime? _lastAmplitudeUpdate;

  OnboardingStep get currentStep => steps[currentStepIndex.value];
  bool get canGoBack => currentStepIndex.value > 0;
  bool get canGoForward => currentStepIndex.value < steps.length - 1;
  bool get isFirstStep => currentStepIndex.value == 0;
  bool get isLastStep => currentStepIndex.value == steps.length - 1;

  /// Set callback to receive amplitude updates for visualizer
  void setAmplitudeCallback(AmplitudeCallback callback) {
    _amplitudeCallback = callback;
  }

  @override
  void onInit() {
    super.onInit();
    steps = OnboardingStep.getAllSteps();
    _setupAudioListeners();
    _loadCurrentStepAudio();
  }

  void _setupAudioListeners() {
    // Position updates for transcription highlighting
    _audioPlayer.positionStream.listen((position) {
      audioPosition.value = position;
      _updateActiveSegment(position);

      // Check if audio has completed based on position
      if (audioDuration.value != Duration.zero &&
          position >= audioDuration.value - const Duration(milliseconds: 100)) {
        if (!isAudioCompleted.value) {
          isAudioCompleted.value = true;
        }
      }

      // Generate amplitude based on active segment
      if (isPlaying.value) {
        _generateAmplitudeFromPosition(position);
      }
    });

    // Duration updates
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        audioDuration.value = duration;
      }
    });

    // Playing state
    _audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;

      if (!playing) {
        // Fade out amplitude when stopped
        _fadeOutAmplitude();
      }
    });

    // Player state for completion detection
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAudioCompleted();
      }
    });
  }

  void _updateActiveSegment(Duration position) {
    final segments = currentStep.segments;

    for (int i = 0; i < segments.length; i++) {
      if (segments[i].isActiveAt(position)) {
        activeSegmentIndex.value = i;
        segmentProgress.value = segments[i].progressAt(position);
        return;
      }
    }

    // Check if we're past all segments
    if (segments.isNotEmpty && position >= segments.last.endTime) {
      activeSegmentIndex.value = segments.length - 1;
      segmentProgress.value = 1.0;
    }
  }

  /// Generate simulated amplitude based on playback position and active words
  void _generateAmplitudeFromPosition(Duration position) {
    final now = DateTime.now();
    final deltaMs = _lastAmplitudeUpdate != null
        ? now.difference(_lastAmplitudeUpdate!).inMilliseconds
        : 16;
    _lastAmplitudeUpdate = now;

    final segments = currentStep.segments;
    final activeIdx = activeSegmentIndex.value;

    if (activeIdx < 0 || activeIdx >= segments.length) {
      _simulatedAmplitude *= 0.9; // Decay
      _notifyAmplitude(_simulatedAmplitude);
      return;
    }

    final segment = segments[activeIdx];
    final progress = segment.progressAt(position);
    final wordLength = segment.text.length;

    // Base amplitude from word characteristics
    // Longer words and words with certain letters tend to be louder
    double baseAmplitude = 0.3 + (wordLength / 20.0).clamp(0.0, 0.4);

    // Add variation based on word content
    final text = segment.text.toLowerCase();
    if (text.contains(RegExp(r'[aeiou]{2,}')))
      baseAmplitude += 0.1; // Vowel clusters
    if (text.contains('!')) baseAmplitude += 0.15; // Exclamation
    if (text.contains('?')) baseAmplitude += 0.1; // Question
    if (text.endsWith(',') || text.endsWith('.'))
      baseAmplitude -= 0.05; // Pause coming

    // Create natural speech envelope (attack-sustain-release)
    double envelope;
    if (progress < 0.15) {
      // Attack
      envelope = progress / 0.15;
    } else if (progress < 0.7) {
      // Sustain with slight variation
      final sustainProgress = (progress - 0.15) / 0.55;
      envelope = 0.9 + 0.1 * (0.5 + 0.5 * _pseudoSin(sustainProgress * 6.28));
    } else {
      // Release
      envelope = 1.0 - ((progress - 0.7) / 0.3);
    }

    // Add micro-variations for naturalness
    final time = position.inMilliseconds / 1000.0;
    final microVariation =
        0.1 * _pseudoSin(time * 15) + 0.05 * _pseudoSin(time * 23);

    // Calculate target amplitude
    final targetAmplitude = (baseAmplitude * envelope + microVariation).clamp(
      0.0,
      1.0,
    );

    // Smooth transition
    final smoothFactor = (deltaMs / 50.0).clamp(0.1, 1.0);
    _simulatedAmplitude =
        _simulatedAmplitude +
        (targetAmplitude - _simulatedAmplitude) * smoothFactor;

    _notifyAmplitude(_simulatedAmplitude);
  }

  /// Simple pseudo-sin for variation without importing math
  double _pseudoSin(double x) {
    // Approximate sin using Taylor series terms
    x = x % 6.28318;
    if (x > 3.14159) x -= 6.28318;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  void _fadeOutAmplitude() async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      _simulatedAmplitude *= 0.85;
      _notifyAmplitude(_simulatedAmplitude);
      if (_simulatedAmplitude < 0.01) break;
    }
    _simulatedAmplitude = 0.0;
    _notifyAmplitude(0.0);
  }

  void _notifyAmplitude(double amplitude) {
    currentAmplitude.value = amplitude;
    _amplitudeCallback?.call(amplitude);
  }

  Future<void> _loadCurrentStepAudio() async {
    try {
      isAudioLoaded.value = false;
      isAudioCompleted.value = false; // Reset completion state
      activeSegmentIndex.value = -1;
      segmentProgress.value = 0.0;

      await _audioPlayer.setAsset(currentStep.audioPath);
      isAudioLoaded.value = true;
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  Future<void> playCurrentStep() async {
    if (!isAudioLoaded.value) return;

    try {
      await _audioPlayer.seek(Duration.zero);
      isAudioCompleted.value = false; // Reset when playing from start
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.play();
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      pauseAudio();
    } else {
      if (audioPosition.value >= audioDuration.value) {
        playCurrentStep();
      } else {
        resumeAudio();
      }
    }
  }

  void _onAudioCompleted() {
    // Audio finished playing
    debugPrint('Step ${currentStepIndex.value + 1} audio completed');
    isAudioCompleted.value = true;
    _fadeOutAmplitude();
  }

  Future<void> goToNextStep() async {
    if (!canGoForward) return;

    isNavigatingForward.value = true;
    await _audioPlayer.stop();
    _simulatedAmplitude = 0.0;
    currentStepIndex.value++;
    await _loadCurrentStepAudio();

    // Auto-play next step after a brief delay
    await Future.delayed(const Duration(milliseconds: 400));
    playCurrentStep();
  }

  Future<void> goToPreviousStep() async {
    if (!canGoBack) return;

    isNavigatingForward.value = false;
    await _audioPlayer.stop();
    _simulatedAmplitude = 0.0;
    currentStepIndex.value--;
    await _loadCurrentStepAudio();

    // Auto-play after navigation
    await Future.delayed(const Duration(milliseconds: 400));
    playCurrentStep();
  }

  Future<void> goToStep(int index) async {
    if (index < 0 || index >= steps.length || index == currentStepIndex.value) {
      return;
    }

    isNavigatingForward.value = index > currentStepIndex.value;
    await _audioPlayer.stop();
    _simulatedAmplitude = 0.0;
    currentStepIndex.value = index;
    await _loadCurrentStepAudio();

    await Future.delayed(const Duration(milliseconds: 400));
    playCurrentStep();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
