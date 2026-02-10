import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zenopay/core/app_nav_key.dart';

/// Shows a big center-screen celebration when the user gains a streak point.
class StreakCelebrationOverlay {
  static OverlayEntry? _activeEntry;

  /// Shows the "Streak Point Gained!" animation. Call when streak has increased.
  static void show() {
    if (_activeEntry != null) return;

    final overlay = navKey.currentState?.overlay;
    if (overlay == null) return;

    _activeEntry = OverlayEntry(
      builder: (context) => const _StreakCelebrationWidget(),
    );
    overlay.insert(_activeEntry!);
  }

  static void _remove() {
    _activeEntry?.remove();
    _activeEntry = null;
  }
}

class _StreakCelebrationWidget extends StatefulWidget {
  const _StreakCelebrationWidget();

  @override
  State<_StreakCelebrationWidget> createState() => _StreakCelebrationWidgetState();
}

class _StreakCelebrationWidgetState extends State<_StreakCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
    _fadeController.forward();

    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        StreakCelebrationOverlay._remove();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _fadeController]),
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4 * _fadeAnimation.value),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFF97316),
                              size: 72,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Streak Point Gained!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2A3B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keep it up! 🔥',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
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
}
