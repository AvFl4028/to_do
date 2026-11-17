import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_motion.dart';

/// Emojis sugeridos para listas. Se puede pegar cualquiera en el campo de texto.
const List<String> _suggestedEmojis = <String>[
  '📥',
  '📋',
  '📝',
  '📌',
  '🏠',
  '💼',
  '🛒',
  '🎯',
  '🚀',
  '💡',
  '📚',
  '🎵',
  '🎨',
  '🏋️',
  '✈️',
  '🌱',
  '🍎',
  '🐶',
  '🐱',
  '❤️',
  '⭐',
  '🔥',
  '⚽',
  '🎮',
  '☕',
  '🍕',
  '🧾',
  '📅',
  '🛠️',
  '🎓',
  '🚗',
  '🎁',
  '💰',
  '🏆',
  '⚡',
  '🌙',
  '☀️',
  '🌈',
  '🍀',
  '💻',
  '📱',
  '🖨️',
  '🧹',
  '🧪',
  '🩺',
  '💊',
  '🎬',
  '📷',
];

/// Muestra el selector de emoji y devuelve el elegido, o `null` al cancelar.
Future<String?> showEmojiPickerDialog(BuildContext context, {String? initial}) {
  return showAppDialog<String>(
    context: context,
    builder: (context) => _EmojiPickerDialog(initial: initial),
  );
}

class _EmojiPickerDialog extends StatefulWidget {
  const _EmojiPickerDialog({this.initial});

  final String? initial;

  @override
  State<_EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<_EmojiPickerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(240.0, 360.0);

    return AlertDialog(
      title: const Text('Elegir emoji'),
      content: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('emoji-field'),
              controller: _controller,
              maxLength: 8,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'Pega o escribe un emoji',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final emoji in _suggestedEmojis)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(emoji),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Usar')),
      ],
    );
  }
}
