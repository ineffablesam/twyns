import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Custom painter for the main visualizer output
class AudioVisualizerPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final ui.Image? bufferAImage;
  final double warpStrength;
  final double colorIntensity;
  final double glowFalloff;
  final double smoothness;

  const AudioVisualizerPainter({
    required this.program,
    required this.time,
    this.bufferAImage,
    required this.warpStrength,
    required this.colorIntensity,
    required this.glowFalloff,
    required this.smoothness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bufferAImage == null) {
      _drawLoadingState(canvas, size);
      return;
    }

    try {
      final shader = program.fragmentShader();

      // Set basic uniforms
      shader.setFloat(0, size.width); // uResolution.x
      shader.setFloat(1, size.height); // uResolution.y
      shader.setFloat(2, time); // uTime

      // Set shader control uniforms
      shader.setFloat(3, warpStrength);
      shader.setFloat(4, colorIntensity);
      shader.setFloat(5, smoothness);
      shader.setFloat(6, glowFalloff);

      shader.setImageSampler(0, bufferAImage!);

      final paint = Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } catch (e) {
      debugPrint('Paint error: $e');
      _drawErrorState(canvas, size);
    }
  }

  void _drawLoadingState(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.15;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawErrorState(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1a1a1a),
    );
  }

  @override
  bool shouldRepaint(covariant AudioVisualizerPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.bufferAImage != bufferAImage ||
        oldDelegate.warpStrength != warpStrength ||
        oldDelegate.colorIntensity != colorIntensity ||
        oldDelegate.glowFalloff != glowFalloff ||
        oldDelegate.smoothness != smoothness;
  }
}
