import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_motion.dart';
import '../../application/task_scope.dart';
import '../task_detail_page.dart';
import '../task_form_page.dart';

/// Panel derecho de escritorio: detalle y edición sin salir de la lista.
class TaskDetailPanel extends StatefulWidget {
  const TaskDetailPanel({
    super.key,
    required this.taskId,
    required this.onClose,
  });

  final String taskId;
  final VoidCallback onClose;

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  bool _editing = false;

  @override
  void didUpdateWidget(TaskDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _editing = false;
    }
  }

  Future<void> _save(TaskFormResult result) async {
    final store = TaskScope.of(context);
    await store.updateTask(
      widget.taskId,
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      dueTimeMinutes: result.dueTimeMinutes,
      listId: result.listId,
      isImportant: result.isImportant,
      tagIds: result.tagIds,
      attachments: result.attachments,
    );
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = TaskScope.of(context).taskById(widget.taskId);
    final duration = appMotionDuration(context);

    if (task == null) {
      return ColoredBox(
        color: theme.colorScheme.surface,
        child: const Center(child: Text('Esta tarea ya no existe.')),
      );
    }

    return ColoredBox(
      key: const ValueKey<String>('task-detail-panel'),
      color: theme.colorScheme.surface,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _editing
            ? TaskFormPage(
                key: ValueKey<String>('panel-form-${widget.taskId}'),
                task: task,
                embedded: true,
                onCancel: () => setState(() => _editing = false),
                onEmbeddedSave: _save,
              )
            : TaskDetailPage(
                key: ValueKey<String>('panel-detail-${widget.taskId}'),
                taskId: widget.taskId,
                embedded: true,
                onEdit: () => setState(() => _editing = true),
                onClose: widget.onClose,
                onDeleted: widget.onClose,
              ),
      ),
    );
  }
}
