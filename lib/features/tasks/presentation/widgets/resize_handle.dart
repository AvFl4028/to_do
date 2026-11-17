import 'package:material_ui/material_ui.dart';

/// Zona de arrastre vertical para redimensionar un panel lateral.
class ResizeHandle extends StatelessWidget {
  const ResizeHandle({
    super.key,
    required this.onDrag,
    required this.onDragEnd,
    required this.onReset,
    this.width = 8,
  });

  /// Recibe el desplazamiento horizontal en píxeles.
  final ValueChanged<double> onDrag;

  /// Se llama al soltar el arrastre, para persistir el ancho una sola vez.
  final VoidCallback onDragEnd;

  /// Doble clic para volver al ancho por defecto.
  final VoidCallback onReset;

  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: Tooltip(
        message: 'Arrastra para cambiar el tamaño',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
          onHorizontalDragEnd: (_) => onDragEnd(),
          onDoubleTap: onReset,
          child: SizedBox(
            width: width,
            child: Center(
              child: Container(width: 1, color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}
