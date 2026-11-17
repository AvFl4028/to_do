# Registro de planificación — Mis tareas

## 2026-11-16 19:18 CST — Plan de nuevas funciones

> Estado: **implementado y verificado** el 2026-11-16 19:43 CST.
>
> Este documento conserva el plan original acordado y sirve como registro de la
> funcionalidad añadida.

### Objetivo

Añadir cuatro mejoras a la aplicación:

1. **Hora de entrega** opcional, además del día de entrega.
2. **Panel derecho en escritorio** para abrir el detalle de una tarea sin
   abandonar la pantalla completa.
3. **Redimensionado de los sidebars** en escritorio: barra de navegación
   izquierda y panel derecho.
4. **Pantalla de configuración** para tema, animaciones y duración de las
   animaciones.

### Decisiones confirmadas

- En escritorio, al abrir una tarea se usa un panel lateral derecho.
- El formulario de edición se abre dentro del mismo panel derecho.
- La hora de entrega **no** cambia el estado «Vencida» ni los filtros, que
  siguen siendo por día.
- Si una tarea vence hoy, tiene hora y esa hora ya pasó, se muestra un aviso
  pequeño y discreto de «Hora pasada», sin marcarla como vencida.
- El tema se puede elegir entre **Claro**, **Oscuro** y **Sistema**.
- La duración de las animaciones se ajusta con un control deslizante.
- Los dos sidebars de escritorio se pueden redimensionar a voluntad.
- Los anchos de los sidebars se guardan al soltar el arrastre y se restauran al
  volver a abrir la aplicación.

---

## 1. Hora de entrega

### Modelo de datos

- Añadir `dueTimeMinutes` (`int?`, rango 0–1439) a `Task`.
- Serialización en `workspace_v2` como `"dueTime": "14:30"`.
- Compatibilidad hacia atrás: si el campo no existe, `dueTimeMinutes` queda
  `null`.
- La hora solo puede existir si hay fecha de entrega. Si se elimina la fecha,
  se elimina también la hora.
- Actualizar `copyWith`, igualdad, `hashCode`, `fromJson` y `toJson`.
- No se cambia la clave de persistencia `workspace_v2`.

### Formulario de tarea

- Añadir la fila **Hora de entrega** debajo de **Fecha de entrega**.
- Abrir un selector de hora en español con formato de 24 horas.
- Deshabilitar la fila mientras no haya fecha, con el texto
  «Elige primero una fecha».
- Mostrar «Sin hora» cuando no haya hora seleccionada.
- Permitir quitar la hora con un botón.
- Al quitar la fecha, limpiar automáticamente la hora.
- Incluir la hora en `TaskFormResult` y en la detección de cambios sin guardar.

### Visualización

- El badge de vencimiento mostrará fecha y hora cuando exista hora:
  - `Hoy · 14:30`
  - `Mañana · 09:00`
  - `12 nov 2026 · 18:00`
- En la pantalla de detalle se añade una fila de hora editable junto a la fecha.
- Orden de tareas:
  - Primero por fecha.
  - Después por hora ascendente.
  - Las tareas sin hora se colocan antes que las que tienen hora dentro del
    mismo día.
  - Las tareas sin fecha siguen al final, como hasta ahora.

### Vencimiento y aviso de hora pasada

- El estado **Vencida**, el filtro de vencidas y los contadores siguen
  calculándose solo por día.
- Nueva comprobación `isTimePast(task)` en `TaskStore`, usando el reloj
  inyectado del store:
  - Solo para tareas pendientes.
  - Solo si la fecha de entrega es hoy.
  - Solo si hay hora y la hora actual ya la superó.
- En ese caso se muestra un aviso visual pequeño **«Hora pasada»**:
  - Color ámbar/terciario, no rojo.
  - No cambia el estado de la tarea.
  - No altera filtros ni contadores.
  - Aparece en la tarjeta de la tarea y en el detalle.
- Si la fecha ya pasó, se mantiene la etiqueta **Vencida** actual.

---

## 2. Panel derecho en escritorio

### Comportamiento

- A partir del ancho de escritorio actual (≥ 1000 px), pulsar una tarea no
  abre una página completa: muestra un panel fijo a la derecha.
- La lista principal y la sidebar izquierda siguen visibles.
- Se puede cambiar de tarea sin cerrar el panel.
- El panel tiene cabecera propia y botón de cerrar.
- Al cambiar de vista desde la sidebar, el panel se cierra.
- Si la tarea seleccionada se elimina, el panel se cierra.
- En móvil y ventanas estrechas se mantiene la navegación actual a página
  completa.
