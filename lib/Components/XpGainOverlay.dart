import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zenopay/core/app_nav_key.dart';
import 'package:zenopay/theme/zenopay_colors.dart';

/// Curve that clamps output to [0, 1] so TweenSequence never receives out-of-range values.
class _ClampCurve extends Curve {
  final Curve curve;
  const _ClampCurve(this.curve);
  @override
  double transformInternal(double t) => curve.transform(t).clamp(0.0, 1.0);
}

/// Shows an animated "+X XP" celebration when the user gains XP (e.g. after saving a transaction).
class XpGainOverlay {
  static OverlayEntry? _activeEntry;

  /// Shows the XP gain animation. [xp] is the amount earned (e.g. 5).
  static void show({int xp = 5}) {
    if (_activeEntry != null) return;

    final overlay = navKey.currentState?.overlay;
    if (overlay == null) return;

    _activeEntry = OverlayEntry(
      builder: (context) => _XpGainWidget(xp: xp),
    );
    overlay.insert(_activeEntry!);
  }

  static void _remove() {
    _activeEntry?.remove();
    _activeEntry = null;
  }
}

class _XpGainWidget extends StatefulWidget {
  final int xp;

  const _XpGainWidget({required this.xp});

  @override
  State<_XpGainWidget> createState() => _XpGainWidgetState();
}

class _XpGainWidgetState extends State<_XpGainWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _starController;
  late AnimationController _sparkleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starScaleAnimation;
  late Animation<double> _starRotateAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _starController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: const _ClampCurve(Curves.easeOutCubic),
    ));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 84),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 8),
    ]).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const _ClampCurve(Curves.easeInOut),
    ));

    _starScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _starController,
      curve: const _ClampCurve(Curves.easeOutBack),
    ));

    _starRotateAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _starController,
        curve: const _ClampCurve(Curves.easeOutCubic),
      ),
    );

    _scaleController.forward();
    _fadeController.forward();
    _starController.forward();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      _sparkleController.forward();
    });

    Future<void>.delayed(const Duration(milliseconds: 5100), () {
      if (mounted) XpGainOverlay._remove();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _starController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ZenoPayColors.of(context);
    final accent = const Color(0xFF4F6DFF);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleController,
          _fadeController,
          _starController,
          _sparkleController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                  child: Container(
                  color: Colors.black.withValues(alpha: 0.35 * _fadeAnimation.value.clamp(0.0, 1.0)),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value.clamp(0.0, 1.2),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: c.shadow.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildSparkles(),
                                Transform.rotate(
                                  angle: (_starRotateAnimation.value.clamp(-0.15, 0.0)) * 2 * math.pi,
                                  child: Transform.scale(
                                    scale: _starScaleAnimation.value.clamp(0.0, 1.5),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            accent,
                                            accent.withValues(alpha: 0.75),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(alpha: 0.5),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Saved!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${widget.xp} XP',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F6DFF),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSparkles() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, _) {
        const count = 6;
        final progress = Curves.easeOut.transform(_sparkleController.value);
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(count, (i) {
              final angle = (i / count) * 2 * math.pi + progress * 0.5;
              final radius = 28.0 + progress * 20;
              final x = math.cos(angle) * radius;
              final y = math.sin(angle) * radius;
              final opacity = (progress * 1.5).clamp(0.0, 1.0) * (1 - progress * 0.5);
              final scale = 0.3 + progress * 0.7;
              return Transform.translate(
                offset: Offset(x, y),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: const Color(0xFF4F6DFF).withValues(alpha: 0.9),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
