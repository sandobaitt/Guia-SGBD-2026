**U3 - Actividad 2 · La regla que no puede romperse**

**Objetivo**
Decidir cuándo conviene usar constraint, función, procedimiento o trigger para proteger una regla de negocio dentro del motor.

**Escenario**
Una aplicación permitió operaciones inconsistentes porque determinadas reglas quedaron sólo en el código de la aplicación. La organización solicita reforzar la integridad desde el SGBD.

**Desafío**
Implementen en el motor asignado una solución que cubra estas reglas:
*   Una cuenta no puede quedar con saldo negativo.
*   Toda modificación de precio de producto debe quedar auditada. Se debe utilizar la tabla de auditoría generada por el script inicial.
*   Debe existir una función o procedimiento que clasifique un cliente según su total anual. Categorías: Bronce (< 2.000.000), Plata (entre 2.000.000 y 50.000.000), Oro (> 50.000.000).
*   Al menos una regla simple debe resolverse con una restricción declarativa, no con trigger.

**Decisión técnica obligatoria**
Para cada regla indiquen qué mecanismo usaron y por qué:

| Necesidad | Recurso posible | Pregunta guía |
| :--- | :--- | :--- |
| Validar una regla simple | CHECK, NOT NULL, UNIQUE, FK | ¿Puede expresarse declarativamente? |
| Reutilizar un cálculo | Función almacenada | ¿Se usa dentro de consultas? |
| Ejecutar varios pasos | Procedimiento almacenado | ¿Es un proceso explícito? |
| Reaccionar ante cambios | Trigger | ¿Debe ejecutarse automáticamente ante INSERT, UPDATE o DELETE? |

**Pruebas mínimas**
*   **Caso válido:** debe aceptar la operación.
*   **Caso inválido:** debe rechazar o impedir la inconsistencia.
*   **Caso límite:** debe producir el comportamiento esperado.
*   **Verificación de auditoría:** mostrar el registro generado.

**Entregables**
*   Un archivo `.sql` con el script SQL de los objetos creados.
*   Un archivo `.sql` con el script de pruebas.
*   Un archivo `.pdf` con:
    *   Capturas o salida de consola.
    *   Bitácora técnica con decisiones, errores y uso de IA declarado.

**Archivos de apoyo**
*   `actividad2_mysql_base.sql` (26 de agosto de 2026, 19:42)

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

> **Pregunta para defensa:** ¿Esta regla debería estar en la base, en la aplicación o en ambas? Justifiquen según riesgo, mantenibilidad y evidencia.