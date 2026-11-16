import 'package:material_ui/material_ui.dart';

import '../../domain/task_filter.dart';
import '../../domain/task_view.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({
    super.key,
    required this.view,
    required this.filter,
    required this.onCreate,
  });

  final TaskView view;
  final TaskFilter filter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = _content();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                content.icon,
                size: 34,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (content.showCreate) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Nueva tarea'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({IconData icon, String title, String message, bool showCreate}) _content() {
    return switch (view) {
      TodayTasksView() => (
        icon: Icons.wb_sunny_outlined,
        title: 'Nada para hoy',
        message: 'No hay tareas pendientes que venzan hoy.',
        showCreate: false,
      ),
      ImportantTasksView() => (
        icon: Icons.star_outline_rounded,
        title: 'Sin tareas importantes',
        message: 'Marca una tarea con la estrella para verla aquí.',
        showCreate: false,
      ),
      TagTasksView() => (
        icon: Icons.label_outline_rounded,
        title: 'Sin tareas con esta etiqueta',
        message: 'Asigna esta etiqueta a una tarea para verla aquí.',
        showCreate: false,
      ),
      ListTasksView() => (
        icon: Icons.list_alt_rounded,
        title: 'Esta lista está vacía',
        message: 'Crea una tarea para empezar a organizarla.',
        showCreate: true,
      ),
      AllTasksView() => _allTasksContent(),
    };
  }

  ({IconData icon, String title, String message, bool showCreate})
  _allTasksContent() {
    return switch (filter) {
      TaskFilter.all => (
        icon: Icons.checklist_rounded,
        title: 'Aún no hay tareas',
        message: 'Crea tu primera tarea y organízala con listas, etiquetas y fechas.',
        showCreate: true,
      ),
      TaskFilter.pending => (
        icon: Icons.pending_actions_rounded,
        title: 'No hay tareas pendientes',
        message: 'Todo al día. Crea una nueva tarea cuando la necesites.',
        showCreate: true,
      ),
      TaskFilter.completed => (
        icon: Icons.task_alt_rounded,
        title: 'No hay tareas completadas',
        message: 'Cuando completes una tarea aparecerá aquí.',
        showCreate: false,
      ),
      TaskFilter.overdue => (
        icon: Icons.event_busy_rounded,
        title: 'No hay tareas vencidas',
        message: 'Ninguna tarea pendiente pasó su fecha de entrega.',
        showCreate: false,
      ),
    };
  }
}
