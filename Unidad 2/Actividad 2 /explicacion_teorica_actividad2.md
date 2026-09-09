# Guía de Defensa y Profundización Teórica - Actividad 2

Este documento está diseñado para ayudarte a defender tu propuesta en la "Batalla de diseños físicos" (minuto 55-65 del laboratorio). 

Aquí encontrarás los conceptos clave explicados de forma clara, para que puedas responder cualquier pregunta del profesor o de los otros grupos.

## 1. El problema de no tener índices (Línea de base)

### ¿Qué es un Table Scan (Escaneo completo)?
Imagina que buscas un libro específico en una biblioteca que no tiene ningún catálogo ni estantes ordenados. La única forma de encontrarlo es mirar libro por libro desde el principio hasta el final. 
En bases de datos, eso es un **Table Scan**. Cuando ejecutamos las consultas A y B sin índices, MySQL tiene que leer las **300.000 filas** de la tabla `pedido` preguntando una por una si el `cliente_id` es 1500, o si la `sucursal_id` es 12. Esto gasta muchísimo CPU y memoria.

### ¿Qué es un Filesort (Ordenamiento en memoria)?
Una vez que el Table Scan encontró, por ejemplo, los 50 pedidos del cliente 1500, la Consulta A exige ordenarlos por fecha (`ORDER BY fecha DESC`). Como los registros en la tabla están guardados en el orden en que se insertaron (no por fecha), MySQL tiene que cargar esos 50 registros en la memoria RAM y aplicar un algoritmo de ordenamiento. Esto se conoce en el plan de ejecución como **filesort**. Es una de las operaciones más costosas para un motor de base de datos.

---

## 2. Nuestra solución: Índices Compuestos

Un índice funciona exactamente igual que el índice alfabético al final de un libro: tiene la palabra clave y un puntero (la página) que te lleva directo al lugar físico donde está la información. 

En bases de datos relacionales, los índices utilizan una estructura de datos llamada **B-Tree** (Árbol B). Esta estructura mantiene los datos perfectamente balanceados y ordenados.

### Para la Consulta A: `(cliente_id, fecha)`
Si sólo hiciéramos un índice por `cliente_id`, evitaríamos el Table Scan (iríamos directo a los pedidos del cliente 1500). **¡Pero el motor seguiría necesitando hacer un filesort para ordenarlos!**

Por eso usamos un **índice compuesto**: `(cliente_id, fecha)`. 
Al construir este índice, el B-Tree se ordena *primero por cliente*, y para cada cliente, *se ordenan sus pedidos por fecha*.
Cuando MySQL ejecuta la consulta:
1. Navega por el árbol y salta directamente al cliente 1500 (Index Seek).
2. Como los registros de ese cliente ya están ordenados por fecha en el propio índice, simplemente lee las últimas 20 filas. **¡El filesort desaparece por completo!**

### Para la Consulta B: `(sucursal_id, estado, fecha)`
El principio es el mismo. Tenemos dos condiciones de igualdad (`WHERE sucursal = X AND estado = Y`). 
Si colocamos primero en el índice las columnas del `WHERE`, MySQL salta directo a ese subconjunto de datos. Si colocamos la columna del `ORDER BY` (`fecha`) al final del índice, los resultados de ese subconjunto ya vienen pre-ordenados de fábrica.

---

## 3. El Costo de Mantenimiento (La penalidad de escritura)

Si los índices son tan buenos, ¿por qué no le ponemos índices a todas las columnas de todas las tablas?
**Porque los índices no son gratis.**

Cada vez que ejecutamos un `INSERT`, `UPDATE` o `DELETE` en la tabla `pedido`:
1. MySQL tiene que escribir la fila en la tabla principal.
2. MySQL tiene que **actualizar todos los árboles B (B-Trees)** de los índices que existan en esa tabla para insertar las nuevas referencias.

### Cómo defender la prueba de escritura (Script 03)
En la demostración vas a notar que luego de crear los índices, el `INSERT` masivo de 10.000 filas se vuelve más lento (tarda más milisegundos).
**Tu argumento de defensa debe ser:** 
> "Reconocemos que los índices agregan una penalidad al tiempo de escritura (como evidenció nuestra medición). Sin embargo, en la prioridad de la carga, las Consultas A y B están marcadas como *Muy Alta* y *Alta*. El tiempo y CPU que le ahorramos al servidor al evitar los Table Scans de 300,000 filas y los costosos filesorts de lectura, justifican ampliamente el pequeño costo adicional que pagamos al insertar. Es un trade-off (intercambio) altamente beneficioso para la estabilidad del sistema".

---

## 4. Respuestas rápidas a posibles ataques de otros grupos

- **"¿Por qué no crearon un índice separado para sucursal y otro para estado?"**
  *Respuesta:* En MySQL 8, aunque el motor puede hacer "Index Merge" (unir dos índices en memoria), sigue siendo ineficiente comparado con un solo índice compuesto que filtre ambas condiciones simultáneamente de una sola pasada en el B-Tree.
- **"La Consulta C sigue siendo lenta, ¿por qué no la optimizaron?"**
  *Respuesta:* La consigna claramente especifica que la Consulta C tiene prioridad *Baja*. Crear un tercer índice solo para C violaría la regla del límite de 2 índices, y además, aumentaríamos la penalidad de escritura por algo que no es prioritario. Nuestro diseño maximiza el beneficio donde realmente importa (Consultas A y B).
- **"Su penalidad de escritura (INSERT) aumentó muchísimo (de ~81ms a ~408ms). ¿No es un mal diseño?"**
  *Respuesta:* El tiempo aumentó porcentualmente, pero debemos mirar los valores absolutos y el contexto. Insertar 10,000 filas ahora tarda unos 408 milisegundos en total, es decir, ~0.04 ms por fila insertada. Esto ocurre usualmente en procesos por lotes (background). Sin embargo, una sola lectura de usuario (Consulta A) tardaba 100 ms y ahora tarda 0.1 ms. Dado que la lectura es sincrónica y bloquea al usuario, mejorar la lectura 1000 veces a costa de 0.04 ms extra por inserción es un excelente diseño para una base de datos OLTP.
