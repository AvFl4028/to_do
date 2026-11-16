import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_formatters.dart';
import '../application/task_scope.dart';
import '../application/task_store.dart';
import '../domain/attachment.dart';
import '../domain/task.dart';
import '../domain/task_tag.dart';
import 'image_preview_page.dart';
import 'task_form_page.dart';
import 'widgets/attachment_section.dart';
import 'widgets/due_date_badge.dart';
import 'widgets/due_date_picker.dart';
import 'widgets/list_indicator.dart';
import 'widgets/tag_chip.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final task = store.taskById(taskId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la tarea'),
        actions: task == null
            ? null
            : [
                IconButton(
                  tooltip: 'Editar tarea',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editTask(context, store, task),
                ),
                IconButton(
                  tooltip: 'Eliminar tarea',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTask(context, store, task),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: task == null
          ? const Center(child: Text('Esta tarea ya no existe.'))
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      _TaskHeader(task: task, store: store),
                      const SizedBox(height: 20),
                      Card(
                        child: ListTile(
                          key: const ValueKey('task-detail-due-date'),
                          leading: const Icon(Icons.event_outlined),
                          title: const Text('Fecha de entrega'),
                          subtitle: Text(
                            task.dueDate == null
                                ? 'Sin fecha'
                                : AppDates.long(task.dueDate!),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.dueDate != null)
                                IconButton(
                                  tooltip: 'Quitar fecha',
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      store.setDueDate(task.id, null),
                                ),
                              const Icon(Icons.edit_calendar_outlined),
                            ],
                          ),
                          onTap: () => _pickDueDate(context, store, task),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AttachmentSection(
                        attachments: task.attachments,
                        onAdd: () => _addAttachments(context, store, task),
                        onRemove: (attachment) =>
                            _removeAttachment(store, task, attachment),
                        onOpen: (attachment) =>
                            _openAttachment(context, attachment),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Descripción',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contenido en Markdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: task.description.trim().isEmpty
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.notes_rounded,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Esta tarea no tiene descripción. Puedes añadirla desde Editar.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                )
                              : SelectionArea(
                                  child: GptMarkdown(
                                    task.description,
                                    isStreaming: false,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _pickDueDate(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final picked = await pickTaskDueDate(context, initialDate: task.dueDate);
    if (picked == null) {
      return;
    }
    await store.setDueDate(task.id, picked);
  }

  Future<void> _addAttachments(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final storage = TaskScope.attachmentsOf(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!storage.isAvailable) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Los adjuntos no están disponibles en esta plataforma.',
          ),
        ),
      );
      return;
    }

    try {
      final picked = await storage.pickAndStore();
      for (final attachment in picked) {
        await store.addAttachment(task.id, attachment);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudieron añadir los archivos.')),
      );
    }
  }

  void _removeAttachment(TaskStore store, Task task, Attachment attachment) {
    store.removeAttachment(task.id, attachment.id);
  }

  Future<void> _openAttachment(
    BuildContext context,
    Attachment attachment,
  ) async {
    final storage = TaskScope.attachmentsOf(context);
    final opener = TaskScope.openerOf(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!await storage.exists(attachment.storedName)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El archivo ya no está disponible.')),
      );
      return;
    }

    final path = storage.pathFor(attachment.storedName);
    if (path == null) {
      return;
    }

    if (attachment.isImage) {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) =>
              ImagePreviewPage(attachment: attachment, path: path),
        ),
      );
      return;
    }

    final opened = await opener.open(path);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el archivo con el sistema.'),
        ),
      );
    }
  }

  Future<void> _editTask(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute<TaskFormResult>(
        builder: (context) => TaskFormPage(task: task),
      ),
    );
    if (result == null) {
      return;
    }
    await store.updateTask(
      task.id,
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      listId: result.listId,
      isImportant: result.isImportant,
      tagIds: result.tagIds,
      attachments: result.attachments,
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    TaskStore store,
    Task task,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Seguro que quieres eliminar «${task.title}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await store.delete(task.id);
    if (!context.mounted) {
      return;
    }
    navigator.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('«${task.title}» eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => store.undoDelete(),
        ),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task, required this.store});

  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final list = store.listById(task.listId);
    final tags = <TaskTag>[
      for (final tag in store.tags)
        if (task.tagIds.contains(tag.id)) tag,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: task.isCompleted
              ? 'Marcar como pendiente'
              : 'Marcar como completada',
          child: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => store.toggleCompleted(task.id),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: task.isCompleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: task.isImportant
                        ? 'Quitar de importantes'
                        : 'Marcar como importante',
                    onPressed: () => store.toggleImportant(task.id),
                    icon: Icon(
                      task.isImportant
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: task.isImportant
                          ? const Color(0xFFF59E0B)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusChip(task: task),
                  if (task.dueDate != null) DueDateBadge(task: task),
                  if (list != null)
                    ListIndicator(emoji: list.emoji, name: list.name),
                  for (final tag in tags) TagChip(tag: tag, compact: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, background, foreground) = _style(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  (String, Color, Color) _style(ColorScheme scheme) {
    if (task.isCompleted) {
      return (
        'Completada',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      );
    }
    final dueDate = task.dueDate;
    if (dueDate != null && AppDates.isOverdue(dueDate)) {
      return ('Vencida', scheme.errorContainer, scheme.onErrorContainer);
    }
    return ('Pendiente', scheme.primaryContainer, scheme.onPrimaryContainer);
  }
}
