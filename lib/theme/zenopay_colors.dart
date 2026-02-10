import 'package:flutter/material.dart';

/// App-wide semantic colors so every screen adapts to light/dark theme.
@immutable
class ZenoPayColors extends ThemeExtension<ZenoPayColors> {
  const ZenoPayColors({
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.surfaceGradientStart,
    required this.surfaceGradientEnd,
    required this.navBar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentMuted,
    required this.border,
    required this.borderLight,
    required this.shadow,
    required this.error,
    required this.success,
    required this.progressBg,
  });

  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color surfaceGradientStart;
  final Color surfaceGradientEnd;
  final Color navBar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentMuted;
  final Color border;
  final Color borderLight;
  final Color shadow;
  final Color error;
  final Color success;
  final Color progressBg;

  static const ZenoPayColors light = ZenoPayColors(
    surface: Color(0xFFF8FAFC),
    surfaceVariant: Color(0xFFF1F5F9),
    card: Colors.white,
    surfaceGradientStart: Color(0xFFF5F3FF),
    surfaceGradientEnd: Color(0xFFF0FDF4),
    navBar: Color(0xFF1E293B),
    textPrimary: Color(0xFF1E2A3B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    accent: Color(0xFF4F6DFF),
    accentMuted: Color(0xFFEEF2FF),
    border: Color(0xFFE2E8F0),
    borderLight: Color(0xFFF1F5F9),
    shadow: Color(0x0D000000),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    progressBg: Color(0xFFE2E8F0),
  );

  static const ZenoPayColors dark = ZenoPayColors(
    surface: Color(0xFF0F172A),
    surfaceVariant: Color(0xFF1E293B),
    card: Color(0xFF1E293B),
    surfaceGradientStart: Color(0xFF1E1B4B),
    surfaceGradientEnd: Color(0xFF0F172A),
    navBar: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    accent: Color(0xFF4F6DFF),
    accentMuted: Color(0xFF312E81),
    border: Color(0xFF334155),
    borderLight: Color(0xFF475569),
    shadow: Color(0x40000000),
    error: Color(0xFFF87171),
    success: Color(0xFF34D399),
    progressBg: Color(0xFF334155),
  );

  @override
  ZenoPayColors copyWith({
    Color? surface,
    Color? surfaceVariant,
    Color? card,
    Color? surfaceGradientStart,
    Color? surfaceGradientEnd,
    Color? navBar,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentMuted,
    Color? border,
    Color? borderLight,
    Color? shadow,
    Color? error,
    Color? success,
    Color? progressBg,
  }) {
    return ZenoPayColors(
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      card: card ?? this.card,
      surfaceGradientStart: surfaceGradientStart ?? this.surfaceGradientStart,
      surfaceGradientEnd: surfaceGradientEnd ?? this.surfaceGradientEnd,
      navBar: navBar ?? this.navBar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      shadow: shadow ?? this.shadow,
      error: error ?? this.error,
      success: success ?? this.success,
      progressBg: progressBg ?? this.progressBg,
    );
  }

  @override
  ZenoPayColors lerp(ThemeExtension<ZenoPayColors>? other, double t) {
    if (other is! ZenoPayColors) return this;
    return ZenoPayColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceGradientStart: Color.lerp(surfaceGradientStart, other.surfaceGradientStart, t)!,
      surfaceGradientEnd: Color.lerp(surfaceGradientEnd, other.surfaceGradientEnd, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      progressBg: Color.lerp(progressBg, other.progressBg, t)!,
    );
  }

  /// Use in build(): final c = ZenoPayColors.of(context);
  static ZenoPayColors of(BuildContext context) {
    final ext = Theme.of(context).extension<ZenoPayColors>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? ZenoPayColors.dark : ZenoPayColors.light;
  }
}
