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
    this.dueTimeMinutes,
    this.listId = TaskList.inboxId,
    this.isImportant = false,
    this.tagIds = const <String>[],
    this.attachments = const <Attachment>[],
  }) : assert(id != ''),
       assert(
         dueTimeMinutes == null ||
             (dueTimeMinutes >= 0 && dueTimeMinutes < 24 * 60),
         'La hora de entrega debe estar entre 00:00 y 23:59.',
       );

  final String id;
  final String title;

  /// Descripción en Markdown. Solo se edita desde el formulario.
  final String description;

  final bool isCompleted;

  /// Fecha de entrega elegida manualmente. Es opcional y solo representa un día.
  final DateTime? dueDate;

  /// Hora de entrega en minutos desde medianoche (0–1439).
  ///
  /// Es opcional y solo puede existir junto a [dueDate].
  final int? dueTimeMinutes;

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

    final dueDate = _parseDueDate(json['dueDate']);
    final dueTimeMinutes = dueDate == null
        ? null
        : _parseDueTime(json['dueTime']);

    return Task(
      id: id,
      title: title,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      isCompleted: json['isCompleted'] == true,
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
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
    'dueTime': _formatDueTime(dueTimeMinutes),
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
    int? dueTimeMinutes,
    bool clearDueTime = false,
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
    assert(
      !(dueTimeMinutes != null && clearDueTime),
      'No se puede asignar y limpiar la hora de entrega a la vez.',
    );

    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTimeMinutes: clearDueDate || clearDueTime
          ? null
          : (dueTimeMinutes ?? this.dueTimeMinutes),
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

  static int? _parseDueTime(Object? value) {
    if (value is! String) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  static String? _formatDueTime(int? minutes) {
    if (minutes == null) {
      return null;
    }
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
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
        other.dueTimeMinutes == dueTimeMinutes &&
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
    dueTimeMinutes,
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
