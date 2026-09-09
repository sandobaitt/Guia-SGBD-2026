# Actividad 2. Batalla práctica de diseños físicos
## Unidad 2. Diseño físico y rendimiento

* **Motor:** MySQL
* **Grupos:** G03, G07, G08, G09, G11 y G12
* **Modalidad:** grupal
* **Duración:** 70 minutos

### Propósito
Aplicar decisiones reales de diseño físico sobre el motor instalado. El grupo obtendrá una línea de base, formulará una hipótesis, creará como máximo dos índices, repetirá las mediciones y decidirá si conserva, modifica o revierte su propuesta.
No gana el diseño con más estructuras. Se valorará la explicación que mejor conecte la consulta, el plan de ejecución, las métricas, la intervención física y sus costos.

### Reglas del laboratorio
1. Trabajar solamente sobre la base `sgbd_a2_lab`.
2. Usar exactamente los parámetros provistos.
3. Ejecutar cada consulta tres veces y registrar la mediana.
4. Escribir la hipótesis antes de crear índices.
5. Crear como máximo dos índices con nombres del tipo `idx_a2_gXX_descripcion`.
6. No reiniciar el servidor ni limpiar manualmente las cachés.
7. Conservar los planes de ejecución anteriores y posteriores.
8. No eliminar la base manualmente durante la actividad.

### Secuencia de trabajo

| Minutos | Momento | Evidencia esperada |
| :--- | :--- | :--- |
| **0-5** | Verificación | Motor, versión, cantidad de filas e índices existentes. |
| **5-15** | Línea de base | Tres ejecuciones y planes iniciales. |
| **15-23** | Hipótesis | Predicción del cambio antes de ejecutar el DDL. |
| **23-35** | Intervención | Hasta dos índices y estadísticas actualizadas. |
| **35-45** | Segunda medición | Planes y métricas posteriores. |
| **45-55** | Prueba de costo | Costo de escritura antes y después de indexar. |
| **55-65** | Batalla | Defensa oral y devolución del grupo rival. |
| **65-70** | Entrega | Bitácora, DDL, planes y veredicto. |

### Escenario M: Lectura versus escritura
**Pregunta central:** ¿La mejora de las consultas A y B justifica el costo adicional sobre las escrituras?

#### Archivos y orden de ejecución
1. `00_instalar_lab_mysql.sql`: crea y carga el laboratorio. Debe estar ejecutado antes de comenzar.
2. `01_linea_base_mysql.sql`: obtiene los planes iniciales de las consultas A, B y C.
3. `03_prueba_escritura_mysql.sql`: mide un lote de 10.000 inserciones y finaliza con `ROLLBACK`.
4. Registrar en la bitácora la hipótesis y el cambio esperado.
5. `02_experimento_estudiantes_mysql.sql`: incorporar el DDL elegido y repetir las consultas.
6. Volver a ejecutar `03_prueba_escritura_mysql.sql` con los índices creados.
7. Comparar resultados y emitir el veredicto.

### Prioridades de la carga

| Operación | Importancia | Qué observar |
| :--- | :--- | :--- |
| **A. Últimos pedidos de un cliente** | Muy alta | Filas examinadas, forma de acceso, ordenamiento y `LIMIT`. |
| **B. Pedidos pendientes por sucursal** | Alta | Filtro combinado y orden por fecha. |
| **C. Resumen temporal** | Baja | Evitar sobreoptimizar una carga secundaria. |
| **Inserciones** | Muy alta | Costo adicional después de crear los índices. |

### Evidencia mínima
* Plan y tiempo mediano de A y B antes y después.
* Índice elegido por el optimizador.
* Presencia o ausencia de ordenamiento.
* Tiempo del lote de inserciones antes y después.
* Una estructura considerada y descartada.
* Veredicto: mantener, modificar o revertir.

### Entregable
* Bitácora de experimentación completa.
* DDL realmente ejecutado.
* Planes de ejecución anterior y posterior.
* Tabla con las tres mediciones y la mediana.
* Decisión descartada y su justificación.
* Conclusión sobre el beneficio de lectura y el costo de escritura.

### Criterios de evaluación

| Criterio | Ponderación | Qué se observará |
| :--- | :--- | :--- |
| **Evidencia experimental** | 40% | Planes y métricas comparables antes y después. |
| **Interpretación** | 25% | Explicación del trabajo físico que cambió. |
| **Coherencia** | 20% | Relación entre los índices y la carga asignada. |
| **Costos y defensa** | 15% | Reconocimiento del costo de mantenimiento y defensa de la decisión. |

**Importante:** una hipótesis refutada también es válida si el grupo explica por qué el optimizador no utilizó la estructura o por qué el costo global no mejoró.