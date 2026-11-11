# Notificador Local — EasyHome (#21)

Este servicio local en Node.js sustituye a las Cloud Functions para permitir el envío de **notificaciones push (FCM)** en EasyHome **sin requerir plan Blaze ni tarjeta de crédito**.

FCM (Firebase Cloud Messaging) es completamente gratuito a través de la API v1 / Firebase Admin. Este notificador corre en la computadora de Jaqueline/desarrollador durante pruebas y demostraciones.

---

## ⚠️ Advertencia importante
- Las notificaciones push se emitirán **únicamente mientras este script esté en ejecución** (`node index.js`).
- En un entorno de producción futuro con presupuesto/tarjeta, este código se migra directamente a Google Cloud Functions o Cloud Run.

---

## Instrucciones de configuración y arranque

### 1. Generar la llave de cuenta de servicio (serviceAccountKey.json)
1. Abre la [Consola de Firebase](https://console.firebase.google.com/project/easyhome-6ef93/settings/serviceaccounts/adminsdk).
2. Ve a **Configuración del proyecto** ⚙️ → Pestaña **Cuentas de servicio**.
3. Asegúrate de tener seleccionado **Firebase Admin SDK** (Node.js).
4. Haz clic en el botón **"Generar nueva clave privada"** y confirma la descarga.
5. Renombra el archivo descargado exactamente a:
   ```text
   serviceAccountKey.json
   ```
6. Cópialo dentro de esta carpeta:
   ```text
   c:\easyhome\notificador\serviceAccountKey.json
   ```
   > 🔒 **Seguridad:** El archivo `serviceAccountKey.json` está listado en `.gitignore` y **NUNCA** debe commitearse ni subirse a GitHub.

### 2. Instalar dependencias
Desde la terminal en esta carpeta:
```bash
cd notificador
npm install
```

### 3. Ejecutar pruebas unitarias
```bash
npm test
```

### 4. Arrancar el notificador local
```bash
node index.js
```
o bien:
```bash
npm start
```

### 5. Qué esperar en consola
Verás mensajes similares a:
```text
✅ Firebase Admin inicializado exitosamente con el proyecto: easyhome-6ef93
🕒 Notificador arrancado a las 2026-11-10T...
📡 Escuchando colecciones "productos" y "quehaceres" en tiempo real...
💡 Presiona Ctrl+C para detener el proceso cuando termines las pruebas.

📦 Carga inicial de productos ignorada (X productos existentes).
📋 Carga inicial de quehaceres ignorada (Y quehaceres existentes).
```
Cuando un usuario agregue un producto o asigne un quehacer desde la app, verás:
```text
🔔 [Producto notificado] "Leche" por Jaqueline -> Éxito: 1, Fallos: 0
🔔 [Quehacer notificado] "Lavar platos" asignado a uid_integrante -> Éxito: 1, Fallos: 0
```

### 6. Detener el notificador
Presiona `Ctrl + C` en la terminal.
