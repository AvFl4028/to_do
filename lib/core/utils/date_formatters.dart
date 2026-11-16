import 'package:intl/intl.dart';

/// Utilidades de fecha compartidas por la interfaz.
///
/// La aplicación trabaja con fechas de entrega sin hora. Para evitar
/// corrimientos por zona horaria, la fecha se normaliza a medianoche local y
/// se serializa como `YYYY-MM-DD` en [Task.toJson].
abstract final class AppDates {
  static final DateFormat _long = DateFormat("d 'de' MMMM 'de' y", 'es');
  static final DateFormat _short = DateFormat('d MMM y', 'es');

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String long(DateTime date) => _long.format(date);

  static String short(DateTime date) => _short.format(date);

  /// Texto corto para el badge de la lista: `Hoy`, `Mañana`, la fecha, o
  /// `Vencida · 12 nov 2026` cuando ya pasó.
  static String dueLabel(
    DateTime dueDate, {
    bool isCompleted = false,
    DateTime? now,
  }) {
    final current = dateOnly(now ?? DateTime.now());
    final target = dateOnly(dueDate);

    if (!isCompleted && target.isBefore(current)) {
      return 'Vencida · ${_short.format(target)}';
    }
    if (target == current) {
      return 'Hoy';
    }
    if (target == DateTime(current.year, current.month, current.day + 1)) {
      return 'Mañana';
    }
    return _short.format(target);
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
}