- **Nueva tarea** seguirá abriéndose a pantalla completa. Se puede ampliar más
  adelante si se quiere crear también desde el panel.

### Edición dentro del panel

- El detalle se muestra en el panel.
- Al pulsar **Editar**, el panel cambia al formulario de edición.
- Al guardar, se actualiza la tarea y el panel vuelve al detalle.
- Al cancelar o descartar cambios, se vuelve al detalle.
- Se reutiliza el mismo formulario y la misma lógica de adjuntos que en la
  página completa.
- El formulario se extrae para poder mostrarse:
  - Como página completa en móvil.
  - Embebido en el panel en escritorio.

### Estructura prevista

- `TaskDetailPage` gana un modo embebido (`embedded`).
- Nuevo `TaskDetailPanel` que controla:
  - Tarea seleccionada.
  - Modo detalle / edición.
  - Cierre del panel.
  - Ancho del panel.
- `TaskListContent` recibe un callback opcional `onOpenTask`:
  - En escritorio selecciona la tarea en el panel.
  - En móvil mantiene el `Navigator.push` actual.
- `TasksHomePage` guarda el `taskId` seleccionado y decide si mostrar el panel.

### Tamaño del panel derecho

- Ancho mínimo: 320 px.
- Ancho máximo: 560 px.
- Ancho por defecto: 400 px.
- Ancho adaptativo según el tamaño de la ventana.
- La lista central conserva un ancho mínimo para que el diseño no se rompa.

---

## 3. Redimensionado de sidebars en escritorio

### Sidebar izquierda (navegación)

- Zona de arrastre sobre el divisor vertical.
- Ancho mínimo: 240 px.
- Ancho máximo: 420 px.
- Ancho por defecto: 300 px.

### Panel derecho (detalle/edición)

- Zona de arrastre en su borde izquierdo.
- Ancho mínimo: 320 px.
- Ancho máximo: 560 px.
- Ancho por defecto: 400 px.
- El formulario de edición dentro del panel respeta el ancho elegido.

### Interacción

- Cursor `resizeLeftRight` al pasar sobre la zona de arrastre.
- Tooltip «Arrastra para cambiar el tamaño».
- Doble clic sobre el divisor restablece el ancho por defecto.
- Solo en escritorio; en móvil no cambia nada.
- Límites dinámicos:
  - La lista central siempre conserva un ancho mínimo.
  - Si la ventana se reduce, los paneles se recortan visualmente sin romper la
    interfaz.
  - Al arrastrar se respetan los límites disponibles.

### Persistencia

- Guardar `sidebarWidth` y `panelWidth` en `settings_v1`.
- Guardar al soltar el arrastre, no en cada píxel.
- Restaurar los anchos al arrancar.
- Si el valor guardado no es válido, usar el valor por defecto.

### Implementación

- Widget reutilizable `ResizeHandle` para ambos divisores.
- Estado de anchos en `TasksHomePage`.
- Sincronización con `SettingsController`.
- El ancho del `Drawer` móvil no se ve afectado.

---

## 4. Pantalla de configuración

### Ajustes

- **Tema**: Claro / Oscuro / Sistema.
- **Animaciones**: activadas / desactivadas.
- **Duración de animaciones**: 100–600 ms, por defecto 250 ms.
- **Anchos de sidebars**: se guardan junto con el resto de ajustes, sin
  necesidad de exponerlos en la pantalla de configuración.

### Persistencia

- Nueva clave `settings_v1` en `shared_preferences`.
- Modelo `AppSettings`:
  - `themePreference`
  - `animationsEnabled`
  - `animationDurationMs`
  - `sidebarWidth`
  - `panelWidth`
- Repositorio de ajustes con interfaz para poder usar un repositorio en
  memoria en las pruebas.
- `SettingsController` + `SettingsScope`.
- Cargar los ajustes antes de `runApp` para evitar parpadeos de tema.

### Interfaz

- Acceso desde un botón de engranaje en la AppBar, disponible en escritorio y
  móvil.
- Pantalla `SettingsPage` con dos secciones:
  - **Apariencia**: selector Claro / Oscuro / Sistema.
  - **Animaciones**: interruptor y control deslizante de duración.
