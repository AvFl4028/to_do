import 'package:flutter/widgets.dart';

import '../data/attachment_service.dart';
import 'task_store.dart';

/// Expone el [TaskStore] y los servicios de adjuntos al árbol de widgets.
///
/// Al ser un [InheritedNotifier], los widgets que dependen de él se reconstruyen
/// cuando cambia el estado de las tareas.
class TaskScope extends InheritedNotifier<TaskStore> {
  const TaskScope({
    super.key,
    required TaskStore store,
    this.attachmentStorage = const UnsupportedAttachmentStorage(),
    this.fileOpener = const UnsupportedFileOpener(),
    required super.child,
  }) : super(notifier: store);

  final AttachmentStorage attachmentStorage;
  final FileOpener fileOpener;

  static TaskScope _scopeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TaskScope>();
    assert(scope != null, 'TaskScope no se encontró en el árbol de widgets.');
    return scope!;
  }

  static TaskStore of(BuildContext context) => _scopeOf(context).notifier!;

  static AttachmentStorage attachmentsOf(BuildContext context) =>
      _scopeOf(context).attachmentStorage;

  static FileOpener openerOf(BuildContext context) =>
      _scopeOf(context).fileOpener;
}
