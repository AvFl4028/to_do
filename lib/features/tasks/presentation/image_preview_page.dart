import 'package:material_ui/material_ui.dart';

import '../domain/attachment.dart';
import 'widgets/attachment_image.dart';

/// Vista previa a pantalla completa de una imagen adjunta.
class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({
    super.key,
    required this.attachment,
    required this.path,
  });

  final Attachment attachment;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar vista previa',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: AttachmentImage(
              path: path,
              fit: BoxFit.contain,
              isSvg: attachment.isSvg,
            ),
          ),
        ),
      ),
    );
  }
}
