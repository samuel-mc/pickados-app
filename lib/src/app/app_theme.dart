import 'package:flutter/material.dart';

ThemeData buildPickadosTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  const blue = Color(0xFF2E7CF6);
  const orange = Color(0xFFFF7A45);
  const teal = Color(0xFF22C7A9);

  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    brightness: brightness,
  ).copyWith(
    primary: blue,
    secondary: orange,
    tertiary: teal,
    surface: isDark ? const Color(0xFF0F1722) : const Color(0xFFFFFFFF),
    onSurface: isDark ? const Color(0xFFF3F7FB) : const Color(0xFF15202B),
    surfaceContainerHighest: isDark
        ? const Color(0xFF1A2533)
        : const Color(0xFFEFF4FA),
    outline: isDark ? const Color(0xFF2A3648) : const Color(0xFFD8E1EC),
  );

  final colors = PickadosColors(
    pageGradientTop: isDark ? const Color(0xFF0B1220) : const Color(0xFFF7FBFF),
    pageGradientBottom: isDark ? const Color(0xFF101926) : const Color(0xFFEDF3F9),
    cardGlass: isDark
        ? const Color(0xFF121C28).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9),
    softSurface: isDark ? const Color(0xFF182433) : const Color(0xFFF5F8FC),
    blueSurface: isDark ? const Color(0xFF15283E) : const Color(0xFFEAF3FF),
    warmSurface: isDark ? const Color(0xFF342117) : const Color(0xFFFFF2E8),
    borderSoft: isDark ? const Color(0xFF263244) : const Color(0xFFDCE5EF),
    textMuted: isDark ? const Color(0xFF9AA9BA) : const Color(0xFF64748B),
    success: const Color(0xFF1DBA84),
    danger: const Color(0xFFFF7A45),
    warning: const Color(0xFFF2B63D),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    extensions: [colors],
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        height: 1.02,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: scheme.onSurface.withValues(alpha: 0.9),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        color: colors.textMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.cardGlass,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colors.borderSoft),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: scheme.onSurface),
      actionsIconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    dividerColor: colors.borderSoft,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: colors.blueSurface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF182230) : const Color(0xFF15202B),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.softSurface,
      labelStyle: TextStyle(color: colors.textMuted),
      hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.borderSoft),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.blueSurface,
      selectedColor: scheme.primary.withValues(alpha: 0.16),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      labelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.cardGlass,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: selected ? scheme.primary : colors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : colors.textMuted,
        );
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  );

  return base;
}

class PickadosColors extends ThemeExtension<PickadosColors> {
  const PickadosColors({
    required this.pageGradientTop,
    required this.pageGradientBottom,
    required this.cardGlass,
    required this.softSurface,
    required this.blueSurface,
    required this.warmSurface,
    required this.borderSoft,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.warning,
  });

  final Color pageGradientTop;
  final Color pageGradientBottom;
  final Color cardGlass;
  final Color softSurface;
  final Color blueSurface;
  final Color warmSurface;
  final Color borderSoft;
  final Color textMuted;
  final Color success;
  final Color danger;
  final Color warning;

  @override
  ThemeExtension<PickadosColors> copyWith({
    Color? pageGradientTop,
    Color? pageGradientBottom,
    Color? cardGlass,
    Color? softSurface,
    Color? blueSurface,
    Color? warmSurface,
    Color? borderSoft,
    Color? textMuted,
    Color? success,
    Color? danger,
    Color? warning,
  }) {
    return PickadosColors(
      pageGradientTop: pageGradientTop ?? this.pageGradientTop,
      pageGradientBottom: pageGradientBottom ?? this.pageGradientBottom,
      cardGlass: cardGlass ?? this.cardGlass,
      softSurface: softSurface ?? this.softSurface,
      blueSurface: blueSurface ?? this.blueSurface,
      warmSurface: warmSurface ?? this.warmSurface,
      borderSoft: borderSoft ?? this.borderSoft,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<PickadosColors> lerp(
    covariant ThemeExtension<PickadosColors>? other,
    double t,
  ) {
    if (other is! PickadosColors) {
      return this;
    }

    return PickadosColors(
      pageGradientTop: Color.lerp(pageGradientTop, other.pageGradientTop, t)!,
      pageGradientBottom: Color.lerp(pageGradientBottom, other.pageGradientBottom, t)!,
      cardGlass: Color.lerp(cardGlass, other.cardGlass, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      blueSurface: Color.lerp(blueSurface, other.blueSurface, t)!,
      warmSurface: Color.lerp(warmSurface, other.warmSurface, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
