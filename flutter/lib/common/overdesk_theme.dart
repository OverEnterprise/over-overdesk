import 'package:flutter/material.dart';

class OverDeskTheme {
  static const enabled = bool.fromEnvironment('OVERDESK');
  static const brand = Color(0xFFC72826);
  static const darkAccent = Color(0xFFF26B66);

  static ThemeData apply(ThemeData theme) {
    if (!enabled) return theme;
    final dark = theme.brightness == Brightness.dark;
    final accent = dark ? darkAccent : brand;
    final background = dark ? const Color(0xFF0A0A0A) : Colors.white;
    final card = dark ? const Color(0xFF171717) : const Color(0xFFFAFAFA);
    final foreground = dark ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A);
    return theme.copyWith(
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      dialogBackgroundColor: card,
      cardColor: card,
      colorScheme: theme.colorScheme.copyWith(
        primary: accent,
        onPrimary: dark ? const Color(0xFF0A0A0A) : Colors.white,
        secondary: accent,
        onSecondary: dark ? const Color(0xFF0A0A0A) : Colors.white,
        background: card,
        surface: card,
        onSurface: foreground,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(fillColor: card),
      textTheme: theme.textTheme.copyWith(
        labelLarge: theme.textTheme.labelLarge?.copyWith(color: accent),
      ),
      textButtonTheme: TextButtonThemeData(
        style: theme.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled) ? null : accent),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withOpacity(0.25),
        selectionHandleColor: accent,
      ),
      progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(color: accent),
    );
  }
}
