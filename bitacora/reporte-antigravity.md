# Reporte de Ejecución Autónoma — EasyHome (Antigravity)

**Desarrollado para:** Jaqueline Camarillo  
**Repositorio:** [JaquelineCamarillo/EasyHome](https://github.com/JaquelineCamarillo/EasyHome)  
**Proyecto Firebase:** `easyhome-6ef93`  
**Fecha de finalización:** 5 de noviembre de 2026  

---

## 1. Tabla de Merges de la Fase 1 (Ramas de Carol integradas a `develop`)

Línea base previa al inicio de merges: **75 tests pasados al 100%**.

| Orden | Rama de Carol | Tarjeta | Resultado del Merge | Tests Antes / Después | Estado de Push |
|---|---|---|---|---|---|
| 1 | `origin/feat/editarProducto` | #12 | Exitoso (estrategia ort, sin conflictos) | 75 / 78 (+3) | Integrado en local |
| 2 | `origin/feat/eliminarProducto` | #13 | Exitoso (estrategia ort, sin conflictos) | 78 / 80 (+2) | Integrado en local |
| 3 | `origin/feat/feedbackConfirmacion` | #14 | Exitoso (estrategia ort, sin conflictos) | 80 / 86 (+6) | Integrado en local |
| **Final** | `develop` | - | Merge commits `--no-ff` completados | **86 tests verdes** | **Pushed a `origin/develop` (`f34639a..0d506b4`)** |

*Nota:* `main` se mantuvo 100% intacta en todo momento cumpliendo la regla dura #1.

---

## 2. Tabla de Ramas de la Fase 2 (Módulo de Quehaceres)

Ramas encadenadas secuencialmente desde `develop`, sin mergear, verificadas con tests en verde y subidas a `origin`:

| Orden | Rama | Tarjeta | Base directa | Commit final | Tests pasando | Estado Push | Archivo PR generado |
|---|---|---|---|---|---|---|---|
| 1 | `feat/dashboardQuehaceres` | #16 | `develop` | `1db61e7` | **97 tests** | `origin/feat/dashboardQuehaceres` | `bitacora/pr/feat-dashboardQuehaceres.md` |
| 2 | `feat/agregarQuehacer` | #17 | `feat/dashboardQuehaceres` | `ca2e249` | **104 tests** | `origin/feat/agregarQuehacer` | `bitacora/pr/feat-agregarQuehacer.md` |
| 3 | `feat/marcarQuehacerHecho` | #18 | `feat/agregarQuehacer` | `c6bc10d` | **107 tests** | `origin/feat/marcarQuehacerHecho` | `bitacora/pr/feat-marcarQuehacerHecho.md` |
| 4 | `feat/editarQuehacer` | #19 | `feat/marcarQuehacerHecho` | *(commit de esta rama)* | **112 tests** | `origin/feat/editarQuehacer` | `bitacora/pr/feat-editarQuehacer.md` |

---

## 3. Decisiones Arquitectónicas y de Diseño Tomadas

1. **Responsable del Quehacer (sin duplicidad de datos):**
   - El documento Firestore `quehaceres/{id}` solo guarda `asignadoA` (el `uid` del usuario).
   - La interfaz cruza en tiempo real ese `uid` con el stream `HogarService.observarIntegrantes(hogarId)`. Si el integrante cambia de nombre o es reasignado, se refleja en vivo. Si no se encuentra en la lista, muestra `"Integrante"`.
2. **Navegación del Dashboard:**
   - Se implementó una barra de navegación inferior (`BottomNavigationBar`) para alternar entre "Compras" y "Quehaceres" de forma nativa y fluida.
   - De esta manera, el módulo de Compras y sus 15 pruebas de widget preexistentes no sufrieron alteración alguna en sus selectores ni estructuras de tabs.
3. **Ordenamiento de Quehaceres en Memoria:**
   - Se ordenan en el cliente: primero tareas pendientes, luego por fecha límite más próxima (las tareas con fecha van antes que las sin fecha) y por último alfabéticamente por título.
   - Esto evita requerir la creación manual de índices compuestos en Firestore.
4. **Desmarcar Quehaceres (Toggle bidireccional):**
   - El responsable puede marcar una tarea como hecha y también desmarcarla en caso de error o tarea recurrente.
5. **Control de Permisos Estricto:**
   - Botón (+) y menú de opciones (Editar, Reasignar, Eliminar) visibles únicamente para administradores (`esAdministrador == true`).
   - Bloqueo en UI y servicio: Si un usuario regular intenta crear o disparar opciones, recibe mensajes informativos amigables (`"Solo el administrador puede crear quehaceres"`, `"No tienes permiso para esta acción"`).
   - Checkbox de completar tarea: deshabilitado para no-responsables; al tocarlo reciben la notificación `"Solo <nombre> puede marcar este quehacer"`.

---

## 4. Aspectos que Fallaron, Ajustes Realizados y Pendientes

1. **Herramienta GitHub CLI (`gh`):**
   - `gh` no se encuentra instalado en el entorno de la máquina local. Por ello no se cerraron los PRs vía CLI; sin embargo, las ramas de Carol ya están integradas limpiamente en `develop` y pusheadas al repositorio remoto.
2. **Icono `Icons.person_sync_outlined` en Flutter:**
   - No disponible en la versión del SDK instalada; se reemplazó de forma limpia por `Icons.swap_horiz_rounded` para la acción de reasignación.
3. **Reglas de Seguridad (`firestore.rules`):**
   - Se versionó el archivo `firestore.rules` con las reglas de `quehaceres` y se dejó comentada la propuesta endurecida de `usuarios`.
   - **Pendiente para Jaqueline:** La publicación en Firebase Console es un paso manual (copiar reglas, validar en Rules Playground y publicar en el proyecto `easyhome-6ef93`).

---

## 5. Guía de Pruebas Manuales (2 Cuentas en 2 Dispositivos / Navegadores)

Para verificar el funcionamiento en tiempo real extremo a extremo en Firebase Console:

### Preparación
- **Cuenta A (Administrador):** Usuario con `esAdministrador: true` en el hogar (ej. Jaqueline).
- **Cuenta B (Miembro):** Usuario integrante del mismo hogar con `esAdministrador: false` (ej. Carlos).

### Escenarios de Prueba

1. **Creación en vivo:**
   - En Dispositivo A (Admin), ir a la pestaña **Quehaceres** y pulsar el botón **(+)**.
   - Crear el quehacer *"Limpiar la terraza"*, asignarlo a la **Cuenta B** y definir una fecha límite.
   - Al pulsar "Crear quehacer", verificar en el Dispositivo B que la tarea aparece de inmediato sin recargar la pantalla.

2. **Marcado por el responsable:**
   - En Dispositivo B (Responsable), tocar el checkbox del quehacer recién creado.
   - Verificar que cambia a estado *"Hecho"* (icono verde y texto tachado) y que en Dispositivo A se refleja en vivo simultáneamente.
   - En Dispositivo B, volver a tocar el checkbox para comprobar que regresa a estado *"Pendiente"*.

3. **Restricción de marcado (No-responsable bloqueado):**
   - En Dispositivo A (no es el responsable de esa tarea), intentar presionar el checkbox o la tarjeta del quehacer de Carlos.
   - Verificar que el checkbox está deshabilitado y que aparece el mensaje: `"Solo Carlos puede marcar este quehacer"`.
   - Comprobar que el estado de la tarea en Firestore no cambia.

4. **Acciones administrativas (Editar, Reasignar y Eliminar):**
   - En Dispositivo A (Admin), presionar el botón ⋮ o mantener presionada la tarea.
   - Seleccionar **Editar**: cambiar el título a *"Limpiar y pintar la terraza"*; comprobar que se actualiza en ambos dispositivos.
   - Seleccionar **Reasignar**: cambiar el responsable a la Cuenta A; verificar que ahora el nombre asignado es Jaqueline.
   - Seleccionar **Eliminar**: pulsar *"Cancelar"* en el diálogo (la tarea no se borra); pulsar *"Eliminar"* en un segundo intento (la tarea desaparece de ambos dispositivos).

5. **Restricción de permisos para miembros:**
   - En Dispositivo B (Miembro no admin):
     * Verificar que el botón flotante **(+)** NO aparece en la interfaz.
     * Si intenta acceder a `/agregar-quehacer`, verificar que se muestra la pantalla de bloqueo con el texto `"Solo el administrador puede crear quehaceres"`.
     * Comprobar que en las tarjetas de quehacer no aparece el icono de opciones (⋮) y que al mantener presionada una tarjeta se muestra el mensaje `"No tienes permiso para esta acción"`.
