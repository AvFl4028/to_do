import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_scope.dart';
import '../../../core/theme/app_motion.dart';
import '../../settings/presentation/settings_page.dart';
import '../application/task_scope.dart';
import '../domain/task.dart';
import 'task_form_page.dart';
import 'task_list_page.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/resize_handle.dart';
import 'widgets/task_detail_panel.dart';

/// Punto de entrada de la aplicación de tareas.
///
/// En escritorio (ancho ≥ 1000 px) la sidebar es persistente y el detalle se
/// abre en un panel derecho. Por debajo de ese ancho ambos se ocultan o se
/// muestran como página completa.
class TasksHomePage extends StatefulWidget {
  const TasksHomePage({super.key});

  @override
  State<TasksHomePage> createState() => _TasksHomePageState();
}

class _TasksHomePageState extends State<TasksHomePage> {
  static const double _desktopBreakpoint = 1000;
  static const double _contentMinWidth = 320;
  static const double _handleWidth = 8;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _selectedTaskId;
  String? _panelTaskId;
  double _sidebarWidth = AppSettings.defaultSidebarWidth;
  double _panelWidth = AppSettings.defaultPanelWidth;
  bool _layoutInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_layoutInitialized) {
      return;
    }
    final settings = SettingsScope.maybeOf(context)?.settings;
    if (settings != null) {
      _sidebarWidth = settings.sidebarWidth;
      _panelWidth = settings.panelWidth;
    }
    _layoutInitialized = true;
  }

  void _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  }

  void _handleNavigate() {
    _closeDrawer();
    _closePanel();
  }

  void _closePanel() {
    if (_selectedTaskId == null) {
      return;
    }
    setState(() => _selectedTaskId = null);
  }

  void _selectTask(Task task) {
    setState(() {
      _selectedTaskId = task.id;
      _panelTaskId = task.id;
    });
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
      dueTimeMinutes: result.dueTimeMinutes,
      listId: result.listId,
      isImportant: result.isImportant,
      tagIds: result.tagIds,
      attachments: result.attachments,
    );
  }

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const SettingsPage()),
    );
  }

  _HomeLayout _layout(double width, {required bool hasPanel}) {
    final gap = hasPanel ? _handleWidth * 2 : _handleWidth;
    final sidebarMax = hasPanel
        ? math.min(
            AppSettings.maxSidebarWidth,
            math.max(
              AppSettings.minSidebarWidth,
              width - _panelWidth - _contentMinWidth - gap,
            ),
          )
        : math.min(
            AppSettings.maxSidebarWidth,
            math.max(
              AppSettings.minSidebarWidth,
              width - _contentMinWidth - _handleWidth,
            ),
          );
    final sidebarWidth = _sidebarWidth.clamp(
      AppSettings.minSidebarWidth,
      sidebarMax,
    );
    final panelMax = math.min(
      AppSettings.maxPanelWidth,
      math.max(
        AppSettings.minPanelWidth,
        width - sidebarWidth - _contentMinWidth - gap,
      ),
    );
    final panelWidth = _panelWidth.clamp(AppSettings.minPanelWidth, panelMax);

    return _HomeLayout(
      sidebarWidth: sidebarWidth,
      panelWidth: panelWidth,
      sidebarMax: sidebarMax,
      panelMax: panelMax,
    );
  }

  void _dragSidebar(double delta) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = _layout(width, hasPanel: _selectedTaskId != null);
    setState(() {
      _sidebarWidth = (layout.sidebarWidth + delta).clamp(
        AppSettings.minSidebarWidth,
        layout.sidebarMax,
      );
    });
  }

  void _dragPanel(double delta) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = _layout(width, hasPanel: _selectedTaskId != null);
    setState(() {
      _panelWidth = (layout.panelWidth - delta).clamp(
        AppSettings.minPanelWidth,
        layout.panelMax,
      );
    });
  }

  void _persistSidebarWidth() {
    SettingsScope.maybeOf(context)?.setSidebarWidth(_sidebarWidth);
  }

  void _persistPanelWidth() {
    SettingsScope.maybeOf(context)?.setPanelWidth(_panelWidth);
  }

  void _resetSidebarWidth() {
    setState(() => _sidebarWidth = AppSettings.defaultSidebarWidth);
    _persistSidebarWidth();
  }

  void _resetPanelWidth() {
    setState(() {
      _panelWidth = AppSettings.defaultPanelWidth;
    });
    _persistPanelWidth();
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _desktopBreakpoint;
    final selectedTask = _selectedTaskId == null
        ? null
        : store.taskById(_selectedTaskId!);
    final showPanel = isDesktop && selectedTask != null;
    final layout = _layout(width, hasPanel: showPanel);
    final theme = Theme.of(context);
    final motion = appMotionDuration(context);

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
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  '${store.pendingCount} pendientes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop) ...[
              SizedBox(
                key: const ValueKey<String>('app-sidebar-container'),
                width: layout.sidebarWidth,
                child: AppSidebar(onNavigate: _handleNavigate),
              ),
              ResizeHandle(
                key: const ValueKey<String>('sidebar-resize-handle'),
                onDrag: _dragSidebar,
                onDragEnd: _persistSidebarWidth,
                onReset: _resetSidebarWidth,
              ),
            ],
            Expanded(
              child: TaskListContent(
                onCreate: _createTask,
                onOpenTask: isDesktop ? _selectTask : null,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: showPanel ? 1 : 0),
              duration: motion,
              curve: Curves.easeOutCubic,
              builder: (context, factor, child) {
                if (!showPanel && factor == 0) {
                  return const SizedBox.shrink(
                    key: ValueKey<String>('panel-closed'),
                  );
                }
                return ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: factor,
                    child: Opacity(opacity: factor, child: child),
                  ),
                );
              },
              child: Row(
                key: const ValueKey<String>('panel-open'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResizeHandle(
                    key: const ValueKey<String>('panel-resize-handle'),
                    onDrag: _dragPanel,
                    onDragEnd: _persistPanelWidth,
                    onReset: _resetPanelWidth,
                  ),
                  SizedBox(
                    key: const ValueKey<String>('task-panel-container'),
                    width: layout.panelWidth,
                    child: TaskDetailPanel(
                      key: ValueKey<String>(
                        'task-panel-${_panelTaskId ?? _selectedTaskId}',
                      ),
                      taskId: _panelTaskId ?? _selectedTaskId ?? '',
                      onClose: _closePanel,
                    ),
                  ),
                ],
              ),
            ),
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

class _HomeLayout {
  const _HomeLayout({
    required this.sidebarWidth,
    required this.panelWidth,
    required this.sidebarMax,
    required this.panelMax,
  });

  final double sidebarWidth;
  final double panelWidth;
  final double sidebarMax;
  final double panelMax;
}
