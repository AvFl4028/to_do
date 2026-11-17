import 'package:flutter/widgets.dart';

import 'settings_controller.dart';

/// Expone el [SettingsController] al árbol de widgets.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsScope>()
        ?.notifier;
  }

  static SettingsController of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SettingsScope no se encontró en el árbol.');
    return scope!;
  }
}
