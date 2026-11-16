import 'package:material_ui/material_ui.dart';

/// Indicador compacto de la lista a la que pertenece una tarea.
class ListIndicator extends StatelessWidget {
  const ListIndicator({
    super.key,
    required this.emoji,
    required this.name,
    this.compact = false,
  });

  final String emoji;
  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        (compact ? theme.textTheme.labelSmall : theme.textTheme.labelSmall)
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: compact ? 11 : 12)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
