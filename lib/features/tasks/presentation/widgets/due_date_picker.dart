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
