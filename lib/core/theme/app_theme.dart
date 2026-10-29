import 'package:flutter/material.dart';

/// PrivaPDF visual identity.
///
/// A deep violet seed signals trust and privacy, deliberately distinct from
/// the red of cloud PDF tools. Material 3, with full light and dark schemes.
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF5A48E0);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }
}
