import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';
import 'features/tasks/application/task_scope.dart';
import 'features/tasks/application/task_store.dart';
import 'features/tasks/data/attachment_service.dart';
import 'features/tasks/presentation/tasks_home_page.dart';

class ToDoApp extends StatelessWidget {
  const ToDoApp({
    super.key,
    required this.store,
    this.services = const AttachmentServices(
      storage: UnsupportedAttachmentStorage(),
      opener: UnsupportedFileOpener(),
    ),
  });

  final TaskStore store;
  final AttachmentServices services;

  @override
  Widget build(BuildContext context) {
    return TaskScope(
      store: store,
      attachmentStorage: services.storage,
      fileOpener: services.opener,
      child: MaterialApp(
        title: 'Mis tareas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        locale: const Locale('es'),
        supportedLocales: const <Locale>[Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const TasksHomePage(),
      ),
    );
  }
}
