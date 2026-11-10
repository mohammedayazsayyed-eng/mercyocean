import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A stylised prayer-beads (tasbih) glyph, hand-drawn with a [CustomPainter]
/// so it renders crisply at any size without shipping a bespoke SVG asset.
/// A ring of beads with a pendant of three strands hanging beneath it —
/// matching the icon used for the floating Tasbih button.
class TasbihBeadsIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TasbihBeadsIcon({super.key, this.size = 28, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TasbihBeadsPainter(color: color),
    );
  }
}

class _TasbihBeadsPainter extends CustomPainter {
  final Color color;

  _TasbihBeadsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final beadFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ringStroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.028;
    final strandStroke = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.5, size.height * 0.40);
    final radius = size.width * 0.32;
    const beadCount = 14;
    final beadRadius = size.width * 0.052;

    // Faint loop connecting the beads.
    canvas.drawCircle(center, radius, ringStroke);

    for (int i = 0; i < beadCount; i++) {
      final angle = (2 * math.pi / beadCount) * i - math.pi / 2;
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), beadRadius, beadFill);
    }

    // Pendant: three strands hanging from the bottom of the loop, the
    // centre one longer, each ending in a slightly larger bead.
    final bottom = Offset(center.dx, center.dy + radius);
    _drawStrand(
      canvas,
      beadFill,
      strandStroke,
      start: bottom,
      dx: -size.width * 0.14,
      length: size.height * 0.30,
      beadRadius: beadRadius * 0.85,
    );
    _drawStrand(
      canvas,
      beadFill,
      strandStroke,
      start: bottom,
      dx: 0,
      length: size.height * 0.40,
      beadRadius: beadRadius * 0.95,
    );
    _drawStrand(
      canvas,
      beadFill,
      strandStroke,
      start: bottom,
      dx: size.width * 0.14,
      length: size.height * 0.30,
      beadRadius: beadRadius * 0.85,
    );
  }

  void _drawStrand(
    Canvas canvas,
    Paint beadFill,
    Paint strandStroke, {
    required Offset start,
    required double dx,
    required double length,
    required double beadRadius,
  }) {
    final end = Offset(start.dx + dx, start.dy + length);
    canvas.drawLine(start, end, strandStroke);
    canvas.drawCircle(end, beadRadius, beadFill);
  }

  @override
  bool shouldRepaint(covariant _TasbihBeadsPainter oldDelegate) =>
      oldDelegate.color != color;
}
