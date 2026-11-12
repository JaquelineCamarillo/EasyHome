# Guía y Reporte de Pruebas Manuales — Notificaciones Push (#21)

> **Estado general:** ⚠️ **PENDIENTE — Paso manual de Jaqueline Camarillo / Princes**  
> **Motivo:** Las notificaciones push en segundo plano requieren interacción con la consola de Firebase, ejecución del notificador en máquina local y dos dispositivos/navegadores reales con cuentas distintas.

---

## Prerrequisitos de configuración

### Paso 1: Configurar la clave VAPID para Web (Opcional si pruebas en Web)
1. Entrar a [Firebase Console](https://console.firebase.google.com/project/easyhome-6ef93/settings/cloudmessaging).
2. Ir a **Configuración del proyecto** ⚙️ → Pestaña **Cloud Messaging**.
3. En la sección **Certificados push web**, hacer clic en **Generar par de claves**.
4. Copiar la clave pública (Key pair).
5. Al ejecutar la aplicación Web con Flutter, pasarla por línea de comandos:
   ```bash
   flutter run -d chrome --dart-define=FCM_VAPID_KEY=TU_CLAVE_VAPID_AQUI
   ```

### Paso 2: Generar credencial de servicio local y arrancar el Notificador
1. En Firebase Console, ir a **Configuración del proyecto** → Pestaña **Cuentas de servicio**.
2. Hacer clic en **Generar nueva clave privada** y descargar el JSON.
3. Guardar el archivo como:
   ```text
   c:\easyhome\notificador\serviceAccountKey.json
   ```
4. En una terminal, arrancar el notificador:
   ```bash
   cd notificador
   npm install
   node index.js
   ```
5. Confirmar que en la consola aparezca:
   ```text
   ✅ Firebase Admin inicializado exitosamente con el proyecto: easyhome-6ef93
   📡 Escuchando colecciones "productos" y "quehaceres" en tiempo real...
   ```

---

## Casos de Prueba Manual a Ejecutar

### Prueba 1: Notificación al agregar producto (excluyendo al autor)
- **Preparación:** Dispositivo A (Usuario 1: Jaqueline) y Dispositivo B (Usuario 2: Integrante del mismo hogar).
- **Acción:**
  1. En Dispositivo B, iniciar sesión y minimizar la app o colocarla en segundo plano.
  2. En Dispositivo A, agregar un producto nuevo a la lista de compras (ej. "Manzanas rojas").
- **Resultado esperado:**
  - En la consola del notificador se registra: `🔔 [Producto notificado] "Manzanas rojas" por Jaqueline...`.
  - Dispositivo B recibe una notificación del sistema:
    - **Título:** `"Nuevo producto en la lista"`
    - **Cuerpo:** `"Jaqueline agregó Manzanas rojas"`
  - Dispositivo A (autor) **NO** recibe ninguna notificación.
  - Al tocar la notificación en Dispositivo B, la app se abre directamente en el Dashboard.

### Prueba 2: Notificación al asignar un quehacer (solo al asignado)
- **Preparación:** Dispositivo A (Admin) y Dispositivo B (Integrante asignado).
- **Acción:**
  1. En Dispositivo B, colocar la app en segundo plano.
  2. En Dispositivo A, crear un quehacer nuevo (ej. "Limpiar el refrigerador") asignado al Usuario 2.
- **Resultado esperado:**
  - En la consola del notificador se registra: `🔔 [Quehacer notificado] "Limpiar el refrigerador" asignado a uid_integrante...`.
  - Dispositivo B recibe la notificación:
    - **Título:** `"Te asignaron un quehacer"`
    - **Cuerpo:** `"Limpiar el refrigerador"`
  - Si el administrador se asigna una tarea a sí mismo, el notificador la ignora y no envía push.

### Prueba 3: Notificaciones en primer plano
- **Acción:** Tener la app abierta en pantalla en Dispositivo B. Agregar un producto en Dispositivo A.
- **Resultado esperado:** Se muestra un snackbar amigable en pantalla mediante `AppFeedback` sin interrumpir la navegación.

### Prueba 4: Limpieza de token al cerrar sesión
- **Acción:**
  1. En la consola de Firestore, inspeccionar `usuarios/{uid}` y verificar que el campo `fcmToken` exista con una cadena de texto.
  2. En la app, ir al Perfil del Hogar y tocar **Cerrar sesión**.
  3. Refrescar el documento en la consola de Firestore.
- **Resultado esperado:** El campo `fcmToken` ya no existe en el documento del usuario (fue eliminado), garantizando que no se envíen más mensajes a ese dispositivo tras el logout.
