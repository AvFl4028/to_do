import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Muestra una imagen o SVG almacenado en el sistema de archivos local.
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
    final file = File(path);
    if (!file.existsSync()) {
      return _MissingFile(isSvg: isSvg);
    }

    if (isSvg) {
      return SvgPicture.file(file, fit: fit);
    }

    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _MissingFile(isSvg: isSvg),
    );
  }
}

class _MissingFile extends StatelessWidget {
  const _MissingFile({required this.isSvg});

  final bool isSvg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
