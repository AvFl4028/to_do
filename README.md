# Mis tareas

Aplicación de lista de tareas hecha con Flutter, enfocada en escritorio
(Linux/Windows) y Android, con soporte adicional para web.

## Funcionalidades

- CRUD completo de tareas: crear, ver, editar, completar y eliminar.
- Eliminación con opción de **deshacer**.
- Fecha de entrega manual y opcional por tarea.
- Descripción en **Markdown** con editor y vista previa.
- Pantalla de detalle separada con la descripción renderizada y la fecha de
  entrega.
- Filtros por todas, pendientes, completadas y vencidas.
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
  main.dart                         # Arranque, migración y limpieza de adjuntos
  app.dart                          # MaterialApp, tema, locale y TaskScope
  core/
    theme/app_theme.dart
    theme/tag_palette.dart          # Colores estables de las etiquetas
    utils/date_formatters.dart
    utils/file_size.dart
  features/tasks/
    domain/                         # Task, listas, etiquetas, adjuntos y vistas
    data/                           # Repositorio del workspace y adjuntos
    application/                    # TaskStore (ChangeNotifier) y TaskScope
    presentation/                   # Sidebar, contenido, formulario, detalle, etc.
test/
  features/tasks/                   # Tests de dominio, datos, estado y widgets
  support/                          # Repositorio y servicios simulados
```

## Persistencia y sincronización futura

El workspace completo (tareas, listas y etiquetas) se guarda como un único
documento JSON versionado en `shared_preferences` bajo la clave `workspace_v2`.
El acceso está detrás de la interfaz `WorkspaceRepository`, por lo que se puede
añadir en el futuro un repositorio con sincronización (Google Tasks, Nextcloud,
etc.) sin cambiar la interfaz de usuario. Los modelos ya incluyen IDs estables
(`uuid`) y `updatedAt` para facilitar la resolución de conflictos.

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
