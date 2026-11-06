# Bitácora de Merges a `develop`

Registro histórico de ramas integradas a la rama principal de integración `develop`.

---

## 2026-11-05 — Merge #12: Editar Producto
- **Rama origen:** `feat/editarProducto`
- **Rama destino:** `develop`
- **Tarjeta:** #12 — Editar nombre y cantidad de producto
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 71
- **Tests después:** 75 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #13: Eliminar Producto
- **Rama origen:** `feat/eliminarProducto`
- **Rama destino:** `develop`
- **Tarjeta:** #13 — Confirmación y eliminación de producto
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 75
- **Tests después:** 80 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #14: Feedback de Confirmación
- **Rama origen:** `feat/feedbackConfirmacion`
- **Rama destino:** `develop`
- **Tarjeta:** #14 — Feedback visual de confirmación
- **Estrategia:** `git merge --no-ff`
- **Tests antes:** 80
- **Tests después:** 86 (100% pasando)
- **Autoría:** Carol Ríos / Jaqueline Camarillo

## 2026-11-05 — Merge #16: Dashboard de Quehaceres en Tiempo Real
- **Fecha:** 2026-11-05
- **Rama origen:** `origin/feat/dashboardQuehaceres`
- **Rama destino:** `develop`
- **Tarjeta:** #16 — Dashboard de quehaceres en tiempo real
- **Commit de merge:** `421cf02`
- **Estrategia:** `git merge --no-ff`
- **Resumen:**
  - Modelo `Quehacer` (`id`, `titulo`, `asignadoA`, `hecho`, `hogarId`, `creadoPor`, `fechaLimite`).
  - `QuehaceresService` reactivo con `snapshots()` y manejo de excepciones en español (`QuehaceresException`).
  - Barra inferior con pestañas "Compras" y "Quehaceres".
  - Filtros: "Todos", "Mis quehaceres", "Pendientes", "Completados".
  - Botón flotante (+) visible únicamente para el creador/administrador del hogar.
  - Reglas de seguridad `firestore.rules` versionadas y documentadas en `bitacora/reglas-firestore.md`.
- **Tests antes:** 86 pasando
- **Tests después:** 97 pasando (100% éxito)
- **Autor:** Jaqueline Camarillo
