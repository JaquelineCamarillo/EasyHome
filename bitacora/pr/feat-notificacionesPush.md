# PR: feat(notificaciones): notificaciones push en segundo plano (FCM) (#21)

**Base:** `develop`  
**Rama:** `feat/notificacionesPush`

---

## Resumen
Implementación integral del sistema de **notificaciones push en segundo plano (Firebase Cloud Messaging - FCM)** para EasyHome (#21). Permite a los integrantes del hogar recibir notificaciones automáticas cuando se agrega un nuevo producto a la lista de compras (notificando a los demás miembros y excluyendo al autor) o cuando se les asigna un nuevo quehacer (notificando exclusivamente al responsable asignado).

Para garantizar viabilidad operativa inmediata sin costo ni tarjeta de crédito (el equipo no cuenta con plan Blaze para Cloud Functions), se diseñó un servicio de **notificador local en Node.js** (`notificador/`) basado en Firebase Admin y Firestore en tiempo real, complementado con el cliente Flutter totalmente integrado y probado con fakes.

---

## Cambios realizados
1. **Cliente Flutter — Servicio de Notificaciones (`lib/services/notificaciones_service.dart`)**:
   - `inicializar(uid)`: Solicita permisos del sistema (incluyendo `POST_NOTIFICATIONS` para Android 13+), obtiene el token FCM, lo registra en `usuarios/{uid}.fcmToken` y escucha renovaciones con `onTokenRefresh`.
   - `limpiarToken(uid)`: Al cerrar sesión borra `fcmToken` de Firestore y revoca el token local con `deleteToken()`.
   - Manejo de notificaciones en primer plano vía `AppFeedback` y redirección automática al tocar la notificación.
   - Totalmente inyectable y probado con fakes sin inicializar Firebase real.
2. **Ciclo de vida y cierre de sesión (`lib/screens/dashboard_screen.dart`, `lib/services/hogar_service.dart`)**:
   - Inicialización automática al cargar el dashboard con usuario autenticado.
   - Inyección de `NotificacionesService` en `HogarService.cerrarSesion()` para garantizar la remoción del token.
   - Eliminación del ruido `[core/no-app] No Firebase App '[DEFAULT]'` en la suite de pruebas mediante inyección de fakes seguros.
3. **Manejador de segundo plano (`lib/main.dart`)**:
   - Handler de nivel superior con anotación `@pragma('vm:entry-point')` registrado con `FirebaseMessaging.onBackgroundMessage`.
4. **Configuración de plataformas (`android/`, `web/`)**:
   - `android/app/src/main/AndroidManifest.xml`: Permiso `POST_NOTIFICATIONS` y canal predeterminado `easyhome_default_channel`.
   - `web/firebase-messaging-sw.js`: Service worker configurado con las credenciales públicas del proyecto; soporte para clave VAPID inyectable por `--dart-define=FCM_VAPID_KEY=...`.
5. **Notificador Local (`notificador/`)**:
   - Módulo en Node.js (`notificador/index.js`, `src/destinatarios.js`, `src/mensajes.js`, `src/limpiezaTokens.js`) para escuchar cambios en Firestore en tiempo real y emitir push con `sendEachForMulticast`.
   - Excluye al autor de productos y auto-asignaciones de quehaceres.
   - Limpieza automática de tokens desregistrados/inválidos en Firestore sin exponer tokens en logs.
   - 17 pruebas unitarias con Jest (`notificador/test/`) ejecutables con `npm test`.
   - Instrucciones completas en `notificador/README.md`.
6. **Reglas de seguridad y modelo de datos (`firestore.rules`, `bitacora/`)**:
   - Actualización de `firestore.rules` permitiendo a cada usuario modificar su propio campo `fcmToken`.
   - Actualización de `bitacora/modelo-datos-firestore.md` y `bitacora/reglas-firestore.md`.
7. **Pruebas automatizadas**:
   - 8 pruebas unitarias nuevas para `NotificacionesService` (`test/notificaciones_service_test.dart`).
   - 142 pruebas en Flutter pasando al 100% (línea base 134 + 8 nuevas).

---

## Cómo probar
1. **Pruebas automatizadas Flutter:**
   ```bash
   flutter test
   ```
   Verificar que pasen los 142 tests sin advertencias ni fallos.
2. **Pruebas automatizadas del notificador:**
   ```bash
   cd notificador
   npm test
   ```
   Verificar que pasen los 17 tests de Jest.
3. **Prueba manual de notificaciones push:**
   - Seguir la guía detallada en [bitacora/reporte-push.md](file:///C:/easyhome/bitacora/reporte-push.md).
   - Generar la llave de cuenta de servicio en Firebase Console y colocarla en `notificador/serviceAccountKey.json`.
   - Correr `node notificador/index.js` y probar con dos dispositivos/cuentas la creación de productos y asignación de tareas.

---

## Criterios de aceptación cumplidos
- [x] Recibir notificación cuando se agrega un producto al hogar.
- [x] Notificar a los demás integrantes del hogar al agregar un producto (excluyendo al autor).
- [x] Recibir notificación cuando se asigna un quehacer nuevo.
- [x] Notificar solo al integrante asignado al crear un quehacer (no notificar si se auto-asigna).
- [x] Funciona con la app en segundo plano (vía notificador local + FCM).
- [x] Token guardado en `usuarios/{uid}.fcmToken` y borrado en logout.
- [x] Reglas de Firestore versionadas y documentadas.
- [x] Arquitectura y decisiones documentadas en `bitacora/decisiones-notificaciones.md`.
