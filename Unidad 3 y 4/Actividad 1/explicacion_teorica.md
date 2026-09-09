# Defensa y Explicación Teórica - Actividad 1

Esta guía contiene los conceptos teóricos explicados de forma sencilla para que entiendas qué hace el código, seguido de las respuestas para defender tus decisiones ante el profesor.

---

## PARTE 1: Conceptos Teóricos Clave (Para entender el código)

Antes de defender el código, es vital entender qué son estas herramientas "avanzadas" de SQL que usamos.

### 1. ¿Qué es una Función de Ventana (Window Function)?
Imagina que usas un `GROUP BY`. El `GROUP BY` agarra muchas filas, las aplasta y te devuelve una sola fila con el total. El problema es que **pierdes el detalle** de las filas originales.
Una **Función de Ventana** (como `ROW_NUMBER() OVER...` o `SUM() OVER...`) hace los cálculos agrupados, **pero sin aplastar las filas**. Te devuelve todas las filas originales y les agrega una columna extra al lado con el cálculo.
- `PARTITION BY`: Le dice a SQL "agrupa mentalmente por esta columna" (ej. por cliente) para hacer el cálculo, pero sin borrar el detalle.
- `ORDER BY`: Le dice a SQL en qué orden procesar las filas dentro de ese grupo mental.

### 2. ¿Qué es una CTE (Common Table Expression / `WITH`)?
Una CTE es simplemente una **tabla temporal virtual** que existe solo por un milisegundo mientras dura tu consulta. En lugar de hacer una subconsulta gigante y confusa dentro del `FROM`, declaras la CTE arriba con la palabra `WITH nombre_cte AS (...)` y luego la usas abajo como si fuera una tabla real. Hace el código mucho más limpio y fácil de leer.

### 3. ¿Qué es una CTE Recursiva (`WITH RECURSIVE`)?
Es un bucle (un loop) dentro de SQL. Sirve para recorrer árboles o jerarquías (jefes y empleados). Tiene dos partes:
1. **El Ancla (Anchor):** La consulta base. Ej: Traer a los jefes supremos (los que no tienen jefe).
2. **El Bucle (UNION ALL):** Toma los resultados del ancla, busca quién depende de ellos, los suma a la lista, y vuelve a repetir el proceso una y otra vez hasta que no encuentre a nadie más.

---

## PARTE 2: Defensa ante el Profesor

### 1. Alternativa elegida vs Descartada (Punto Obligatorio de la Rúbrica)

La consigna pedía: *"Comparación breve entre dos alternativas para al menos una consulta"*. 

**Pregunta del Profesor:** ¿Por qué para sacar la "última venta del cliente" (Consulta 1) usaron una función de ventana (`ROW_NUMBER`) en vez de un clásico `GROUP BY` y un `JOIN`?

**Tu Defensa:** 
> "Evaluamos usar `GROUP BY cliente_id, MAX(fecha)`, pero esa técnica tiene un problema grave: nos devuelve la fecha máxima, pero nos hace perder el resto de las columnas de ESA venta (como el `total` o el `canal`). Para recuperar esas columnas, tendríamos que haber hecho un `INNER JOIN` gigante contra la misma tabla de ventas, igualando cliente y fecha. Eso duplica el trabajo del motor. 
> 
> En cambio, la función de ventana `ROW_NUMBER() OVER(PARTITION BY cliente_id ORDER BY fecha DESC)` no aplasta las filas. Simplemente les pone un número (1 a la más nueva, 2 a la anterior, etc.). Al poner eso en una CTE temporal y filtrar `cont_venta = 1`, obtenemos la fila completa y detallada en una sola pasada de lectura."

### 2. Acumulado Mensual (Consulta 2)

**Pregunta del Profesor:** ¿Por qué el uso de `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`?

**Tu Defensa:**
> "Esta es la sintaxis nativa del estándar SQL para un 'Running Total' (total progresivo). Le estamos diciendo al motor que, dentro de la partición de un cliente, vaya sumando los valores desde la primera fila de esa partición (`UNBOUNDED PRECEDING`) hasta la fila donde está parado actualmente (`CURRENT ROW`). Es la forma más óptima; si usáramos subconsultas anidadas en el SELECT para sumar hacia atrás, el tiempo de ejecución colapsaría a medida que la tabla crezca."

### 3. Jerarquías: ¿Por qué CTE Recursiva? (Consulta 4)

**Pregunta del Profesor:** Si querían saber quién depende de quién, ¿por qué no hicieron 3 o 4 `LEFT JOIN` a la tabla cliente y listo?

**Tu Defensa:**
> "Hacer `LEFT JOIN` sucesivos solo sirve cuando sabemos exactamente que la jerarquía de la empresa tiene, por ejemplo, exactamente 3 niveles. Pero en la vida real, las jerarquías son dinámicas. La **CTE Recursiva** (`WITH RECURSIVE`) nos permite resolver un árbol de profundidad infinita. Arranca con los gerentes generales, y luego el motor hace un bucle iterativo buscando los dependientes hasta llegar a la base de la pirámide, asignando automáticamente el nivel de profundidad."

### 4. DENSE_RANK() vs RANK() (Consulta 3)

**Pregunta del Profesor:** ¿Por qué eligieron `DENSE_RANK()` en vez de `RANK()` o `ROW_NUMBER()` para el podio de clientes?

**Tu Defensa:**
> "Para cuestiones comerciales, los empates en el total vendido pueden ocurrir. 
> - Si usábamos `ROW_NUMBER()`, iba a desempatar al azar asignando un puesto a cada uno.
> - Si usábamos `RANK()`, ante un empate en el puesto 1, el siguiente cliente pasaría a ser el número 3 (dejando un hueco en el ranking). 
> - Al usar `DENSE_RANK()`, garantizamos que si dos clientes empatan en el primer puesto, el siguiente ocupará el puesto 2, preservando una secuencia lógica y sin huecos para el reporte comercial."
