import 'package:material_ui/material_ui.dart';

/// En web los adjuntos aún no están disponibles; esta variante mantiene la
/// interfaz compilable y muestra un marcador.
class AttachmentImage extends StatelessWidget {
  const AttachmentImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.isSvg = false,
  });

  final String path;
  final BoxFit fit;
  final bool isSvg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
