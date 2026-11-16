import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/features/tasks/domain/attachment.dart';
import 'package:to_do/features/tasks/domain/task.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';

void main() {
  group('Task', () {
    test('serializa y restaura todos los campos', () {
      final attachment = Attachment(
        id: 'attachment-1',
        fileName: 'informe.pdf',
        storedName: 'attachment-1.pdf',
        extension: 'pdf',
        kind: AttachmentKind.pdf,
        sizeBytes: 1024,
        createdAt: DateTime.utc(2026, 11, 15),
      );
      final task = Task(
        id: 'task-1',
        title: 'Preparar informe',
        description: '# Informe\n\n- Punto uno',
        dueDate: DateTime(2026, 11, 20),
        listId: 'list-1',
        isImportant: true,
        tagIds: const ['tag-1', 'tag-2'],
        attachments: [attachment],
        createdAt: DateTime.utc(2026, 11, 16, 10, 30),
        updatedAt: DateTime.utc(2026, 11, 17, 8),
      );

      final restored = Task.fromJson(task.toJson());

      expect(restored, task);
      expect(restored.dueDate, DateTime(2026, 11, 20));
      expect(restored.listId, 'list-1');
      expect(restored.isImportant, isTrue);
      expect(restored.tagIds, <String>['tag-1', 'tag-2']);
      expect(restored.attachments.single.fileName, 'informe.pdf');
    });

    test('usa valores por defecto con datos de la versión anterior', () {
      final restored = Task.fromJson(<String, dynamic>{
        'id': 'task-1',
        'title': 'Tarea antigua',
        'createdAt': '2026-11-16T10:00:00.000Z',
        'updatedAt': '2026-11-16T10:00:00.000Z',
      });

      expect(restored.listId, TaskList.inboxId);
      expect(restored.isImportant, isFalse);
      expect(restored.tagIds, isEmpty);
      expect(restored.attachments, isEmpty);
      expect(restored.description, '');
    });

    test('guarda la fecha de entrega sin hora ni zona horaria', () {
      final task = Task(
        id: 'task-1',
        title: 'Tarea',
        description: '',
        dueDate: DateTime(2026, 3, 4, 18, 45),
        createdAt: DateTime.utc(2026, 3, 1),
        updatedAt: DateTime.utc(2026, 3, 1),
      );

      expect(task.toJson()['dueDate'], '2026-03-04');
    });

    test('rechaza datos inválidos al deserializar', () {
      expect(
        () => Task.fromJson(<String, dynamic>{'title': 'Sin id'}),
        throwsFormatException,
      );
      expect(
        () => Task.fromJson(<String, dynamic>{
          'id': 'task-1',
          'title': 'Sin fechas',
        }),
        throwsFormatException,
      );
    });

    test('copyWith puede limpiar la fecha y cambiar la organización', () {
      final task = Task(
        id: 'task-1',
        title: 'Tarea',
        description: 'Descripción',
        dueDate: DateTime(2026, 11, 20),
        createdAt: DateTime.utc(2026, 11, 16),
        updatedAt: DateTime.utc(2026, 11, 16),
      );

      final updated = task.copyWith(
        clearDueDate: true,
        listId: 'list-2',
        isImportant: true,
        tagIds: const ['tag-3'],
      );

      expect(updated.dueDate, isNull);
      expect(updated.listId, 'list-2');
      expect(updated.isImportant, isTrue);
      expect(updated.tagIds, <String>['tag-3']);
      expect(updated.createdAt, task.createdAt);
      expect(updated.title, task.title);
    });
  });
}
