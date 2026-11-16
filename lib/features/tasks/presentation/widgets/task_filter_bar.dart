import 'package:material_ui/material_ui.dart';

import '../../domain/task_filter.dart';

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final TaskFilter selected;
  final Map<TaskFilter, int> counts;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TaskFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(filter, counts[filter] ?? 0)),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }

  String _label(TaskFilter filter, int count) {
    final label = switch (filter) {
      TaskFilter.all => 'Todas',
      TaskFilter.pending => 'Pendientes',
      TaskFilter.completed => 'Completadas',
      TaskFilter.overdue => 'Vencidas',
    };
    return count > 0 ? '$label ($count)' : label;
  }
}
