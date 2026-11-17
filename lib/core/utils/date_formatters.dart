import 'package:intl/intl.dart';

/// Utilidades de fecha y hora compartidas por la interfaz.
///
/// La fecha de entrega se guarda sin zona horaria (`YYYY-MM-DD`) y la hora como
/// minutos desde medianoche. Así el día y la hora se mantienen estables al
/// mover los datos entre equipos o sincronizarlos en el futuro.
abstract final class AppDates {
  static final DateFormat _long = DateFormat("d 'de' MMMM 'de' y", 'es');
  static final DateFormat _short = DateFormat('d MMM y', 'es');
  static final DateFormat _time = DateFormat('HH:mm', 'es');

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String long(DateTime date) => _long.format(date);

  static String short(DateTime date) => _short.format(date);

  /// Hora en formato de 24 horas: `14:30`.
  static String timeLabel(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return _time.format(DateTime(2000, 1, 1, hour, minute));
  }

  /// Texto corto para el badge de la lista: `Hoy`, `Mañana`, la fecha, o
  /// `Vencida · 12 nov 2026` cuando ya pasó. Si hay hora, se añade al final.
  static String dueLabel(
    DateTime dueDate, {
    bool isCompleted = false,
    int? dueTimeMinutes,
    DateTime? now,
  }) {
    final current = dateOnly(now ?? DateTime.now());
    final target = dateOnly(dueDate);
    final timeSuffix = dueTimeMinutes == null
        ? ''
        : ' · ${timeLabel(dueTimeMinutes)}';

    if (!isCompleted && target.isBefore(current)) {
      return 'Vencida · ${_short.format(target)}$timeSuffix';
    }
    if (target == current) {
      return 'Hoy$timeSuffix';
    }
    if (target == DateTime(current.year, current.month, current.day + 1)) {
      return 'Mañana$timeSuffix';
    }
    return '${_short.format(target)}$timeSuffix';
  }

  static bool isOverdue(
    DateTime dueDate, {
    bool isCompleted = false,
    DateTime? now,
  }) {
    if (isCompleted) {
      return false;
    }
    final current = dateOnly(now ?? DateTime.now());
    return dateOnly(dueDate).isBefore(current);
  }

  static bool isToday(DateTime dueDate, {DateTime? now}) {
    final current = dateOnly(now ?? DateTime.now());
    return dateOnly(dueDate) == current;
  }

  /// Comprueba si la hora de entrega de hoy ya pasó.
  ///
  /// No se usa para marcar la tarea como vencida: el vencimiento sigue siendo
  /// por día. Solo alimenta el aviso discreto de «Hora pasada».
  static bool isTimePast(
    DateTime dueDate,
    int? dueTimeMinutes, {
    DateTime? now,
  }) {
    if (dueTimeMinutes == null) {
      return false;
    }
    final current = now ?? DateTime.now();
    if (!isToday(dueDate, now: current)) {
      return false;
    }
    final currentMinutes = current.hour * 60 + current.minute;
    return currentMinutes > dueTimeMinutes;
  }
}
