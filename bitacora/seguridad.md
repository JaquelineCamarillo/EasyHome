# Auditoría y Modelo Integral de Seguridad — EasyHome (#22)

Este documento detalla el análisis integral de seguridad, modelo de amenazas, matriz de controles implementados, riesgos residuales y el checklist de configuración manual para el proyecto `easyhome-6ef93`.

---

## 1. Modelo de Amenazas (STRIDE & OWASP Mobile Top 10)

| Categoría STRIDE | Amenaza Identificada en EasyHome | Impacto | Mitigación Implementada (#22) |
|---|---|---|---|
| **Spoofing (Suplantación)** | Un usuario intenta registrarse o suplantar a otro modificando el `uid` en las peticiones de Firestore. | Alto | En `firestore.rules`: `allow create: if estaAutenticado() && request.auth.uid == uid`. No se pueden crear perfiles para otros `uid`. |
| **Tampering (Alteración)** | Modificación no autorizada de productos de otro hogar o alteración de títulos/estados de quehaceres. | Alto | Reglas de Firestore exigen `miHogarId() == resource.data.hogarId`. Asignados solo pueden alterar `hecho`, administradores editan tareas, validación de esquema con `keys().hasOnly()`. |
| **Repudiation (Repudio)** | Un integrante crea o elimina elementos sin dejar rastro de autoría. | Medio | En `productos` y `quehaceres`, `creadoPor`/`agregadoPor` debe coincidir obligatoriamente con `request.auth.uid`. |
| **Information Disclosure (Fuga de Información)** | Filtración de qué usuarios pertenecen a un hogar, códigos de invitación listables o enumeración de correos en login/recuperación. | Alto | Códigos de invitación no listables (`allow list: if false`). Respuestas de login y recuperación uniformes ("Si el correo está registrado, recibirás un correo"). Aislamiento estricto multi-hogar. |
| **Denial of Service (Denegación de Servicio)** | Fuerza bruta contra códigos de 6 caracteres o payloads gigantescos en campos de texto. | Medio | Rate limiting del lado del cliente en `UnirseHogarScreen` (bloqueo de 60s tras 5 fallos consecutivos). Validaciones de longitud en `Validators` y `firestore.rules` (nombre <= 30, títulos <= 120, cantidades 1-9999). |
| **Elevation of Privilege (Escalamiento de Privilegios)** | Usuario común se asigna `esAdministrador: true` al crearse o mediante `update`. | Crítico | Auto-creación como admin bloqueada (`esAdministrador == false`). Actualización a admin permitida únicamente si se verifica la creación atómica de hogar vía `getAfter` o si es promovido por un admin del mismo hogar. |

---

## 2. Matriz de Controles de Seguridad Implementados

| Control de Seguridad | Archivo(s) | Prueba Automatizada | Estado |
|---|---|---|---|
| **Regla Catch-All de Denegación** | [firestore.rules](file:///C:/easyhome/firestore.rules) | `reglas.test.js` | Implementado |
| **Aislamiento Multi-hogar (Productos y Quehaceres)** | [firestore.rules](file:///C:/easyhome/firestore.rules) | `reglas.test.js` | Implementado |
| **Prevención de Escalamiento de Privilegios** | [firestore.rules](file:///C:/easyhome/firestore.rules) | `reglas.test.js` | Implementado |
| **Validación de Esquema y Límites de Entrada** | [firestore.rules](file:///C:/easyhome/firestore.rules) | `reglas.test.js` | Implementado |
| **Códigos de Invitación No Listables** | [firestore.rules](file:///C:/easyhome/firestore.rules) | `reglas.test.js` | Implementado |
| **Política de Contraseñas Fuertes (8+, letra, número)** | [lib/utils/validators.dart](file:///C:/easyhome/lib/utils/validators.dart) | [test/validators_test.dart](file:///C:/easyhome/test/validators_test.dart) | Implementado |
| **Pantalla de Recuperación de Contraseña (Anti-enumeración)** | [lib/screens/recuperar_contrasena_screen.dart](file:///C:/easyhome/lib/screens/recuperar_contrasena_screen.dart) | [test/recuperar_contrasena_screen_test.dart](file:///C:/easyhome/test/recuperar_contrasena_screen_test.dart) | Implementado |
| **Rate Limit de Fuerza Bruta en Códigos (5 intentos / 60s)** | [lib/screens/unirse_hogar_screen.dart](file:///C:/easyhome/lib/screens/unirse_hogar_screen.dart) | [test/unirse_hogar_screen_test.dart](file:///C:/easyhome/test/unirse_hogar_screen_test.dart) | Implementado |
| **Deshabilitación de Backups Inseguros de Android** | [android/app/src/main/AndroidManifest.xml](file:///C:/easyhome/android/app/src/main/AndroidManifest.xml) | Inspección de manifiesto (`allowBackup=false`) | Implementado |
| **Higiene de Logs (Sin UIDs en consolas)** | [lib/services/notificaciones_service.dart](file:///C:/easyhome/lib/services/notificaciones_service.dart) | [test/notificaciones_service_test.dart](file:///C:/easyhome/test/notificaciones_service_test.dart) | Implementado |

---

## 3. Riesgos Residuales Conocidos

1. **Rate Limiting en Frontend:** El bloqueo tras 5 intentos en `UnirseHogarScreen` reside en memoria de la app cliente. Un atacante con acceso a las APIs directas de Firestore podría enviar peticiones saltándose la UI a menos que se configure Firebase App Check.
2. **Plataforma Web y Tokens:** En la versión web (`firebase-messaging-sw.js`), las configuraciones de API key de Firebase son públicas por diseño de Firebase; la seguridad descansa enteramente en las Reglas de Seguridad de Firestore y en las restricciones de clave en Google Cloud Console.

---

## 4. CHECKLIST MANUAL — Pasos Obligatorios para Jaqueline / Princes

Debido a que requieren permisos de consola, tarjetas de crédito o hardware físico, estos pasos **no pueden ejecutarse automáticamente** y deben realizarse manualmente:

### A. Restricción de API Keys en Google Cloud Console
1. Entrar a [Google Cloud Console](https://console.cloud.google.com/) con la cuenta propietaria del proyecto `easyhome-6ef93`.
2. Ir a **APIs & Services (APIs y Servicios)** -> **Credentials (Credenciales)**.
3. Localizar las claves API utilizadas por EasyHome (Android y Web).
4. Para la **clave de Android**:
   - Cambiar *Application restrictions* a **Android apps**.
   - Agregar el nombre de paquete: `com.example.easyhome`.
   - Agregar la huella SHA-1 de release (y de depuración de desarrollo).
   - En *API restrictions*, limitar a: *Firebase Authentication API*, *Cloud Firestore API*, *Firebase Cloud Messaging API*.
5. Guardar los cambios.

### B. Habilitar Protección contra Enumeración de Correo (Email Enumeration Protection)
1. Entrar a [Firebase Console](https://console.firebase.google.com/).
2. Seleccionar `easyhome-6ef93` -> **Authentication** -> pestaña **Configuración (Settings)**.
3. En **Acciones del usuario (User actions)**, activar la casilla:
   - **"Protección contra la enumeración de correo electrónico" (Email enumeration protection)**.
   - Esto evita que un atacante descubra si un correo está registrado o no analizando los códigos de error de Firebase Auth.

### C. Configurar Firebase App Check con Play Integrity
1. En Firebase Console, navegar a **App Check**.
2. Registrar la app Android vinculándola con **Play Integrity**.
3. Requerir App Check en **Cloud Firestore** para garantizar que solo la app oficial compilada y firmada pueda interactuar con la base de datos.

### D. Seguridad de Acceso y Cuentas (IAM y 2FA)
1. Activar verificación en dos pasos (2FA) en todas las cuentas de Google con roles de Administrador/Editor en el proyecto.
2. Proteger `serviceAccountKey.json`: nunca debe subirse al repositorio Git.
