import 'attachment_service.dart';

/// En web los adjuntos todavía no están disponibles: se necesitará un backend
/// para almacenar los archivos.
Future<AttachmentServices> createAttachmentServices() async {
  return const AttachmentServices(
    storage: UnsupportedAttachmentStorage(),
    opener: UnsupportedFileOpener(),
  );
}
