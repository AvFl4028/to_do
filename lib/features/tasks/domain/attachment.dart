/// Tipo de archivo adjunto, usado para elegir el icono y cómo se abre.
enum AttachmentKind { image, pdf, word, excel, powerpoint, text, other }

/// Archivo adjunto a una tarea.
///
/// Solo se guarda el nombre relativo dentro del directorio de adjuntos de la
/// aplicación (`storedName`), nunca una ruta absoluta: así el workspace se puede
/// mover entre equipos y, en el futuro, sincronizar con un backend.
class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.storedName,
    required this.extension,
    required this.kind,
    required this.sizeBytes,
    required this.createdAt,
  });

  /// Identificador estable del adjunto.
  final String id;

  /// Nombre original del archivo, para mostrarlo al usuario.
  final String fileName;

  /// Nombre del archivo dentro del directorio local de adjuntos.
  final String storedName;

  /// Extensión en minúsculas y sin punto (`png`, `pdf`, ...).
  final String extension;

  final AttachmentKind kind;

  final int sizeBytes;

  final DateTime createdAt;

  bool get isImage => kind == AttachmentKind.image;

  bool get isSvg => extension == 'svg';

  static const Set<String> imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  };

  static const Set<String> _pdfExtensions = <String>{'pdf'};

  static const Set<String> _wordExtensions = <String>{
    'doc',
    'docx',
    'odt',
    'rtf',
  };

  static const Set<String> _excelExtensions = <String>{
    'xls',
    'xlsx',
    'csv',
    'ods',
  };

  static const Set<String> _powerpointExtensions = <String>{
    'ppt',
    'pptx',
    'odp',
  };

  static const Set<String> _textExtensions = <String>{'txt', 'md', 'log'};

  /// Clasifica una extensión (sin punto y en minúsculas).
  static AttachmentKind kindForExtension(String extension) {
    final normalized = extension.toLowerCase();
    if (imageExtensions.contains(normalized)) {
      return AttachmentKind.image;
    }
    if (_pdfExtensions.contains(normalized)) {
      return AttachmentKind.pdf;
    }
    if (_wordExtensions.contains(normalized)) {
      return AttachmentKind.word;
    }
    if (_excelExtensions.contains(normalized)) {
      return AttachmentKind.excel;
    }
    if (_powerpointExtensions.contains(normalized)) {
      return AttachmentKind.powerpoint;
    }
    if (_textExtensions.contains(normalized)) {
      return AttachmentKind.text;
    }
    return AttachmentKind.other;
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fileName = json['fileName'];
    final storedName = json['storedName'];
    final createdAt = json['createdAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('El adjunto no tiene un identificador.');
    }
    if (fileName is! String || fileName.isEmpty) {
      throw const FormatException('El adjunto no tiene un nombre de archivo.');
    }
    if (storedName is! String || storedName.isEmpty) {
      throw const FormatException('El adjunto no tiene un nombre almacenado.');
    }
    if (createdAt is! String) {
      throw const FormatException('El adjunto no tiene una fecha válida.');
    }

    final extension = json['extension'] is String
        ? (json['extension'] as String).toLowerCase()
        : _extensionOf(fileName);

    return Attachment(
      id: id,
      fileName: fileName,
      storedName: storedName,
      extension: extension,
      kind: AttachmentKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => kindForExtension(extension),
      ),
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : 0,
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fileName': fileName,
    'storedName': storedName,
    'extension': extension,
    'kind': kind.name,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  Attachment copyWith({String? fileName}) {
    return Attachment(
      id: id,
      fileName: fileName ?? this.fileName,
      storedName: storedName,
      extension: extension,
      kind: kind,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
    );
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dot + 1).toLowerCase();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Attachment &&
        other.id == id &&
        other.fileName == fileName &&
        other.storedName == storedName &&
        other.extension == extension &&
        other.kind == kind &&
        other.sizeBytes == sizeBytes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileName,
    storedName,
    extension,
    kind,
    sizeBytes,
    createdAt,
  );

  @override
  String toString() => 'Attachment(id: $id, file: $fileName)';
}
