import 'package:to_do/core/settings/app_settings.dart';
import 'package:to_do/core/settings/settings_repository.dart';

/// Repositorio de ajustes en memoria para las pruebas.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({AppSettings? initial}) : _settings = initial;

  AppSettings? _settings;
  int saveCount = 0;

  AppSettings? get saved => _settings;

  @override
  Future<AppSettings?> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
    saveCount++;
  }
}
