# Arquitectura — EasyHome

> Tarjetas Trello #8 (estructura y ramas) y "Arquitectura e integración inicial en la nube"
> Última actualización: 4 de octubre de 2026

## 1. Visión general

EasyHome es una app Flutter que combina dos módulos sobre una base de datos compartida en Firebase:

- **Módulo de compras** (Carol): lista de productos del hogar, marcar como comprados.
- **Módulo de quehaceres** (Princes): reparto y seguimiento de tareas del hogar.

Ambos módulos comparten el concepto de **hogar** (`hogarId`): cada usuario pertenece a un hogar, y todo lo que ve/edita está filtrado por ese hogar.

## 2. Diagrama de arquitectura

```
                    ┌─────────────────────────┐
                    │     App Flutter          │
                    │  (Android / iOS / Web)   │
                    │                           │
                    │  screens/  services/      │
                    │  widgets/  models/        │
                    └─────────────┬─────────────┘
                                  │
                                  │  SDKs oficiales de Firebase
                                  ▼
          ┌───────────────────────────────────────────┐
          │                 FIREBASE                   │
          │                                             │
          │  ┌───────────────┐   ┌───────────────────┐ │
          │  │ Authentication │   │  Cloud Firestore   │ │
          │  │ (correo/clave) │   │  (hogares,         │ │
          │  │                │   │   usuarios,        │ │
          │  │                │   │   productos,       │ │
          │  │                │   │   quehaceres)      │ │
          │  └───────────────┘   └───────────────────┘ │
          │                                             │
          │  ┌───────────────────────────────────────┐ │
          │  │  Cloud Messaging (FCM)                  │ │
          │  │  Reservado para notificaciones futuras  │ │
          │  │  (ej. recordatorio de quehacer pendiente)│ │
          │  └───────────────────────────────────────┘ │
          └───────────────────────────────────────────┘
```

La app Flutter nunca habla con un servidor propio: todo el acceso a datos y autenticación pasa directo del cliente a los servicios de Firebase, usando los SDKs oficiales y protegido por las reglas de seguridad de Firestore (sección 5).

## 3. Justificación: ¿por qué Firebase?

- **Backend as a Service (BaaS):** no necesitamos levantar, mantener ni pagar un servidor propio — Firebase ya resuelve autenticación, base de datos y hosting de forma administrada.
- **Sincronización en tiempo real:** Firestore notifica a todos los dispositivos conectados cuando un documento cambia. Esto es clave para EasyHome: si un integrante marca un producto como comprado o un quehacer como hecho, los demás lo ven reflejado al instante sin refrescar.
- **Integración nativa con Flutter:** los paquetes `firebase_core`, `cloud_firestore` y `firebase_auth` están mantenidos oficialmente y cubren exactamente lo que el proyecto necesita.
- **Costo:** el plan gratuito (Spark) es suficiente para el alcance de este proyecto académico.

## 4. Stack

| Capa | Tecnología |
|---|---|
| Cliente | Flutter (Dart) |
| Backend / BaaS | Firebase |
| Base de datos | Cloud Firestore |
| Autenticación | Firebase Authentication (correo/contraseña) |
| Control de versiones | Git + GitHub |

Proyecto de Firebase: `easyhome-6ef93`.

## 5. Estructura de carpetas del proyecto

```
lib/
  main.dart          # Punto de entrada, inicializa Firebase
  firebase_options.dart
  models/            # Clases de datos (Hogar, Usuario, Producto, Quehacer)
  screens/           # Pantallas de la app (una carpeta o archivo por pantalla)
  services/          # Lógica de acceso a Firestore/Auth (ej. ProductoService, QuehacerService)
  widgets/           # Componentes de UI reutilizables entre pantallas
bitacora/            # Documentos de arquitectura, modelo de datos y decisiones del equipo
```

**Regla general:** una pantalla no habla directo con Firestore — pasa siempre por un `service`. Esto facilita hacer pruebas y evita duplicar lógica de consultas en varias pantallas.

## 6. Modelo de datos y reglas de seguridad

El modelo de datos completo (colecciones `hogares`, `usuarios`, `productos`, `quehaceres`, con todos sus campos) está documentado en `bitacora/modelo-datos-firestore.md`.

La regla de seguridad central, a nivel de documento, es:

> **Un usuario autenticado solo puede leer o escribir documentos de `productos` y `quehaceres` cuyo campo `hogarId` coincida con el `hogarId` guardado en su propio documento de `usuarios/{uid}`.**

Esto se implementa en Firestore con una función auxiliar que consulta el `hogarId` del usuario autenticado y lo compara contra el documento solicitado (ver el archivo `firestore.rules` propuesto en `bitacora/modelo-datos-firestore.md`). Mientras no se publiquen estas reglas, la base de datos está en modo producción con acceso denegado por defecto (`allow read, write: if false`), así que ningún cliente puede leer ni escribir hasta que las reglas reales se publiquen.

## 7. Manejo de configuración y claves de Firebase

Cada integrante necesita, en su copia local del proyecto, dos archivos de configuración nativa que Firebase genera por plataforma:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` (solo si se compila para iOS)

**Estos archivos no se suben al repositorio.** Están listados en `.gitignore` para evitar subir identificadores de proyecto y claves de API al historial público de GitHub, aunque el repo sea privado. Cada integrante los descarga directamente desde Firebase Console → ⚙️ Configuración del proyecto → sus apps registradas (Android/iOS) → "Descargar google-services.json" / "Descargar GoogleService-Info.plist", y los coloca en la ruta indicada arriba.

El archivo `lib/firebase_options.dart` (generado por `flutterfire configure`) sí se mantiene en el repositorio, ya que es necesario para que cualquiera pueda clonar y correr la app sin reconfigurar Firebase desde cero. La seguridad real de los datos no depende de ocultar este archivo, sino de las reglas de seguridad de Firestore descritas en la sección 6 — es la misma razón por la que un cliente Firebase puede traer sus credenciales embebidas sin que eso comprometa la base de datos.

## 8. Flujo de ramas (branching)

- **`main`**: código estable, siempre listo para entregar/demostrar.
- **`develop`**: rama de integración, donde se juntan los módulos en desarrollo antes de pasar a `main`.
- **`feature/nombre-funcionalidad`**: una rama por tarea/funcionalidad (ej. `feature/pantalla-registro`, `feature/lista-compras`, `feature/reparto-quehaceres`).

### Flujo de trabajo

1. Crear la rama de la tarea desde `develop`:
   ```
   git checkout develop
   git pull
   git checkout -b feature/nombre-funcionalidad
   ```
2. Hacer el trabajo y subir commits a esa rama:
   ```
   git add .
   git commit -m "Descripción del cambio"
   git push -u origin feature/nombre-funcionalidad
   ```
3. Abrir un **Pull Request** en GitHub de `feature/nombre-funcionalidad` hacia `develop`.
4. Al menos **otro integrante del equipo revisa** el PR antes de aprobarlo.
5. Una vez aprobado, hacer **merge** a `develop`.
6. Cuando `develop` tiene una versión estable y probada, se hace merge de `develop` hacia `main`.

## 9. Decisiones del equipo

- Metodología: Scrum, con tablero de Trello.
- Base de datos: Firebase/Firestore (decidido sobre otras alternativas por la necesidad de sincronización en tiempo real entre dispositivos).
- Modo de producción en Firestore desde el inicio, para forzar el uso de reglas de seguridad.