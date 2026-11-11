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

### Propuesta endurecida para `usuarios` (comentada en `firestore.rules`)
Se incluye en `firestore.rules` como comentario la regla que restringe la autoasignación del rol de administrador y permite a los administradores gestionar los integrantes de su hogar:
```firestore-rules
// allow update: if estaAutenticado() && (
//   (request.auth.uid == uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre','avatarColor']))
//   || (request.auth.uid == uid && resource.data.hogarId == null &&
//       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId','esAdministrador']) &&
//       (request.resource.data.esAdministrador == false ||
//        getAfter(/databases/$(database)/documents/hogares/$(request.resource.data.hogarId)).data.creadoPor == request.auth.uid))
//   || (request.auth.uid == uid && request.resource.data.hogarId == null && request.resource.data.esAdministrador == false &&
//       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId','esAdministrador']))
//   || (resource.data.hogarId != null && soyAdminDe(resource.data.hogarId) &&
//       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hogarId','esAdministrador']) &&
//       (request.resource.data.hogarId == resource.data.hogarId || request.resource.data.hogarId == null))
// );
```
> **Nota de seguridad:** Mantener comentada hasta validar en simulador/Rules Playground todos los flujos de creación y unión a hogares.

---

## 2. Instrucciones para aplicar en Firebase Console
1. Entra a [Firebase Console](https://console.firebase.google.com/) con tu cuenta y selecciona el proyecto `easyhome-6ef93`.
2. Ve a **Firestore Database** en el menú lateral izquierdo y abre la pestaña **Reglas** (*Rules*).
3. Copia el contenido íntegro del archivo `firestore.rules` del repositorio.
4. Antes de publicar, haz clic en **Simulador de reglas** (*Rules Playground*) y comprueba:
   - Lectura autenticada con mismo `hogarId`: permitida.
   - Creación de quehacer por usuario sin `esAdministrador: true`: bloqueada.
   - Creación de quehacer por usuario admin: permitida.
   - Modificación del campo `hecho` por el usuario asignado: permitida.
   - Modificación del campo `hecho` por un usuario distinto al asignado (y no admin): bloqueada.
   - Rotación semanal por integrante del hogar: modificación de `asignadoA` y `hecho` en tarea con `recurrente == true` permitida; cualquier otro campo bloqueado.
5. Haz clic en **Publicar** (*Publish*).
