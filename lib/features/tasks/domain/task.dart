import 'attachment.dart';
import 'task_list.dart';

/// Una tarea de la lista.
///
/// El identificador es estable y [updatedAt] se actualiza en cada cambio para
/// que, en el futuro, se pueda implementar una sincronización con servicios
/// externos (Google Tasks, Nextcloud, etc.) sin migrar los datos guardados.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.dueDate,
    this.listId = TaskList.inboxId,
    this.isImportant = false,
    this.tagIds = const <String>[],
    this.attachments = const <Attachment>[],
  }) : assert(id != '');

  final String id;
  final String title;

  /// Descripción en Markdown. Solo se edita desde el formulario.
  final String description;

  final bool isCompleted;

  /// Fecha de entrega elegida manualmente. Es opcional y solo representa un día.
  final DateTime? dueDate;

  /// Lista a la que pertenece la tarea.
  final String listId;

  /// Las tareas importantes aparecen en su propia sección de la sidebar.
  final bool isImportant;

  /// Etiquetas globales asignadas.
  final List<String> tagIds;

  /// Archivos adjuntos, con solo el nombre relativo dentro del almacenamiento.
  final List<Attachment> attachments;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('La tarea no tiene un identificador válido.');
    }
    if (title is! String) {
      throw const FormatException('La tarea no tiene un título válido.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('La tarea no tiene fechas válidas.');
    }

    return Task(
      id: id,
      title: title,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      isCompleted: json['isCompleted'] == true,
      dueDate: _parseDueDate(json['dueDate']),
      listId: json['listId'] is String && (json['listId'] as String).isNotEmpty
          ? json['listId'] as String
          : TaskList.inboxId,
      isImportant: json['isImportant'] == true,
      tagIds: _parseStringList(json['tagIds']),
      attachments: _parseAttachments(json['attachments']),
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'dueDate': _formatDueDate(dueDate),
    'listId': listId,
    'isImportant': isImportant,
    'tagIds': tagIds,
    'attachments': attachments
        .map((attachment) => attachment.toJson())
        .toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? listId,
    bool? isImportant,
    List<String>? tagIds,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    assert(
      !(dueDate != null && clearDueDate),
      'No se puede asignar y limpiar la fecha de entrega a la vez.',
    );

    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      listId: listId ?? this.listId,
      isImportant: isImportant ?? this.isImportant,
      tagIds: tagIds ?? this.tagIds,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDueDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _formatDueDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return <String>[
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  static List<Attachment> _parseAttachments(Object? value) {
    if (value is! List) {
      return const <Attachment>[];
    }

    final attachments = <Attachment>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      try {
        attachments.add(Attachment.fromJson(item));
      } on FormatException {
        // Un adjunto inválido no debe impedir cargar el resto de la tarea.
        continue;
      }
    }
    return attachments;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.dueDate == dueDate &&
        other.listId == listId &&
        other.isImportant == isImportant &&
        _sameList(other.tagIds, tagIds) &&
        _sameList(other.attachments, attachments) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    isCompleted,
    dueDate,
    listId,
    isImportant,
    Object.hashAll(tagIds),
    Object.hashAll(attachments),
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Task(id: $id, title: $title, completed: $isCompleted)';
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
