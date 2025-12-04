// lib/widgets/shared_axis_transition.dart

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/step_audio_controller.dart';
import '../models/transcription_model.dart';

class SharedAxisStepTransition extends StatelessWidget {
  final Widget child;
  final int stepIndex;

  const SharedAxisStepTransition({
    super.key,
    required this.child,
    required this.stepIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          reverse: !controller.isNavigatingForward.value,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: KeyedSubtree(key: ValueKey(stepIndex), child: child),
        );
      },
    );
  }
}

// Wrapper for step content with shared axis animation
class AnimatedStepContent extends StatelessWidget {
  final Widget Function(OnboardingStep step) builder;

  const AnimatedStepContent({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        final step = controller.currentStep;
        final isForward = controller.isNavigatingForward.value;

        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          reverse: !isForward,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey(controller.currentStepIndex.value),
            child: builder(step),
          ),
        );
      },
    );
  }
}

// Custom vertical slide transition (alternative without animations package)
class VerticalSlideTransition extends StatelessWidget {
  final Widget child;
  final int index;
  final bool reverse;
  final Duration duration;

  const VerticalSlideTransition({
    super.key,
    required this.child,
    required this.index,
    this.reverse = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        final offsetAnimation =
            Tween<Offset>(
              begin: Offset(0, reverse ? -0.3 : 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(index), child: child),
    );
  }
}

// Full step container with all animations
class AnimatedOnboardingStep extends StatelessWidget {
  final Widget transcriptionWidget;
  final Widget? inputWidget;
  final EdgeInsets padding;

  const AnimatedOnboardingStep({
    super.key,
    required this.transcriptionWidget,
    this.inputWidget,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          reverse: !controller.isNavigatingForward.value,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: Container(
            key: ValueKey(controller.currentStepIndex.value),
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                transcriptionWidget,
                if (inputWidget != null) ...[
                  const SizedBox(height: 24),
                  inputWidget!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
