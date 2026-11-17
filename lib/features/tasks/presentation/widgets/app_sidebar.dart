import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tag_palette.dart';
import '../../application/task_scope.dart';
import '../../domain/task_list.dart';
import '../../domain/task_tag.dart';
import '../../domain/task_view.dart';
import 'list_form_dialog.dart';
import 'tag_dialogs.dart';

enum _ListMenuAction { edit, delete }

enum _TagMenuAction { edit, delete }

/// Barra lateral con las vistas rápidas, las listas y las etiquetas.
///
/// En escritorio se muestra fija; en móvil vive dentro de un [Drawer].
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.isDrawer = false, this.onNavigate});

  /// `true` cuando se muestra dentro del drawer de móvil.
  final bool isDrawer;

  /// Se llama al navegar para que el drawer pueda cerrarse.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final view = store.view;

    return Material(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
        children: [
          _BrandHeader(isDrawer: isDrawer, onClose: onNavigate),
          const SizedBox(height: 4),
          _NavHeader(
            key: const ValueKey<String>('sidebar-nav-today'),
            label: 'Vence hoy',
            icon: Icons.wb_sunny_outlined,
            count: store.todayCount,
            selected: view is TodayTasksView,
            onTap: () => _go(context, const TodayTasksView()),
          ),
          _NavHeader(
            key: const ValueKey<String>('sidebar-nav-important'),
            label: 'Importantes',
            icon: Icons.star_outline_rounded,
            count: store.importantCount,
            selected: view is ImportantTasksView,
            onTap: () => _go(context, const ImportantTasksView()),
          ),
          _NavHeader(
            key: const ValueKey<String>('sidebar-nav-all'),
            label: 'Todas las tareas',
            icon: Icons.checklist_rounded,
            count: store.pendingCount,
            selected: view is AllTasksView,
            onTap: () => _go(context, const AllTasksView()),
          ),
          const Divider(height: 20),
          _GroupHeader(
            label: 'Listas',
            tooltip: 'Nueva lista',
            onAdd: () => _createList(context),
          ),
          for (final list in store.lists)
            _ListRow(
              key: ValueKey<String>('sidebar-list-${list.id}'),
              list: list,
              pendingCount: store.pendingCountForList(list.id),
              selected: view == ListTasksView(list.id),
              onTap: () => _go(context, ListTasksView(list.id)),
              onEdit: () => _editList(context, list),
              onDelete: list.isInbox ? null : () => _deleteList(context, list),
            ),
          const SizedBox(height: 12),
          _GroupHeader(
            label: 'Etiquetas',
            tooltip: 'Nueva etiqueta',
            onAdd: () => _createTag(context),
          ),
          if (store.tags.isEmpty)
            const _EmptyHint('Sin etiquetas')
          else
            for (final tag in store.tags)
              _TagRow(
                key: ValueKey<String>('sidebar-tag-${tag.id}'),
                tag: tag,
                pendingCount: store.pendingCountForTag(tag.id),
                selected: view == TagTasksView(tag.id),
                onTap: () => _go(context, TagTasksView(tag.id)),
                onEdit: () => _editTag(context, tag),
                onDelete: () => _deleteTag(context, tag),
              ),
        ],
      ),
    );
  }

  void _go(BuildContext context, TaskView view) {
    TaskScope.of(context).setView(view);
    onNavigate?.call();
  }

  Future<void> _createList(BuildContext context) async {
    final store = TaskScope.of(context);
    final draft = await showListFormDialog(context);
    if (draft == null) {
      return;
    }
    final list = await store.createList(name: draft.name, emoji: draft.emoji);
    if (!context.mounted) {
      return;
    }
    _go(context, ListTasksView(list.id));
  }

  Future<void> _editList(BuildContext context, TaskList list) async {
    final store = TaskScope.of(context);
    final draft = await showListFormDialog(context, list: list);
    if (draft == null) {
      return;
    }
    await store.updateList(list.id, name: draft.name, emoji: draft.emoji);
  }

  Future<void> _deleteList(BuildContext context, TaskList list) async {
    final store = TaskScope.of(context);
    final taskCount = store.tasksInList(list.id).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text(
          taskCount == 0
              ? '¿Seguro que quieres eliminar «${list.name}»?'
              : 'Se eliminará «${list.name}». '
                    '${taskCount == 1 ? 'Su tarea se moverá' : 'Sus $taskCount tareas se moverán'} '
                    'a la Bandeja de entrada.',
        ),
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

    if (confirmed == true) {
      await store.deleteList(list.id);
    }
  }

  Future<void> _createTag(BuildContext context) async {
    final store = TaskScope.of(context);
    final name = await showTagNameDialog(context);
    if (name == null) {
      return;
    }
    await store.createTag(name);
  }

  Future<void> _editTag(BuildContext context, TaskTag tag) async {
    final store = TaskScope.of(context);
    final name = await showTagNameDialog(
      context,
      initialName: tag.name,
      title: 'Editar etiqueta',
    );
    if (name == null) {
      return;
    }
    await store.updateTag(tag.id, name: name);
  }

  Future<void> _deleteTag(BuildContext context, TaskTag tag) async {
    final store = TaskScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar etiqueta'),
        content: Text(
          'Se eliminará «#${tag.name}» y se quitará de todas las tareas.',
        ),
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

    if (confirmed == true) {
      await store.deleteTag(tag.id);
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isDrawer, this.onClose});

  final bool isDrawer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 0, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.checklist_rounded,
              size: 22,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mis tareas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isDrawer)
            IconButton(
              tooltip: 'Cerrar menú',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _NavHeader extends StatelessWidget {
  const _NavHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? foreground : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                _CountBadge(count: count, selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? scheme.secondary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: selected ? scheme.onSecondary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.tooltip,
    required this.onAdd,
  });

  final String label;
  final String tooltip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 0, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          IconButton(
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    super.key,
    required this.list,
    required this.pendingCount,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskList list;
  final int pendingCount;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// `null` para la bandeja de entrada, que no se puede eliminar.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Center(
                    child: Text(
                      list.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _CountBadge(count: pendingCount, selected: selected),
                ),
                PopupMenuButton<_ListMenuAction>(
                  tooltip: 'Opciones de ${list.name}',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (action) => switch (action) {
                    _ListMenuAction.edit => onEdit(),
                    _ListMenuAction.delete => onDelete?.call(),
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _ListMenuAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: _ListMenuAction.delete,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
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
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    super.key,
    required this.tag,
    required this.pendingCount,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskTag tag;
  final int pendingCount;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final dotColor = TagPalette.foreground(tag.colorIndex, scheme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
            child: Row(
              children: [
                Icon(Icons.label_rounded, size: 16, color: dotColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _CountBadge(count: pendingCount, selected: selected),
                ),
                PopupMenuButton<_TagMenuAction>(
                  tooltip: 'Opciones de ${tag.name}',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (action) => switch (action) {
                    _TagMenuAction.edit => onEdit(),
                    _TagMenuAction.delete => onDelete(),
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _TagMenuAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Renombrar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _TagMenuAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20),
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
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 2, 8, 6),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
