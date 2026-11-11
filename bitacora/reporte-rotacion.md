# Reporte y Guía de Prueba Manual: Rotación Semanal Automática (#20)

> **Proyecto Firebase:** `easyhome-6ef93`  
> **Rama:** `feat/rotacionSemanal`  
> **Fecha:** 2026-11-05  
> **Responsable:** Jaqueline Camarillo (Ingeniería de Software)

---

## 1. Resumen de la Funcionalidad Implementada
La tarjeta **#20** implementa la reasignación automática de los quehaceres marcados como recurrentes (`recurrente: true`) entre los miembros de un hogar cada semana.
- **Disparo:** Se ejecuta de manera transparente al abrir el dashboard (`DashboardScreen._iniciar()`).
- **Idempotencia:** Verifica el campo `hogar.ultimaRotacion` (formato ISO `YYYY-MM-DD` correspondiente al lunes de la semana). Si ya coincide con la semana en curso, no realiza ninguna acción adicional.
- **Transición:** Si la semana actual es posterior a `ultimaRotacion`, calcula la diferencia de semanas ($\Delta s$) y rota los quehaceres recurrentes de forma atómica en Firestore (`WriteBatch`), reiniciando además el estado a pendiente (`hecho: false`).
- **Feedback:** Cuando la rotación ocurre, el usuario recibe el mensaje de confirmación: `"Se rotaron los quehaceres de la semana"`.

---

## 2. Guía de Prueba Manual con 2 Cuentas y Firebase Console

### Requisitos previos
1. Dos cuentas de usuario registradas en la app que pertenezcan al **mismo hogar**:
   - **Usuario 1 (Admin):** ej. `admin@easyhome.test` (UID: `uid_admin`)
   - **Usuario 2 (Miembro):** ej. `miembro@easyhome.test` (UID: `uid_miembro`)
2. Acceso a la [Consola de Firebase](https://console.firebase.google.com/) en el proyecto `easyhome-6ef93` (sección Firestore Database).

---

### Paso a Paso para la Prueba de Rotación

#### Fase A: Crear quehacer recurrente
1. Iniciar sesión en la app con la cuenta de **Usuario 1 (Admin)**.
2. Ir a la pestaña **Quehaceres**.
3. Pulsar el botón flotante **(+)** para abrir la pantalla *Nuevo Quehacer*.
4. Ingresar un título: `"Lavar trastes del comedor"`.
5. Seleccionar como responsable inicial a **Usuario 1**.
6. Activar el interruptor **"Repetir semanalmente"** (`switch_recurrente`).
7. Pulsar **"Guardar quehacer"**.
8. Verificar en el dashboard:
   - La tarea aparece asignada a **Usuario 1**.
   - Muestra el distintivo visual con icono de repetición: **"Semanal"**.

#### Fase B: Marcar la tarea como hecha (opcional para verificar reinicio)
1. Marcar la casilla de verificación (checkbox) del quehacer.
2. Confirmar que el texto se tacha y se marca como completada.

#### Fase C: Simular cambio de semana en Firebase Console
1. Abrir la pestaña de **Firestore Database** en la Consola de Firebase.
2. Navegar a la colección `hogares` y seleccionar el documento correspondiente al hogar de prueba.
3. Observar los campos:
   - `ultimaRotacion`: string con la clave del lunes actual (ej. `"2026-11-02"`).
   - `ordenRotacion`: lista con los UIDs `["uid_admin", "uid_miembro"]`.
4. Editar manualmente el campo `ultimaRotacion`:
   - Cambiar su valor a una fecha de una semana anterior, por ejemplo: `"2026-10-26"`.
   - Guardar los cambios en la consola de Firestore.

#### Fase D: Ejecutar y validar la rotación
1. En el dispositivo o emulador, cerrar la app o salir a la pantalla de bienvenida y volver a iniciar sesión con **Usuario 2** (o recargar el dashboard con cualquiera de los integrantes).
2. Al ingresar al dashboard de Quehaceres:
   - Aparece en la parte inferior el mensaje flotante: **"Se rotaron los quehaceres de la semana"**.
   - La tarea `"Lavar trastes del comedor"` ahora aparece asignada automáticamente a **Usuario 2**.
   - El estado de la tarea volvió a **pendiente** (`hecho: false`, casilla desmarcada).
3. Regresar a Firebase Console:
   - Verificar que `hogares/{hogarId}.ultimaRotacion` se actualizó automáticamente a la semana actual (`"2026-11-02"`).

#### Fase E: Probar un segundo ciclo de rotación
1. Volver a cambiar manualmente `ultimaRotacion` en Firebase Console a `"2026-10-26"`.
2. Volver a abrir el dashboard en la app.
3. Observar que:
   - Se muestra nuevamente `"Se rotaron los quehaceres de la semana"`.
   - La tarea `"Lavar trastes del comedor"` rota de regreso a **Usuario 1** (completando el ciclo de 2 vueltas sin saltarse a ningún integrante).

---

## 3. Cobertura de Pruebas Automatizadas
La funcionalidad cuenta con cobertura al 100% mediante pruebas unitarias y de widgets en:
- `test/rotacion_semanal_test.dart` (21 pruebas: cálculo de semanas, años bisiestos, saltos de 1 y más semanas, adición y remoción de integrantes, y simulación de 3 ciclos completos).
- `test/quehacer_test.dart` (serialización y deserialización del atributo `recurrente`).
- `test/agregar_quehacer_screen_test.dart` (interacción y persistencia del switch de recurrencia).
- `test/dashboard_quehaceres_test.dart` (renderizado del badge "Semanal" y ejecución de rotación).
- `test/editar_quehacer_test.dart` (edición del switch de recurrencia en modal de edición).
