import 'package:material_ui/material_ui.dart';

/// Paleta de colores estable para las etiquetas.
///
/// El color de una etiqueta se deriva de su `colorIndex` para que no haga falta
/// elegirlo a mano y para que se vea bien en tema claro y oscuro.
abstract final class TagPalette {
  static const List<Color> _baseColors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
    Color(0xFF65A30D),
  ];

  static Color foreground(int colorIndex, ColorScheme scheme) {
    final color = _baseColors[colorIndex % _baseColors.length];
    final lightness = scheme.brightness == Brightness.dark ? 0.76 : 0.34;
    return HSLColor.fromColor(color).withLightness(lightness).toColor();
  }

  static Color background(int colorIndex, ColorScheme scheme) {
    final color = _baseColors[colorIndex % _baseColors.length];
    final lightness = scheme.brightness == Brightness.dark ? 0.7 : 0.45;
    final tinted = HSLColor.fromColor(color).withLightness(lightness).toColor();
    return Color.alphaBlend(
      tinted.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.3 : 0.16,
      ),
      scheme.surface,
    );
  }
}
