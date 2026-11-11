# Modelo de datos — Firestore (EasyHome)

> Tarjeta Trello #2 — Diseñar el modelo de datos en Firestore
> Tarjeta Trello #20 — Rotación semanal automática
> Última actualización: 5 de noviembre de 2026

## 1. Colecciones

### `hogares/{hogarId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre del hogar (ej. "Depa de Jaqueline") |
| `codigoInvitacion` | `string` | Único, 6 caracteres alfanuméricos en mayúscula. Se usa para que otros integrantes se unan al hogar |
| `creadoPor` | `string` | `uid` del usuario que creó el hogar |
| `ordenRotacion` | `array<string>` | *(Opcional / #20)* Lista ordenada de `uid`s de integrantes para la secuencia de rotación semanal |
| `ultimaRotacion` | `string` | *(Opcional / #20)* Clave de la última semana rotada en formato `YYYY-MM-DD` (lunes de esa semana) |

### `usuarios/{uid}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre visible del usuario |
| `correo` | `string` | Correo electrónico del usuario |
| `esAdministrador` | `boolean` | `true` si el usuario administra el hogar (lo creó o fue promovido) |
| `hogarId` | `string \| null` | Hogar al que pertenece. `null` si aún no se ha unido a ninguno |
| `avatarColor` | `number` | Valor entero del color del avatar del usuario |

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
| `recurrente` | `boolean` | *(#20)* `true` si el quehacer rota semanalmente entre los integrantes; `false` por defecto |

## 2. Reglas de negocio

1. Todo documento de `productos` y `quehaceres` **debe** llevar `hogarId`, para poder filtrar por hogar en cada query (ej. `.where('hogarId', isEqualTo: miHogarId)`).
2. Las reglas de seguridad de Firestore deben validar que el usuario autenticado solo lea/escriba documentos cuyo `hogarId` coincida con el `hogarId` guardado en su propio documento de `usuarios/{uid}`.
3. Para quehaceres recurrentes (`recurrente: true`), al inicio de cada nueva semana (`claveSemana(DateTime.now()) != ultimaRotacion`), se reasignan en orden cíclico y su estado `hecho` se restablece a `false`.

## 3. Reglas de seguridad vigentes (`firestore.rules`)

Ver archivo [firestore.rules](file:///C:/easyhome/firestore.rules) y detalle en [bitacora/reglas-firestore.md](file:///C:/easyhome/bitacora/reglas-firestore.md).
