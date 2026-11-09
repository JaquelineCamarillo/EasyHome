# Reglas de Rotación Semanal Automática (#20)

> **Acordado con el equipo:** Jaqueline Camarillo, Carol Ríos, Princes Guerrero / fecha 2026-11-05

Este documento define el funcionamiento de la rotación automática de quehaceres recurrentes en EasyHome, garantizando una distribución equitativa de las tareas del hogar semana a semana.

---

## 1. Concepto y Objetivos
- **Quehacer recurrente:** Tarea del hogar marcada con `recurrente: true` que se repite periódicamente semana a semana (ej. "Lavar platos", "Sacar basura", "Limpiar el baño").
- **Objetivo:** Rotar automáticamente el responsable (`asignadoA`) entre todos los integrantes activos del hogar al inicio de cada nueva semana, sin intervención manual de los administradores.
- **Reinicio de estado:** Al rotar, cada quehacer recurrente vuelve a su estado pendiente (`hecho: false`).
- **Quehaceres no recurrentes:** Las tareas con `recurrente: false` no se ven afectadas en ningún momento por la rotación.

---

## 2. Definición de la Semana y Clave de Rotación
- **Día de inicio:** Lunes (conforme al estándar ISO-8601, donde en Dart `DateTime.monday == 1`).
- **Clave de semana (`claveSemana`):** Cadena en formato `YYYY-MM-DD` correspondiente al lunes de la semana en curso según la fecha local del dispositivo:
  $$\text{lunes} = \text{fecha} - (\text{fecha.weekday} - 1)\text{ días}$$
  *Ejemplo:* Para cualquier fecha entre el lunes 2026-11-02 y el domingo 2026-11-08, la clave es `2026-11-02`.
- **Registro en Firestore:** El documento del hogar (`hogares/{hogarId}`) almacena:
  - `ultimaRotacion`: Cadena `YYYY-MM-DD` de la última semana en que se aplicó o inicializó la rotación.
  - `ordenRotacion`: Lista ordenada de UIDs de integrantes (`List<String>`) que determina la secuencia de rotación.

---

## 3. Disparo de la Rotación: Cliente (Opción B) vs Cloud Functions
Se seleccionó la **Opción (b): Verificación al abrir la app** (específicamente cuando el `DashboardScreen` resuelve el `hogarId` del usuario autenticado), por las siguientes razones de arquitectura:
1. **Independencia de infraestructura externa:** No requiere plan Blaze de Firebase ni despliegue de Cloud Functions con Cloud Scheduler.
2. **Idempotencia estricta:** Al utilizar la clave de semana `YYYY-MM-DD`, si dos integrantes abren la aplicación la misma semana (o el mismo integrante la abre múltiples veces), la rotación solo se ejecuta una sola vez. Si `ultimaRotacion == claveSemanaActual`, no se hace ninguna modificación.
3. **Manejo de semanas inactivas:** Si ningún integrante abre la app durante 2 o más semanas, al abrirse nuevamente se calcula la cantidad de semanas transcurridas $\Delta s = \text{semanasEntre}(\text{ultimaRotacion}, \text{claveSemanaActual})$ y la rotación avanza $\Delta s$ posiciones cíclicamente, manteniendo la consistencia temporal.
4. **Resiliencia:** Si la llamada de rotación falla por problemas de red o permisos, se captura de manera silenciosa en el cliente sin bloquear la carga del dashboard ni la interacción del usuario.

---

## 4. Algoritmo de Rotación y Reconciliación de Integrantes

### 4.1 Reconciliación del Orden de Rotación
Dado el `ordenRotacion` almacenado y la lista actual de UIDs de integrantes del hogar:
1. **Integrantes eliminados:** Todo UID presente en `ordenRotacion` que ya no pertenezca al hogar se descarta.
2. **Integrantes nuevos:** Todo UID del hogar que no esté en `ordenRotacion` se agrega al final de la lista.
3. **Inicialización (primer uso):** Si `ordenRotacion` está vacío, se construye a partir de los integrantes actuales ordenados alfabéticamente/por UID para garantizar determinismo.
4. Si la lista resultante tiene menos de 2 integrantes, no se puede rotar entre personas distintas (pero el quehacer recurrente sí reinicia su estado `hecho: false` si cambió de semana).

