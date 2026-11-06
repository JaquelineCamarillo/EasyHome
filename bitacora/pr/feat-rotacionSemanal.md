# PR: feat(quehaceres): rotación semanal automática de quehaceres recurrentes (#20)

**Base:** `develop` (o `origin/feat/editarQuehacer` durante el ciclo de integración)  
**Rama:** `feat/rotacionSemanal`

---

## Resumen
Implementación de la rotación semanal automática de quehaceres recurrentes (#20). Permite configurar quehaceres con periodicidad recurrente semanal para que, al iniciar cada nueva semana (clave ISO `YYYY-MM-DD` de cada lunes), roten de manera determinista y justa entre los integrantes del hogar sin requerir reasignación manual. La rotación se dispara de forma limpia y transparente al abrir el dashboard cuando se conoce el `hogarId`, utilizando operaciones por lote atómicas en Firestore y previniendo ejecuciones duplicadas mediante control de semana procesada.

---

## Cambios realizados
1. **Reglas documentadas (`bitacora/reglas-rotacion.md`)**:
   - Definición matemática de la semana ISO lunes (`claveSemana` formato `YYYY-MM-DD`).
   - Cálculo de saltos de semanas transcurridas ($\Delta s = s_2 - s_1$) para semanas vacías.
   - Algoritmo de rotación cíclica $(i + \Delta s) \pmod n$ garantizando que nadie se salte turnos.
   - Reconciliación determinista de orden al unirse o salir integrantes del hogar (orden alfabético por UID para desempates).
   - Tabla de 3 ciclos completos para integrantes A, B y C verificando distribución equitativa.
   - Acuerdo formal de diseño documentado con fecha 2026-11-05.
2. **Utilidad pura (`lib/utils/rotacion_semanal.dart`)**:
   - `claveSemana(DateTime)`: obtiene la clave del lunes correspondiente a cualquier fecha.
   - `semanasEntre(clave1, clave2)`: calcula las semanas transcurridas entre dos claves de rotación.
   - `reconciliarOrden(integrantesActuales, ordenPrevio)`: mantiene el orden preexistente agregando nuevos al final y removiendo a quienes salieron.
   - `siguienteResponsable(asignadoActual, integrantes, saltos)`: calcula el nuevo asignado preservando el ciclo exacto.
3. **Modelo de datos extendido (`lib/models/quehacer.dart`)**:
   - Nuevo atributo `recurrente: bool` (por defecto `false`).
   - Métodos `fromMap`, `toMap` y `copyWith` actualizados.
4. **Servicio Firestore (`lib/services/quehaceres_service.dart`)**:
   - Método `rotarSiCorresponde(String hogarId)`:
     * Lectura del documento del hogar (`hogares/{hogarId}`) para obtener `ultimaRotacion` y `ordenRotacion`.
     * Compara contra la semana actual; si ya rotó esta semana, retorna `false` inmediatamente (idempotente).
     * Si no tiene `ultimaRotacion` previa, inicializa la semana actual y el orden como línea base sin rotar anticipadamente.
     * Consulta quehaceres recurrentes (`recurrente == true`) del hogar.
     * Ejecuta un `WriteBatch` atómico actualizando `asignadoA` al siguiente integrante y reiniciando `hecho = false`.
     * Actualiza `ultimaRotacion` y `ordenRotacion` en el hogar.
     * Retorna `true` únicamente si se ejecutó una rotación efectiva.
5. **Interfaz de usuario (UI)**:
   - **Formulario Agregar (`lib/screens/agregar_quehacer_screen.dart`)**:
     * Switch interactivo "Repetir semanalmente" con icono `Icons.repeat_rounded` (`Key('switch_recurrente')`).
   - **Dashboard & Edición (`lib/screens/dashboard_screen.dart`)**:
     * Ejecución automática de `rotarSiCorresponde` al cargar el dashboard en `_iniciar()`.
     * Notificación amigable con `AppFeedback.mostrarExito(context, 'Se rotaron los quehaceres de la semana')` cuando ocurre una rotación.
     * Modal de edición con switch "Repetir semanalmente" (`Key('switch_recurrente_edicion')`) para cambiar la recurrencia de una tarea existente.
     * Badge visual "Semanal" con icono `Icons.repeat_rounded` (`Key('badge_recurrente_${q.id}')`) visible en las tarjetas de quehaceres recurrentes.
6. **Reglas de seguridad (`firestore.rules` y `bitacora/reglas-firestore.md`)**:
   - Regla agregada permitiendo a cualquier integrante del hogar autenticado actualizar únicamente `asignadoA` y `hecho` en quehaceres con `recurrente == true` durante la rotación.
7. **Pruebas automatizadas**:
   - 21 pruebas unitarias en `test/rotacion_semanal_test.dart` verificando domingos, lunes, años bisiestos, saltos de varias semanas, entrada/salida de integrantes y 3 ciclos completos sin omisiones.
   - Pruebas unitarias de serialización en `test/quehacer_test.dart`.
   - Pruebas de widget en `test/agregar_quehacer_screen_test.dart`, `test/dashboard_quehaceres_test.dart` y `test/editar_quehacer_test.dart`.

---

## Cómo probar
1. Ejecutar la suite completa de pruebas:
   ```bash
   flutter test
   ```
2. Crear un quehacer activando la opción "Repetir semanalmente".
3. Verificar que la tarjeta del quehacer muestra el badge "Semanal".
4. Ver `bitacora/reporte-rotacion.md` para la guía paso a paso de prueba manual en Firebase Console con 2 cuentas simulando un cambio de semana.

---

## Criterios de aceptación cumplidos
- [x] Reglas de rotación documentadas en `/bitacora` antes de programar (`bitacora/reglas-rotacion.md`).
- [x] Al iniciar una nueva semana, los quehaceres marcados como recurrentes se reasignan automáticamente.
- [x] Probado con al menos 2 ciclos de rotación (verificados 3 ciclos completos en tests automatizados y documentación).
- [x] Switch de recurrencia en creación y edición de quehaceres.
- [x] Distintivo visual (badge "Semanal") en tarjetas recurrentes.
- [x] Notificación visual informativa cuando ocurre la rotación automática al iniciar la app.
