// Imagen local del adjunto.
//
// Se resuelve con importación condicional porque `dart:io` no existe en web.
export 'attachment_image_unsupported.dart'
    if (dart.library.io) 'attachment_image_io.dart';
