import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Full-screen loader shown while a page is loading.
/// Replaces the partial layout (bottom nav only) with a cohesive loading state.
class FullPageLoader extends StatefulWidget {
  final Color? accentColor;

  const FullPageLoader({super.key, this.accentColor});

  @override
  State<FullPageLoader> createState() => _FullPageLoaderState();
}

class _FullPageLoaderState extends State<FullPageLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? const Color(0xFF4F6DFF);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LoaderPainter(
                      progress: _controller.value,
                      color: accent,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoaderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const dotCount = 8;
    const radius = 24.0;

    for (var i = 0; i < dotCount; i++) {
      final dotProgress = (progress + i / dotCount) % 1.0;
      final scale = 0.5 + 0.5 * math.sin(dotProgress * math.pi);
      final alpha = (0.4 + 0.6 * scale).clamp(0.0, 1.0);
      final dotRadius = 5.0 + 2.0 * scale;

      final angle = (i / dotCount) * 2 * math.pi - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        dotRadius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
