// lib/widgets/pill_highlighted_transcription.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/step_audio_controller.dart';
import '../models/transcription_model.dart';

/// Karaoke-style transcription with smooth pill highlight that morphs between words
class PillHighlightedTranscription extends StatefulWidget {
  final List<TranscriptionSegment> segments;
  final TextStyle baseStyle;
  final TextStyle activeStyle;
  final TextStyle completedStyle;
  final Color pillColor;
  final Color glowColor;
  final double pillBorderRadius;
  final EdgeInsets pillPadding;

  const PillHighlightedTranscription({
    super.key,
    required this.segments,
    required this.baseStyle,
    required this.activeStyle,
    required this.completedStyle,
    this.pillColor = const Color(0xFF6366F1),
    this.glowColor = const Color(0xFF818CF8),
    this.pillBorderRadius = 8.0,
    this.pillPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  });

  @override
  State<PillHighlightedTranscription> createState() =>
      _PillHighlightedTranscriptionState();
}

class _PillHighlightedTranscriptionState
    extends State<PillHighlightedTranscription>
    with TickerProviderStateMixin {
  final List<GlobalKey> _segmentKeys = [];
  final Map<int, Rect> _segmentRects = {};

  late AnimationController _pillController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  Rect? _currentPillRect;
  Rect? _targetPillRect;
  int _lastActiveIndex = -1;
  bool _needsRemeasure = true;

  @override
  void initState() {
    super.initState();
    _initKeys();

    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180), // Faster for word-by-word
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _initKeys() {
    _segmentKeys.clear();
    _segmentKeys.addAll(
      List.generate(widget.segments.length, (_) => GlobalKey()),
    );
  }

  @override
  void didUpdateWidget(PillHighlightedTranscription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.segments.length != oldWidget.segments.length) {
      _initKeys();
      _segmentRects.clear();
      _needsRemeasure = true;
    }
  }

  void _measureSegments() {
    final RenderBox? parentBox = context.findRenderObject() as RenderBox?;
    if (parentBox == null || !parentBox.hasSize) return;

    _segmentRects.clear();

    for (int i = 0; i < _segmentKeys.length; i++) {
      final key = _segmentKeys[i];
      final RenderBox? box =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final position = box.localToGlobal(Offset.zero, ancestor: parentBox);
        _segmentRects[i] = Rect.fromLTWH(
          position.dx - widget.pillPadding.left,
          position.dy - widget.pillPadding.top,
          box.size.width + widget.pillPadding.horizontal,
          box.size.height + widget.pillPadding.vertical,
        );
      }
    }
    _needsRemeasure = false;
  }

  void _animatePillTo(int index) {
    if (!_segmentRects.containsKey(index)) {
      _measureSegments();
      if (!_segmentRects.containsKey(index)) return;
    }

    final targetRect = _segmentRects[index]!;

    // If first activation or big jump, snap instead of animate
    if (_currentPillRect == null ||
        (_lastActiveIndex >= 0 && (index - _lastActiveIndex).abs() > 3)) {
      _currentPillRect = targetRect;
      _targetPillRect = targetRect;
      _pillController.value = 1.0;
    } else {
      _currentPillRect = _targetPillRect ?? targetRect;
      _targetPillRect = targetRect;
      _pillController.forward(from: 0);
    }

    _lastActiveIndex = index;
  }

  @override
  void dispose() {
    _pillController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        final activeIndex = controller.activeSegmentIndex.value;

        // Schedule measurement and animation after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_needsRemeasure || _segmentRects.isEmpty) {
            _measureSegments();
          }
          if (activeIndex >= 0 && activeIndex != _lastActiveIndex) {
            _animatePillTo(activeIndex);
          }
        });

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Animated pill background
            if (activeIndex >= 0)
              AnimatedBuilder(
                animation: Listenable.merge([_pillController, _glowAnimation]),
                builder: (context, child) {
                  if (_currentPillRect == null || _targetPillRect == null) {
                    return const SizedBox.shrink();
                  }

                  final t = Curves.easeOutCubic.transform(
                    _pillController.value,
                  );
                  final rect = _lerpRect(
                    _currentPillRect!,
                    _targetPillRect!,
                    t,
                  );

                  return Positioned(
                    left: rect.left,
                    top: rect.top,
                    child: _AnimatedPill(
                      width: rect.width,
                      height: rect.height,
                      color: widget.pillColor,
                      glowColor: widget.glowColor,
                      glowIntensity: _glowAnimation.value,
                      borderRadius: widget.pillBorderRadius,
                    ),
                  );
                },
              ),

            // Word segments with proper wrapping
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: List.generate(widget.segments.length, (index) {
                final segment = widget.segments[index];
                final isActive = index == activeIndex;
                final isCompleted = index < activeIndex;

                return _WordText(
                  key: _segmentKeys[index],
                  text: segment.text,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  baseStyle: widget.baseStyle,
                  activeStyle: widget.activeStyle,
                  completedStyle: widget.completedStyle,
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Rect _lerpRect(Rect a, Rect b, double t) {
    return Rect.fromLTWH(
      a.left + (b.left - a.left) * t,
      a.top + (b.top - a.top) * t,
      a.width + (b.width - a.width) * t,
      a.height + (b.height - a.height) * t,
    );
  }
}

class _AnimatedPill extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Color glowColor;
  final double glowIntensity;
  final double borderRadius;

  const _AnimatedPill({
    required this.width,
    required this.height,
    required this.color,
    required this.glowColor,
    required this.glowIntensity,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.4), color.withOpacity(0.25)],
        ),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity * 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withOpacity(glowIntensity * 0.2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

/// Simple word text widget with smooth color transition
class _WordText extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isCompleted;
  final TextStyle baseStyle;
  final TextStyle activeStyle;
  final TextStyle completedStyle;

  const _WordText({
    super.key,
    required this.text,
    required this.isActive,
    required this.isCompleted,
    required this.baseStyle,
    required this.activeStyle,
    required this.completedStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      style: isActive
          ? activeStyle
          : isCompleted
          ? completedStyle
          : baseStyle,
      child: Text(text),
    );
  }
}

/// Simpler version with individual box highlights per word (no morphing pill)
class SimpleWordHighlightTranscription extends StatelessWidget {
  final List<TranscriptionSegment> segments;
  final TextStyle baseStyle;
  final TextStyle activeStyle;
  final TextStyle completedStyle;
  final Color highlightColor;
  final double borderRadius;

  const SimpleWordHighlightTranscription({
    super.key,
    required this.segments,
    required this.baseStyle,
    required this.activeStyle,
    required this.completedStyle,
    this.highlightColor = const Color(0xFF6366F1),
    this.borderRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return GetX<StepAudioController>(
      builder: (controller) {
        final activeIndex = controller.activeSegmentIndex.value;

        return Wrap(
          spacing: 6,
          runSpacing: 8,
          children: List.generate(segments.length, (index) {
            final segment = segments[index];
            final isActive = index == activeIndex;
            final isCompleted = index < activeIndex;

            return _AnimatedWordBox(
              key: ValueKey('word_${controller.currentStepIndex.value}_$index'),
              text: segment.text,
              isActive: isActive,
              isCompleted: isCompleted,
              baseStyle: baseStyle,
              activeStyle: activeStyle,
              completedStyle: completedStyle,
              highlightColor: highlightColor,
              borderRadius: borderRadius,
            );
          }),
        );
      },
    );
  }
}

class _AnimatedWordBox extends StatefulWidget {
  final String text;
  final bool isActive;
  final bool isCompleted;
  final TextStyle baseStyle;
  final TextStyle activeStyle;
  final TextStyle completedStyle;
  final Color highlightColor;
  final double borderRadius;

  const _AnimatedWordBox({
    super.key,
    required this.text,
    required this.isActive,
    required this.isCompleted,
    required this.baseStyle,
    required this.activeStyle,
    required this.completedStyle,
    required this.highlightColor,
    required this.borderRadius,
  });

  @override
  State<_AnimatedWordBox> createState() => _AnimatedWordBoxState();
}

class _AnimatedWordBoxState extends State<_AnimatedWordBox>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOutCubic,
    );

    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.isActive) {
      _scaleController.forward(from: 0);
      _backgroundController.forward();
    } else if (widget.isCompleted) {
      _scaleController.value = 1.0;
      _backgroundController.value = 1.0;
    } else {
      _backgroundController.reverse();
    }
  }

  @override
  void didUpdateWidget(_AnimatedWordBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive ||
        widget.isCompleted != oldWidget.isCompleted) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _backgroundAnimation]),
      builder: (context, child) {
        final showBg = widget.isActive || widget.isCompleted;
        final bgOpacity = showBg ? _backgroundAnimation.value : 0.0;

        return Transform.scale(
          scale: widget.isActive ? _scaleAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: widget.highlightColor.withOpacity(
                widget.isActive ? bgOpacity * 0.3 : bgOpacity * 0.15,
              ),
              border: showBg && bgOpacity > 0.5
                  ? Border.all(
                      color: widget.highlightColor.withOpacity(
                        widget.isActive ? 0.5 : 0.25,
                      ),
                      width: 1,
                    )
                  : null,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.highlightColor.withOpacity(
                          bgOpacity * 0.35,
                        ),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: widget.isActive
                  ? widget.activeStyle
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
