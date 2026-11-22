# Modelo de datos — Firestore (EasyHome)

> Tarjeta Trello #2 — Diseñar el modelo de datos en Firestore
> Tarjeta Trello #20 — Rotación semanal automática
> Tarjeta Trello #21 — Notificaciones push (FCM)
> Requerimientos de la clienta (videollamada): ajustes a productos, espacios y quehaceres
> Última actualización: 21 de noviembre de 2026

## 1. Colecciones

### `hogares/{hogarId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre del hogar o espacio (ej. "Depa de Jaqueline", "Equipo Alfa") |
| `codigoInvitacion` | `string` | Único, 6 caracteres alfanuméricos en mayúscula. Se usa para que otros integrantes se unan al espacio |
| `creadoPor` | `string` | `uid` del usuario que creó el hogar o espacio |
| `tipoEspacio` | `string` | Tipo de espacio o equipo: `hogar` (Hogar / Familia), `roommates` (Roommates / Departamento), `equipo` (Equipo / Proyecto), `oficina` (Oficina / Trabajo), `evento` (Viaje / Evento) |
| `ordenRotacion` | `array<string>` | *(Opcional / #20)* Lista ordenada de `uid`s de integrantes para la secuencia de rotación semanal |
| `ultimaRotacion` | `string` | *(Opcional / #20)* Clave de la última semana rotada en formato `YYYY-MM-DD` (lunes de esa semana) |

### `usuarios/{uid}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre visible del usuario |
| `correo` | `string` | Correo electrónico del usuario |
| `esAdministrador` | `boolean` | `true` si el usuario administra el espacio activo (lo creó o fue promovido) |
| `hogarId` | `string \| null` | Espacio activo actual. `null` si aún no se ha unido a ninguno |
| `hogaresIds` | `array<string>` | Lista de `hogarId`s de todos los hogares o equipos a los que pertenece el usuario (soporte multi-espacio) |
| `avatarColor` | `string \| number` | Valor del color del avatar del usuario |
| `fcmToken` | `string \| null` | *(#21)* Token de registro Firebase Cloud Messaging para notificaciones push en segundo plano |

### `productos/{productoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `string` | Nombre del producto a comprar (1 a 120 caracteres) |
| `descripcion` | `string \| null` | *(Opcional)* Descripción o detalles adicionales del producto (máximo 250 caracteres) |
| `cantidad` | `number` | Cantidad solicitada (entero > 0) |
| `costo` | `number \| null` | *(Opcional)* Costo unitario estimado del producto (>= 0, hasta 2 decimales) |
| `comprado` | `boolean` | `true` cuando ya se compró |
| `hogarId` | `string` | Espacio al que pertenece el producto (obligatorio, para filtrar por espacio) |
| `agregadoPor` | `string` | `uid` de quien agregó el producto |
| `fechaCreacion` | `timestamp` | Fecha de creación del documento |

### `quehaceres/{quehacerId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `titulo` | `string` | Nombre del quehacer o tarea (1 a 120 caracteres) |
| `descripcion` | `string \| null` | *(Opcional)* Descripción o instrucciones detalladas del quehacer (máximo 300 caracteres) |
| `prioridad` | `string` | Nivel de prioridad: `alta`, `media` (por defecto) o `baja` |
| `categoria` | `string` | Área o categoría: `general`, `limpieza`, `cocina`, `mantenimiento`, `gestion`, `compras` |
| `asignadoA` | `string` | `uid` del integrante responsable |
| `hecho` | `boolean` | `true` cuando el quehacer se completó |
| `hogarId` | `string` | Espacio al que pertenece el quehacer (obligatorio) |
| `creadoPor` | `string` | `uid` de quien creó el quehacer |
| `fechaLimite` | `timestamp \| null` | Fecha límite opcional |
| `recurrente` | `boolean` | *(#20)* `true` si el quehacer rota semanalmente entre los integrantes; `false` por defecto |

### Subcolección `quehaceres/{quehacerId}/comentarios/{comentarioId}`

| Campo | Tipo | Descripción |
|---|---|---|
| `autorId` | `string` | `uid` del integrante que escribió el comentario |
| `autorNombre` | `string` | Nombre del autor del comentario |
| `texto` | `string` | Contenido del comentario (1 a 300 caracteres) |
| `creadoEn` | `timestamp` | Fecha y hora de publicación |

## 2. Reglas de negocio

1. Todo documento de `productos` y `quehaceres` **debe** llevar `hogarId`, para poder filtrar por espacio activo en cada query (ej. `.where('hogarId', isEqualTo: miHogarId)`).
2. Un usuario (incluido el administrador) puede crear, unirse y cambiar entre varios espacios o equipos mediante `hogaresIds` y el selector **"Espacios"**, actualizando su `hogarId` activo.
3. Las reglas de seguridad de Firestore validan que el usuario autenticado solo lea/escriba documentos cuyo `hogarId` coincida con el `hogarId` activo en su propio documento de `usuarios/{uid}`.
4. Los quehaceres se ordenan automáticamente mostrando primero los pendientes (`hecho: false`), luego por nivel de prioridad (`alta` -> `media` -> `baja`), fecha límite más próxima y orden alfabético.
5. Para quehaceres recurrentes (`recurrente: true`), al inicio de cada nueva semana (`claveSemana(DateTime.now()) != ultimaRotacion`), se reasignan en orden cíclico y su estado `hecho` se restablece a `false`.
6. En `usuarios/{uid}.fcmToken`, cada usuario registra su token al autenticarse y otorgar permiso, y se borra (`FieldValue.delete()`) al cerrar sesión para garantizar la privacidad y evitar envíos espurios.

## 3. Reglas de seguridad vigentes (`firestore.rules`)

Ver archivo [firestore.rules](file:///C:/Users/carol/OneDrive/Documentos/Escritorio/EasyHome/EasyHome/firestore.rules) y detalle en [bitacora/reglas-firestore.md](file:///C:/Users/carol/OneDrive/Documentos/Escritorio/EasyHome/EasyHome/bitacora/reglas-firestore.md).
