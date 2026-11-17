import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'settings_repository.dart';

/// Guarda los ajustes como un único documento JSON en `shared_preferences`.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const storageKey = 'settings_v1';
  static final Logger _logger = Logger();

  final SharedPreferences _preferences;

  static Future<SharedPreferencesSettingsRepository> create() async {
    return SharedPreferencesSettingsRepository(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<AppSettings?> load() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _logger.w('Los ajustes guardados no son un objeto JSON.');
        return null;
      }
      return AppSettings.fromJson(decoded);
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron leer los ajustes guardados.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final saved = await _preferences.setString(
      storageKey,
      jsonEncode(settings.toJson()),
    );
    if (!saved) {
      throw StateError('No se pudieron escribir los ajustes.');
    }
  }
}
