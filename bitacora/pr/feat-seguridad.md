# PR: feat(seguridad): endurecimiento integral de seguridad y reglas (#22)

**Base:** `develop`  
**Rama:** `feat/seguridad`

---

## Resumen
Implementación integral de seguridad para EasyHome (#22), abarcando reglas endurecidas de Firestore con validación estricta de esquemas y tipos, regla catch-all de denegación por defecto, suite de pruebas automatizadas con el emulador de Firestore (`@firebase/rules-unit-testing`), política reforzada de contraseñas, flujo y pantalla de recuperación de contraseña con protección anti-enumeración de usuarios, mitigación de fuerza bruta en códigos de invitación con rate limiting del lado del cliente, protección de backups en Android y auditoría exhaustiva con checklist manual.

---

## Cambios realizados

1. **Reglas de seguridad endurecidas en Firestore (`firestore.rules` & `bitacora/reglas-firestore.md`)**:
   - **Regla Catch-All:** `match /{document=**} { allow read, write: if false; }` al final del archivo para denegar cualquier colección o subcolección no autorizada.
   - **Prevención de auto-promoción a administrador:** en `/usuarios/{uid}` solo se puede crear con `esAdministrador: false` y `hogarId: null`. La asignación de administrador solo es permitida si coincide atómicamente con la creación del hogar (`getAfter`) o mediante promoción explícita por un admin del mismo hogar.
   - **Validación de esquema en productos:** tipos y longitudes de campos validados (`nombre` 2-100 caracteres, `cantidad` entero 1-9999, `comprado` booleano) y restricción estricta de llaves con `keys().hasOnly(...)`.
   - **Validación de esquema en quehaceres:** título de 1 a 120 caracteres, rol de creador/admin verificado, responsable solo puede modificar el estado `hecho`, llaves restringidas con `keys().hasOnly(...)`.
   - **Hogares y códigos:** nombres de hogar validados (1-30 caracteres), códigos de invitación de 6 caracteres, y colección `codigosInvitacion` protegida contra listados (`allow list: if false`).

2. **Suite de pruebas automáticas de Firestore (`firestore-tests/`)**:
   - Proyecto Node.js con `@firebase/rules-unit-testing` y Jest.
   - 20 pruebas unitarias automatizadas probando aislamiento multi-hogar, RBAC, prevención de escalamiento de privilegios, validación de tipos, cotas y regla catch-all ejecutadas contra el emulador oficial de Firestore.

3. **Política de contraseñas fortalecida (`lib/utils/validators.dart`)**:
   - Mínimo 8 caracteres, al menos 1 letra y al menos 1 número en registro y cambio de contraseña.
   - Mensajes descriptivos en español.
   - Método `sanitizarTexto` para recorte de espacios.
   - Indicador visual adaptado a 8+ caracteres en `RegistroScreen` y `EditarPerfilScreen`.

4. **Flujo de recuperación de contraseña (`lib/screens/recuperar_contrasena_screen.dart` & `lib/services/auth_service.dart`)**:
   - Nueva pantalla `RecuperarContrasenaScreen` con `campo_correo_recuperar`, `boton_enviar_recuperacion` y `enlace_volver_login`.
   - Conexión del enlace "¿Olvidaste tu contraseña?" en `LoginScreen`.
   - Registro de ruta `AppRoutes.recuperarContrasena` en `routes.dart` y `main.dart`.
   - Servicio `AuthService.recuperarContrasena` con respuesta uniforme para prevenir enumeración de cuentas.

5. **Mitigación de fuerza bruta en códigos de invitación (`lib/screens/unirse_hogar_screen.dart`)**:
   - Rate limiting client-side: tras 5 intentos fallidos consecutivos se bloquea el formulario durante 60 segundos con aviso explicativo.

6. **Protección a nivel plataforma y privacidad (`AndroidManifest.xml` & `NotificacionesService`)**:
   - Configuración `android:allowBackup="false"` en el manifiesto para evitar extracción de datos privados vía adb backup.
   - Sanitización de mensajes `debugPrint` en `NotificacionesService` para no imprimir IDs de usuario en consola.

7. **Documentación y checklist (`bitacora/seguridad.md`)**:
   - Modelo de amenazas STRIDE / OWASP Mobile Top 10.
   - Matriz de controles implementados.
   - Riesgos residuales documentados.
   - Checklist manual con instrucciones paso a paso para Jaqueline/Princes (restricción de claves API, App Check con Play Integrity, email enumeration protection y 2FA/IAM).

---

## Cómo probar

1. **Pruebas de Flutter:**
   ```bash
   flutter test
   ```
   Verificar que pasen los 152 tests (100% de la suite).

2. **Pruebas de reglas de Firestore (Emulador):**
   ```bash
   cd firestore-tests
   npm test
   # o bien mediante el emulador:
   npm run test:emulator
   ```
   Verificar que pasen los 20 tests de reglas.

3. **Pruebas de notificador local:**
   ```bash
   cd notificador
   npm test
   ```
   Verificar que pasen los 17 tests unitarios.

4. **Prueba manual en la app:**
   - En la pantalla de inicio de sesión, pulsar "¿Olvidaste tu contraseña?" y verificar la navegación y validación del correo.
   - En el formulario de registro, verificar que la contraseña exija 8 caracteres, letra y número.
   - En "Unirse a un hogar", ingresar códigos erróneos 5 veces y comprobar que se bloquea durante 60 segundos.

---

## Criterios de aceptación cumplidos
- [x] Reglas de Firestore protegidas contra multi-inquilino, auto-promoción a admin y campos extra.
- [x] Regla catch-all de denegación al final de las reglas.
- [x] Pruebas de reglas en emulador pasando 100%.
- [x] Contraseña con mínimo 8 caracteres, letras y números.
- [x] Pantalla y flujo de recuperación de contraseña funcionando.
- [x] Rate limiting en unión a hogar por código de invitación.
- [x] Android backup deshabilitado.
- [x] Checklist y modelo de amenazas documentados en `bitacora/seguridad.md`.
