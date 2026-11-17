import 'package:material_ui/material_ui.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_scope.dart';

/// Pantalla de preferencias de apariencia y movimiento.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      key: const ValueKey<String>('settings-page'),
      appBar: AppBar(title: const Text('Configuración')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SettingsErrorBanner(
                      message: controller.errorMessage!,
                      onDismiss: controller.clearError,
                    ),
                  ),
                Text(
                  'Apariencia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema de la aplicación',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '«Sistema» sigue la preferencia del sistema operativo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<AppThemePreference>(
                            key: const ValueKey<String>(
                              'settings-theme-selector',
                            ),
                            segments: const <ButtonSegment<AppThemePreference>>[
                              ButtonSegment<AppThemePreference>(
                                value: AppThemePreference.system,
                                label: Text('Sistema'),
                                icon: Icon(Icons.brightness_auto_outlined),
                              ),
                              ButtonSegment<AppThemePreference>(
                                value: AppThemePreference.light,
                                label: Text('Claro'),
                                icon: Icon(Icons.light_mode_outlined),
                              ),
                              ButtonSegment<AppThemePreference>(
                                value: AppThemePreference.dark,
                                label: Text('Oscuro'),
                                icon: Icon(Icons.dark_mode_outlined),
                              ),
                            ],
                            selected: <AppThemePreference>{
                              settings.themePreference,
                            },
                            onSelectionChanged: (selection) {
                              controller.setThemePreference(selection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Animaciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const ValueKey<String>(
                          'settings-animations-switch',
                        ),
                        secondary: Icon(
                          settings.animationsEnabled
                              ? Icons.animation_rounded
                              : Icons.motion_photos_off_outlined,
                        ),
                        title: const Text('Usar animaciones'),
                        subtitle: const Text(
                          'Transiciones de pantalla, cambio de tema, paneles y '
                          'diálogos.',
                        ),
                        value: settings.animationsEnabled,
                        onChanged: controller.setAnimationsEnabled,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Duración',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: settings.animationsEnabled
                                          ? scheme.onSurface
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${settings.animationDurationMs} ms',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              key: const ValueKey<String>(
                                'settings-duration-slider',
                              ),
                              min: AppSettings.minAnimationDurationMs
                                  .toDouble(),
                              max: AppSettings.maxAnimationDurationMs
                                  .toDouble(),
                              divisions: 10,
                              label: '${settings.animationDurationMs} ms',
                              value: settings.animationDurationMs.toDouble(),
                              onChanged: settings.animationsEnabled
                                  ? (value) => controller
                                        .setAnimationDurationMs(value.round())
                                  : null,
                            ),
                            Text(
                              'Se aplica a las transiciones y a los cambios de '
                              'tema. Con las animaciones desactivadas, la '
                              'interfaz cambia de inmediato.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsErrorBanner extends StatelessWidget {
  const _SettingsErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.error_outline, color: scheme.onErrorContainer),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar aviso',
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
