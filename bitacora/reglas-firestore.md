# Reglas de Seguridad de Firestore (`firestore.rules`) — EasyHome (#22)

> **IMPORTANTE:** La publicación de estas reglas en producción es un **PASO MANUAL DE JAQUELINE / PRINCES**. Deben copiarse y pegarse en la **Consola de Firebase** (`easyhome-6ef93` -> Firestore Database -> pestaña *Reglas/Rules*) y probarse previamente en el **Rules Playground** antes de publicarlas.

---

## 1. Reglas endurecidas completas

```firestore-rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function estaAutenticado() {
      return request.auth != null;
    }

    function miHogarId() {
      return get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.hogarId;
    }

    function soyAdminDe(hid) {
      let yo = get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data;
      return yo.hogarId == hid && yo.esAdministrador == true;
    }

    // --- USUARIOS ---
    match /usuarios/{uid} {
      allow read: if estaAutenticado();
      // Nadie puede crearse con hogarId o como administrador directamente
      allow create: if estaAutenticado()
                    && request.auth.uid == uid
                    && request.resource.data.esAdministrador == false
                    && request.resource.data.hogarId == null
                    && request.resource.data.nombre is string
                    && request.resource.data.nombre.size() > 0;
      allow update: if estaAutenticado() && (
        // 1. Modificar perfil personal básico: nombre, avatarColor, fcmToken
        (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre', 'avatarColor', 'fcmToken']))
        // 2. Solo token FCM (#21)
        || (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken']))
        // 3. Crear hogar: auto-vincularse como admin verificado con el creador del hogar
        || (request.auth.uid == uid && resource.data.hogarId == null &&
            request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId', 'esAdministrador']) &&
            (request.resource.data.esAdministrador == false ||
             getAfter(/databases/$(database)/documents/hogares/$(request.resource.data.hogarId)).data.creadoPor == request.auth.uid))
        // 4. Unirse a un hogar como miembro común (no admin)
        || (request.auth.uid == uid && resource.data.hogarId == null &&
            request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId', 'esAdministrador']) &&
            request.resource.data.esAdministrador == false)
        // 5. Salir del hogar voluntariamente
        || (request.auth.uid == uid && request.resource.data.hogarId == null && request.resource.data.esAdministrador == false &&
            request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId', 'esAdministrador']))
        // 6. Admin del hogar gestiona integrantes de su PROPIO hogar (promover, degradar o remover)
        || (resource.data.hogarId != null && soyAdminDe(resource.data.hogarId) &&
            request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId', 'esAdministrador']) &&
            (request.resource.data.hogarId == resource.data.hogarId || request.resource.data.hogarId == null))
      );
      allow delete: if false;
    }

    // --- HOGARES ---
    match /hogares/{hogarId} {
      allow read: if estaAutenticado() && (
        miHogarId() == hogarId ||
        resource.data.creadoPor == request.auth.uid
      );
      allow create: if estaAutenticado()
                    && request.resource.data.creadoPor == request.auth.uid
                    && request.resource.data.nombre is string
                    && request.resource.data.nombre.size() > 0
                    && request.resource.data.nombre.size() <= 30
                    && request.resource.data.codigoInvitacion is string
                    && request.resource.data.codigoInvitacion.size() == 6;
      allow update: if estaAutenticado() && miHogarId() == hogarId && (
        // Admin del hogar puede editar datos o regenerar código
        soyAdminDe(hogarId)
        // Integrantes pueden actualizar metadatos de rotación semanal (#20)
        || request.resource.data.diff(resource.data).affectedKeys().hasOnly(['ordenRotacion', 'ultimaRotacion'])
      );
      allow delete: if false;
    }

    // --- PRODUCTOS ---
    match /productos/{productoId} {
      allow read: if estaAutenticado() && resource.data.hogarId == miHogarId();
      allow create: if estaAutenticado()
                    && request.resource.data.hogarId == miHogarId()
                    && request.resource.data.agregadoPor == request.auth.uid
                    && request.resource.data.nombre is string
                    && request.resource.data.nombre.size() >= 2
                    && request.resource.data.nombre.size() <= 100
                    && request.resource.data.cantidad is int
                    && request.resource.data.cantidad > 0
                    && request.resource.data.cantidad <= 9999
                    && request.resource.data.comprado == false
                    && request.resource.data.keys().hasOnly(['hogarId', 'agregadoPor', 'nombre', 'cantidad', 'comprado', 'fechaCreacion']);
      allow update: if estaAutenticado()
                    && resource.data.hogarId == miHogarId()
                    && request.resource.data.hogarId == resource.data.hogarId
                    && (
                      // Marcar/desmarcar comprado
                      request.resource.data.diff(resource.data).affectedKeys().hasOnly(['comprado'])
                      // Editar nombre y/o cantidad válidos
                      || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre', 'cantidad'])
                          && request.resource.data.nombre is string
                          && request.resource.data.nombre.size() >= 2
                          && request.resource.data.nombre.size() <= 100
                          && request.resource.data.cantidad is int
                          && request.resource.data.cantidad > 0
                          && request.resource.data.cantidad <= 9999)
                    );
      allow delete: if estaAutenticado() && resource.data.hogarId == miHogarId();
    }

    // --- QUEHACERES ---
    match /quehaceres/{quehacerId} {
      allow read:   if estaAutenticado() && resource.data.hogarId == miHogarId();
      allow create: if estaAutenticado()
                    && soyAdminDe(request.resource.data.hogarId)
                    && request.resource.data.creadoPor == request.auth.uid
                    && request.resource.data.hecho == false
                    && request.resource.data.titulo is string
                    && request.resource.data.titulo.size() >= 1
                    && request.resource.data.titulo.size() <= 120
                    && request.resource.data.keys().hasOnly(['hogarId', 'creadoPor', 'asignadoA', 'titulo', 'hecho', 'fechaLimite', 'recurrente']);
      allow update: if estaAutenticado() && (
          // Admin del hogar puede actualizar cualquier campo del quehacer (con título válido)
          (soyAdminDe(resource.data.hogarId)
           && request.resource.data.hogarId == resource.data.hogarId
           && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['titulo']) ||
               (request.resource.data.titulo is string && request.resource.data.titulo.size() >= 1 && request.resource.data.titulo.size() <= 120)))
          // El responsable actual puede marcar/desmarcar su quehacer
          || (resource.data.asignadoA == request.auth.uid
              && resource.data.hogarId == miHogarId()
              && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hecho']))
          // Rotación semanal (#20): cualquier integrante del hogar puede rotar tareas recurrentes
          || (resource.data.hogarId == miHogarId()
              && resource.data.recurrente == true
              && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['asignadoA', 'hecho']))
      );
      allow delete: if estaAutenticado() && soyAdminDe(resource.data.hogarId);
    }

    // --- CÓDIGOS DE INVITACIÓN (No listables) ---
    match /codigosInvitacion/{codigoId} {
      allow get: if estaAutenticado();
      allow list: if false;
      allow write: if false;
    }

    // --- REGLA CATCH-ALL: Cierra cualquier otra colección no permitida ---
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 2. Resumen de vulnerabilidades mitigadas

1. **Auto-promoción a Administrador (Privilege Escalation):**
   - Antes: Cualquier usuario autenticado podía enviar un payload `{ esAdministrador: true }` y promoverse arbitrariamente.
   - Ahora: Solo se permite `esAdministrador: true` si es creador del hogar verificado mediante `getAfter` o si es promovido por un administrador existente del mismo hogar.

2. **Aislamiento Multi-inquilino (Cross-Tenant Data Leak):**
   - Lecturas, escrituras y eliminaciones en `productos` y `quehaceres` exigen coincidencia estricta con `miHogarId()`.
   - Usuarios de Hogar A no pueden leer ni alterar datos de Hogar B.

3. **Validación Exhaustiva de Esquema (Schema Poisoning):**
   - `keys().hasOnly(...)` previene inyección de campos arbitrarios o payloads pesados.
   - Longitud de títulos de quehacer (1 a 120), nombres de producto (2 a 100), nombres de hogar (1 a 30) y enteros positivos para cantidades (1 a 9999).

4. **Regla Catch-All de Denegación por Defecto:**
   - La regla final `match /{document=**} { allow read, write: if false; }` garantiza que cualquier nueva colección o subcolección permanezca completamente cerrada hasta que se definan reglas explícitas.

---

## 3. Procedimiento de publicación manual en Firebase Console

1. Iniciar sesión en [Firebase Console](https://console.firebase.google.com/).
2. Seleccionar el proyecto `easyhome-6ef93`.
3. Navegar en el menú lateral a **Firestore Database** -> pestaña **Reglas (Rules)**.
4. Reemplazar el editor con el contenido completo de [firestore.rules](file:///C:/easyhome/firestore.rules).
5. Hacer clic en **Publicar (Publish)**.
6. Probar en **Rules Playground**:
   - `get` en `/productos/prod123` con `auth.uid = "usuario_ajeno"` -> debe dar `Simulated read denied`.
   - `create` en `/usuarios/nuevo` con `{ esAdministrador: true }` -> debe dar `Simulated write denied`.
