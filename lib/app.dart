import 'package:material_ui/material_ui.dart';

import 'core/settings/settings_controller.dart';
import 'core/settings/settings_scope.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';
import 'features/tasks/application/task_scope.dart';
import 'features/tasks/application/task_store.dart';
import 'features/tasks/data/attachment_service.dart';
import 'features/tasks/presentation/tasks_home_page.dart';

class ToDoApp extends StatelessWidget {
  const ToDoApp({
    super.key,
    required this.store,
    required this.settings,
    this.services = const AttachmentServices(
      storage: UnsupportedAttachmentStorage(),
      opener: UnsupportedFileOpener(),
    ),
  });

  final TaskStore store;
  final SettingsController settings;
  final AttachmentServices services;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final appSettings = settings.settings;

          return TaskScope(
            store: store,
            attachmentStorage: services.storage,
            fileOpener: services.opener,
            child: MaterialApp(
              title: 'Mis tareas',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(
                animationsEnabled: appSettings.animationsEnabled,
                animationDurationMs: appSettings.animationDurationMs,
              ),
              darkTheme: AppTheme.dark(
                animationsEnabled: appSettings.animationsEnabled,
                animationDurationMs: appSettings.animationDurationMs,
              ),
              themeMode: appSettings.themePreference.themeMode,
              themeAnimationDuration: appSettings.motionDuration,
              locale: const Locale('es'),
              supportedLocales: const <Locale>[Locale('es'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) {
                final media = MediaQuery.maybeOf(context);
                if (media == null || child == null) {
                  return child ?? const SizedBox.shrink();
                }
                return MediaQuery(
                  data: media.copyWith(
                    disableAnimations: !appSettings.animationsEnabled,
                  ),
                  child: child,
                );
              },
              home: const TasksHomePage(),
            ),
          );
        },
      ),
    );
  }
}
