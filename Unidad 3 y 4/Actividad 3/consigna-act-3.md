**U3 - Actividad 3 · Release de base de datos v2.0**

**Objetivo**
Evolucionar una base de datos existente sin borrar datos, usando scripts versionados, validaciones y plan de rollback.

**Escenario**
La base de datos `v1` ya está en producción y contiene datos. El equipo de desarrollo solicita liberar una versión `v2.0` con nuevos requisitos. No se permite borrar la base ni recrearla desde cero.

**Requerimientos v2.0**
*   Agregar estados de pedido: pendiente, pagado, enviado, cancelado.
*   Agregar una tabla de auditoría de cambios de estado.
*   Agregar una regla que impida totales negativos.
*   Crear una función o consulta reutilizable para calcular total por cliente.
*   Crear un script de rollback razonable o documentar qué cambios no son reversibles sin pérdida.

**Restricción principal**
No pueden entregar un único `CREATE DATABASE` final. Deben demostrar la evolución: `v1` + datos iniciales → migración `v2` → pruebas → evidencia.

**Estructura sugerida de entrega**
*   `01_schema_v1.sql`
*   `02_datos_v1.sql`
*   `03_migracion_v2.sql`
*   `04_programabilidad_v2.sql`
*   `05_pruebas_v2.sql`
*   `06_rollback_v2.sql`
*   `07_bitacora.pdf`

**Pruebas mínimas**
*   Los datos de `v1` siguen existiendo después de migrar.
*   Los nuevos estados funcionan.
*   La auditoría registra cambios relevantes.
*   Las restricciones impiden datos inválidos.
*   La función o consulta reutilizable devuelve resultados verificables.

**Archivos de apoyo**
*   `actividad3_mysql_v1.sql` (26 de agosto de 2026, 19:44)

**Plantilla de bitácora para usar en las actividades:**
1. Problema a resolver: Describir brevemente el requerimiento.
2. Decisiones técnicas: Indicar qué construcciones SQL u objetos del motor se eligieron y por qué.
3. Comandos y evidencias: Pegar comandos relevantes, resultados, planes o capturas referenciadas.
4. Pruebas realizadas:
    * Caso válido:
    * Caso inválido:
    * Caso límite:
5. Errores y diagnóstico: Qué falló, cómo se detectó y cómo se corrigió.
6. Uso de IA: Indicar si se usó IA, para qué, qué se validó y qué se descartó.
7. Aprendizajes: Qué queda consolidado para la próxima actividad.

> **Defensa esperada:** El grupo debe explicar cómo garantizó continuidad, qué riesgos detectó, cómo validó la migración y qué haría diferente para un despliegue real.