# PR: Dejar develop con la seguridad de Princes (sin #22 ni notificaciones)

**Base:** `develop`  
**Rama:** `fix/develop-solo-seguridad-princes`  

---

## 1. Resumen
Restaura la rama `develop` para que contenga **únicamente el trabajo de seguridad legítimo de Princes** (`4204d78` y `239ba71`), preservando la base de tareas completadas (#16 a #20 que vienen de `main` y `develop`), y retirando completamente tanto la tarjeta #22 generada por Antigravity como las notificaciones push (#21), las cuales se entregan en un PR independiente sobre esta base (`feat/notificacionesPush-v2`).

---

## 2. Contexto de la corrección
- **Qué había:** En el PR #11 (merge commit `4219f65`), se mezcló accidentalmente el trabajo de Princes con las notificaciones push (`e1e5a83`) y una implementación alternativa de la tarjeta #22 generada por Antigravity (`2e113ed`, `39868b6`, `afdb488`). Dicha mezcla sobrescribió las reglas de Firestore de Princes y las pantallas de autenticación.
- **Qué se retira:**
  - Todo el código de la tarjeta #22 de Antigravity: `firestore-tests/`, `lib/screens/recuperar_contrasena_screen.dart`, validadores extendidos de contraseña a 8 caracteres, rate limit en frontend y modificaciones de esquema no alineadas.
  - El código de notificaciones push (#21): `notificador/`, `lib/services/notificaciones_service.dart`, `web/firebase-messaging-sw.js`, dependencias de `firebase_messaging`.
  - Archivos y reportes transitorios asociados.
- **Qué se conserva:**
  - La totalidad del trabajo de seguridad implementado por Princes (`roygro`).
  - Todas las funcionalidades de las tarjetas #16, #17, #18, #19 y #20 (módulo de quehaceres con rotación semanal y asignaciones).

---

## 3. Matriz de Archivos de Princes y su Estado en este PR

| Archivo de Princes | Estado en este PR | Verificación |
|---|---|---|
| `firestore.rules` | **100 % idéntico a Princes (`239ba71`)** | Reglas con RBAC original, casos 1 a 5 de usuarios, bloqueo de auto-admin |
| `lib/screens/login_screen.dart` | **100 % idéntico a Princes (`239ba71`)** | UI y validaciones exactas de Princes |
| `lib/services/auth_service.dart` | **100 % idéntico a Princes (`239ba71`)** | Métodos y excepciones de Princes |
| `lib/utils/validators.dart` | **100 % idéntico a Princes (`239ba71`)** | Política de contraseña de 6 caracteres con requisitos |
| `bitacora/seguridad.md` | **100 % idéntico a Princes (`239ba71`)** | Documentación de seguridad de Princes |
| `test/seguridad_test.dart` | **100 % idéntico a Princes (`239ba71`)** | Pruebas de seguridad de Princes |
| `test/validators_test.dart` | **100 % idéntico a Princes (`239ba71`)** | Pruebas de validadores de Princes |
| `test/login_screen_test.dart` | **100 % idéntico a Princes (`239ba71`)** | Pruebas de login de Princes |
| `.github/workflows/security-ci.yml` | **100 % idéntico a Princes (`239ba71`)** | Pipeline de CI de seguridad |
| `android/app/google-services.json.example` | **100 % idéntico a Princes (`239ba71`)** | Ejemplo de configuración |
| `lib/firebase_options.example.dart` | **100 % idéntico a Princes (`239ba71`)** | Ejemplo de opciones Firebase |

---

## 4. Cómo probar
1. En la rama `fix/develop-solo-seguridad-princes`:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```
2. Verificar que `test/seguridad_test.dart` y toda la suite de pruebas pasen satisfactoriamente.
3. Verificar que no exista ningún archivo de `firestore-tests`, `notificador` o `recuperar_contrasena`.
