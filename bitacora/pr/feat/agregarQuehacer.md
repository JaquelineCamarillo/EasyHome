# PR: feat(quehaceres): formulario agregar quehacer (#17)

**Base:** `feat/dashboardQuehaceres` (o `develop`)  
**Rama:** `feat/agregarQuehacer`

---

## Resumen
Implementación del formulario para la creación de quehaceres asignados a integrantes del hogar (#17). Restringe la creación exclusivamente a usuarios administradores del hogar, valida la integridad de los datos en interfaz y servicio, y ofrece soporte opcional para fecha límite.

---

## Cambios realizados
1. **Formulario de creación (`lib/screens/agregar_quehacer_screen.dart`)**:
   - Reemplazo del placeholder previo por el formulario completo.
   - Campo para el título del quehacer (`TextFormField`, obligatorio, no solo espacios).
   - Menú desplegable (`DropdownButtonFormField`) de integrantes del hogar.
   - Selector interactivo de fecha opcional (`showDatePicker`) con opción para remover la fecha.
   - Botón "Crear quehacer" con indicador de carga y feedback flotante (`AppFeedback`).
   - Bloqueo estricto para no administradores: muestra el mensaje exacto `"Solo el administrador puede crear quehaceres"`.
2. **Validaciones (`lib/utils/validators.dart`)**:
   - Incorporación de `Validators.tituloQuehacer` y `Validators.titulo`.
   - Pruebas unitarias correspondientes en `test/validators_test.dart`.
3. **Servicio y modelo (`lib/services/quehaceres_service.dart`)**:
   - Método `crearQuehacer` validando existencia y pertenencia del integrante al mismo hogar, así como permisos de administrador.
4. **Pruebas automatizadas**:
   - Pruebas de widget en `test/agregar_quehacer_screen_test.dart` verificando: validación de título vacío o espacios, mensaje informativo para no administradores, creación exitosa con fecha nula, selección/eliminación de fecha y rechazo de responsables ajenos al hogar.

---

## Cómo probar
1. Ejecutar `flutter test` (104 tests verdes).
2. Como administrador, pulsar el botón (+) en la pestaña de Quehaceres.
3. Ingresar un título y seleccionar un integrante de la lista.
4. (Opcional) Elegir una fecha límite con el calendario o dejarla vacía.
5. Presionar "Crear quehacer"; verificar mensaje de confirmación y retorno al dashboard donde aparece la tarea en tiempo real.
6. Si se ingresa con una cuenta que no es administradora, verificar que no se muestra el formulario sino el mensaje `"Solo el administrador puede crear quehaceres"`.

---

## Criterios de aceptación cumplidos
- [x] Solo administradores pueden crear quehaceres (mensaje exacto para no administradores).
- [x] Validación de título y pertenencia del integrante en UI y servicio.
- [x] Soporte para fecha límite opcional y removible.
- [x] Feedback visual con `AppFeedback` y navegación automática.
