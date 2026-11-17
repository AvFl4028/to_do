import 'package:material_ui/material_ui.dart';

/// Abre el selector de fecha de entrega en español.
///
/// Devuelve `null` si el usuario cancela. Una tarea puede quedarse sin fecha.
Future<DateTime?> pickTaskDueDate(
  BuildContext context, {
  DateTime? initialDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 20),
    helpText: 'Fecha de entrega',
    fieldLabelText: 'Fecha de entrega',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
  );
}

/// Abre el selector de hora de entrega en formato de 24 horas.
///
/// Devuelve los minutos desde medianoche, o `null` si el usuario cancela.
Future<int?> pickTaskDueTime(
  BuildContext context, {
  int? initialMinutes,
}) async {
  final now = TimeOfDay.now();
  final initial = initialMinutes == null
      ? now
      : TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60);

  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
    helpText: 'Hora de entrega',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (picked == null) {
    return null;
  }
  return picked.hour * 60 + picked.minute;
}
