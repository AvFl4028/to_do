# Mis tareas

Aplicación de lista de tareas hecha con Flutter, enfocada en escritorio
(Linux/Windows) y Android, con soporte adicional para web.

## Funcionalidades

- CRUD completo de tareas: crear, ver, editar, completar y eliminar.
- Eliminación con opción de **deshacer**.
- Fecha de entrega manual y opcional por tarea.
- Hora de entrega opcional (solo si hay fecha), con selector de 24 horas y aviso
  discreto de **Hora pasada** cuando vence hoy y la hora ya pasó.
- Descripción en **Markdown** con editor y vista previa.
- Detalle en un **panel derecho** en escritorio, con edición dentro del mismo
  panel; en móvil se mantiene la página de detalle completa.
- Barras laterales redimensionables en escritorio, con anchos persistentes.
- Pantalla de **Configuración** con tema Claro / Oscuro / Sistema, animaciones
  activables y duración ajustable de 100 a 600 ms.
- Filtros por todas, pendientes, completadas y vencidas (el vencimiento sigue
  siendo por día, no por hora).
- La vista principal separa las tareas **Pendientes** de las **Completadas**.
- Botón **Borrar completadas** para eliminar las tareas completadas de la vista
  actual.
- Barra lateral con botones y contadores de pendientes: tareas que vencen hoy,
  tareas importantes y todas las tareas. La sidebar ya no lista tareas.
- Listas personalizadas con emoji, renombrables y eliminables. Al eliminar una
  lista sus tareas se mueven a la **Bandeja de entrada**.
- Etiquetas globales compartidas por todas las listas, con color automático.
- Adjuntos por tarea:
  - Las imágenes se muestran como miniatura y se abren en una vista previa
    dentro de la aplicación.
  - PDF, Word, Excel, PowerPoint y texto se abren con la aplicación
    predeterminada del sistema.
- Persistencia local, tema claro/oscuro e interfaz en español.

## Escritorio y móvil

- En escritorio (ancho ≥ 1000 px) la barra lateral izquierda está siempre
  visible y, al abrir una tarea, el detalle aparece en un panel derecho sin
  abandonar la lista.
- Los divisores de ambas barras se pueden arrastrar; un doble clic restablece el
  ancho por defecto. Los anchos se guardan al soltar el arrastre.
- En pantallas más estrechas la barra lateral se abre desde el menú y el detalle
  de la tarea se abre como página completa.

## Barra lateral

- En escritorio (ancho ≥ 1000 px) está siempre visible.
- En pantallas más estrechas (móvil y ventanas pequeñas) se abre desde el menú
  lateral.
- Cada acceso muestra un contador con las tareas pendientes.
- La **Bandeja de entrada** siempre existe: se puede renombrar y cambiar de
  emoji, pero no eliminar.

## Estructura

```text
lib/
  main.dart                         # Arranque, ajustes, migración y adjuntos
  app.dart                          # MaterialApp, tema, animaciones y scopes
  core/
    settings/                       # AppSettings, controlador, scope y storage
    theme/app_motion.dart           # Transiciones, diálogos y duración
    theme/app_theme.dart
    theme/tag_palette.dart          # Colores estables de las etiquetas
    utils/date_formatters.dart
    utils/file_size.dart
  features/settings/presentation/    # Pantalla de configuración
  features/tasks/
    domain/                         # Task, listas, etiquetas, adjuntos y vistas
    data/                           # Repositorio del workspace y adjuntos
    application/                    # TaskStore (ChangeNotifier) y TaskScope
    presentation/                   # Sidebar, contenido, formulario, panel, etc.
test/
  core/settings/                    # Pruebas de ajustes
  features/settings/                # Pruebas de la pantalla de configuración
  features/tasks/                   # Tests de dominio, datos, estado y widgets
  support/                          # Repositorios y servicios simulados
```

## Persistencia y sincronización futura

El workspace completo (tareas, listas y etiquetas) se guarda como un único
documento JSON versionado en `shared_preferences` bajo la clave `workspace_v2`.
La hora de entrega se guarda como `dueTime` (`"HH:mm"`), sin cambiar la versión
del documento. El acceso está detrás de la interfaz `WorkspaceRepository`, por
lo que se puede añadir en el futuro un repositorio con sincronización (Google
Tasks, Nextcloud, etc.) sin cambiar la interfaz de usuario. Los modelos ya
incluyen IDs estables (`uuid`) y `updatedAt` para facilitar la resolución de
conflictos.

Los ajustes locales (tema, animaciones y anchos de las barras laterales) se
guardan por separado en `settings_v1`. Al arrancar se cargan antes de mostrar la
interfaz para evitar parpadeos de tema.

### Migración desde `tasks_v1`

Al arrancar, si no existe `workspace_v2` pero sí la clave antigua `tasks_v1`, las
tareas antiguas se cargan automáticamente y se asignan a la Bandeja de entrada.
La clave `tasks_v1` se conserva como respaldo y no se modifica.

### Adjuntos

Los archivos se copian a `<directorio de datos de la aplicación>/attachments` y
en el workspace solo se guarda el nombre relativo, nunca una ruta absoluta. Así
los datos se pueden mover entre equipos o sincronizar en el futuro. Al arrancar
se eliminan los adjuntos huérfanos; los de tareas eliminadas individualmente se
conservan hasta el siguiente arranque para que **Deshacer** siga funcionando.

Al usar **Borrar completadas**, las tareas se eliminan y también se borran sus
copias internas de adjuntos. Los archivos originales que el usuario seleccionó
nunca se tocan: la aplicación solo guarda y elimina sus propias copias.

En **web** los adjuntos están deshabilitados temporalmente: se necesitará un
backend para almacenar los archivos. La interfaz de almacenamiento ya está
preparada para esa implementación.

## Comandos

```bash
flutter pub get
flutter run -d linux     # o windows / android / chrome
flutter test
flutter analyze
flutter build linux --debug
flutter build apk --debug
flutter build web
```

## Dependencias principales

- `material_ui`: widgets Material 3 del SDK actual.
- `gpt_markdown`: renderizado de Markdown compatible con `material_ui`.
- `shared_preferences`: almacenamiento local del workspace.
- `uuid`: identificadores estables.
- `intl`: fechas en español.
- `file_selector`: selección de archivos para los adjuntos.
- `open_filex`: apertura de archivos con la aplicación del sistema.
- `path_provider` y `path`: directorio de datos y rutas seguras de adjuntos.
- `flutter_svg`: vista previa de imágenes SVG.