- El control deslizante se deshabilita cuando las animaciones están apagadas.
- Mostrar el valor actual en milisegundos.

### Qué controla la configuración de animaciones

- Transiciones entre pantallas.
- Animación del cambio de tema.
- Apertura/cierre del panel derecho.
- Cambio entre detalle y edición dentro del panel.
- Diálogos de la aplicación.
- Con animaciones desactivadas:
  - Duración cero.
  - `MediaQuery.disableAnimations`.
  - Sin efecto ripple.

---

## 5. Archivos previstos

### Nuevos

- `lib/core/settings/app_settings.dart`
- `lib/core/settings/settings_controller.dart`
- `lib/core/settings/settings_repository.dart`
- `lib/core/settings/shared_prefs_settings_repository.dart`
- `lib/core/settings/settings_scope.dart`
- `lib/core/theme/app_motion.dart`
- `lib/features/settings/presentation/settings_page.dart`
- `lib/features/tasks/presentation/widgets/resize_handle.dart`
- `lib/features/tasks/presentation/widgets/task_detail_panel.dart`

### Modificados

- `lib/features/tasks/domain/task.dart`
- `lib/core/utils/date_formatters.dart`
- `lib/features/tasks/application/task_store.dart`
- `lib/features/tasks/presentation/task_form_page.dart`
- `lib/features/tasks/presentation/task_detail_page.dart`
- `lib/features/tasks/presentation/task_list_page.dart`
- `lib/features/tasks/presentation/tasks_home_page.dart`
- `lib/features/tasks/presentation/widgets/task_tile.dart`
- `lib/features/tasks/presentation/widgets/due_date_badge.dart`
- `lib/features/tasks/presentation/widgets/due_date_picker.dart`
- `lib/app.dart`
- `lib/main.dart`
- `lib/core/theme/app_theme.dart`
- `README.md`

### Pruebas

- `test/features/tasks/domain/task_test.dart`
- `test/features/tasks/application/task_store_test.dart`
- `test/features/tasks/presentation/task_form_page_test.dart`
- `test/features/tasks/presentation/task_detail_page_test.dart`
- `test/features/tasks/presentation/tasks_home_page_test.dart`
- Nuevas pruebas de ajustes en `test/core/settings/` o
  `test/features/settings/`.
- Repositorio de ajustes en memoria en `test/support/`.
- Actualizar `test/support/test_harness.dart` para inyectar ajustes.

---

## 6. Pruebas previstas

### Dominio y store

- Serialización y lectura de `dueTime`.
- Compatibilidad con tareas antiguas sin hora.
- Limpieza de la hora al quitar la fecha.
- Orden por fecha y hora.
- Crear y editar tareas con hora.
- `setDueTime` y `setDueDate`.
- Vencimiento por día sin cambios.
- `isTimePast` con reloj inyectado.
- Aviso «Hora pasada» solo para tareas de hoy con hora superada.

### Interfaz

- Campo de hora deshabilitado sin fecha.
- Hora precargada al editar.
- Panel derecho en escritorio:
  - Abre el detalle.
  - No abre página completa.
  - Cierra el panel.
  - Cambia de tarea.
  - Edita dentro del panel.
  - Se cierra al cambiar de vista o eliminar la tarea.
- Móvil sigue abriendo página completa.
- Redimensionado:
  - Arrastrar la sidebar izquierda.
  - Arrastrar el panel derecho.
  - Doble clic restablece.
  - Límites mínimos y máximos.
  - Persistencia de anchos.
- Configuración:
  - Cambio de tema.
  - Interruptor de animaciones.
  - Slider de duración.
  - Persistencia y recarga.
  - Valor por defecto si los datos son inválidos.

### Verificación final

- `dart format`
- `flutter analyze`
- `flutter test`
- Builds:
  - `flutter build linux --debug`
  - `flutter build apk --debug`
  - `flutter build web`
- Comprobación visual:
  - Hora de entrega.
  - Aviso «Hora pasada».
  - Panel derecho.
  - Redimensionado de ambos sidebars.
  - Tema claro/oscuro.
  - Animaciones activadas/desactivadas y duración.

---

## 7. Fuera de alcance por ahora

- Crear tareas nuevas directamente dentro del panel derecho.
- Sincronización remota de ajustes o tareas.
- Redimensionado de la sidebar en móvil.
- Cambiar el orden de las tareas manualmente.
- Notificaciones o recordatorios automáticos por hora de entrega.
