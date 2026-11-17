import 'package:flutter/widgets.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/settings/shared_prefs_settings_repository.dart';
import 'core/settings/settings_controller.dart';
import 'features/tasks/application/task_store.dart';
import 'features/tasks/data/attachment_service_factory.dart';
import 'features/tasks/data/shared_prefs_workspace_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final repository = await SharedPreferencesWorkspaceRepository.create();
  final settingsRepository = await SharedPreferencesSettingsRepository.create();
  final services = await createAttachmentServices();
  await services.storage.ensureReady();

  final settings = SettingsController(settingsRepository);
  await settings.load();

  final store = TaskStore(repository);
  await store.load();

  // Los adjuntos de tareas eliminadas se conservan hasta el siguiente arranque
  // para que «Deshacer» siga funcionando. Aquí se limpian los huérfanos.
  await services.storage.cleanOrphans(store.storedAttachmentNames);

  runApp(ToDoApp(store: store, settings: settings, services: services));
}
