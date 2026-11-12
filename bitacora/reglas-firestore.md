# Reglas de Seguridad de Firestore (`firestore.rules`) — EasyHome

> **IMPORTANTE:** La publicación de estas reglas en producción es **manual**. Deben copiarse y pegarse en la **Consola de Firebase** (`easyhome-6ef93` -> Firestore Database -> pestaña *Reglas/Rules*) y probarse previamente en el **Rules Playground** antes de publicarlas.

---

## 1. Resumen de mejoras y reglas agregadas

### Función auxiliar `soyAdminDe(hid)`
```firestore-rules
function soyAdminDe(hid) {
  let yo = get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data;
  return yo.hogarId == hid && yo.esAdministrador == true;
}
```
Verifica que el usuario solicitante pertenezca al hogar indicado y cuente con el rol `esAdministrador: true`.

---

### Reglas para la colección `usuarios` (#21 - fcmToken)
```firestore-rules
match /usuarios/{uid} {
  allow read: if estaAutenticado();
  allow create: if estaAutenticado() && request.auth.uid == uid;
  allow update: if estaAutenticado() && (
    // El usuario puede actualizar su propio token FCM (#21)
    (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken']))
    // O su perfil básico (nombre, color de avatar, token)
    || (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre', 'avatarColor', 'fcmToken']))
    // O vincularse / desvincularse de un hogar
    || (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId', 'esAdministrador']))
  );
  allow delete: if false;
}
```

- Cada usuario puede guardar o eliminar su propio `fcmToken` sin exponer la posibilidad de alterar otros campos no autorizados de su documento.
- El notificador local corre con credenciales de cuenta de servicio mediante el SDK Admin de Firebase, el cual omite las reglas de seguridad de cliente.

---

### Reglas para la colección `quehaceres`
```firestore-rules
match /quehaceres/{quehacerId} {
  allow read:   if estaAutenticado() && resource.data.hogarId == miHogarId();
  allow create: if estaAutenticado()
                && soyAdminDe(request.resource.data.hogarId)
                && request.resource.data.creadoPor == request.auth.uid
                && request.resource.data.hecho == false;
  allow update: if estaAutenticado() && (
      // Admin del hogar puede actualizar cualquier campo del quehacer
      (soyAdminDe(resource.data.hogarId) && request.resource.data.hogarId == resource.data.hogarId)
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
```

- **Lectura (`read`):** Cualquier integrante del hogar autenticado puede consultar los quehaceres de su hogar.
- **Creación (`create`):** Solo los administradores del hogar pueden crear quehaceres. El quehacer debe crearse con `hecho: false` y con `creadoPor` igual al `uid` del administrador.
- **Actualización (`update`):**
  1. El administrador del hogar puede editar o reasignar cualquier campo del quehacer (manteniendo el `hogarId` constante).
  2. El integrante responsable (`resource.data.asignadoA == request.auth.uid`) puede actualizar **únicamente** el campo `hecho` (`affectedKeys().hasOnly(['hecho'])`). Ningún otro integrante puede alterar el estado ni los datos.
  3. **Rotación Semanal (#20):** Cualquier integrante del hogar puede ejecutar la rotación semanal automática en quehaceres recurrentes (`recurrente == true`), actualizando únicamente los campos `asignadoA` (nuevo responsable del ciclo) y `hecho` (reiniciado a `false`).
- **Eliminación (`delete`):** Exclusiva para el administrador del hogar.

---

## 2. Procedimiento de publicación manual en Firebase Console

1. Iniciar sesión en [Firebase Console](https://console.firebase.google.com/).
2. Seleccionar el proyecto `easyhome-6ef93`.
3. Navegar en el menú lateral a **Firestore Database** -> pestaña **Reglas (Rules)**.
4. Reemplazar el editor con el contenido completo de [firestore.rules](file:///C:/easyhome/firestore.rules).
5. Hacer clic en **Publicar (Publish)**.
6. Verificar en el **Rules Playground** que las simulaciones de lectura/escritura respondan de acuerdo a lo esperado.
