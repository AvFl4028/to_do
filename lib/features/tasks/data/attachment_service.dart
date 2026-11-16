import '../domain/attachment.dart';

/// Almacenamiento de los archivos adjuntos.
///
/// La interfaz permite sustituir en el futuro el almacenamiento local por uno
/// respaldado en un servidor de sincronización sin cambiar la interfaz de
/// usuario. Solo se manejan nombres relativos (`storedName`), nunca rutas.
abstract interface class AttachmentStorage {
  /// `false` en plataformas sin sistema de archivos (web).
  bool get isAvailable;

  /// Prepara el directorio de adjuntos. Debe llamarse antes de [pathFor].
  Future<void> ensureReady();

  /// Ruta absoluta del archivo, o `null` si no está listo o el nombre no es
  /// seguro (por ejemplo, si intenta salir del directorio de adjuntos).
  String? pathFor(String storedName);

  Future<bool> exists(String storedName);

  /// Abre el selector de archivos y copia las selecciones al almacenamiento
  /// local. Devuelve los metadatos de los archivos copiados.
  Future<List<Attachment>> pickAndStore();

  Future<void> deleteStored(Iterable<String> storedNames);

  /// Elimina los archivos que ya no referencia ninguna tarea.
  Future<void> cleanOrphans(Set<String> keepStoredNames);
}

/// Abre un archivo con la aplicación predeterminada del sistema.
abstract interface class FileOpener {
  /// Devuelve `true` si el sistema pudo abrir el archivo.
  Future<bool> open(String path);
}

/// Servicios de adjuntos inyectados en la aplicación.
class AttachmentServices {
  const AttachmentServices({required this.storage, required this.opener});

  final AttachmentStorage storage;
  final FileOpener opener;
}

/// Implementación usada en web, donde los adjuntos aún no están disponibles.
class UnsupportedAttachmentStorage implements AttachmentStorage {
  const UnsupportedAttachmentStorage();

  @override
  bool get isAvailable => false;

  @override
  Future<void> ensureReady() async {}

  @override
  String? pathFor(String storedName) => null;

  @override
  Future<bool> exists(String storedName) async => false;

  @override
  Future<List<Attachment>> pickAndStore() async => const <Attachment>[];

  @override
  Future<void> deleteStored(Iterable<String> storedNames) async {}

  @override
  Future<void> cleanOrphans(Set<String> keepStoredNames) async {}
}

class UnsupportedFileOpener implements FileOpener {
  const UnsupportedFileOpener();

  @override
  Future<bool> open(String path) async => false;
}
