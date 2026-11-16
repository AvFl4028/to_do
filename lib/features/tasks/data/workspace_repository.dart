import '../domain/workspace.dart';

/// Acceso a la persistencia del workspace completo (tareas, listas y etiquetas).
///
/// La interfaz permite sustituir el almacenamiento local por uno con
/// sincronización (Google Tasks, Nextcloud, etc.) sin tocar la interfaz de
/// usuario. Para ello, todos los modelos tienen IDs estables y `updatedAt`.
abstract interface class WorkspaceRepository {
  Future<Workspace> load();

  Future<void> save(Workspace workspace);
}
