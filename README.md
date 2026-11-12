# EasyHome

App de hogar compartido que unifica **lista de compras** y **reparto de quehaceres**, dirigida a familias o roommates. Proyecto Integrador de la materia Desarrollo Móvil Integral (UTNG).

## Equipo

- Juana Jaqueline Camarillo Olaez
- Carol Guadalupe Ríos Rios
- Princes Rocio Guerrero Sanchez

**Profesor:** Anastacio Rodríguez García
**Metodología:** Scrum — tablero de Trello: https://trello.com/invite/b/690aa99fadeed0a42d97cd71/ATTIa3fa005ee2bac61064250270bfae8081C8B98B56/easyhome

## Tecnologías

- **Flutter** (Dart) — app multiplataforma (Android principalmente, también configurado para iOS/Web/Windows)
- **Firebase**:
  - Firestore (base de datos)
  - Authentication (correo/contraseña)
- Proyecto de Firebase: `easyhome-6ef93`

## Requisitos previos

Antes de clonar el proyecto, instala en tu computadora:

1. **Flutter SDK** (canal stable) — https://docs.flutter.dev/get-started/install
2. **Android Studio** (trae el Android SDK y el emulador). Durante la instalación acepta las licencias del SDK.
3. **Git**
4. **VS Code** (recomendado) con las extensiones "Flutter" y "Dart"
5. Un teléfono Android con **depuración USB activada**, o un emulador configurado en Android Studio

Verifica que todo esté listo corriendo en una terminal:

```
flutter doctor
```

Resuelve cualquier ❌ o ⚠️ que marque antes de seguir (sobre todo las licencias de Android: `flutter doctor --android-licenses`).

## Clonar el proyecto

```
git clone https://github.com/JaquelineCamarillo/EasyHome.git
cd EasyHome
```

Por defecto quedas en la rama `main`. Para empezar a trabajar, cambia a `develop`:

```
git checkout develop
git pull
```

## Instalar dependencias

```
flutter pub get
```

Esto descarga todos los paquetes que usa el proyecto (incluyendo `firebase_core`, `cloud_firestore`, `firebase_auth`, etc.), según lo que está declarado en `pubspec.yaml`.

## Configuración de Firebase y Servicios en la Nube

Por directrices de seguridad y buenas prácticas de protección de credenciales (evitando publicar secretos reales en el control de versiones), el repositorio proporciona plantillas de configuración con valores de referencia:

1. **Configuración FlutterFire:**
   - Si trabajas en un entorno de desarrollo nuevo o local, copia la plantilla de ejemplo:
     ```bash
     cp lib/firebase_options.example.dart lib/firebase_options.dart
     ```
   - O bien, enlaza el proyecto directamente con la CLI oficial de Firebase:
     ```bash
     flutterfire configure --project=easyhome-6ef93
     ```

2. **Configuración Nativa Android (`google-services.json`):**
   - El archivo real se encuentra estrictamente excluido en `.gitignore` para no exponer identificadores del proyecto.
   - Existe una plantilla de estructura en `android/app/google-services.json.example`.
   - Para compilar y ejecutar localmente, descarga el archivo legítimo desde Firebase Console:
     1. Entra a **Firebase Console** → Selecciona el proyecto del equipo.
     2. Ve a ⚙️ **Configuración del proyecto** → Sección **Tus apps** → App Android (`com.example.easyhome`).
     3. Descarga `google-services.json` y colócalo en:
        `android/app/google-services.json`

> [!NOTE]
> Para consultar la arquitectura de seguridad integral, modelo de amenazas, control de acceso por roles y matriz de cumplimiento OWASP, consulta la documentación detallada en [`bitacora/seguridad.md`](bitacora/seguridad.md).

## Correr la app

1. Conecta tu teléfono Android por USB (con depuración USB activada) o abre un emulador desde Android Studio.
2. Verifica que Flutter lo detecta:
   ```
   flutter devices
   ```
3. Corre la app:
   ```
   flutter run
   ```

La primera vez que compiles puede tardar varios minutos porque Gradle descarga dependencias de Android. Las siguientes veces es mucho más rápido.

### Comandos útiles mientras `flutter run` está activo

