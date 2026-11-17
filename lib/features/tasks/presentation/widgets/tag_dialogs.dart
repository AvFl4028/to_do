import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_motion.dart';
import '../../application/task_scope.dart';
import '../../domain/task_tag.dart';
import 'tag_chip.dart';

/// Pide un nombre de etiqueta. Devuelve el nombre recortado o `null`.
Future<String?> showTagNameDialog(
  BuildContext context, {
  String? initialName,
  String title = 'Nueva etiqueta',
}) {
  return showAppDialog<String>(
    context: context,
    builder: (context) =>
        _TagNameDialog(initialName: initialName, title: title),
  );
}

class _TagNameDialog extends StatefulWidget {
  const _TagNameDialog({this.initialName, required this.title});

  final String? initialName;
  final String title;

  @override
  State<_TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<_TagNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la etiqueta.');
      return;
    }
    if (name.length > 24) {
      setState(() => _error = 'El nombre no puede superar los 24 caracteres.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 380.0);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: width,
        child: TextField(
          key: const ValueKey('tag-name-field'),
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Nombre de la etiqueta',
            errorText: _error,
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

/// Selector múltiple de etiquetas con creación al vuelo.
Future<Set<String>?> showTagPickerDialog(
  BuildContext context, {
  required Set<String> initialSelection,
}) {
  return showAppDialog<Set<String>>(
    context: context,
    builder: (context) => _TagPickerDialog(initialSelection: initialSelection),
  );
}

class _TagPickerDialog extends StatefulWidget {
  const _TagPickerDialog({required this.initialSelection});

  final Set<String> initialSelection;

  @override
  State<_TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<_TagPickerDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = <String>{...widget.initialSelection};
  }

  Future<void> _createTag() async {
    final name = await showTagNameDialog(context);
    if (name == null || !mounted) {
      return;
    }

    final store = TaskScope.of(context);
    final tag = await store.createTag(name);
    if (!mounted) {
      return;
    }
    setState(() => _selected.add(tag.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = TaskScope.of(context);
    final tags = store.tags;
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 420.0);

    return AlertDialog(
      title: const Text('Etiquetas'),
      content: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Todavía no hay etiquetas. Crea la primera para '
                    'organizar tus tareas por categorías.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final tag in tags)
                        _TagCheckbox(
                          tag: tag,
                          selected: _selected.contains(tag.id),
                          onChanged: (value) {
                            setState(() {
                              if (value) {
                                _selected.add(tag.id);
                              } else {
                                _selected.remove(tag.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              const Divider(height: 20),
              TextButton.icon(
                onPressed: _createTag,
                icon: const Icon(Icons.add),
                label: const Text('Nueva etiqueta'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(<String>{..._selected}),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}

class _TagCheckbox extends StatelessWidget {
  const _TagCheckbox({
    required this.tag,
    required this.selected,
    required this.onChanged,
  });

  final TaskTag tag;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      controlAffinity: ListTileControlAffinity.leading,
      title: Align(
        alignment: Alignment.centerLeft,
        child: TagChip(tag: tag, compact: true),
      ),
    );
  }
}
