# PR: feat(quehaceres): marcar quehacer como hecho (#18)

**Base:** `feat/agregarQuehacer` (o `develop`)  
**Rama:** `feat/marcarQuehacerHecho`

---

## Resumen
Implementación de la funcionalidad para marcar quehaceres como completados (y alternar su estado / toggle) en tiempo real (#18). Se garantiza por diseño que únicamente el integrante responsable pueda cambiar el estado de su tarea asignada, mostrando a cualquier otro integrante un aviso informativo amigable con el nombre del responsable y manteniendo el control interactivo deshabilitado.

---

## Cambios realizados
1. **Interfaz interactiva en Dashboard (`lib/screens/dashboard_screen.dart`)**:
   - Checkbox reactivo y soporte de toque en la tarjeta para alternar entre `hecho: true` y `hecho: false`.
   - Control habilitado solo para el usuario asignado (`asignadoA == uidActual`).
   - Para integrantes no responsables: el checkbox se presenta deshabilitado y, al tocar la tarjeta o el control, se muestra una notificación informativa amigable: `"Solo <nombre> puede marcar este quehacer"`.
   - Notificación flotante de éxito (`"Quehacer completado"` / `"Quehacer pendiente"`).
2. **Validación en el servicio (`lib/services/quehaceres_service.dart`)**:
   - El método `marcarHecho` verifica rigurosamente que el `uidActual` coincida con el `asignadoA` del quehacer, lanzando `QuehaceresException` en caso contrario.
3. **Decisión documentada (`bitacora/decisiones-quehaceres.md`)**:
   - Justificación de soporte para desmarcar tareas (toggle bidireccional) ante errores de captura.
4. **Pruebas automatizadas**:
   - Pruebas en `test/marcar_quehacer_hecho_test.dart` verificando:
     * El responsable puede marcar y desmarcar (toggle) con llamada al servicio y cambio de estado.
     * No responsables observan el control deshabilitado y reciben el mensaje con el nombre correspondiente al intentar interactuar.
     * El servicio rechaza peticiones con `uid` diferente.

---

## Cómo probar
1. Ejecutar `flutter test` (107 tests verdes).
2. Iniciar sesión con un usuario asignado a un quehacer pendiente y pulsar el checkbox o la tarjeta; verificar que pasa a estado `Hecho`.
3. Volver a presionar para verificar que regresa al estado `Pendiente`.
4. Con una cuenta distinta (no responsable de ese quehacer), intentar marcar la tarea y verificar que el checkbox está deshabilitado y aparece el mensaje: `"Solo <nombre> puede marcar este quehacer"`.

---

## Criterios de aceptación cumplidos
- [x] Checkbox / tap funcional para cambiar estado a hecho y desmarcar.
- [x] Exclusividad para el responsable: no responsables ven control deshabilitado y mensaje exacto `"Solo <nombre> puede marcar este quehacer"`.
- [x] Doble validación en UI y en el servicio.
- [x] Actualización en vivo reactiva vía Firestore snapshots.
