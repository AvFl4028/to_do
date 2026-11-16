import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tag_palette.dart';
import '../../domain/task_tag.dart';

/// Chip de una etiqueta global, con el color estable de su paleta.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    this.onDeleted,
    this.compact = false,
  });

  final TaskTag tag;

  /// Si no es `null`, se muestra una «x» para quitar la etiqueta.
  final VoidCallback? onDeleted;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = TagPalette.background(tag.colorIndex, scheme);
    final foreground = TagPalette.foreground(tag.colorIndex, scheme);

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        compact ? 2 : 4,
        onDeleted == null ? 8 : 2,
        compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${tag.name}',
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
          if (onDeleted != null)
            InkWell(
              onTap: onDeleted,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: compact ? 12 : 14,
                  color: foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
