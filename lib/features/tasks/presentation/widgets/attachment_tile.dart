import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/file_size.dart';
import '../../domain/attachment.dart';
import 'attachment_image.dart';

/// Fila compacta de un adjunto.
///
/// Las imágenes muestran una miniatura real; los documentos muestran un icono
/// representativo de su tipo.
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    this.path,
    this.onOpen,
    this.onRemove,
  });

  final Attachment attachment;

  /// Ruta local resuelta por el almacenamiento, si está disponible.
  final String? path;

  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 250,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: _buildPreview(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_kindLabel(attachment.kind)} · ${formatFileSize(attachment.sizeBytes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Quitar adjunto',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (attachment.isImage && path != null) {
      return AttachmentImage(
        path: path!,
        fit: BoxFit.cover,
        isSvg: attachment.isSvg,
      );
    }

    final (icon, tint) = _iconFor(
      attachment.kind,
      Theme.of(context).colorScheme,
    );
    return ColoredBox(
      color: tint.withValues(alpha: 0.14),
      child: Icon(icon, color: tint, size: 24),
    );
  }

  static String _kindLabel(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => 'Imagen',
    AttachmentKind.pdf => 'PDF',
    AttachmentKind.word => 'Word',
    AttachmentKind.excel => 'Hoja de cálculo',
    AttachmentKind.powerpoint => 'Presentación',
    AttachmentKind.text => 'Texto',
    AttachmentKind.other => 'Archivo',
  };

  static (IconData, Color) _iconFor(AttachmentKind kind, ColorScheme scheme) {
    return switch (kind) {
      AttachmentKind.image => (Icons.image_outlined, scheme.primary),
      AttachmentKind.pdf => (
        Icons.picture_as_pdf_outlined,
        const Color(0xFFDC2626),
      ),
      AttachmentKind.word => (
        Icons.description_outlined,
        const Color(0xFF2563EB),
      ),
      AttachmentKind.excel => (
        Icons.table_chart_outlined,
        const Color(0xFF059669),
      ),
      AttachmentKind.powerpoint => (
        Icons.slideshow_outlined,
        const Color(0xFFEA580C),
      ),
      AttachmentKind.text => (Icons.article_outlined, scheme.onSurfaceVariant),
      AttachmentKind.other => (
        Icons.insert_drive_file_outlined,
        scheme.outline,
      ),
    };
  }
}
