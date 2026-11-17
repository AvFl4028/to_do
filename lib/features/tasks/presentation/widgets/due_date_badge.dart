import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_formatters.dart';
import '../../domain/task.dart';

class DueDateBadge extends StatelessWidget {
  const DueDateBadge({
    super.key,
    required this.task,
    this.timePassed = false,
    this.now,
  });

  final Task task;

  /// Muestra un aviso discreto cuando la hora de hoy ya pasó.
  final bool timePassed;

  /// Reloj de referencia; por defecto, la hora local del dispositivo.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;
    if (dueDate == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = _colors(scheme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_outlined, size: 14, color: foreground),
              const SizedBox(width: 4),
              Text(
                AppDates.dueLabel(
                  dueDate,
                  isCompleted: task.isCompleted,
                  dueTimeMinutes: task.dueTimeMinutes,
                  now: now,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (timePassed) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'La hora de entrega ya pasó',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 13,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hora pasada',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  (Color, Color) _colors(ColorScheme scheme) {
    final dueDate = task.dueDate!;
    if (task.isCompleted) {
      return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
    if (AppDates.isOverdue(dueDate, now: now)) {
      return (scheme.errorContainer, scheme.onErrorContainer);
    }
    if (AppDates.isToday(dueDate, now: now)) {
      return (scheme.tertiaryContainer, scheme.onTertiaryContainer);
    }
    return (scheme.secondaryContainer, scheme.onSecondaryContainer);
  }
}
