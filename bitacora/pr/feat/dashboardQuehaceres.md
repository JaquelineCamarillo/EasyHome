# PR: feat(quehaceres): dashboard de quehaceres en tiempo real (#16)

**Base:** `develop`  
**Rama:** `feat/dashboardQuehaceres`

---

## Resumen
Implementación del módulo y vista de Dashboard de Quehaceres en tiempo real dentro de EasyHome (#16). Permite a los integrantes del hogar consultar sus tareas y todas las del hogar, observar los estados (Pendiente/Hecho), el responsable asignado y la fecha límite, manteniendo intacto el módulo de compras y sus pruebas.

---

## Cambios realizados
1. **Modelo `Quehacer` (`lib/models/quehacer.dart`)**:
   - Campos: `id`, `hogarId`, `titulo`, `asignadoA`, `hecho`, `creadoPor`, `fechaLimite`.
   - Métodos `fromMap`, `toMap` y `copyWith`.
2. **Servicio `QuehaceresService` (`lib/services/quehaceres_service.dart`)**:
   - `observarQuehaceres(hogarId)` con ordenamiento reactivo en memoria: pendientes primero, luego por fecha límite y título alfabético.
   - Manejo de excepciones amigables con `QuehaceresException`.
3. **Dashboard reactivo (`lib/screens/dashboard_screen.dart`)**:
   - Integración de barra inferior (`BottomNavigationBar`) para alternar entre "Compras" y "Quehaceres".
   - Filtros de segmento: "Mis quehaceres" y "Todos los del hogar".
   - Cruce dinámico de `asignadoA` con `HogarService.observarIntegrantes` para obtener el nombre del responsable sin duplicar datos en Firestore.
   - Indicador visual y textual del estado (`Pendiente` / `Hecho`).
   - Botón flotante (+) visible únicamente para administradores (`esAdministrador == true`) que navega a `AppRoutes.agregarQuehacer`.
   - Estado vacío amigable: `"Aún no hay quehaceres"`.
4. **Reglas de seguridad y documentación (`firestore.rules` & `bitacora/reglas-firestore.md`)**:
   - Versión formal de reglas de seguridad en Firestore para la colección `quehaceres`.
5. **Rutas y configuración**:
   - Ruta `/agregar-quehacer` registrada en `AppRoutes` con pantalla placeholder "Próximamente".
6. **Pruebas automatizadas**:
   - Pruebas unitarias para el modelo `Quehacer` (`test/quehacer_test.dart`).
   - Pruebas unitarias para el servicio `QuehaceresService` (`test/quehaceres_service_test.dart`).
   - Pruebas de widget para el dashboard de quehaceres (`test/dashboard_quehaceres_test.dart`).

---

## Cómo probar
1. Ejecutar `flutter test` y verificar que todas las pruebas pasen (97+ tests verdes).
2. Abrir la app e iniciar sesión con un usuario perteneciente a un hogar.
3. En la barra inferior, pulsar en la pestaña **Quehaceres**.
4. Alternar entre "Mis quehaceres" y "Todos los del hogar".
5. Si el usuario es administrador, verificar la presencia del botón (+) y pulsar para navegar al placeholder de agregar quehacer.
6. Si el usuario no es administrador, comprobar que el botón (+) no aparece.

---

## Criterios de aceptación cumplidos
- [x] Sección de Quehaceres agregada al dashboard sin romper Compras ni sus pruebas.
- [x] Lista en tiempo real con título, responsable y estado (icono + color + texto) y fecha límite.
- [x] Filtro de segmentos funcional ("Mis quehaceres" y "Todos los del hogar").
- [x] FAB visible solo para `esAdministrador: true`.
- [x] Estado vacío amable ("Aún no hay quehaceres").
- [x] Decisión de nombre del responsable documentada en `bitacora/decisiones-quehaceres.md`.
