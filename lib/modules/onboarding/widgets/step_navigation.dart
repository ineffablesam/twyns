// lib/widgets/step_navigation.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/step_audio_controller.dart';

class StepNavigation extends StatelessWidget {
  final double iconSize;
  final Color activeColor;
  final Color inactiveColor;

  const StepNavigation({
    super.key,
    this.iconSize = 24,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Up arrow (previous step)
            _NavigationArrow(
              icon: Icons.keyboard_arrow_up_rounded,
              isEnabled: controller.canGoBack,
              onTap: controller.goToPreviousStep,
              iconSize: iconSize,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),

            const SizedBox(height: 8),

            // Step indicator
            _StepIndicator(
              currentStep: controller.currentStepIndex.value,
              totalSteps: controller.steps.length,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),

            const SizedBox(height: 8),

            // Down arrow (next step)
            _NavigationArrow(
              icon: Icons.keyboard_arrow_down_rounded,
              isEnabled: controller.canGoForward,
              onTap: controller.goToNextStep,
              iconSize: iconSize,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        );
      },
    );
  }
}

class _NavigationArrow extends StatefulWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;
  final double iconSize;
  final Color activeColor;
  final Color inactiveColor;

  const _NavigationArrow({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
    required this.iconSize,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<_NavigationArrow> createState() => _NavigationArrowState();
}

class _NavigationArrowState extends State<_NavigationArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              opacity: widget.isEnabled ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.isEnabled
                    ? widget.activeColor
                    : widget.inactiveColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor
                  : (isCompleted
                        ? activeColor.withOpacity(0.6)
                        : inactiveColor),
            ),
          ),
        );
      }),
    );
  }
}

// Minimal version with just arrows
class MinimalStepNavigation extends StatelessWidget {
  const MinimalStepNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        // Don't show navigation on first step
        // if (controller.isFirstStep) {
        //   return const SizedBox.shrink();
        // }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Up arrow only shown when not on first step
            _MinimalArrow(
              icon: Icons.keyboard_arrow_up_rounded,
              isEnabled: controller.canGoBack,
              onTap: controller.goToPreviousStep,
            ),

            const SizedBox(height: 16),

            // Down arrow
            _MinimalArrow(
              icon: Icons.keyboard_arrow_down_rounded,
              isEnabled: controller.canGoForward,
              onTap: controller.goToNextStep,
            ),
          ],
        );
      },
    );
  }
}

class _MinimalArrow extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _MinimalArrow({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: isEnabled ? 0.8 : 0.2,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
