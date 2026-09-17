**U5 - Actividad 2 - Concurrencia & Bloqueos**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.

**Desafío "Dos usuarios (o más), un mismo dato"**
*   **Modalidad:** Grupal. Una única entrega por grupo. Cada grupo trabaja con su motor asignado: **MySQL** o **PostgreSQL**.
*   **Objetivo:** Demostrar con evidencia cómo el SGBD controla accesos concurrentes mediante transacciones, aislamiento, esperas, *locks* y detección de *deadlocks*.

**Organización**
*   Utilizar al menos dos sesiones independientes conectadas al mismo servidor.
*   Operar preferentemente desde computadoras diferentes del grupo para evidenciar el entorno concurrente.

**Experimento 1 - ¿Quién bloquea a quién?**
1.  **Sesión A:** Inicia una transacción y modifica una fila de `cuenta` sin confirmar.
2.  **Sesión B:** Intenta modificar la misma fila.
3.  **Inspección:** Sin cancelar la operación, auditar desde la herramienta gráfica y/o vistas del motor:
    *   Sesión bloqueada.
    *   Sesión bloqueante.
    *   Estado de espera.
    *   Recurso involucrado (*row lock*, tabla, etc.).
4.  **Resolución:** Sesión A ejecuta `COMMIT` o `ROLLBACK`. Registrar el comportamiento y desbloqueo de B.

**Experimento 2 - Aislamiento: ¿vemos lo mismo?**
1.  Identificar el nivel de aislamiento configurado por defecto en el motor o sesión activa.
2.  **Sesión A:** Inicia una transacción y consulta el saldo de una cuenta.
3.  **Sesión B:** Modifica ese saldo y ejecuta `COMMIT`.
4.  **Sesión A:** Ejecuta nuevamente la consulta dentro de la misma transacción abierta.
5.  **Análisis:** Explicar el resultado observado según el nivel de aislamiento y el motor utilizado (comparar comportamiento frente a lecturas no repetibles / lecturas consistentes MVCC).

**Experimento 3 - Deadlock controlado**
1.  **Sesión A:** Bloquea la cuenta 1.
2.  **Sesión B:** Bloquea la cuenta 2.
3.  **Sesión A:** Intenta modificar la cuenta 2 (entra en espera).
4.  **Sesión B:** Intenta modificar la cuenta 1 (genera ciclo de espera cruzada).
5.  **Registro:** Capturar qué transacción es abortada por el motor, el mensaje de error arrojado y la evidencia diagnóstica.

**Desafío final**
*   Proponer **dos medidas preventivas** aplicables en arquitectura o diseño de aplicaciones para reducir contención, esperas y *deadlocks* (sin recurrir al escalado vertical de hardware).

**Entrega grupal**
*   **Scripts SQL:** Archivo `.sql` con los comandos ejecutados por cada sesión.
*   **Bitácora técnica:** Archivo `.pdf` estructurado con la línea temporal coordinada de Sesión A y B:
    *   Evidencia de sesión bloqueada y bloqueante.
    *   Resultados y justificación técnica del test de aislamiento.
    *   Evidencia, traza diagnóstica y explicación del *deadlock*.
    *   Dos medidas preventivas técnicamente justificadas.

> **Criterio de evaluación:** Se evalúa diagnóstico, captura de evidencia, fundamentación técnica y comprensión conceptual de la concurrencia, no la velocidad para provocar el fallo.