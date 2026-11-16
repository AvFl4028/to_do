import 'package:material_ui/material_ui.dart';

import '../../domain/task_list.dart';
import 'emoji_picker_dialog.dart';

/// Datos devueltos por el formulario de lista.
class ListDraft {
  const ListDraft({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

/// Diálogo para crear o editar una lista de tareas.
Future<ListDraft?> showListFormDialog(BuildContext context, {TaskList? list}) {
  return showDialog<ListDraft>(
    context: context,
    builder: (context) => _ListFormDialog(list: list),
  );
}

class _ListFormDialog extends StatefulWidget {
  const _ListFormDialog({this.list});

  final TaskList? list;

  @override
  State<_ListFormDialog> createState() => _ListFormDialogState();
}

class _ListFormDialogState extends State<_ListFormDialog> {
  late final TextEditingController _nameController;
  late String _emoji;
  String? _error;

  bool get _isEditing => widget.list != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list?.name ?? '');
    _emoji = widget.list?.emoji ?? '📋';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final picked = await showEmojiPickerDialog(context, initial: _emoji);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _emoji = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la lista.');
      return;
    }
    if (name.length > 40) {
      setState(() => _error = 'El nombre no puede superar los 40 caracteres.');
      return;
    }
    Navigator.of(context).pop(ListDraft(name: name, emoji: _emoji));
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 400.0);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar lista' : 'Nueva lista'),
      content: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('list-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Nombre de la lista',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('list-emoji-button'),
              onPressed: _pickEmoji,
              icon: Text(_emoji, style: const TextStyle(fontSize: 22)),
              label: const Text('Cambiar emoji'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
