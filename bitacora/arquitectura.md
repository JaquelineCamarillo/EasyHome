# Arquitectura — EasyHome

> Tarjeta Trello #8 — Configurar estructura y ramas del repositorio
> Última actualización: 4 de octubre de 2026

## 1. Visión general

EasyHome es una app Flutter que combina dos módulos sobre una base de datos compartida en Firebase:

- **Módulo de compras** (Carol): lista de productos del hogar, marcar como comprados.
- **Módulo de quehaceres** (Princes): reparto y seguimiento de tareas del hogar.

Ambos módulos comparten el concepto de **hogar** (`hogarId`): cada usuario pertenece a un hogar, y todo lo que ve/edita está filtrado por ese hogar.

## 2. Stack

| Capa | Tecnología |
|---|---|
| Cliente | Flutter (Dart) |
| Backend / BaaS | Firebase |
| Base de datos | Cloud Firestore |
| Autenticación | Firebase Authentication (correo/contraseña) |
| Control de versiones | Git + GitHub |

Proyecto de Firebase: `easyhome-6ef93`.

## 3. Estructura de carpetas del proyecto

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

## 4. Modelo de datos

El modelo de datos (colecciones `hogares`, `usuarios`, `productos`, `quehaceres`) está documentado en detalle en `bitacora/modelo-datos-firestore.md`, junto con las reglas de seguridad de Firestore.

## 5. Flujo de ramas (branching)

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

## 6. Decisiones del equipo

- Metodología: Scrum, con tablero de Trello.
- Base de datos: Firebase/Firestore (decidido sobre otras alternativas por la necesidad de sincronización en tiempo real entre dispositivos).
- Modo de producción en Firestore desde el inicio, para forzar el uso de reglas de seguridad.