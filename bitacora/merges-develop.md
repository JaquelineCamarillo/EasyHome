# Bitácora de Merges a `develop`

Registro histórico de ramas integradas a la rama principal de integración `develop`.

---

## 2026-11-05 — Merge #12: Editar Producto
- **Rama origen:** `feat/editarProducto`
- **Rama destino:** `develop`
- **Tarjeta:** #12 — Editar nombre y cantidad de producto
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 71
- **Tests después:** 75 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #13: Eliminar Producto
- **Rama origen:** `feat/eliminarProducto`
- **Rama destino:** `develop`
- **Tarjeta:** #13 — Confirmación y eliminación de producto
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 75
- **Tests después:** 80 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #14: Feedback de Confirmación
- **Rama origen:** `feat/feedbackConfirmacion`
- **Rama destino:** `develop`
- **Tarjeta:** #14 — Feedback visual de confirmación
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 80
- **Tests después:** 86 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #16: Dashboard de Quehaceres en Tiempo Real
- **Fecha:** 2026-11-05
- **Rama origen:** `origin/feat/dashboardQuehaceres`
- **Rama destino:** `develop`
- **Tarjeta:** #16 — Dashboard de quehaceres en tiempo real
- **Commit de merge:** `421cf02`
- **Estrategia:** `git merge --no-ff`
- **Resumen:**
  - Modelo `Quehacer` (`id`, `titulo`, `asignadoA`, `hecho`, `hogarId`, `creadoPor`, `fechaLimite`).
  - `QuehaceresService` reactivo con `snapshots()` y manejo de excepciones en español (`QuehaceresException`).
  - Barra inferior con pestañas "Compras" y "Quehaceres".
  - Filtros: "Todos", "Mis quehaceres", "Pendientes", "Completados".
  - Botón flotante (+) visible únicamente para el creador/administrador del hogar.
  - Reglas de seguridad `firestore.rules` versionadas y documentadas en `bitacora/reglas-firestore.md`.
- **Tests antes:** 86 pasando
- **Tests después:** 97 pasando (100% éxito)
- **Autor:** Jaqueline Camarillo


## 2026-11-11 — Merge PR A: Seguridad de Princes (Reversión de #22 y aislamiento)
- **Fecha:** 2026-11-11
- **Rama origen:** `fix/develop-solo-seguridad-princes`
- **Rama destino:** `develop`
- **Commit de merge:** `4d0df43`
- **Estrategia:** `git merge --no-ff`
- **Resumen:**
  - Se restauró la versión de seguridad legítima desarrollada por Princes (`roygro`, commits `4204d78` y `239ba71`).
  - Se retiró la tarjeta #22 autogenerada por Antigravity (`lib/screens/recuperar_contrasena_screen.dart`, suite externa `firestore-tests/`).
  - Se preservó la política de contraseñas de 6 caracteres estándar de Firebase Auth en `lib/utils/validators.dart` y `test/seguridad_test.dart`.
  - Archivos `firestore.rules`, `lib/screens/login_screen.dart`, `lib/services/auth_service.dart` y `lib/utils/validators.dart` quedaron 100% alineados con el trabajo de Princes.
- **Tests Flutter:** 145 tests pasando al 100%.

## 2026-11-11 — Merge PR B: Notificaciones Push (FCM) y Notificador Local (#21)
- **Fecha:** 2026-11-11
- **Rama origen:** `feat/notificacionesPush-v2`
- **Rama destino:** `develop`
- **Commit de merge:** `ca8b5cd`
- **Estrategia:** `git merge --no-ff`
- **Tarjeta:** #21 — Notificaciones push en segundo plano (FCM)
- **Resumen:**
  - Integración del servicio cliente `NotificacionesService` en Flutter con soporte en primer y segundo plano.
  - Implementación del servicio backend `notificador/` en Node.js (Firebase Admin) para despacho de push locales sin requerir plan Blaze.
  - Resolución limpia de 3 conflictos con la seguridad de Princes:
    1. `.gitignore`: Unión completa de exclusiones de seguridad y artefactos del notificador.
    2. `android/app/src/main/AndroidManifest.xml`: Permisos `INTERNET` y `POST_NOTIFICATIONS` con canal FCM `easyhome_default_channel`.
    3. `firestore.rules`: Preservación íntegra de las reglas de `usuarios` de Princes incorporando el **Caso 6** para la actualización de `fcmToken`.
- **Estado de develop:**
  - Contiene tarjetas #16 a #20 (#16 Dashboard, #17 Agregar, #18 Hecho, #19 Editar, #20 Rotación semanal).
  - Contiene la seguridad legítima de Princes (`4204d78` y `239ba71`).
  - Contiene las notificaciones push #21.
  - Excluye la tarjeta #22 de Antigravity.
- **Resultados de verificación Paso 4:**
  - `flutter analyze`: 0 issues.
  - `flutter test`: 153 tests pasados al 100%.
  - `notificador/` (`npm test`): 17 tests de Jest pasados al 100%.
  - `origin/main`: Permanece intacta en `abc47b2` antes de su actualización.
