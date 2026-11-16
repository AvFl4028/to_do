/// Lista de tareas creada por el usuario.
///
/// La bandeja de entrada ([inboxId]) siempre existe, no se puede eliminar y
/// recibe las tareas de las listas que se borran.
class TaskList {
  const TaskList({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String inboxId = 'inbox';
  static const String inboxEmoji = '📥';
  static const String inboxName = 'Bandeja de entrada';

  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isInbox => id == inboxId;

  factory TaskList.inbox(DateTime now) {
    final timestamp = now.toUtc();
    return TaskList(
      id: inboxId,
      name: inboxName,
      emoji: inboxEmoji,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory TaskList.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('La lista no tiene un identificador.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('La lista no tiene un nombre válido.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('La lista no tiene fechas válidas.');
    }

    return TaskList(
      id: id,
      name: name,
      emoji: json['emoji'] is String && (json['emoji'] as String).isNotEmpty
          ? json['emoji'] as String
          : '📋',
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'emoji': emoji,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  TaskList copyWith({String? name, String? emoji, DateTime? updatedAt}) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TaskList &&
        other.id == id &&
        other.name == name &&
        other.emoji == emoji &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, createdAt, updatedAt);

  @override
  String toString() => 'TaskList(id: $id, name: $name)';
}
