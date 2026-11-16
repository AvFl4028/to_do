import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:to_do/core/theme/app_theme.dart';
import 'package:to_do/features/tasks/application/task_scope.dart';
import 'package:to_do/features/tasks/application/task_store.dart';
import 'package:to_do/features/tasks/domain/attachment.dart';
import 'package:to_do/features/tasks/domain/task.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/domain/task_tag.dart';
import 'package:to_do/features/tasks/domain/workspace.dart';

import 'fake_attachment_service.dart';

Future<void> initializeSpanishLocale() => initializeDateFormatting('es');

Widget buildTestApp({
  required TaskStore store,
  required Widget home,
  FakeAttachmentStorage? storage,
  FakeFileOpener? opener,
}) {
  return TaskScope(
    store: store,
    attachmentStorage: storage ?? FakeAttachmentStorage(),
    fileOpener: opener ?? FakeFileOpener(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: const <Locale>[Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}

Task buildTask({
  String id = 'task-1',
  String title = 'Tarea de prueba',
  String description = '',
  bool isCompleted = false,
  DateTime? dueDate,
  DateTime? createdAt,
  String listId = TaskList.inboxId,
  bool isImportant = false,
  List<String> tagIds = const <String>[],
  List<Attachment> attachments = const <Attachment>[],
}) {
  final created = createdAt ?? DateTime.utc(2026, 11, 16, 10);
  return Task(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    dueDate: dueDate,
    listId: listId,
    isImportant: isImportant,
    tagIds: tagIds,
    attachments: attachments,
    createdAt: created,
    updatedAt: created,
  );
}

TaskList buildList({
  String id = 'list-1',
  String name = 'Trabajo',
  String emoji = '💼',
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 11, 1);
  return TaskList(
    id: id,
    name: name,
    emoji: emoji,
    createdAt: created,
    updatedAt: created,
  );
}

TaskTag buildTag({
  String id = 'tag-1',
  String name = 'Casa',
  int colorIndex = 0,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 11, 1);
  return TaskTag(
    id: id,
    name: name,
    colorIndex: colorIndex,
    createdAt: created,
    updatedAt: created,
  );
}

Attachment buildAttachment({
  String id = 'attachment-1',
  String fileName = 'foto.png',
  String storedName = 'attachment-1.png',
  String extension = 'png',
  int sizeBytes = 2048,
  DateTime? createdAt,
}) {
  return Attachment(
    id: id,
    fileName: fileName,
    storedName: storedName,
    extension: extension,
    kind: Attachment.kindForExtension(extension),
    sizeBytes: sizeBytes,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 16),
  );
}

Workspace buildWorkspace({
  List<Task> tasks = const <Task>[],
  List<TaskList> lists = const <TaskList>[],
  List<TaskTag> tags = const <TaskTag>[],
}) {
  return Workspace(tasks: tasks, lists: lists, tags: tags);
}
