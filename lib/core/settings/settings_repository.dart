import 'app_settings.dart';

/// Persistencia de los ajustes locales de la aplicación.
abstract interface class SettingsRepository {
  /// Devuelve `null` cuando todavía no hay ajustes guardados.
  Future<AppSettings?> load();

  Future<void> save(AppSettings settings);
}
