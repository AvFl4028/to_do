import 'package:material_ui/material_ui.dart';

import '../../application/task_scope.dart';
import '../../domain/attachment.dart';
import 'attachment_tile.dart';

/// Sección reutilizable de adjuntos, usada en el formulario y en el detalle.
class AttachmentSection extends StatelessWidget {
  const AttachmentSection({
    super.key,
    required this.attachments,
    this.onAdd,
    this.onRemove,
    this.onOpen,
  });

  final List<Attachment> attachments;
  final VoidCallback? onAdd;
  final ValueChanged<Attachment>? onRemove;
  final ValueChanged<Attachment>? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final storage = TaskScope.attachmentsOf(context);
    final isAvailable = storage.isAvailable;
    final canAdd = onAdd != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Adjuntos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canAdd)
              TextButton.icon(
                onPressed: isAvailable ? onAdd : null,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Añadir'),
              ),
          ],
        ),
        if (!isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Los adjuntos no están disponibles en esta plataforma. '
              'En escritorio y Android puedes añadir imágenes y documentos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else if (attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Sin archivos adjuntos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final attachment in attachments)
                  AttachmentTile(
                    key: ValueKey<String>('attachment-${attachment.id}'),
                    attachment: attachment,
                    path: storage.pathFor(attachment.storedName),
                    onOpen: onOpen == null ? null : () => onOpen!(attachment),
                    onRemove: onRemove == null
                        ? null
                        : () => onRemove!(attachment),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
