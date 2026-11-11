# PR: feat(notificaciones): notificaciones push en segundo plano (FCM) (#21)

> [!IMPORTANT]
> **ORDEN DE FUSIÓN REQUERIDO:**
> **Fusionar primero el PR A (`fix/develop-solo-seguridad-princes`)**. Este PR B (`feat/notificacionesPush-v2`) está apilado sobre la versión de seguridad legítima de Princes y resuelve limpiamente los 3 conflictos entre ambas tarjetas.

**Base:** `develop`  
**Rama:** `feat/notificacionesPush-v2`  

---

## Resumen
Implementación integral del sistema de **notificaciones push en segundo plano (Firebase Cloud Messaging - FCM)** para EasyHome (#21), montado sobre la arquitectura de seguridad legítima de Princes (`roygro`).

Permite a los integrantes del hogar recibir notificaciones automáticas cuando se agrega un nuevo producto a la lista de compras (notificando a los demás miembros y excluyendo al autor) o cuando se les asigna un nuevo quehacer (notificando exclusivamente al responsable asignado).

Para garantizar viabilidad operativa inmediata sin costo ni tarjeta de crédito (sin requerir plan Blaze para Cloud Functions), se incluye el servicio de **notificador local en Node.js** (`notificador/`) basado en Firebase Admin y listeners de Firestore en tiempo real, complementado con el cliente Flutter totalmente integrado y probado con fakes.

---

## Resolución de conflictos con la rama de seguridad de Princes
Al integrar la tarjeta #21 sobre la seguridad de Princes, se resolvieron de forma quirúrgica exactamente 3 conflictos:

1. **`.gitignore`**:
   - Se mantuvo la unión estricta de ambos lados sin duplicaciones.
   - Seguridad (Princes): `.env`, `.env.*`, `*.env`, `*.jks`, `*.keystore`, `key.properties`, `local.properties`, credenciales de Firebase.
   - Notificaciones (#21): `notificador/serviceAccountKey.json`, `notificador/.env`, `notificador/node_modules/`, `**/serviceAccount*.json`, `service-account*.json`, registrants de plugins Flutter.
2. **`android/app/src/main/AndroidManifest.xml`**:
   - Se conservó el principio de privilegios mínimos de Princes con su comentario aclaratorio para el permiso `INTERNET`.
   - Se agregó `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (indispensable para Android 13+).
   - Se conservó la configuración del canal predeterminado `easyhome_default_channel`.
3. **`firestore.rules`**:
   - **Se conservó al 100% el bloque `usuarios` de Princes** (validación estricta en `create`, casos 1 al 5 en `update`, `delete: if false`).
   - Se agregó en `allow update` de `usuarios` únicamente el **Caso 6** para el token FCM:
     ```firestore-rules
     // Caso 6: Guardar o borrar el propio token FCM (notificaciones push, #21)
     || (request.auth.uid == uid
       && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken'])
       && (!('fcmToken' in request.resource.data) || (request.resource.data.fcmToken is string && request.resource.data.fcmToken.size() <= 4096)))
     ```
   - El resto de colecciones (`hogares`, `productos`, `quehaceres`, `codigosInvitacion`) permanece idéntico a lo diseñado por Princes.

---

## Cambios realizados
1. **Cliente Flutter — Servicio de Notificaciones (`lib/services/notificaciones_service.dart`)**:
   - `inicializar(uid)`: Solicita permisos del sistema (incluyendo `POST_NOTIFICATIONS` para Android 13+), obtiene el token FCM, lo registra en `usuarios/{uid}.fcmToken` (conforme al Caso 6 de reglas) y escucha renovaciones con `onTokenRefresh`.
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
   - Reglas de Firestore combinadas respetando la seguridad de Princes (Caso 6 para FCM).
   - Actualización de `bitacora/modelo-datos-firestore.md` y `bitacora/reglas-firestore.md`.
7. **Pruebas automatizadas**:
   - 8 pruebas unitarias nuevas para `NotificacionesService` (`test/notificaciones_service_test.dart`).
   - Suite completa de Flutter y suite de Node.js pasando al 100%.

---

## Cómo probar
1. **Pruebas automatizadas Flutter:**
   ```bash
   flutter test
   ```
   Verificar que pasen todos los tests unitarios y de widget.
2. **Pruebas automatizadas del notificador:**
   ```bash
   cd notificador
   npm test
   ```
   Verificar que pasen los 17 tests de Jest.
3. **Prueba manual de notificaciones push:**
   - Seguir la guía detallada en `bitacora/reporte-push.md`.
   - Generar la llave de cuenta de servicio en Firebase Console y colocarla en `notificador/serviceAccountKey.json`.
   - Correr `node notificador/index.js` y probar con dos dispositivos/cuentas la creación de productos y asignación de tareas.
