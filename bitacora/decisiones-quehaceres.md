# Decisiones de Diseño e Implementación — Módulo Quehaceres

Este documento registra las decisiones arquitectónicas y de diseño tomadas para el módulo de Quehaceres (Tarjetas #16, #17, #18 y #19) en EasyHome.

---

## 1. Responsable del Quehacer: No duplicar el nombre en el documento
- **Decisión:** En el documento `quehaceres/{id}`, solo se almacena `asignadoA` con el `uid` del integrante responsable.
- **Razón:** Si un integrante actualiza su nombre de perfil o si se reasigna la tarea, los cambios se reflejan de inmediato y de forma consistente sin necesidad de migrar o sincronizar múltiples documentos de Firestore.
- **Implementación:** La interfaz cruza en tiempo real el `asignadoA` con el `Stream<List<Integrante>>` obtenido mediante `HogarService.observarIntegrantes(hogarId)`. Si el `uid` ya no pertenece al hogar o no está en la lista, se muestra el respaldo `"Integrante"`.

---

## 2. Navegación en el Dashboard
- **Decisión:** Se incorpora una barra de navegación inferior (`BottomNavigationBar`) en `DashboardScreen` para alternar fluidamente entre la sección de **Compras** y la de **Quehaceres**.
- **Razón:** Permite incorporar todo el módulo de Quehaceres con sus propios filtros, estados y acciones sin romper la estructura, funcionalidad, widgets ni pruebas existentes del módulo de Compras.

---

## 3. Ordenamiento de quehaceres en memoria
- **Decisión:** El stream `observarQuehaceres(hogarId)` consulta Firestore filtrando por `where('hogarId', isEqualTo: hogarId)` y realiza el ordenamiento en memoria del cliente:
  1. Quehaceres pendientes primero (`hecho: false`), luego los hechos (`hecho: true`).
  2. Por fecha límite más próxima (las tareas con fecha límite van antes que las tareas sin fecha).
  3. Por título en orden alfabético insensible a mayúsculas/minúsculas.
- **Razón:** Evita la necesidad de crear índices compuestos manuales en Firebase Console, reduciendo la fricción de despliegue y garantizando compatibilidad inmediata.

---

## 4. Desmarcar quehaceres (#18)
- **Decisión:** Se permite que el responsable cambie el estado tanto de pendiente a hecho como de hecho a pendiente (toggle).
- **Razón:** Si un integrante marca una tarea por error, debe poder devolverla al estado pendiente sin fricción ni necesidad de intervención del administrador.

---

## 5. Control de permisos y accesibilidad
- **Decisión:**
  - El botón para agregar quehaceres (FAB) solo se muestra a los usuarios administradores (`esAdministrador == true`).
  - La pantalla de agregar quehacer valida en UI y en el servicio que el usuario sea administrador.
  - El checkbox de marcar quehacer solo se habilita para el responsable directo (`asignadoA == uid`). Para cualquier otro integrante, el control aparece visualmente atenuado/deshabilitado y al tocarlo se muestra un mensaje informativo amigable: `"Solo <nombre> puede marcar este quehacer"`.
  - El menú de opciones de quehacer (Editar, Reasignar, Eliminar) solo es visible y accesible para el administrador del hogar. Si se invoca sin permisos, se muestra el mensaje: `"No tienes permiso para esta acción"`.
