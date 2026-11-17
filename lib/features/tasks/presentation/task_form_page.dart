import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/utils/date_formatters.dart';
import '../application/task_scope.dart';
import '../domain/attachment.dart';
import '../domain/task.dart';
import '../domain/task_list.dart';
import '../domain/task_tag.dart';
import 'image_preview_page.dart';
import 'widgets/attachment_section.dart';
import 'widgets/due_date_picker.dart';
import 'widgets/tag_chip.dart';
import 'widgets/tag_dialogs.dart';

/// Datos devueltos por [TaskFormPage] al guardar.
class TaskFormResult {
  const TaskFormResult({
    required this.title,
    required this.description,
    required this.listId,
    required this.isImportant,
    required this.tagIds,
    required this.attachments,
    this.dueDate,
    this.dueTimeMinutes,
  });

  final String title;
  final String description;
  final String listId;
  final bool isImportant;
  final List<String> tagIds;
  final List<Attachment> attachments;
  final DateTime? dueDate;
  final int? dueTimeMinutes;
}

enum _EditorMode { write, preview }

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({
    super.key,
    this.task,
    this.initialListId,
    this.embedded = false,
    this.onCancel,
    this.onEmbeddedSave,
  });

  /// Si es `null`, el formulario crea una tarea nueva.
  final Task? task;

  /// Lista preseleccionada al crear desde una lista concreta.
  final String? initialListId;

  /// `true` para mostrar solo el contenido, sin `Scaffold` ni AppBar.
  final bool embedded;

  /// Se llama al cancelar o descartar cambios en modo embebido.
  final VoidCallback? onCancel;

  /// Se llama al guardar en modo embebido en lugar de cerrar una ruta.
  final Future<void> Function(TaskFormResult)? onEmbeddedSave;

  bool get isEditing => task != null;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _dueDate;
  int? _dueTimeMinutes;
  late String _listId;
  late bool _isImportant;
  late Set<String> _tagIds;
  late List<Attachment> _attachments;

  /// Archivos copiados desde que se abrió el formulario. Si se descarta la
  /// edición, se eliminan para no dejar huérfanos.
  final Set<String> _newStoredNames = <String>{};

  _EditorMode _mode = _EditorMode.write;
  bool _isConfirmingExit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _dueDate = widget.task?.dueDate;
    _dueTimeMinutes = widget.task?.dueTimeMinutes;
    _listId = widget.task?.listId ?? widget.initialListId ?? TaskList.inboxId;
    _isImportant = widget.task?.isImportant ?? false;
    _tagIds = <String>{...?widget.task?.tagIds};
    _attachments = <Attachment>[...?widget.task?.attachments];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final original = widget.task;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (original == null) {
      return title.isNotEmpty ||
          description.isNotEmpty ||
          _dueDate != null ||
          _dueTimeMinutes != null ||
          _isImportant ||
          _tagIds.isNotEmpty ||
          _attachments.isNotEmpty;
    }

    return title != original.title ||
        description != original.description ||
        _normalizedDate(_dueDate) != _normalizedDate(original.dueDate) ||
        _dueTimeMinutes != original.dueTimeMinutes ||
        _listId != original.listId ||
        _isImportant != original.isImportant ||
        !_sameIds(_tagIds, original.tagIds) ||
        !_sameAttachmentIds(_attachments, original.attachments);
  }

  bool _sameIds(Set<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    return b.every(a.contains);
  }

  bool _sameAttachmentIds(List<Attachment> a, List<Attachment> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index].id != b[index].id) {
        return false;
      }
    }
    return true;
  }

  DateTime? _normalizedDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _pickDueDate() async {
    final picked = await pickTaskDueDate(context, initialDate: _dueDate);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _dueDate = _normalizedDate(picked));
  }

  Future<void> _pickDueTime() async {
    if (_dueDate == null) {
      return;
    }
    final picked = await pickTaskDueTime(
      context,
      initialMinutes: _dueTimeMinutes,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _dueTimeMinutes = picked);
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
      _dueTimeMinutes = null;
    });
  }

  void _clearDueTime() {
    setState(() => _dueTimeMinutes = null);
  }

  Future<void> _pickList() async {
    final store = TaskScope.of(context);
    final selected = await showAppDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Elegir lista'),
        children: [
          for (final list in store.lists)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(list.id),
              child: Row(
                children: [
                  Text(list.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                  if (list.id == _listId) const Icon(Icons.check, size: 20),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => _listId = selected);
    }
  }

  Future<void> _pickTags() async {
    final store = TaskScope.of(context);
    final selected = await showTagPickerDialog(
      context,
      initialSelection: _tagIds,
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _tagIds = <String>{
        for (final id in selected)
          if (store.tagById(id) != null) id,
      };
    });
  }

  Future<void> _pickAttachments() async {
    final storage = TaskScope.attachmentsOf(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await storage.pickAndStore();
      if (!mounted || picked.isEmpty) {
        return;
      }
      setState(() {
        _attachments = <Attachment>[..._attachments, ...picked];
        _newStoredNames.addAll(picked.map((item) => item.storedName));
      });
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudieron añadir los archivos.')),
      );
    }
  }

  void _removeAttachment(Attachment attachment) {
    setState(() {
      _attachments = _attachments
          .where((item) => item.id != attachment.id)
          .toList(growable: false);
    });
    if (_newStoredNames.remove(attachment.storedName)) {
      TaskScope.attachmentsOf(context)
          .deleteStored(<String>[attachment.storedName]);
    }
  }

  Future<void> _openAttachment(Attachment attachment) async {
    final storage = TaskScope.attachmentsOf(context);
    final opener = TaskScope.openerOf(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!await storage.exists(attachment.storedName)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El archivo ya no está disponible.')),
      );
      return;
    }

    final path = storage.pathFor(attachment.storedName);
    if (path == null) {
      return;
    }

    if (attachment.isImage) {
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) =>
              ImagePreviewPage(attachment: attachment, path: path),
        ),
      );
      return;
    }

    final opened = await opener.open(path);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el archivo con el sistema.'),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final result = TaskFormResult(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      listId: _listId,
      isImportant: _isImportant,
      tagIds: _tagIds.toList(growable: false),
      attachments: List<Attachment>.unmodifiable(_attachments),
      dueDate: _normalizedDate(_dueDate),
      dueTimeMinutes: _dueTimeMinutes,
    );

    if (widget.embedded) {
      await widget.onEmbeddedSave?.call(result);
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _closeForm() {
    if (widget.embedded) {
      widget.onCancel?.call();
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handlePop() async {
    if (_isConfirmingExit) {
      return;
    }
    if (!_hasChanges) {
      _closeForm();
      return;
    }

    _isConfirmingExit = true;
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Si sales ahora se perderán los cambios sin guardar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    _isConfirmingExit = false;

    if (discard == true && mounted) {
      final storage = TaskScope.attachmentsOf(context);
      await storage.deleteStored(_newStoredNames);
      _closeForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          _buildEmbeddedHeader(context),
          Expanded(child: _buildFormBody(context)),
        ],
      );
    }

    return PopScope<TaskFormResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handlePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Editar tarea' : 'Nueva tarea'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                key: const ValueKey('task-save-button'),
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
        body: SafeArea(child: _buildFormBody(context)),
      ),
    );
  }

  Widget _buildEmbeddedHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al detalle',
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePop,
          ),
          Expanded(
            child: Text(
              widget.isEditing ? 'Editar tarea' : 'Nueva tarea',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            key: const ValueKey('task-save-button'),
            onPressed: _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final store = TaskScope.of(context);
    final selectedList =
        store.listById(_listId) ?? store.listById(TaskList.inboxId);
    final selectedTags = <TaskTag>[
      for (final tag in store.tags)
        if (_tagIds.contains(tag.id)) tag,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              TextFormField(
                key: const ValueKey('task-title-field'),
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: '¿Qué necesitas hacer?',
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) {
                    return 'Escribe un título para la tarea.';
                  }
                  if (title.length > 120) {
                    return 'El título no puede superar los 120 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      key: const ValueKey('task-list-field'),
                      leading: Text(
                        selectedList?.emoji ?? TaskList.inboxEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: const Text('Lista'),
                      subtitle: Text(selectedList?.name ?? TaskList.inboxName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickList,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const ValueKey('task-due-date-field'),
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Fecha de entrega'),
                      subtitle: Text(
                        _dueDate == null
                            ? 'Sin fecha'
                            : AppDates.long(_dueDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueDate != null)
                            IconButton(
                              tooltip: 'Quitar fecha',
                              icon: const Icon(Icons.close),
                              onPressed: _clearDueDate,
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: _pickDueDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const ValueKey('task-due-time-field'),
                      enabled: _dueDate != null,
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Hora de entrega'),
                      subtitle: Text(
                        _dueDate == null
                            ? 'Elige primero una fecha'
                            : (_dueTimeMinutes == null
                                  ? 'Sin hora'
                                  : AppDates.timeLabel(_dueTimeMinutes!)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueTimeMinutes != null)
                            IconButton(
                              tooltip: 'Quitar hora',
                              icon: const Icon(Icons.close),
                              onPressed: _clearDueTime,
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: _dueDate == null ? null : _pickDueTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  key: const ValueKey('task-important-field'),
                  secondary: Icon(
                    _isImportant
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _isImportant
                        ? const Color(0xFFF59E0B)
                        : scheme.onSurfaceVariant,
                  ),
                  title: const Text('Importante'),
                  subtitle: const Text(
                    'Aparecerá en la sección Importantes de la barra lateral.',
                  ),
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Etiquetas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('task-tags-button'),
                    onPressed: _pickTags,
                    icon: const Icon(Icons.label_outline, size: 18),
                    label: const Text('Elegir'),
                  ),
                ],
              ),
              if (selectedTags.isEmpty)
                Text(
                  'Sin etiquetas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in selectedTags)
                      TagChip(
                        tag: tag,
                        onDeleted: () => setState(() => _tagIds.remove(tag.id)),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              AttachmentSection(
                attachments: _attachments,
                onAdd: _pickAttachments,
                onRemove: _removeAttachment,
                onOpen: _openAttachment,
              ),
              const SizedBox(height: 24),
              Text(
                'Descripción',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Puedes escribir Markdown: encabezados, listas, negritas, enlaces y bloques de código.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_EditorMode>(
                segments: const [
                  ButtonSegment(
                    value: _EditorMode.write,
                    label: Text('Escribir'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: _EditorMode.preview,
                    label: Text('Vista previa'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: switch (_mode) {
                  _EditorMode.write => TextField(
                    key: const ValueKey('task-description-field'),
                    controller: _descriptionController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText:
                          '# Plan\n\n'
                          '- [ ] Primer paso\n'
                          '- [x] Paso completado\n\n'
                          '**Importante:** revisar antes del viernes.',
                      hintMaxLines: 8,
                    ),
                  ),
                  _EditorMode.preview => DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      color: scheme.surfaceContainerLowest,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildPreview(theme),
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_descriptionController.text.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'La vista previa aparecerá aquí.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return GptMarkdown(_descriptionController.text, isStreaming: false);
  }
}
