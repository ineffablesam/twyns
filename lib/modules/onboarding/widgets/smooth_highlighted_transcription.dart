// lib/widgets/smooth_highlighted_transcription.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/step_audio_controller.dart';
import '../models/transcription_model.dart';

class SmoothHighlightedTranscription extends StatelessWidget {
  final List<TranscriptionSegment> segments;
  final TextStyle baseStyle;
  final TextStyle highlightedStyle;
  final TextStyle completedStyle;
  final Color highlightColor;
  final double highlightBorderRadius;
  final EdgeInsets highlightPadding;

  const SmoothHighlightedTranscription({
    super.key,
    required this.segments,
    required this.baseStyle,
    required this.highlightedStyle,
    required this.completedStyle,
    this.highlightColor = const Color(0xFF3B82F6),
    this.highlightBorderRadius = 8.0,
    this.highlightPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<StepAudioController>();
      final activeIndex = controller.activeSegmentIndex.value;

      return Wrap(
        spacing: 6,
        runSpacing: 8,
        children: List.generate(segments.length, (index) {
          final segment = segments[index];
          final isActive = index == activeIndex;
          final isCompleted = index < activeIndex;

          return _AnimatedHighlightBox(
            key: ValueKey(
              'segment_${controller.currentStepIndex.value}_$index',
            ),
            text: segment.text,
            isActive: isActive,
            isCompleted: isCompleted,
            baseStyle: baseStyle,
            highlightedStyle: highlightedStyle,
            completedStyle: completedStyle,
            highlightColor: highlightColor,
            borderRadius: highlightBorderRadius,
            padding: highlightPadding,
          );
        }),
      );
    });
  }
}

class _AnimatedHighlightBox extends StatefulWidget {
  final String text;
  final bool isActive;
  final bool isCompleted;
  final TextStyle baseStyle;
  final TextStyle highlightedStyle;
  final TextStyle completedStyle;
  final Color highlightColor;
  final double borderRadius;
  final EdgeInsets padding;

  const _AnimatedHighlightBox({
    super.key,
    required this.text,
    required this.isActive,
    required this.isCompleted,
    required this.baseStyle,
    required this.highlightedStyle,
    required this.completedStyle,
    required this.highlightColor,
    required this.borderRadius,
    required this.padding,
  });

  @override
  State<_AnimatedHighlightBox> createState() => _AnimatedHighlightBoxState();
}

class _AnimatedHighlightBoxState extends State<_AnimatedHighlightBox>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Spring scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(_AnimatedHighlightBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive ||
        widget.isCompleted != oldWidget.isCompleted) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.isActive) {
      _fadeController.forward();
      _scaleController.forward(from: 0);
      _glowController.repeat(reverse: true);
    } else {
      _fadeController.reverse();
      _scaleController.reverse();
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _fadeAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        final isHighlighted = widget.isActive || widget.isCompleted;

        return Transform.scale(
          scale: widget.isActive ? _scaleAnimation.value : 1.0,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: widget.isActive
                  ? widget.highlightColor.withOpacity(
                      _fadeAnimation.value * 0.25,
                    )
                  : widget.isCompleted
                  ? widget.highlightColor.withOpacity(0.15)
                  : Colors.transparent,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.highlightColor.withOpacity(
                          _glowAnimation.value * _fadeAnimation.value,
                        ),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: widget.isActive
                  ? widget.highlightedStyle
                  : widget.isCompleted
                  ? widget.completedStyle
                  : widget.baseStyle,
              child: Text(widget.text),
            ),
          ),
        );
      },
    );
  }
}

// Alternative: Gradient sweep highlight effect
class GradientSweepTranscription extends StatelessWidget {
  final List<TranscriptionSegment> segments;
  final TextStyle baseStyle;
  final TextStyle highlightedStyle;
  final Color highlightColor;

  const GradientSweepTranscription({
    super.key,
    required this.segments,
    required this.baseStyle,
    required this.highlightedStyle,
    this.highlightColor = const Color(0xFF3B82F6),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<StepAudioController>();
      final activeIndex = controller.activeSegmentIndex.value;
      final progress = controller.segmentProgress.value;

      return Wrap(
        spacing: 6,
        runSpacing: 10,
        children: List.generate(segments.length, (index) {
          final segment = segments[index];
          final isActive = index == activeIndex;
          final isCompleted = index < activeIndex;

          return _GradientHighlightBox(
            text: segment.text,
            isActive: isActive,
            isCompleted: isCompleted,
            progress: isActive ? progress : (isCompleted ? 1.0 : 0.0),
            baseStyle: baseStyle,
            highlightedStyle: highlightedStyle,
            highlightColor: highlightColor,
          );
        }),
      );
    });
  }
}

class _GradientHighlightBox extends StatefulWidget {
  final String text;
  final bool isActive;
  final bool isCompleted;
  final double progress;
  final TextStyle baseStyle;
  final TextStyle highlightedStyle;
  final Color highlightColor;

  const _GradientHighlightBox({
    required this.text,
    required this.isActive,
    required this.isCompleted,
    required this.progress,
    required this.baseStyle,
    required this.highlightedStyle,
    required this.highlightColor,
  });

  @override
  State<_GradientHighlightBox> createState() => _GradientHighlightBoxState();
}

class _GradientHighlightBoxState extends State<_GradientHighlightBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _springAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_GradientHighlightBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _springController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _springAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _springAnimation.value : 1.0,
          child: CustomPaint(
            painter: _GradientBoxPainter(
              progress: widget.isCompleted ? 1.0 : widget.progress,
              color: widget.highlightColor,
              borderRadius: 8,
              isActive: widget.isActive,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                widget.text,
                style: (widget.isActive || widget.isCompleted)
                    ? widget.highlightedStyle
                    : widget.baseStyle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientBoxPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final bool isActive;

  _GradientBoxPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      Radius.circular(borderRadius),
    );

    final gradient = LinearGradient(
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(isActive ? 0.2 : 0.15),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRRect(rect, paint);

    // Add subtle glow for active
    if (isActive && progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_GradientBoxPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
