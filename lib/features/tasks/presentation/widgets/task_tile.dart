import 'package:material_ui/material_ui.dart';

import '../../domain/task.dart';
import '../../domain/task_tag.dart';
import 'due_date_badge.dart';
import 'list_indicator.dart';
import 'tag_chip.dart';

enum TaskMenuAction { edit, delete }

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.tags,
    required this.onOpen,
    required this.onToggle,
    required this.onToggleImportant,
    required this.onEdit,
    required this.onDelete,
    this.listLabel,
  });

  final Task task;

  /// Etiquetas ya resueltas que pertenecen a esta tarea.
  final List<TaskTag> tags;

  /// Emoji y nombre de la lista, cuando conviene mostrarlos.
  final (String, String)? listLabel;

  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onToggleImportant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasMetadata =
        task.dueDate != null ||
        task.description.isNotEmpty ||
        tags.isNotEmpty ||
        task.attachments.isNotEmpty ||
        listLabel != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: task.isCompleted
                    ? 'Marcar como pendiente'
                    : 'Marcar como completada',
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (hasMetadata) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (listLabel != null)
                              ListIndicator(
                                emoji: listLabel!.$1,
                                name: listLabel!.$2,
                              ),
                            if (task.dueDate != null) DueDateBadge(task: task),
                            for (final tag in tags.take(3))
                              TagChip(tag: tag, compact: true),
                            if (tags.length > 3)
                              Text(
                                '+${tags.length - 3}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            if (task.attachments.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${task.attachments.length}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            if (task.description.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    size: 14,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Descripción',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: task.isImportant
                    ? 'Quitar de importantes'
                    : 'Marcar como importante',
                onPressed: onToggleImportant,
                icon: Icon(
                  task.isImportant
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: task.isImportant
                      ? const Color(0xFFF59E0B)
                      : scheme.onSurfaceVariant,
                ),
              ),
              PopupMenuButton<TaskMenuAction>(
                tooltip: 'Opciones de la tarea',
                onSelected: (action) => switch (action) {
                  TaskMenuAction.edit => onEdit(),
                  TaskMenuAction.delete => onDelete(),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: TaskMenuAction.edit,
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: TaskMenuAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 12),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
