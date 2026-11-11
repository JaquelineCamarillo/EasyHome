# Bitácora de Decisiones — Notificaciones Push (FCM) (#21)

> **Tarjeta:** #21 · Notificaciones push (Firebase Cloud Messaging)  
> **Fecha:** 10 de noviembre de 2026  
> **Proyecto:** EasyHome (`easyhome-6ef93`)  

---

## 1. Arquitectura del Notificador: Servidor Local vs Cloud Functions

### Decisión
**Se descarta el uso de Google Cloud Functions** y se implementa un **notificador local en Node.js (`notificador/`)** ejecutado con `firebase-admin`.

### Justificación
- El proyecto Firebase `easyhome-6ef93` se encuentra en el **plan gratuito Spark**. El despliegue de Cloud Functions v2 exige obligatoriamente la activación del **plan Blaze** (facturación vinculada a tarjeta de crédito).
- La API de **Firebase Cloud Messaging (FCM HTTP v1)** y el SDK de Firebase Admin son **100% gratuitos** y operan sin restricciones de facturación en el plan Spark.
- Para propósitos de pruebas, evaluación y demostración de Jaqueline y Princes, un proceso local en Node.js escuchando Firestore vía `onSnapshot` replica con fidelidad el comportamiento de las notificaciones reactivas.

### Limitación conocida y mitigación
- **Disponibilidad:** El notificador solo despacha mensajes mientras el proceso `node index.js` esté activo en la computadora de desarrollo.
- **Producción:** La lógica de negocio (`notificador/src/destinatarios.js` y `notificador/src/mensajes.js`) está desacoplada y probada al 100% con Jest, lo que permitirá una migración directa a Cloud Functions o Cloud Run tan pronto se disponga de facturación.

---

## 2. Almacenamiento del Token FCM

### Decisión
El token se almacena en el documento del usuario autenticado: `usuarios/{uid}.fcmToken` como tipo `string` (o `null`).

### Justificación y límite
- Cumple fielmente la especificación de la tarjeta #21.
- **Limitación:** Si un usuario inicia sesión en dos dispositivos a la vez, el segundo dispositivo sobrescribirá el token del primero (un solo dispositivo activo para notificaciones por usuario).
- **Mejora futura documentada:** Evolucionar el campo a un arreglo `fcmTokens: list<string>` o una subcolección `tokens/` para soportar multi-dispositivo simultáneo.

---

## 3. Alcance de los Eventos Notificados (Antispam)

### Decisión
Solo se envían notificaciones push en **creación** (`create` / `added`):
1. **Nuevo producto en compras:** Notifica a todos los integrantes del hogar, **excluyendo a quien agregó el producto**.
2. **Nuevo quehacer asignado:** Notifica **únicamente al integrante asignado**. Si un administrador se asigna una tarea a sí mismo, **no** se emite notificación.

### Eventos deliberadamente excluidos
- **Rotación semanal automática (#20):** La rotación semanal actualiza múltiples tareas simultáneamente en lote. Enviar un push por cada tarea rotada causaría una ráfaga masiva de notificaciones invasivas (spam).
- **Edición y eliminación de productos y quehaceres:** Cambios menores (como editar el nombre o cantidad) no ameritan interrumpir a los integrantes del hogar con alertas sonoras.

---

## 4. Gestión del Ciclo de Vida del Token

### Decisión
1. **Inicialización:** Al iniciar sesión o ingresar al Dashboard, el cliente pide permisos (incluyendo `POST_NOTIFICATIONS` en Android 13+), obtiene el token FCM y lo guarda en `usuarios/{uid}.fcmToken`.
2. **Renovación:** Se escucha `FirebaseMessaging.instance.onTokenRefresh` para actualizar el token en Firestore inmediatamente si Firebase lo renueva.
3. **Cierre de sesión (`limpiarToken`):** Al cerrar sesión, la app ejecuta `deleteToken()` en FCM y borra el campo `fcmToken` en Firestore con `FieldValue.delete()`. Esto garantiza que un usuario deslogueado jamás reciba notificaciones dirigidas al usuario anterior.
4. **Tokens inválidos:** Cuando FCM devuelve errores de token desregistrado (`messaging/registration-token-not-registered`, etc.), el notificador limpia automáticamente el campo en Firestore para optimizar envíos subsecuentes.

---

## 5. Plataformas: Android, Web e iOS

- **Android:** Totalmente configurado con permisos en `AndroidManifest.xml` y canal `easyhome_default_channel`.
- **Web:** Configurado con `web/firebase-messaging-sw.js` utilizando los parámetros públicos del proyecto de `lib/firebase_options.dart`. La clave VAPID se inyecta por compilación con `--dart-define=FCM_VAPID_KEY=...` para no exponer secretos.
- **iOS:** Queda documentado como **PENDIENTE manual**, dado que requiere credenciales de desarrollador Apple (APNs Auth Key `.p8`), Team ID, Key ID y aprovisionamiento en Xcode.
