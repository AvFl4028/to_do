import 'package:material_ui/material_ui.dart';

import '../settings/app_settings.dart';
import '../settings/settings_scope.dart';

extension AppThemePreferenceMode on AppThemePreference {
  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };
}

/// Duración configurada para las animaciones de la interfaz.
Duration appMotionDuration(BuildContext context) {
  return SettingsScope.maybeOf(context)?.settings.motionDuration ??
      AppSettings.defaults.animationDuration;
}

/// Transición de páginas con duración configurable.
///
/// Cuando las animaciones están desactivadas devuelve el contenido directamente
/// y la ruta dura cero, por lo que el cambio es instantáneo.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder({
    required this.duration,
    required this.enabled,
  });

  final Duration duration;
  final bool enabled;

  @override
  Duration get transitionDuration => enabled ? duration : Duration.zero;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!enabled || duration == Duration.zero) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// `showDialog` con la duración de animación elegida en los ajustes.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final settings = SettingsScope.maybeOf(context)?.settings;
  final enabled = settings?.animationsEnabled ?? true;
  final duration = enabled
      ? (settings?.animationDuration ?? AppSettings.defaults.animationDuration)
      : Duration.zero;

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: duration == Duration.zero
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            duration: duration,
            reverseDuration: duration,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
    builder: builder,
  );
}
