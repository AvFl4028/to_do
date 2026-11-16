import 'package:material_ui/material_ui.dart';

import '../application/task_scope.dart';
import 'task_form_page.dart';
import 'task_list_page.dart';
import 'widgets/app_sidebar.dart';

/// Punto de entrada de la aplicación de tareas.
///
/// En escritorio (ancho ≥ 1000 px) la sidebar es persistente; por debajo de ese
/// ancho se oculta en un [Drawer].
class TasksHomePage extends StatefulWidget {
  const TasksHomePage({super.key});

  @override
  State<TasksHomePage> createState() => _TasksHomePageState();
}

class _TasksHomePageState extends State<TasksHomePage> {
  static const double _desktopBreakpoint = 1000;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  }

  Future<void> _createTask() async {
    final store = TaskScope.of(context);
    final result = await Navigator.of(context).push<TaskFormResult>(
      MaterialPageRoute<TaskFormResult>(
        builder: (context) => TaskFormPage(initialListId: store.defaultListId),
      ),
    );
    if (result == null) {
      return;
    }
    await store.create(
      title: result.title,
      description: result.description,
      dueDate: result.dueDate,
      listId: result.listId,
      isImportant: result.isImportant,
      tagIds: result.tagIds,
      attachments: result.attachments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _desktopBreakpoint;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop
          ? null
          : Drawer(
              width: width >= 360 ? 320 : width * 0.9,
              child: SafeArea(
                child: AppSidebar(isDrawer: true, onNavigate: _closeDrawer),
              ),
            ),
      appBar: AppBar(
        leading: isDesktop
            ? null
            : IconButton(
                tooltip: 'Abrir menú',
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        titleSpacing: isDesktop ? 20 : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (store.activeEmoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  store.activeEmoji!,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            Flexible(
              child: Text(
                store.activeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!store.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  '${store.pendingCount} pendientes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop) ...[
              const SizedBox(width: 300, child: AppSidebar()),
              const VerticalDivider(width: 1, thickness: 1),
            ],
            Expanded(child: TaskListContent(onCreate: _createTask)),
          ],
        ),
      ),
      floatingActionButton: width >= 700
          ? FloatingActionButton.extended(
              onPressed: _createTask,
              tooltip: 'Nueva tarea',
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            )
          : FloatingActionButton(
              onPressed: _createTask,
              tooltip: 'Nueva tarea',
              child: const Icon(Icons.add),
            ),
    );
  }
}
