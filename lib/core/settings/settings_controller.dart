import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'app_settings.dart';
import 'settings_repository.dart';

/// Estado observable de los ajustes. Persiste los cambios en orden.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository, {AppSettings? initial})
    : _settings = initial ?? AppSettings.defaults;

  final SettingsRepository _repository;

  static final Logger _logger = Logger();

  AppSettings _settings;
  bool _isLoading = false;
  String? _errorMessage;
  final List<AppSettings> _pendingSaves = <AppSettings>[];
  Future<void>? _saveDrain;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.load();
      if (loaded != null) {
        _settings = loaded;
      }
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron cargar los ajustes.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'No se pudieron cargar los ajustes guardados.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemePreference(AppThemePreference value) {
    return _update(_settings.copyWith(themePreference: value));
  }

  Future<void> setAnimationsEnabled(bool value) {
    return _update(_settings.copyWith(animationsEnabled: value));
  }

  Future<void> setAnimationDurationMs(int value) {
    return _update(_settings.copyWith(animationDurationMs: value));
  }

  Future<void> setSidebarWidth(double value) {
    return _update(_settings.copyWith(sidebarWidth: value));
  }

  Future<void> setPanelWidth(double value) {
    return _update(_settings.copyWith(panelWidth: value));
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _update(AppSettings next) {
    if (next == _settings) {
      return Future<void>.value();
    }

    _settings = next;
    _errorMessage = null;
    notifyListeners();

    _pendingSaves.add(next);
    _saveDrain ??= _drainSaves();
    return _saveDrain!;
  }

  Future<void> _drainSaves() async {
    try {
      while (_pendingSaves.isNotEmpty) {
        final snapshot = _pendingSaves.removeAt(0);
        await _persist(snapshot);
      }
    } finally {
      _saveDrain = null;
    }
  }

  Future<void> _persist(AppSettings snapshot) async {
    try {
      await _repository.save(snapshot);
      if (_errorMessage != null) {
        _errorMessage = null;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      _logger.e(
        'No se pudieron guardar los ajustes.',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'No se pudieron guardar los ajustes.';
      notifyListeners();
    }
  }
}
