# PR: feat(quehaceres): editar, reasignar y eliminar quehacer (#19)

**Base:** `feat/marcarQuehacerHecho` (o `develop`)  
**Rama:** `feat/editarQuehacer`

---

## Resumen
Implementación de la gestión administrativa completa de quehaceres (#19). Permite a los administradores del hogar editar título y fecha límite, reasignar responsables a otros integrantes y eliminar tareas con diálogo de confirmación, tanto desde el menú contextual (⋮) como mediante pulsación prolongada (long-press). Se restringe estrictamente a administradores, garantizando que los miembros sin permiso reciban el mensaje amigable de restricción.

---

## Cambios realizados
1. **Menú de opciones administrativas (`lib/screens/dashboard_screen.dart`)**:
   - Menú accesible mediante pulsación prolongada (long-press) sobre la tarjeta del quehacer y mediante icono de opciones contextuales (⋮).
   - Opciones: **Editar**, **Reasignar** y **Eliminar**.
   - Visibilidad exclusiva: el botón ⋮ solo se muestra si el usuario es administrador (`esAdministrador == true`).
   - Si un usuario no administrador intenta disparar las opciones (ej. mediante long-press), se muestra el mensaje de restricción: `"No tienes permiso para esta acción"`.
2. **Edición (`_mostrarFormularioEditarQuehacer`)**:
   - Modal inferior con campos precargados con los datos actuales del quehacer (título y fecha límite).
   - Selector interactivo de fecha con opción para conservarla, cambiarla o removerla.
   - Guardado atómico en Firestore mediante `QuehaceresService.actualizarQuehacer`.
3. **Reasignación (`_mostrarDialogoReasignarQuehacer`)**:
   - Diálogo con selector de integrantes del hogar precargado con el responsable actual.
   - Actualización del campo `asignadoA` en tiempo real mediante `QuehaceresService.reasignarQuehacer`.
4. **Eliminación (`_confirmarEliminarQuehacer`)**:
   - Diálogo modal con confirmación explícita (`"¿Seguro que quieres eliminar este quehacer...?"`).
   - Cancelar aborta la operación sin modificar la base de datos; confirmar elimina el documento en Firestore mediante `QuehaceresService.eliminarQuehacer`.
5. **Pruebas automatizadas**:
   - Pruebas en `test/editar_quehacer_test.dart` verificando:
     * Menú muestra las 3 opciones para administradores.
     * Editar precarga título y fecha correctamente y persiste los cambios.
     * Reasignar actualiza `asignadoA` al nuevo integrante.
     * Diálogo de confirmación de eliminación (cancelar no borra, confirmar elimina).
     * No-administradores no ven el botón y reciben el mensaje informativo `"No tienes permiso para esta acción"`.

---

## Cómo probar
1. Ejecutar `flutter test` (112 tests verdes).
2. Como administrador del hogar, ubicar un quehacer en la lista y presionar el botón de tres puntos (⋮) o mantener presionada la tarjeta.
3. Probar **Editar**: modificar el título o fecha límite y presionar "Guardar cambios". Comprobar la actualización en pantalla.
4. Probar **Reasignar**: seleccionar otro integrante del hogar y presionar "Reasignar". Comprobar que el nombre del responsable cambia de inmediato.
5. Probar **Eliminar**: abrir el diálogo, pulsar "Cancelar" (la tarea permanece) y luego "Eliminar" (la tarea desaparece en tiempo real).
6. Con una cuenta no administradora, comprobar que el botón (⋮) no está visible y que la pulsación prolongada muestra el aviso `"No tienes permiso para esta acción"`.

---

## Criterios de aceptación cumplidos
- [x] Menú de 3 opciones (Editar, Reasignar, Eliminar) accesible por botón e interacción táctil.
- [x] Edición con precarga de datos y selector de fecha.
- [x] Reasignación de integrante validando pertenencia al hogar.
- [x] Diálogo de confirmación antes de eliminar.
- [x] Restricción estricta para no administradores con mensaje `"No tienes permiso para esta acción"`.
