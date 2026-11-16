// Selecciona la implementación de adjuntos según la plataforma.
export 'attachment_service_unsupported.dart'
    if (dart.library.io) 'attachment_service_io.dart';
