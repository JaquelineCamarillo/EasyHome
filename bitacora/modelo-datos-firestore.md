# Modelo de datos — Firestore (EasyHome)

> Tarjeta Trello #2 — Diseñar el modelo de datos en Firestore
> Última actualización: 4 de octubre de 2026

## 1. Colecciones

### `hogares/{hogarId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre del hogar (ej. "Depa de Jaqueline") |
| `codigoInvitacion` | `string` | Único, 6 caracteres alfanuméricos en mayúscula. Se usa para que otros integrantes se unan al hogar |
| `creadoPor` | `string` | `uid` del usuario que creó el hogar |

### `usuarios/{uid}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre visible del usuario |
| `esAdministrador` | `boolean` | `true` si el usuario administra el hogar (lo creó o fue promovido) |
| `hogarId` | `string \| null` | Hogar al que pertenece. `null` si aún no se ha unido a ninguno |

### `productos/{productoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre del producto a comprar |
| `cantidad` | `number` | Cantidad solicitada |
| `comprado` | `boolean` | `true` cuando ya se compró |
| `hogarId` | `string` | Hogar al que pertenece el producto (obligatorio, para filtrar por hogar) |
| `agregadoPor` | `string` | `uid` de quien agregó el producto |
| `fechaCreacion` | `timestamp` | Fecha de creación del documento |

### `quehaceres/{quehacerId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `titulo` | `string` | Nombre del quehacer |
| `asignadoA` | `string` | `uid` del integrante responsable |
| `hecho` | `boolean` | `true` cuando el quehacer se completó |
| `hogarId` | `string` | Hogar al que pertenece el quehacer (obligatorio) |
| `creadoPor` | `string` | `uid` de quien creó el quehacer |
| `fechaLimite` | `timestamp \| null` | Fecha límite opcional |

## 2. Reglas de negocio

1. Todo documento de `productos` y `quehaceres` **debe** llevar `hogarId`, para poder filtrar por hogar en cada query (ej. `.where('hogarId', isEqualTo: miHogarId)`).
2. Las reglas de seguridad de Firestore deben validar que el usuario autenticado solo lea/escriba documentos cuyo `hogarId` coincida con el `hogarId` guardado en su propio documento de `usuarios/{uid}`.

## 3. Reglas de seguridad propuestas (`firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function estaAutenticado() {
      return request.auth != null;
    }

    function miHogarId() {
      return get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.hogarId;
    }

    match /usuarios/{uid} {
      allow read: if estaAutenticado();
      allow create: if estaAutenticado() && request.auth.uid == uid;
      allow update: if estaAutenticado() && request.auth.uid == uid;
      allow delete: if false;
    }

    match /hogares/{hogarId} {
      allow read: if estaAutenticado() && miHogarId() == hogarId;
      allow create: if estaAutenticado();
      allow update: if estaAutenticado() && miHogarId() == hogarId;
      allow delete: if false;
    }

    match /productos/{productoId} {
      allow read: if estaAutenticado() && resource.data.hogarId == miHogarId();
      allow create: if estaAutenticado() && request.resource.data.hogarId == miHogarId();
      allow update, delete: if estaAutenticado() && resource.data.hogarId == miHogarId();
    }

    match /quehaceres/{quehacerId} {
      allow read: if estaAutenticado() && resource.data.hogarId == miHogarId();
      allow create: if estaAutenticado() && request.resource.data.hogarId == miHogarId();
      allow update, delete: if estaAutenticado() && resource.data.hogarId == miHogarId();
    }
  }
}
```

> Nota: estas reglas son una propuesta inicial basada en la tarjeta de Arquitectura. Ajustar si esa tarjeta define algo distinto (por ejemplo, permisos especiales para `esAdministrador`).

## 4. Documentos de prueba a crear en Firebase Console

Para validar la estructura, crear manualmente un documento de ejemplo en cada colección:

- **hogares**: un documento con `nombre: "Hogar de prueba"`, `codigoInvitacion: "AB12CD"`, `creadoPor: "<tu-uid>"`
- **usuarios**: un documento con ID = tu `uid` real, `nombre: "Jaqueline"`, `esAdministrador: true`, `hogarId: "<id-del-hogar-de-prueba>"`
- **productos**: un documento con `nombre: "Leche"`, `cantidad: 2`, `comprado: false`, `hogarId: "<id-del-hogar-de-prueba>"`, `agregadoPor: "<tu-uid>"`, `fechaCreacion: <timestamp actual>`
- **quehaceres**: un documento con `titulo: "Sacar la basura"`, `asignadoA: "<tu-uid>"`, `hecho: false`, `hogarId: "<id-del-hogar-de-prueba>"`, `creadoPor: "<tu-uid>"`, `fechaLimite: null`

## 5. Revisión del equipo

Pendiente: Carol (módulo de compras) y Princes (módulo de quehaceres) deben revisar este modelo antes de empezar a programar sus módulos.