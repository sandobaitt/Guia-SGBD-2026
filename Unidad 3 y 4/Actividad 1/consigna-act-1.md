**U3 - Actividad 1 · El reporte que nadie puede resolver**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.

**Objetivo**
Resolver un requerimiento analítico usando SQL avanzado dentro del motor instalado, justificando la construcción elegida y conservando evidencia de ejecución.

**Escenario**
El área comercial necesita un reporte sobre clientes, ventas y jerarquías. El reporte debe resolverse dentro del motor de base de datos, sin exportar datos a planillas ni procesarlos fuera del SGBD.

**Desafío**
Construyan un script SQL que responda las siguientes consultas:
*   Última venta de cada cliente, manteniendo datos del cliente y de la venta.
*   Acumulado mensual por cliente, conservando el detalle de cada venta.
*   Ranking de clientes por segmento según el total vendido.
*   Recorrido jerárquico de clientes o responsables usando una consulta recursiva.
*   Comparación breve entre dos alternativas para al menos una consulta: por ejemplo subconsulta vs CTE, GROUP BY vs ventana, EXISTS vs JOIN.

> **Nota:** Se recomienda dividir las tareas entre integrantes del grupo para optimizar los tiempos.

**Condiciones**
*   Usar el motor asignado al grupo: MySQL o PostgreSQL.
*   Usar al menos una CTE, una función de ventana y una CTE recursiva.
*   Incluir una validación mínima del resultado esperado.
*   Conservar evidencia del plan o medición básica cuando el motor lo permita.

**Entregables**
*   **Script:** Archivo SQL ejecutable con consultas y comentarios (en un archivo `.sql`).
*   **Resultados:** En archivo `.pdf` con salidas de las consultas o capturas claras.
*   **Bitácora:** Decisiones, errores, evidencia y uso de IA si existió (ver plantilla de bitácora más abajo luego de hacer clic en el botón enviar).
*   **Defensa:** Explicación breve de por qué eligieron esas construcciones.

**Recursos de apoyo**
Se entrega un script por motor a modo de instalación inicial con el esquema y algunos datos cargados para facilitar la actividad.

> **Nota:** En el script se encuentra comentada una inserción masiva de datos para probar carga. Luego de realizar las consultas, descomentarlos y solo ejecutar esa parte para poblar las tablas con más datos.

*   `actividad1_mysql_setup.sql`

**Criterio de cierre**
El grupo debe poder ejecutar el script desde cero, mostrar el resultado y explicar por qué cada construcción SQL es adecuada para el problema.
Plantilla de bitácora para usar en las actividades:

    1. Problema a resolver: Describir brevemente el requerimiento.

    2. Decisiones técnicas: Indicar qué construcciones SQL u objetos del motor se eligieron y por qué.

    3. Comandos y evidencias: Pegar comandos relevantes, resultados, planes o capturas referenciadas.

    4. Pruebas realizadas

        Caso válido:
        Caso inválido:
        Caso límite:

    5. Errores y diagnóstico: Qué falló, cómo se detectó y cómo se corrigió.

    6. Uso de IA: Indicar si se usó IA, para qué, qué se validó y qué se descartó.

    7. Aprendizajes: Qué queda consolidado para la próxima actividad.
