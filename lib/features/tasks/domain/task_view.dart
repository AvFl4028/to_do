/// Vista activa del contenido principal y de la sidebar.
///
/// Las vistas de "Hoy" e "Importantes" solo muestran tareas pendientes; las de
/// lista y etiqueta aplican además el filtro de estado elegido por el usuario.
sealed class TaskView {
  const TaskView();
}

final class AllTasksView extends TaskView {
  const AllTasksView();

  @override
  bool operator ==(Object other) => other is AllTasksView;

  @override
  int get hashCode => (AllTasksView).hashCode;
}

final class TodayTasksView extends TaskView {
  const TodayTasksView();

  @override
  bool operator ==(Object other) => other is TodayTasksView;

  @override
  int get hashCode => (TodayTasksView).hashCode;
}

final class ImportantTasksView extends TaskView {
  const ImportantTasksView();

  @override
  bool operator ==(Object other) => other is ImportantTasksView;

  @override
  int get hashCode => (ImportantTasksView).hashCode;
}

final class ListTasksView extends TaskView {
  const ListTasksView(this.listId);

  final String listId;

  @override
  bool operator ==(Object other) =>
      other is ListTasksView && other.listId == listId;

  @override
  int get hashCode => Object.hash(ListTasksView, listId);
}

final class TagTasksView extends TaskView {
  const TagTasksView(this.tagId);

  final String tagId;

  @override
  bool operator ==(Object other) =>
      other is TagTasksView && other.tagId == tagId;

  @override
  int get hashCode => Object.hash(TagTasksView, tagId);
}
