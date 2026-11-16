import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/attachment.dart';
import 'attachment_service.dart';

/// Guarda los adjuntos en `<directorio de datos>/attachments`.
///
/// Los archivos se copian al almacenamiento de la aplicación para que sigan
/// disponibles aunque el original se mueva o se borre. En el workspace solo se
/// guarda el nombre relativo.
class LocalAttachmentStorage implements AttachmentStorage {
  LocalAttachmentStorage({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  Directory? _root;

  @override
  bool get isAvailable => true;

  @override
  Future<void> ensureReady() async {
    if (_root != null) {
      return;
    }
    final base = await getApplicationSupportDirectory();
    final root = Directory(p.join(base.path, 'attachments'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    _root = root;
  }

  @override
  String? pathFor(String storedName) {
    final root = _root;
    if (root == null) {
      return null;
    }
    if (!_isSafeName(storedName)) {
      return null;
    }
    return p.join(root.path, storedName);
  }

  @override
  Future<bool> exists(String storedName) async {
    final path = pathFor(storedName);
    if (path == null) {
      return false;
    }
    return File(path).exists();
  }

  @override
  Future<List<Attachment>> pickAndStore() async {
    final files = await openFiles();
    if (files.isEmpty) {
      return const <Attachment>[];
    }

    await ensureReady();
    final root = _root!;
    final created = <Attachment>[];
    final now = DateTime.now().toUtc();

    for (final file in files) {
      final extension = _extensionOf(file.name);
      final id = _uuid.v4();
      final storedName = extension.isEmpty ? id : '$id.$extension';
      final bytes = await file.readAsBytes();
      await File(p.join(root.path, storedName))
          .writeAsBytes(bytes, flush: true);

      created.add(
        Attachment(
          id: id,
          fileName: file.name,
          storedName: storedName,
          extension: extension,
          kind: Attachment.kindForExtension(extension),
          sizeBytes: bytes.length,
          createdAt: now,
        ),
      );
    }

    return created;
  }

  @override
  Future<void> deleteStored(Iterable<String> storedNames) async {
    for (final storedName in storedNames) {
      final path = pathFor(storedName);
      if (path == null) {
        continue;
      }
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  Future<void> cleanOrphans(Set<String> keepStoredNames) async {
    final root = _root;
    if (root == null) {
      return;
    }

    await for (final entity in root.list()) {
      if (entity is! File) {
        continue;
      }
      if (!keepStoredNames.contains(p.basename(entity.path))) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Un archivo bloqueado se reintentará en el siguiente arranque.
        }
      }
    }
  }

  static bool _isSafeName(String storedName) {
    if (storedName.isEmpty || storedName == '.' || storedName == '..') {
      return false;
    }
    return storedName == p.basename(storedName);
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dot + 1).toLowerCase();
  }
}

class SystemFileOpener implements FileOpener {
  const SystemFileOpener();

  @override
  Future<bool> open(String path) async {
    try {
      final result = await OpenFilex.open(path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }
}

Future<AttachmentServices> createAttachmentServices() async {
  return AttachmentServices(
    storage: LocalAttachmentStorage(),
    opener: const SystemFileOpener(),
  );
}
