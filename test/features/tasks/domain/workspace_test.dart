import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/features/tasks/domain/attachment.dart';
import 'package:to_do/features/tasks/domain/task_list.dart';
import 'package:to_do/features/tasks/domain/task_tag.dart';
import 'package:to_do/features/tasks/domain/workspace.dart';

import '../../../support/test_harness.dart';

void main() {
  group('Attachment', () {
    test('clasifica las extensiones admitidas', () {
      expect(Attachment.kindForExtension('PNG'), AttachmentKind.image);
      expect(Attachment.kindForExtension('svg'), AttachmentKind.image);
      expect(Attachment.kindForExtension('pdf'), AttachmentKind.pdf);
      expect(Attachment.kindForExtension('docx'), AttachmentKind.word);
      expect(Attachment.kindForExtension('xlsx'), AttachmentKind.excel);
      expect(Attachment.kindForExtension('pptx'), AttachmentKind.powerpoint);
      expect(Attachment.kindForExtension('txt'), AttachmentKind.text);
      expect(Attachment.kindForExtension('zip'), AttachmentKind.other);
    });

    test('serializa y restaura sus metadatos', () {
      final attachment = buildAttachment();
      expect(Attachment.fromJson(attachment.toJson()), attachment);
    });
  });

  group('TaskList', () {
    test('serializa y restaura la lista', () {
      final list = buildList();
      expect(TaskList.fromJson(list.toJson()), list);
    });

    test('rechaza nombres vacíos', () {
      expect(
        () => TaskList.fromJson(<String, dynamic>{
          'id': 'list-1',
          'name': '   ',
          'createdAt': '2026-11-01T00:00:00.000Z',
          'updatedAt': '2026-11-01T00:00:00.000Z',
        }),
        throwsFormatException,
      );
    });

    test('la bandeja de entrada no es eliminable por su id', () {
      final now = DateTime.utc(2026, 11, 16);
      expect(TaskList.inbox(now).isInbox, isTrue);
      expect(buildList().isInbox, isFalse);
    });
  });

  group('TaskTag', () {
    test('normaliza el índice de color al rango de la paleta', () {
      final tag = TaskTag.fromJson(<String, dynamic>{
        'id': 'tag-1',
        'name': 'Casa',
        'colorIndex': 99,
        'createdAt': '2026-11-01T00:00:00.000Z',
        'updatedAt': '2026-11-01T00:00:00.000Z',
      });
      expect(tag.colorIndex, 99 % TaskTag.paletteSize);
    });
  });

  group('Workspace', () {
    test('serializa y restaura tareas, listas y etiquetas', () {
      final list = buildList();
      final tag = buildTag();
      final task = buildTask(listId: list.id, tagIds: [tag.id]);
      final workspace = buildWorkspace(
        tasks: [task],
        lists: [TaskList.inbox(DateTime.utc(2026, 11, 1)), list],
        tags: [tag],
      );

      final restored = Workspace.fromJson(workspace.toJson());

      expect(restored.tasks.single, task);
      expect(restored.lists, hasLength(2));
      expect(restored.tags.single, tag);
      expect(workspace.toJson()['schemaVersion'], Workspace.schemaVersion);
    });

    test('omite elementos inválidos sin perder el resto', () {
      final workspace = Workspace.fromJson(<String, dynamic>{
        'tasks': <Object>[
          buildTask().toJson(),
          <String, dynamic>{'title': 'sin id'},
        ],
        'lists': <Object>[
          buildList().toJson(),
          <String, dynamic>{'id': 'list-2'},
        ],
        'tags': 'formato incorrecto',
      });

      expect(workspace.tasks, hasLength(1));
      expect(workspace.lists, hasLength(1));
      expect(workspace.tags, isEmpty);
    });
  });
}
