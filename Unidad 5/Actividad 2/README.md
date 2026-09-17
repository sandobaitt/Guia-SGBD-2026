**SGBD 2026 - Unidad 5 - Actividad 2 · Scripts guiados para estudiantes**

**Archivos disponibles**
*   `U5_A2_MySQL_3_experimentos_estudiantes.sql`
*   `U5_A2_PostgreSQL_3_experimentos_estudiantes.sql`

**Instrucciones de uso**
1. Cada grupo utiliza **únicamente** el archivo correspondiente a su motor asignado.
2. Abrir dos conexiones independientes al mismo servidor (**Sesión A** y **Sesión B**).
3. **No** ejecutar el script de forma completa o masiva.
4. Ejecutar los bloques paso a paso en el orden indicado, deteniéndose en cada punto.
5. Registrar evidencia diagnóstica antes de liberar cualquier estado de espera.
6. Cerrar explícitamente todas las transacciones abiertas mediante `COMMIT` o `ROLLBACK`.

**Experimentos a ejecutar**
1. **Espera por lock:** Identificación de bloqueo y estados de espera sobre recursos compartidos.
2. **Nivel de aislamiento y segunda lectura:** Evaluación de visibilidad de datos concurrentes y consistencia transaccional.
3. **Deadlock controlado:** Provocación y análisis del ciclo de bloqueo mutuo resuelto por el motor.

> **Objetivo técnico:** Analizar empíricamente el comportamiento del motor y fundamentar los resultados con métricas y evidencias reales del sistema, evitando asumir salidas teóricas.