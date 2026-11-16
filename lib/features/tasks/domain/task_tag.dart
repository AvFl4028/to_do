/// Etiqueta global, compartida por todas las listas de tareas.
///
/// El color no se elige manualmente: se deriva de [colorIndex] sobre una paleta
/// fija para que todas las etiquetas tengan un aspecto consistente.
class TaskTag {
  const TaskTag({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  static const int paletteSize = 8;

  final String id;
  final String name;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskTag.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('La etiqueta no tiene un identificador.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('La etiqueta no tiene un nombre válido.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('La etiqueta no tiene fechas válidas.');
    }

    final rawColor = json['colorIndex'];
    final colorIndex = rawColor is int && rawColor >= 0
        ? rawColor % paletteSize
        : 0;

    return TaskTag(
      id: id,
      name: name,
      colorIndex: colorIndex,
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'colorIndex': colorIndex,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  TaskTag copyWith({String? name, int? colorIndex, DateTime? updatedAt}) {
    return TaskTag(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TaskTag &&
        other.id == id &&
        other.name == name &&
        other.colorIndex == colorIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex, createdAt, updatedAt);

  @override
  String toString() => 'TaskTag(id: $id, name: $name)';
}
