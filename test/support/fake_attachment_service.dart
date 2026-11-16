import 'package:to_do/features/tasks/data/attachment_service.dart';
import 'package:to_do/features/tasks/domain/attachment.dart';

/// Almacenamiento de adjuntos simulado: no toca el disco.
class FakeAttachmentStorage implements AttachmentStorage {
  FakeAttachmentStorage({
    this.isAvailable = true,
    this.root = '/adjuntos',
    List<Attachment>? attachmentsToPick,
  }) {
    if (attachmentsToPick != null) {
      pickQueue.add(attachmentsToPick);
    }
  }

  @override
  bool isAvailable;

  /// Ruta base simulada. Si es `null`, [pathFor] devuelve `null`.
  String? root;

  /// Lotes que devolverá [pickAndStore] en llamadas sucesivas.
  final List<List<Attachment>> pickQueue = <List<Attachment>>[];

  final Set<String> existing = <String>{};
  final List<String> deleted = <String>[];
  final List<Set<String>> cleanedOrphans = <Set<String>>[];
  int pickCalls = 0;

  @override
  Future<void> ensureReady() async {}

  @override
  String? pathFor(String storedName) =>
      root == null ? null : '$root/$storedName';

  @override
  Future<bool> exists(String storedName) async => existing.contains(storedName);

  @override
  Future<List<Attachment>> pickAndStore() async {
    pickCalls++;
    if (pickQueue.isEmpty) {
      return const <Attachment>[];
    }
    return pickQueue.removeAt(0);
  }

  @override
  Future<void> deleteStored(Iterable<String> storedNames) async {
    deleted.addAll(storedNames);
  }

  @override
  Future<void> cleanOrphans(Set<String> keepStoredNames) async {
    cleanedOrphans.add(keepStoredNames);
  }
}

class FakeFileOpener implements FileOpener {
  FakeFileOpener({this.result = true});

  bool result;
  final List<String> opened = <String>[];

  @override
  Future<bool> open(String path) async {
    opened.add(path);
    return result;
  }
}