- `r` — hot reload (aplica cambios de código sin reiniciar la app)
- `R` — hot restart (reinicia la app completa; úsalo si cambiaste `main()` o algo que solo corre al inicio)
- `q` — salir

## Problemas comunes

**Error de NDK ("Android sdkmanager did not install NDK ... into ...\Android\Sdk")**
Abre Android Studio → Tools → SDK Manager → SDK Tools → activa "Show Package Details" → busca "NDK (Side by side)" → instala la versión que pide el error (en este proyecto: `28.2.13676358`).

**Advertencia de Kotlin Gradle Plugin (KGP) por el plugin `firebase_core`**
Es solo una advertencia de versiones futuras de Flutter, no rompe el build actual. Se puede ignorar por ahora.

**"Lost connection to device"**
Pasa si el teléfono se bloquea, se desconecta el cable, o la app pasa mucho tiempo en segundo plano. Vuelve a correr `flutter run`.

## Estructura del proyecto

```
lib/
  main.dart                     # Punto de entrada, inicializa Firebase
  firebase_options.example.dart # Plantilla de configuración (firebase_options.dart ignorado en Git)
  models/                       # Clases de datos (Hogar, Usuario, Producto, Quehacer)
  screens/                      # Pantallas de la app
  services/                     # Lógica de acceso a Firestore/Auth y FCM
  widgets/                      # Componentes de UI reutilizables (QuehacerCard, ProductoCard, etc.)
notificador/                    # Microservicio local Node.js para notificaciones push FCM
android/                        # Proyecto nativo Android
ios/                            # Proyecto nativo iOS
bitacora/                       # Documentos de arquitectura, seguridad y modelo de datos
```

## Modelo de datos (Firestore)

El modelo de datos (colecciones `hogares`, `usuarios`, `productos`, `quehaceres`) está documentado en `bitacora/modelo-datos-firestore.md`, junto con las reglas de seguridad propuestas.

La arquitectura general del proyecto (stack, estructura de carpetas, decisiones del equipo) está en `bitacora/arquitectura.md`.

## Pruebas automatizadas y Calidad CI

El repositorio integra validaciones automáticas mediante GitHub Actions (`.github/workflows/security-ci.yml`):
- **Análisis estático:** `flutter analyze` con 0 errores y 0 advertencias.
- **Suite Flutter:** 153 pruebas unitarias y de widgets (`flutter test`).
- **Suite Notificador FCM:** 17 pruebas con Jest (`cd notificador && npm test`).
- **Gestión de dependencias:** Monitoreo semanal automatizado con `.github/dependabot.yml` y auditoría con `flutter pub outdated`.

## Ramas del repositorio

- **`main`** — código estable, siempre listo para entregar o demostrar.
- **`develop`** — rama de integración, donde se juntan los módulos en desarrollo antes de pasar a `main`.
- **`feature/nombre-funcionalidad`** — una rama por tarea o funcionalidad (ej. `feature/pantalla-registro`, `feature/lista-compras`, `feature/reparto-quehaceres`).

### Flujo para trabajar en una tarea

1. Crear la rama desde `develop`:
   ```
   git checkout develop
   git pull
   git checkout -b feature/nombre-funcionalidad
   ```
2. Hacer el trabajo y subir los commits:
   ```
   git add .
   git commit -m "Descripción del cambio"
   git push -u origin feature/nombre-funcionalidad
   ```
3. Abrir un **Pull Request** en GitHub hacia `develop`.
4. Al menos **otro integrante del equipo revisa** el PR antes de aprobarlo.
5. Hacer **merge** a `develop` una vez aprobado.
6. Cuando `develop` esté estable, se hace merge hacia `main`.

## Flujo de trabajo del equipo

1. Antes de empezar una tarea, revisa la tarjeta correspondiente en Trello.
2. Trabaja siempre sobre una rama `feature/...` creada desde `develop` (ver sección "Ramas del repositorio" arriba). Nunca hagas commits directo a `main` ni a `develop`.
3. Haz commits descriptivos y sube tus cambios con `git push`.
4. Abre un Pull Request hacia `develop` y espera la revisión de al menos otro integrante.
5. Marca la tarjeta de Trello como completada cuando los criterios de aceptación estén cumplidos.