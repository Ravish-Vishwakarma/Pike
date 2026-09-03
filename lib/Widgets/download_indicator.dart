import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pike/Utilities/colors.dart';

enum DownloadIndicatorState { downloading, completed, failed }

class DownloadProgressIndicator extends StatefulWidget {
  final double progress;
  final DownloadIndicatorState state;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    required this.state,
  });

  @override
  State<DownloadProgressIndicator> createState() =>
      _DownloadProgressIndicatorState();
}

class _DownloadProgressIndicatorState extends State<DownloadProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _toggleAnimation();
  }

  @override
  void didUpdateWidget(DownloadProgressIndicator old) {
    super.didUpdateWidget(old);
    if (widget.state != old.state) _toggleAnimation();
  }

  void _toggleAnimation() {
    if (widget.state == DownloadIndicatorState.downloading) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => SizedBox(
        width: 48,
        height: 56,
        child: CustomPaint(
          size: const Size(48, 48),
          painter: _DownloadProgressPainter(
            progress: widget.progress,
            state: widget.state,
            pulse: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _DownloadProgressPainter extends CustomPainter {
  final double progress;
  final DownloadIndicatorState state;
  final double pulse;

  _DownloadProgressPainter({
    required this.progress,
    required this.state,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 3.5;

    _drawTrack(canvas, center, radius, strokeWidth);

    switch (state) {
      case DownloadIndicatorState.completed:
        _drawComplete(canvas, center, radius, strokeWidth);
      case DownloadIndicatorState.failed:
        _drawFailed(canvas, center, radius, strokeWidth);
      case DownloadIndicatorState.downloading:
        _drawDownloading(canvas, center, radius, strokeWidth);
    }
  }

  void _drawTrack(Canvas canvas, Offset center, double radius, double sw) {
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
  }

  void _drawComplete(Canvas canvas, Offset center, double radius, double sw) {
    final r = radius * (0.8 + 0.2 * pulse);
    final completePaint = Paint()
      ..color = Color.lerp(Colors.green.shade400, Colors.green.shade700, pulse)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, completePaint);

    final checkPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = radius * 0.4;
    final path = Path()
      ..moveTo(center.dx - s * 0.55, center.dy)
      ..lineTo(center.dx - s * 0.1, center.dy + s * 0.45)
      ..lineTo(center.dx + s * 0.65, center.dy - s * 0.4);
    canvas.drawPath(path, checkPaint);
  }

  void _drawFailed(Canvas canvas, Offset center, double radius, double sw) {
    final failPaint = Paint()
      ..color = Color.lerp(Colors.red.shade400, Colors.red.shade700, pulse)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, failPaint);

    final xPaint = Paint()
      ..color = Colors.red.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final s = radius * 0.35;
    canvas.drawLine(
      center - Offset(s, s), center + Offset(s, s), xPaint);
    canvas.drawLine(
      center + Offset(s, -s), center - Offset(s, -s), xPaint);
  }

  void _drawDownloading(
      Canvas canvas, Offset center, double radius, double sw) {
    final alpha = (80 + 175 * pulse).round();
    final arcPaint = Paint()
      ..color = MyColors.primary.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );

    _drawArrow(canvas, center, radius);
    _drawPercent(canvas, center, radius);
  }

  void _drawArrow(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = MyColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final a = radius * 0.3;
    final x0 = center.dx;
    final yT = center.dy - a * 0.15;
    final yB = center.dy + a * 0.5;

    canvas.drawLine(Offset(x0, yT), Offset(x0, yB), paint);
    canvas.drawLine(Offset(x0, yB), Offset(x0 - a * 0.35, yB - a * 0.35), paint);
    canvas.drawLine(Offset(x0, yB), Offset(x0 + a * 0.35, yB - a * 0.35), paint);
  }

  void _drawPercent(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).round()}%',
        style: TextStyle(
          color: MyColors.primary,
          fontSize: radius * 0.3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + radius * 0.6),
    );
  }

  @override
  bool shouldRepaint(_DownloadProgressPainter old) =>
      old.progress != progress || old.state != state || old.pulse != pulse;
}