### 4.2 Cálculo del Nuevo Responsable
Para cada quehacer recurrente con responsable actual $U_{act}$:
1. Se localiza el índice $i$ de $U_{act}$ en la lista de orden reconciliada.
   - Si $U_{act}$ ya no está en la lista (se fue del hogar) o era nulo, se toma $i = 0$.
2. El nuevo índice se calcula mediante aritmética modular:
   $$\text{nuevoIndice} = (i + \Delta s) \pmod N$$
   donde $N = \text{orden.length}$ y $\Delta s \ge 1$ es el número de semanas transcurridas.
3. El nuevo responsable es $\text{orden}[\text{nuevoIndice}]$.

### 4.3 Inicialización Inicial (Línea Base)
Si un hogar no tiene `ultimaRotacion` (primera vez que se activa la funcionalidad), se registra `ultimaRotacion = claveSemanaActual` y el `ordenRotacion` inicial, **sin desplazar las tareas**, para establecer la línea base sin alterar las asignaciones recién creadas por el usuario.

---

## 5. Ejemplo de 3 Ciclos de Rotación (Demostración de No-Salto)

Supongamos un hogar con 3 integrantes: **Ana (A)**, **Beto (B)** y **Carlos (C)**.
Orden de rotación: `[A, B, C]`. Longitud $N = 3$.

| Ciclo | Semana (`claveSemana`) | Tarea 1 (Lavar) | Tarea 2 (Basura) | Tarea 3 (Cocina) | Estado `hecho` | Explicación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Inicio** | 2026-11-02 (Línea base) | **Ana (A)** | **Beto (B)** | **Carlos (C)** | Según asignación inicial | Se establece línea base. |
| **Ciclo 1** | 2026-11-09 ($\Delta s = 1$) | **Beto (B)** | **Carlos (C)** | **Ana (A)** | Se reinicia a `false` | $A \to B$, $B \to C$, $C \to A$. Nadie se salta. |
| **Ciclo 2** | 2026-11-16 ($\Delta s = 1$) | **Carlos (C)** | **Ana (A)** | **Beto (B)** | Se reinicia a `false` | $B \to C$, $C \to A$, $A \to B$. Nadie se salta. |
| **Ciclo 3** | 2026-11-23 ($\Delta s = 1$) | **Ana (A)** | **Beto (B)** | **Carlos (C)** | Se reinicia a `false` | Regresa al inicio del ciclo completo. |

**Caso de semana inactiva (ejemplo de salto):**
Si nadie abrió la app la semana del 2026-11-09 y se abre directo el 2026-11-16 ($\Delta s = 2$):
- Tarea 1: pasa de $A$ (índice 0) a $(0 + 2) \pmod 3 = 2 \implies \text{Carlos (C)}$.
- Tarea 2: pasa de $B$ (índice 1) a $(1 + 2) \pmod 3 = 0 \implies \text{Ana (A)}$.
- El avance es matemáticamente exacto al tiempo transcurrido.

---

## 6. Integración en la UI
1. **Creación de quehacer:** Selector `SwitchListTile` con etiqueta "Repetir cada semana (rota entre integrantes)".
2. **Edición de quehacer:** El mismo switch editable por administradores.
3. **Listado de quehaceres:** Chip/badge con icono `Icons.repeat_rounded` y texto `"Semanal"` en quehaceres recurrentes.
4. **Notificación de rotación:** Si al iniciar la app se ejecutó una rotación efectiva ($\text{rotados} > 0$), se muestra un aviso visual mediante `AppFeedback.mostrarExito(context, 'Se rotaron los quehaceres de la semana')`.
