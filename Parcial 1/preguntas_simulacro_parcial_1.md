# Preguntas tipo simulacro · Parcial 1

**Sistemas de Gestión de Bases de Datos 2026 · Bloque temático 1**
80 preguntas de opción múltiple sobre las Unidades 1 a 6, con una sola respuesta correcta en cada una.

---

## Cómo usar este cuestionario

- El formato sigue el del simulacro de la cátedra: una situación concreta, cuatro opciones y una sola correcta. Muchas situaciones salen de las actividades de laboratorio.
- Cada pregunta indica unidad, **nivel** y tema:
  - **Básica:** un concepto central bien aplicado.
  - **Intermedia:** hay que relacionar dos ideas o descartar distractores plausibles.
  - **Desafío:** las opciones se parecen mucho o hace falta entender el mecanismo, no recordar una definición.
- Respondé antes de abrir **"Ver respuesta"**. Cada explicación dice por qué la opción correcta lo es y por qué fallan las demás.
- La base son las clases de las Unidades 1 a 6 y las actividades resueltas en MySQL y PostgreSQL. Algunas preguntas de nivel Desafío van un poco más allá de las clases (por ejemplo, la 31 sobre `NOT IN` con nulos, la 58 sobre lecturas con bloqueo o la 70 sobre `TRUNCATE`). Están para entender el mecanismo. La teoría está en [apunte_parcial_1.md](apunte_parcial_1.md).
- Al final hay una **clave de respuestas** para corregir rápido.

| Unidad | Preguntas | Tema |
| :--- | :--- | :--- |
| U1 | 1 a 10 | Arquitectura de motores |
| U2 | 11 a 24 | Diseño físico y rendimiento |
| U3 | 25 a 37 | SQL avanzado |
| U4 | 38 a 50 | Programabilidad y migraciones |
| U5 | 51 a 65 | Conectividad, transacciones y concurrencia |
| U6 | 66 a 80 | Seguridad, backup, réplica y alta disponibilidad |

### Cómo reconocer la opción correcta

| Señal en una opción | Suele indicar |
| :--- | :--- |
| Absolutos: "siempre", "nunca", "necesariamente", "la única solución" | Opción incorrecta: casi todo depende de la carga y de la evidencia |
| Soluciones desproporcionadas: reiniciar el servidor, más hardware, un índice con todas las columnas, darle permisos de administrador a todos | Opción incorrecta: no atacan la causa |
| "Evaluar ... y comprobar con un nuevo plan y mediciones comparables" | Opción correcta típica: decisión + verificación con evidencia |
| El mecanismo más simple que garantiza la regla | Opción correcta típica |
| Dos opciones casi iguales | Buscá la palabra que cambia: `ON` o `WHERE`, `ROWS` o `RANGE`, `>` o `>=`, síncrona o semisíncrona |

---

## Unidad 1 · Arquitectura de motores de bases de datos

**Pregunta 1** · Intermedia · *Procesamiento de una consulta*

Una aplicación ejecuta `SELECT saldo FROM cuenta WHERE nro_cuenta = 12345;`. ¿Qué secuencia describe correctamente cómo la procesa el motor?

- a) Optimizador → parser → catálogo → ejecutor: primero se elige el plan y después se valida la sintaxis.
- b) Parser → catálogo → optimizador → ejecutor, que trabaja sobre páginas en memoria y pide al almacenamiento las que no están en el buffer.
- c) Ejecutor → buffer → parser → optimizador: primero se leen los datos y después se decide cómo filtrarlos.
- d) Parser → ejecutor → optimizador: el plan se va ajustando a medida que se leen las filas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El parser valida la sintaxis y los objetos, el catálogo aporta metadatos y estadísticas, el optimizador elige el plan de menor costo estimado y el ejecutor lo recorre sobre páginas en memoria; si una página no está en el buffer (*miss*), la pide al almacenamiento. No se puede optimizar antes de validar (a), ni leer datos antes de tener un plan (c). El plan se decide antes de ejecutar (d).

</details>

**Pregunta 2** · Intermedia · *Buffer pool y durabilidad*

Un compañero afirma: "si el servidor se cae, se pierde todo lo que estaba en el buffer pool, incluidos los cambios ya confirmados". ¿Qué evaluación es correcta?

- a) Es correcta: el buffer pool es volátil y lo que estaba solo en memoria no se puede reconstruir.
- b) Es correcta solo para MySQL: PostgreSQL escribe cada página modificada en disco en el momento del `COMMIT`.
- c) Es incorrecta: lo confirmado se rehace desde el log persistido en el `COMMIT`, y lo no confirmado se descarta al recuperar.
- d) Es incorrecta: el buffer pool se vuelca completo al disco en cada `COMMIT`, así que nunca queda nada pendiente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El `COMMIT` fuerza el **log** (redo/WAL) a disco. Las páginas modificadas pueden seguir "sucias" en memoria hasta el checkpoint, y si el servidor cae, la recuperación las reconstruye desde el log. Ningún motor escribe todas las páginas en cada `COMMIT` (b, d): sería lento y es justamente lo que el log evita.

</details>

**Pregunta 3** · Básica · *Escritura anticipada (WAL)*

¿Qué establece el principio de escritura anticipada (*write-ahead logging*)?

- a) La información para rehacer o deshacer un cambio se persiste en el log antes de que la página modificada se escriba en el archivo de datos.
- b) La página modificada se escribe en el archivo de datos antes que el log, para que el log pueda verificarla.
- c) El log se escribe una sola vez por checkpoint, agrupando todos los cambios del período.
- d) El log se genera solo cuando hay réplicas configuradas, para enviarles los cambios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** "Escritura anticipada" significa que el log va **antes** que el dato. Por eso, ante una caída, siempre hay en disco información suficiente para rehacer lo confirmado y deshacer lo que no llegó a confirmarse. El log existe aunque no haya réplicas (d) y se escribe en cada `COMMIT`, no solo en el checkpoint (c).

</details>

**Pregunta 4** · Desafío · *Independencia de datos*

La tabla `cliente` se divide en `cliente` y `cliente_contacto`, y se crea una vista con la forma anterior para que los reportes sigan funcionando sin cambios. ¿Qué tipo de independencia se aprovecha y en qué nivel ANSI/SPARC ocurre el cambio?

- a) Independencia física: el cambio ocurre en el nivel interno.
- b) Independencia física: la vista pertenece al nivel interno y oculta el cambio.
- c) Independencia lógica: el cambio ocurre en el nivel interno.
- d) Independencia lógica: el cambio ocurre en el nivel conceptual y la vista preserva el nivel externo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Dividir una entidad cambia el **esquema conceptual** (lógico). La vista pertenece al **nivel externo** y mantiene lo que ven los reportes: eso es independencia **lógica**. La independencia física aplica a cambios del nivel interno, como crear un índice, mover un tablespace o particionar, que no alteran el modelo lógico.

</details>

**Pregunta 5** · Intermedia · *Instancia, base y esquema*

Un equipo migra de MySQL a PostgreSQL. En MySQL, un reporte cruzaba `ventas.pedido` con `crm.cliente` en una misma consulta. ¿Qué diseño conserva esa posibilidad en PostgreSQL de forma natural?

- a) Crear dos bases (`ventas` y `crm`) en la misma instancia: PostgreSQL permite cruzarlas en una consulta igual que MySQL.
- b) Crear una instancia para cada base, para aislar mejor la carga.
- c) Crear una base con dos esquemas (`ventas` y `crm`): en PostgreSQL una conexión trabaja sobre una sola base, y los esquemas son espacios de nombres dentro de ella.
- d) No hay forma: PostgreSQL no permite consultar dos conjuntos de tablas en la misma sentencia.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** En MySQL "base" y "esquema" son sinónimos, por eso `ventas.pedido` y `crm.cliente` se cruzan sin problema. En PostgreSQL una conexión es a **una** base, y para cruzar bases hacen falta extensiones como `postgres_fdw`. El equivalente natural son **dos esquemas dentro de una misma base**. La opción d es falsa justamente por eso.

</details>

**Pregunta 6** · Básica · *Metadatos y optimizador*

¿Qué información del catálogo usa el optimizador para estimar el costo de los planes posibles?

- a) Estadísticas sobre la cantidad de filas y la distribución de los valores, además de los índices disponibles.
- b) El historial de consultas ejecutadas por cada usuario en el último mes.
- c) El contenido del log transaccional desde el último checkpoint.
- d) Las contraseñas y los roles de los usuarios conectados.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El optimizador compara caminos posibles (scan, índice, tipo de join) y estima cuántas filas pasan por cada paso. Para eso necesita estadísticas y conocer los índices. Los permisos se verifican, pero no intervienen en el costo (d). El log sirve para recuperación, no para planificar (c).

</details>

**Pregunta 7** · Intermedia · *¿El índice obliga al optimizador?*

Se crea un índice sobre `nro_cuenta` en una tabla de 5 filas. En PostgreSQL el plan sigue mostrando `Seq Scan`; en MySQL, el mismo experimento muestra un acceso por índice. ¿Qué conclusión es correcta?

- a) En PostgreSQL el índice quedó dañado y corresponde ejecutar `REINDEX`.
- b) MySQL se equivoca: con 5 filas usar un índice es siempre una mala decisión.
- c) Uno de los dos motores ignora las estadísticas, porque ante la misma tabla deberían elegir el mismo plan.
- d) Los dos comportamientos son válidos: cada optimizador decide por costo con su propio modelo, y la existencia del índice no obliga a usarlo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Con muy pocas filas, a PostgreSQL le resulta más barato leer la tabla entera que pasar por el índice. MySQL estima barato un acceso por igualdad sobre un índice. Son modelos de costo distintos, y ninguno está "roto". La opción b usa un absoluto ("siempre") y la c supone que motores distintos deben coincidir.

</details>

**Pregunta 8** · Intermedia · *Persistencia y transacciones no confirmadas*

Se repite la prueba de persistencia, pero esta vez se ejecuta `BEGIN`, se inserta un registro y se detiene el servicio **sin** `COMMIT`. Al reiniciar, ¿qué se observa?

- a) El registro aparece, porque el `INSERT` ya estaba en el buffer pool cuando se detuvo el servicio.
- b) El registro no aparece: al recuperar, el motor descarta los cambios de transacciones que no se confirmaron.
- c) El registro aparece marcado como pendiente, hasta que alguien ejecute `COMMIT` desde otra sesión.
- d) El servicio no arranca hasta que un administrador resuelva a mano la transacción abierta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es la **atomicidad**: una transacción sin `COMMIT` no deja rastro. Al recuperar, el motor rehace lo confirmado y deshace (o deja invisible) lo que no se confirmó. Ninguna sesión nueva puede "adoptar" una transacción de otra (c).

</details>

**Pregunta 9** · Básica · *Bases de datos en la nube*

Una organización migra su base a un servicio administrado (DBaaS). ¿Qué responsabilidad **sigue** siendo del equipo?

- a) Diseñar el modelo de datos, las consultas y los índices, controlar el acceso y definir el RPO y el RTO del negocio.
- b) Aplicar los parches del sistema operativo del servidor físico, que en DBaaS siguen a cargo del cliente.
- c) Reemplazar los discos dañados y administrar el hardware del centro de datos.
- d) Ninguna: el proveedor garantiza el rendimiento, la seguridad y la continuidad del servicio.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** DBaaS cambia la operación, no elimina la arquitectura. El proveedor se encarga de buena parte del hardware, los parches y los backups automáticos (b y c), pero el modelo, las consultas, los índices, la seguridad de acceso y los objetivos de continuidad siguen siendo decisiones del equipo (d es falsa).

</details>

**Pregunta 10** · Básica · *ACID*

Una transferencia debita la cuenta A y, antes de acreditar la cuenta B, el servidor se cae. Al reiniciar, A tiene su saldo original. ¿Qué propiedad y mecanismo explican el resultado?

- a) Durabilidad, gracias al checkpoint.
- b) Aislamiento, gracias a los locks de fila.
- c) Consistencia, gracias al `CHECK` sobre el saldo.
- d) Atomicidad: la transacción no confirmada se deshace al recuperar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "Todo o nada": como la transacción no llegó a confirmarse, el débito se revierte. La durabilidad protege lo **confirmado** (a). El aislamiento regula lo que ven las transacciones concurrentes (b). Un `CHECK` no tiene relación con una caída (c).

</details>

---

## Unidad 2 · Diseño físico y rendimiento

**Pregunta 11** · Básica · *Índice compuesto para filtro y orden*

La consulta prioritaria es `WHERE sucursal_id = ? AND estado = 'PENDIENTE' ORDER BY fecha LIMIT 100`. ¿Qué índice resuelve a la vez el filtro y el orden?

- a) `(fecha, sucursal_id, estado)`: el `ORDER BY` va primero para evitar el sort.
- b) `(estado, fecha)`: el estado filtra la mayoría de las filas y conviene ponerlo adelante.
- c) `(sucursal_id, estado, fecha)`: primero las dos igualdades y después la columna del `ORDER BY`.
- d) Dos índices separados, `(sucursal_id)` y `(estado)`, que el motor combina para filtrar y ordenar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Con las dos igualdades fijadas, las entradas del índice ya quedan ordenadas por `fecha`: no hay sort y el `LIMIT` corta en 100. En a, el prefijo es `fecha` y no hay filtro por fecha. En b, se mezclan las sucursales y hay que filtrar muchas entradas. En d, combinar dos índices puede ayudar a filtrar, pero no entrega el orden por fecha.

</details>

**Pregunta 12** · Desafío · *Rango en la primera columna*

Consulta: `WHERE fecha >= '2026-08-09' AND fecha < '2026-08-10' ORDER BY importe DESC LIMIT 1000`, donde `fecha` es `DATETIME`. Un grupo propone el índice `(fecha, importe DESC)` para eliminar el ordenamiento. ¿Qué evaluación es correcta?

- a) No elimina el sort: con un rango sobre la primera columna, `importe` queda ordenado solo dentro de cada valor exacto de `fecha`. Haría falta una igualdad, por ejemplo con una columna `dia = DATE(fecha)` indexada junto con `importe`.
- b) Elimina el sort, porque el índice ya guarda `importe` en orden descendente.
- c) Elimina el sort solo si además se agrega `importe` a la lista del `SELECT`.
- d) No sirve en absoluto: los optimizadores no pueden usar índices con condiciones de rango.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El índice ordena por fecha **y hora** primero; dentro del día hay miles de valores distintos de `fecha`, y el importe solo está ordenado dentro de cada uno. Después de un rango, las columnas siguientes del índice no sirven para ordenar. El índice sí sirve para el rango (d es falsa), pero no evita el sort (b). La opción c no cambia nada.

</details>

**Pregunta 13** · Intermedia · *Regla del prefijo izquierdo*

Existe el índice `(cliente_id, fecha)`. ¿Qué consulta **no** puede usarlo para ir directamente a las filas buscadas?

- a) `WHERE cliente_id = 10`
- b) `WHERE cliente_id = 10 AND fecha > '2026-01-01'`
- c) `WHERE cliente_id = 10 ORDER BY fecha DESC`
- d) `WHERE fecha > '2026-01-01'`

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El índice está ordenado primero por `cliente_id`. Sin una condición sobre esa columna, las fechas aparecen dispersas en todo el árbol y no se puede saltar a ellas (como mucho, recorrer el índice completo). Las opciones a, b y c usan el prefijo, y la c además aprovecha el orden por fecha.

</details>

**Pregunta 14** · Intermedia · *Veredicto lectura frente a escritura*

Después de crear dos índices compuestos, las consultas prioritarias pasan de ~160 ms a menos de 1 ms. La mediana de un lote de 10.000 `INSERT` pasa de ~195 ms a ~275 ms. Las inserciones son continuas y de prioridad muy alta. ¿Qué veredicto se defiende mejor?

- a) Revertir: cualquier aumento del costo de escritura invalida la mejora de lectura cuando las inserciones tienen prioridad muy alta.
- b) Mantener: las consultas prioritarias mejoran en órdenes de magnitud frente a un costo de escritura medido y acotado, y conviene vigilar la escritura bajo carga concurrente.
- c) Mantener sin más análisis: un índice nunca perjudica a un sistema transaccional.
- d) Agregar un tercer índice para la consulta de resumen, ya que el costo de escritura subió poco.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El aumento es de unos 8 microsegundos por fila insertada, frente a una ganancia de más de 150 ms por consulta prioritaria. La decisión se justifica con evidencia y reconoce el costo. La opción a es un absoluto, la c niega que los índices tengan costo, y la d ignora la prioridad baja del resumen y el límite de estructuras.

</details>

**Pregunta 15** · Básica · *Mediana de tres ejecuciones*

Las tres ejecuciones del lote de inserciones después de crear los índices dan 2.410 ms, 273 ms y 257 ms. ¿Qué valor corresponde informar?

- a) 980 ms, el promedio, porque considera las tres ejecuciones.
- b) 2.410 ms, porque representa el peor caso que verá el usuario.
- c) 273 ms, la mediana, que no se distorsiona por el valor atípico de la primera ejecución.
- d) 257 ms, el mínimo, porque refleja el rendimiento real del motor.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El protocolo de la materia pide tres ejecuciones y la **mediana**. La primera ejecución suele ser atípica (caché fría, estructuras recién creadas) y arrastra el promedio hacia arriba (a). Ni el peor caso (b) ni el mejor (d) representan el comportamiento típico.

</details>

**Pregunta 16** · Desafío · *Índice cubriente en PostgreSQL*

En PostgreSQL, una consulta filtra por `comercio_id` y `fecha` y proyecta `transaccion_id`, `importe`, `canal` y `descripcion`. Se crea `(comercio_id, fecha) INCLUDE (transaccion_id, importe, canal)`, pero el plan sigue mostrando `Index Scan` con accesos a la tabla. ¿Por qué?

- a) Porque `INCLUDE` solo tiene efecto en MySQL; en PostgreSQL esas columnas deberían ir en la clave.
- b) Porque falta ejecutar `REINDEX` para que el optimizador vea las columnas incluidas.
- c) Porque los `Index Only Scan` solo funcionan con índices de tipo hash.
- d) Porque la consulta sigue pidiendo `descripcion`, que no está en el índice: un `Index Only Scan` necesita todas las columnas que usa la consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La cobertura tiene que ser **total**: con una sola columna afuera, el motor vuelve a la tabla por cada fila. Las opciones son sacar `descripcion` del listado (y traerla solo para la fila que se abre) o incluirla, aceptando un índice mucho más grande. `INCLUDE` existe en PostgreSQL desde la versión 11 (a). El índice nuevo se usa sin `REINDEX` (b). Los `Index Only Scan` usan B-tree (c).

</details>

**Pregunta 17** · Intermedia · *Partition pruning*

La tabla `pedido` está particionada por mes según `fecha`. ¿Qué condición permite que el optimizador descarte particiones (*pruning*)?

- a) `WHERE cliente_id = 1500`
- b) `WHERE estado = 'PENDIENTE' AND sucursal_id = 12`
- c) `WHERE fecha >= '2024-01-01' AND fecha < '2024-04-01'`
- d) `WHERE EXTRACT(MONTH FROM fecha) = 3`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El pruning necesita condiciones sobre la **clave de partición** que puedan compararse con los límites de cada partición: un rango de fechas descarta las particiones de otros meses. Las opciones a y b no filtran por la clave. La d aplica una función: "marzo de cualquier año" no se traduce a un rango de `fecha`, así que no poda.

</details>

**Pregunta 18** · Intermedia · *Partición frente a índice*

En la tabla particionada por mes, la consulta por `cliente_id` recorre las 48 particiones (9,3 ms). Con un índice `(cliente_id, fecha)` baja a 0,17 ms. ¿Qué conclusión corresponde?

- a) La partición reduce lo recorrido cuando se filtra por fecha, pero no localiza filas por otra dimensión: no reemplaza al índice.
- b) Particionar fue un error y hay que volver a la tabla sin particionar.
- c) El índice anula los beneficios del pruning en las consultas por fecha.
- d) Conviene particionar también por `cliente_id` y eliminar el índice.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Partición e índice resuelven problemas distintos. La partición conviene para consultas por período y para retirar datos históricos; el índice localiza filas por otras columnas. Las dos estructuras conviven sin anularse (c). Particionar por cada dimensión de búsqueda no es viable (d).

</details>

**Pregunta 19** · Intermedia · *Retención de datos históricos*

Hay que retirar el mes más antiguo de una tabla particionada por mes, con decenas de millones de filas. ¿Qué afirmación es correcta?

- a) `DELETE` es preferible porque es transaccional y `DETACH PARTITION` no lo es.
- b) `DETACH PARTITION` genera más log que `DELETE`, porque mueve las filas a otra tabla.
- c) `DELETE` y `DETACH` cuestan lo mismo porque afectan exactamente las mismas filas.
- d) `DETACH` o `DROP PARTITION` es un cambio de metadatos; `DELETE` recorre fila por fila, genera log y, en PostgreSQL, deja tuplas muertas para `VACUUM`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Separar o eliminar una partición actualiza el catálogo y no toca las filas, así que el tiempo es casi constante. El `DELETE` masivo genera log, locks y fragmentación. `DETACH` no mueve filas (b), y en PostgreSQL también es transaccional (a).

</details>

**Pregunta 20** · Básica · *Estimado contra real*

El plan estima 12 filas para un paso y en la ejecución real lee 480.000. Antes de crear otro índice, ¿qué corresponde hacer primero?

- a) Aumentar la memoria del servidor para que la lectura sea más rápida.
- b) Actualizar las estadísticas (`ANALYZE`) y volver a comparar el plan.
- c) Particionar la tabla por la columna del filtro.
- d) Crear un índice con todas las columnas de la consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Una diferencia enorme entre lo estimado y lo real indica que el optimizador trabaja con estadísticas viejas o con una distribución sesgada. Con una mala estimación puede elegir un mal plan aunque existan buenos índices. Primero se corrige la causa, que es la más barata.

</details>

**Pregunta 21** · Básica · *Función sobre la columna*

La consulta `WHERE YEAR(fecha) = 2026` no usa el índice que existe sobre `fecha`. ¿Cuál es la mejora más directa?

- a) Crear un índice hash sobre `fecha`.
- b) Agregar `ORDER BY fecha` para que el optimizador prefiera el índice.
- c) Reescribir la condición como rango: `fecha >= '2026-01-01' AND fecha < '2027-01-01'`.
- d) Aumentar `sort_buffer_size`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Aplicar una función sobre la columna impide usar el índice tal como está ordenado. El rango equivalente sí lo aprovecha. Un índice hash solo sirve para igualdad exacta (a), y las opciones b y d no tienen relación con la causa.

</details>

**Pregunta 22** · Intermedia · *Ordenamiento que llega al disco*

Un plan de MySQL muestra un *range scan* que tarda 2,7 s y un tiempo total de 11 s; además `Sort_merge_passes` aumentó en 24. ¿Qué parte domina la demora y qué indica esa métrica?

- a) Domina el ordenamiento: no entró en el buffer de ordenamiento y necesitó pasadas de mezcla en disco.
- b) Domina el range scan: la métrica cuenta las lecturas físicas del índice.
- c) Domina el `LIMIT`: la métrica cuenta cuántas veces se cortó el resultado.
- d) Domina la red: la métrica cuenta los paquetes enviados al cliente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El scan explica 2,7 s de los 11, así que el resto es el ordenamiento. `Sort_merge_passes` cuenta las pasadas de mezcla de archivos temporales: es la señal de que el sort derramó a disco. Se corrige reduciendo las filas que llegan al sort, con un índice que entregue el orden (con igualdad en la primera columna) o con más memoria para esa sesión.

</details>

**Pregunta 23** · Intermedia · *Clave primaria en InnoDB*

En InnoDB se reemplaza una PK `BIGINT` por un `VARCHAR(36)` con UUID. ¿Qué efecto físico es esperable?

- a) Ninguno: la PK afecta solo a la tabla, no a los índices secundarios.
- b) Mejora la inserción, porque los UUID nunca chocan entre sí.
- c) Los índices secundarios se achican, porque dejan de guardar la PK.
- d) Los índices secundarios crecen, porque cada entrada guarda el valor de la PK como referencia a la fila.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** En InnoDB la tabla es un B-tree ordenado por la PK, y cada índice secundario apunta a la fila mediante el valor de la PK: una PK ancha agranda todos los índices. Además, un UUID aleatorio inserta en cualquier lugar del árbol, lo que divide páginas y empeora la inserción (b es falsa).

</details>

**Pregunta 24** · Básica · *Materializar resultados*

Un reporte mensual pesado se consulta cientos de veces por día, y los datos de meses cerrados no cambian. ¿Qué alternativa física es más coherente?

- a) Un índice sobre cada columna que aparece en el reporte.
- b) Desnormalizar todas las tablas del sistema.
- c) Una vista materializada o una tabla resumen, definiendo cuándo se refresca.
- d) Aumentar la cantidad de conexiones del pool.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Si el resultado se repite y los datos de base no cambian, precalcularlo cambia cómputo por almacenamiento. El costo es definir el refresco y la consistencia. Indexar todo (a) y desnormalizar todo (b) son soluciones desproporcionadas; el pool (d) no tiene relación.

</details>

---

## Unidad 3 · SQL avanzado

**Pregunta 25** · Intermedia · *Última venta por cliente*

Se pide la última venta de cada cliente: una fila por cliente con los datos completos de la venta, desempate determinista si hay dos ventas el mismo día y sin perder a los clientes sin ventas. ¿Qué versión cumple todo?

- a) `SELECT cliente_id, MAX(fecha) FROM venta GROUP BY cliente_id`.
- b) Una CTE con `ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha DESC)` sobre `cliente JOIN venta`, filtrando `rn = 1`.
- c) `cliente LEFT JOIN` la CTE con `ROW_NUMBER()` (`ORDER BY fecha DESC, venta_id DESC`), filtrando con `WHERE rn = 1`.
- d) `cliente LEFT JOIN` la CTE con `ROW_NUMBER()` (`ORDER BY fecha DESC, venta_id DESC`), con `rn = 1` dentro de la condición del `ON`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** a) no trae la fila completa ni desempata. b) el `JOIN` pierde a los clientes sin ventas y sin desempate el resultado puede variar. c) parece correcta, pero en el `WHERE` los clientes sin ventas tienen `rn = NULL`, la condición da UNKNOWN y desaparecen. En el `ON`, la condición solo decide con qué fila se empareja cada cliente.

</details>

**Pregunta 26** · Básica · *RANK y DENSE_RANK*

Los totales son A = 500, B = 300, C = 300 y D = 200. Con orden descendente, ¿qué posición asignan `RANK()` y `DENSE_RANK()` a D?

- a) `RANK` = 3 y `DENSE_RANK` = 3
- b) `RANK` = 4 y `DENSE_RANK` = 3
- c) `RANK` = 4 y `DENSE_RANK` = 4
- d) `RANK` = 3 y `DENSE_RANK` = 4

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** B y C comparten el puesto 2. `RANK` deja un hueco (no hay puesto 3), así que D es 4. `DENSE_RANK` no deja huecos, así que D es 3. `ROW_NUMBER` les daría 2 y 3 a B y C, en un orden arbitrario si no hay desempate.

</details>

**Pregunta 27** · Básica · *Filtrar una función de ventana*

¿Por qué falla `SELECT v.*, ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha DESC) AS rn FROM venta v WHERE rn = 1`?

- a) Porque el `WHERE` se evalúa antes que las funciones de ventana y antes de que exista el alias `rn`: hay que filtrar en una consulta externa (CTE o subconsulta).
- b) Porque `ROW_NUMBER` solo se puede usar junto con `GROUP BY`.
- c) Porque las funciones de ventana no admiten alias.
- d) Porque una función de ventana se compara con `IS`, no con `=`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Por el orden lógico de evaluación (`FROM` → `WHERE` → `GROUP BY` → `HAVING` → ventanas → `SELECT`), el `WHERE` no puede ver un cálculo que todavía no existe. Por eso el patrón es "CTE con la ventana + filtro afuera".

</details>

**Pregunta 28** · Desafío · *Marco de la ventana y empates*

Un acumulado usa `SUM(total) OVER (PARTITION BY cliente_id ORDER BY fecha)`, sin marco explícito. Dos ventas del mismo cliente tienen la misma fecha. ¿Qué se observa?

- a) Un error: con `ORDER BY` es obligatorio escribir `ROWS BETWEEN`.
- b) Cada venta muestra un acumulado distinto, en el orden en que se insertaron.
- c) Las dos ventas muestran el mismo acumulado: con `ORDER BY`, el marco por defecto es `RANGE` e incluye a las filas empatadas.
- d) El motor descarta una de las dos ventas para evitar el empate.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El marco por defecto con `ORDER BY` es `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`, que trata a las filas con el mismo valor de orden como "pares" y las suma juntas. Para un acumulado fila por fila se usa `ROWS` y un segundo criterio de orden (`fecha, venta_id`). No hay error (a) y no se garantiza ningún orden de inserción (b).

</details>

**Pregunta 29** · Básica · *Partición incompleta*

El acumulado mensual del cliente 2 empieza sumando el último valor del cliente 1. ¿Qué falta en la ventana?

- a) Un `GROUP BY cliente_id` en la consulta.
- b) Un `ORDER BY total` dentro de la ventana.
- c) Reemplazar `SUM` por `COUNT`.
- d) Particionar por cliente (y también por año y mes, si el acumulado debe reiniciarse cada mes).

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** `PARTITION BY` define dónde se reinicia el cálculo. Sin partición por cliente, el acumulado continúa de un cliente al siguiente. Un `GROUP BY` (a) colapsaría las filas y se perdería el detalle de cada venta.

</details>

**Pregunta 30** · Intermedia · *Existencia frente a combinación*

Se listan los clientes con al menos una venta mayor a 100.000 usando `cliente JOIN venta ON ... WHERE v.total > 100000`, y un cliente aparece tres veces. ¿Qué alternativa expresa mejor la intención?

- a) `WHERE EXISTS (SELECT 1 FROM venta v WHERE v.cliente_id = c.cliente_id AND v.total > 100000)`
- b) Agregar `ORDER BY cliente_id` para agrupar las repeticiones.
- c) Cambiar el `JOIN` por un `LEFT JOIN`.
- d) Agregar `LIMIT 1` al final de la consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La pregunta es de **existencia**, no de combinación: `EXISTS` devuelve cada cliente una sola vez, sin importar cuántas ventas cumplan. El `JOIN` repite al cliente por cada venta (1 a N). `LEFT JOIN` (c) agrega clientes que no corresponden, y `LIMIT 1` (d) devolvería un solo cliente.

</details>

**Pregunta 31** · Desafío · *NOT IN con nulos*

Para obtener clientes sin ventas se usa `WHERE cliente_id NOT IN (SELECT cliente_id FROM venta)`, y la consulta devuelve cero filas aunque hay clientes que nunca compraron. La columna `venta.cliente_id` admite `NULL` y algunas filas lo tienen. ¿Por qué ocurre?

- a) Porque `NOT IN` no se puede usar con subconsultas.
- b) Porque la subconsulta necesita `DISTINCT` para funcionar.
- c) Porque si la lista contiene un `NULL`, la comparación da UNKNOWN para todas las filas; `NOT EXISTS` no tiene ese problema.
- d) Porque falta un índice sobre `venta.cliente_id`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `x NOT IN (1, 2, NULL)` equivale a `x <> 1 AND x <> 2 AND x <> NULL`, y la última comparación da UNKNOWN: la condición nunca es verdadera. `NOT EXISTS` evalúa la existencia de filas y no se ve afectado. Un `DISTINCT` (b) o un índice (d) no cambian el resultado.

</details>

**Pregunta 32** · Desafío · *LEFT JOIN y filtro sobre la tabla derecha*

Se quiere listar **todos** los clientes con sus ventas de 2026, incluidos los que no compraron en 2026. La consulta `cliente c LEFT JOIN venta v ON v.cliente_id = c.cliente_id WHERE v.fecha >= '2026-01-01'` no los muestra. ¿Cómo se corrige?

- a) Cambiar el `LEFT JOIN` por un `RIGHT JOIN`.
- b) Mover la condición de fecha al `ON` del `LEFT JOIN`.
- c) Agregar `OR v.venta_id IS NULL` al `WHERE`.
- d) Cambiar el `LEFT JOIN` por un `INNER JOIN`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** En el `ON`, la fecha decide qué ventas se emparejan, y el cliente se conserva aunque no tenga ninguna de 2026. La opción c es una trampa: recupera a quienes **nunca** compraron, pero sigue perdiendo a quienes solo compraron antes de 2026, porque sus filas existen con fechas anteriores y el `WHERE` las descarta.

</details>

**Pregunta 33** · Desafío · *Ciclos en una CTE recursiva*

Una CTE recursiva se ancla en `cliente_id = 5` para listar todos sus subordinados. Por un error de carga, el cliente 7 depende del 5 y el 5 depende del 7. ¿Qué ocurre?

- a) La recursión no termina por sí sola: MySQL la corta con error al superar `cte_max_recursion_depth` (1000 por defecto); en PostgreSQL hay que protegerla con un límite de nivel, controlando la ruta recorrida o con la cláusula `CYCLE`.
- b) Los dos motores detectan el ciclo y devuelven cada cliente una sola vez.
- c) La consulta devuelve solo la fila del ancla.
- d) La consulta falla de inmediato por un error de sintaxis.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La CTE termina cuando una iteración no produce filas nuevas. Con un ciclo, el paso recursivo vuelve a encontrar al 5, después al 7, y así sin fin. Ningún motor deduplica solo con `UNION ALL` (b). La sintaxis es válida (d): el problema está en los datos.

</details>

**Pregunta 34** · Intermedia · *Tipo de la ruta en MySQL*

En MySQL, una CTE recursiva arma la ruta con `CONCAT(j.ruta, ' > ', c.nombre)` y, a partir del segundo nivel, falla con "Data too long" o la ruta aparece cortada. ¿Por qué?

- a) Porque `CONCAT` no está permitido dentro del paso recursivo.
- b) Porque falta un índice sobre `responsable_id`.
- c) Porque el tipo de la columna lo define el ancla: hay que declarar la ruta inicial con `CAST(nombre AS CHAR(n))`.
- d) Porque MySQL limita las rutas jerárquicas a 10 niveles.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El ancla fija el tipo y el largo de cada columna de la CTE. Si la ruta inicial es un `nombre` de 80 caracteres, la ruta concatenada no entra. En PostgreSQL pasa algo parecido y se resuelve con `nombre::text`.

</details>

**Pregunta 35** · Intermedia · *Ventana frente a subconsulta correlacionada*

Una alternativa al acumulado con ventana es una subconsulta correlacionada que suma las ventas anteriores del mismo cliente y mes. ¿Qué afirmación es correcta?

- a) La subconsulta siempre es más rápida, porque no necesita ordenar.
- b) Pueden dar el mismo resultado, pero la subconsulta se evalúa una vez por fila y debe reproducir a mano el desempate; la ventana resuelve en una pasada sobre los datos ordenados.
- c) La ventana pierde el detalle de cada venta, y por eso se prefiere la subconsulta.
- d) Solo la subconsulta puede reiniciar el acumulado cada mes.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Para dar lo mismo, la subconsulta tiene que comparar `(fecha, venta_id)` igual que el `ORDER BY` de la ventana; si no, las ventas del mismo día muestran el mismo acumulado. Con N ventas, la subconsulta implica N recorridos (salvo que el optimizador la transforme). La ventana conserva cada fila (c es falsa) y se reinicia por mes con `PARTITION BY` (d es falsa).

</details>

**Pregunta 36** · Intermedia · *¿La CTE es más rápida?*

Un compañero afirma: "reescribí la subconsulta como CTE, así que ahora es más rápida". ¿Qué respuesta es la más precisa?

- a) Es correcto: las CTE siempre se materializan, y eso acelera la consulta.
- b) Es correcto: las CTE se ejecutan en paralelo con la consulta principal.
- c) Es incorrecto: las CTE siempre son más lentas que las subconsultas.
- d) No se puede afirmar sin evidencia: la CTE mejora la legibilidad, pero el rendimiento depende de cómo la planifique el motor; hay que comparar los planes.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Una CTE organiza el razonamiento en etapas con nombre. Según el motor y la versión, puede integrarse en la consulta o materializarse, y eso cambia el rendimiento en cualquiera de los dos sentidos. Las opciones a, b y c usan absolutos sin evidencia.

</details>

**Pregunta 37** · Básica · *Carga masiva*

Hay que cargar 2 millones de ventas desde un archivo CSV. ¿Qué enfoque reduce más el costo por fila?

- a) Una carga por lote, con `LOAD DATA INFILE` en MySQL o `COPY` en PostgreSQL, validando conteos y sumas después.
- b) 2 millones de `INSERT` individuales con autocommit, para que cada fila quede confirmada.
- c) Un trigger que inserte las filas de a una.
- d) Una función de ventana que recorra el CSV.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La carga por lote evita el costo repetido de cada interacción: red, parseo y un commit por fila. La herramienta cambia según el motor, pero el principio es el mismo. Después de cargar se valida (cantidad de filas, sumas de control).

</details>

---

## Unidad 4 · Programabilidad y migraciones

**Pregunta 38** · Básica · *Mecanismo para una regla simple*

La regla es "el saldo de una cuenta nunca puede ser negativo". ¿Qué mecanismo es el más adecuado?

- a) Un trigger `BEFORE UPDATE` que valide el saldo y lance un error.
- b) Un procedimiento que la aplicación deba invocar antes de cada `UPDATE`.
- c) Una restricción `CHECK (saldo >= 0)` sobre la tabla.
- d) Una validación solo en la aplicación, para no acoplar la regla al motor.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es una regla simple sobre una fila y se puede declarar: el `CHECK` la evalúa el motor en cualquier ruta de escritura, sin código que mantener. El trigger (a) funciona, pero es más complejo de lo necesario. El procedimiento (b) y la validación en la aplicación (d) se pueden saltear.

</details>

**Pregunta 39** · Intermedia · *CHECK y NULL*

La columna `precio` es `NOT NULL` y tiene `CHECK (precio > 0)`. ¿Qué rechaza la sentencia `UPDATE producto SET precio = NULL WHERE producto_id = 1`?

- a) El `CHECK`, porque `NULL` no es mayor que 0.
- b) La restricción `NOT NULL`: un `CHECK` solo rechaza cuando la condición da FALSE, y con `NULL` da UNKNOWN.
- c) Ninguna restricción: la actualización se acepta.
- d) El trigger de auditoría de precios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es un detalle que confunde en las pruebas. Si la columna aceptara nulos, el `UPDATE` pasaría a pesar del `CHECK`. Para impedir nulos hace falta `NOT NULL`. La opción c sería correcta solo si la columna no tuviera esa restricción.

</details>

**Pregunta 40** · Básica · *Función o procedimiento*

La clasificación Bronce, Plata u Oro de un cliente debe poder usarse dentro de un `SELECT` que lista a todos los clientes. ¿Qué objeto corresponde?

- a) Un procedimiento con un parámetro `OUT`, porque también puede devolver valores.
- b) Un trigger `AFTER INSERT` sobre la tabla de ventas.
- c) Un `CHECK` sobre la tabla de clientes.
- d) Una función almacenada que reciba el cliente y el año, calcule el total y devuelva la categoría.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Se necesita un **valor** reutilizable dentro de una expresión: eso es una función. Un procedimiento se invoca con `CALL` y no se puede usar dentro de un `SELECT` (a). Un trigger reacciona a eventos (b) y un `CHECK` valida filas (c).

</details>

**Pregunta 41** · Desafío · *Bordes de la clasificación*

La regla dice: Bronce menos de 2.000.000; Plata entre 2.000.000 y 50.000.000; Oro más de 50.000.000. ¿Qué implementación respeta los bordes?

- a) `IF total > 50000000 THEN 'Oro' ELSIF total >= 2000000 THEN 'Plata' ELSE 'Bronce'`
- b) `IF total >= 50000000 THEN 'Oro' ELSIF total > 2000000 THEN 'Plata' ELSE 'Bronce'`
- c) `IF total < 2000000 THEN 'Bronce' ELSIF total < 50000000 THEN 'Plata' ELSE 'Oro'`
- d) `IF total > 2000000 THEN 'Plata' ELSIF total > 50000000 THEN 'Oro' ELSE 'Bronce'`

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Hay que probar los valores exactos. Con 2.000.000: a) da Plata ✓, b) da Bronce ✗. Con 50.000.000: a) da Plata ✓, b) y c) dan Oro ✗. En d) nunca se llega a Oro, porque todo lo mayor a 2.000.000 ya entra por la primera condición. Por eso los casos límite son parte de las pruebas.

</details>

**Pregunta 42** · Intermedia · *Parámetros inválidos*

La consulta `SELECT clasificar_cliente(NULL, NULL)` devuelve "Bronce". ¿Qué evaluación es más adecuada?

- a) Es correcto: un cliente inexistente no tiene ventas, así que es Bronce.
- b) Es un resultado engañoso: la función debería validar los parámetros y que el cliente exista, y lanzar un error (`RAISE EXCEPTION` o `SIGNAL`).
- c) Es un error del motor: `SUM` debería fallar cuando recibe parámetros nulos.
- d) Se corrige declarando la función `IMMUTABLE`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `COALESCE(SUM(total), 0)` sobre cero filas da 0, y 0 cae en Bronce: el resultado parece válido aunque la entrada no lo es. Un caso inválido debería producir un error explícito. Además, `IMMUTABLE` sería incorrecto, porque la función lee tablas (d).

</details>

**Pregunta 43** · Básica · *Auditoría automática*

Toda modificación de precio debe quedar registrada con el valor anterior y el nuevo, sin depender de la aplicación. ¿Qué mecanismo y qué valores se usan?

- a) Un `CHECK` que compare el precio viejo con el nuevo.
- b) Un trigger `BEFORE INSERT` que registre `NEW.precio`.
- c) Un procedimiento que la aplicación llame después de cada `UPDATE`.
- d) Un trigger `AFTER UPDATE` que inserte `OLD.precio` y `NEW.precio` en la tabla de auditoría.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Reaccionar automáticamente ante un `UPDATE` es el caso típico del trigger. `OLD` y `NEW` dan el valor anterior y el nuevo. Un `CHECK` no tiene acceso a `OLD` (a), un `INSERT` no es un cambio de precio (b), y un procedimiento depende de que la aplicación se acuerde de llamarlo (c).

</details>

**Pregunta 44** · Intermedia · *Comparación con nulos en un trigger*

Un trigger de auditoría usa `IF OLD.precio <> NEW.precio THEN ...`. ¿En qué caso **no** registra un cambio real?

- a) Cuando el precio pasa de `NULL` a un valor, o de un valor a `NULL`, porque la comparación da UNKNOWN.
- b) Cuando el precio aumenta más del 50 %.
- c) Cuando el mismo `UPDATE` modifica varias filas a la vez.
- d) En ningún caso: `<>` detecta todos los cambios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Cualquier comparación con `NULL` da UNKNOWN, y el `IF` no entra. La forma segura es `OLD.precio IS DISTINCT FROM NEW.precio` en PostgreSQL y `NOT (OLD.precio <=> NEW.precio)` en MySQL. Si la columna es `NOT NULL`, `<>` alcanza. Un trigger `FOR EACH ROW` se ejecuta por cada fila (c).

</details>

**Pregunta 45** · Intermedia · *Triggers en cada motor*

¿Qué diferencia de implementación de triggers entre MySQL y PostgreSQL es correcta?

- a) En PostgreSQL la lógica se escribe dentro del trigger; en MySQL el trigger invoca una función.
- b) MySQL permite `AFTER UPDATE OF precio ... WHEN (...)`; PostgreSQL no tiene esa sintaxis.
- c) En PostgreSQL el trigger ejecuta una función `RETURNS TRIGGER` y admite `UPDATE OF columna` y `WHEN`; en MySQL la lógica va en el cuerpo del trigger y la condición se evalúa adentro con `IF`.
- d) En ninguno de los dos motores el trigger se ejecuta dentro de la transacción que lo disparó.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es exactamente al revés de lo que dicen a y b. En PostgreSQL, `AFTER UPDATE OF precio ... WHEN (OLD.precio IS DISTINCT FROM NEW.precio)` hace que la función ni se invoque si el precio no cambió. En los dos motores el trigger corre dentro de la misma transacción (d es falsa).

</details>

**Pregunta 46** · Intermedia · *Error dentro de un trigger*

Un `UPDATE` de precio dispara un trigger que inserta en la tabla de auditoría, y esa inserción falla por una restricción. ¿Qué pasa con el `UPDATE`?

- a) Se confirma igual, porque el trigger se ejecuta después del cambio.
- b) Falla también: el trigger forma parte de la misma operación y su error revierte la sentencia.
- c) Queda pendiente hasta que se corrija la auditoría.
- d) Se confirma, y el motor reintenta la auditoría más tarde.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Aunque sea `AFTER`, el trigger se ejecuta dentro de la misma sentencia y de la misma transacción: si falla, falla todo. Esa es la garantía de la auditoría por trigger: no puede existir un cambio sin su registro.

</details>

**Pregunta 47** · Desafío · *Migración en una tabla grande*

La tabla `pedido` tiene 80 millones de filas y necesita una columna `estado` obligatoria con valores permitidos, más la auditoría de sus cambios. ¿Qué orden reduce el riesgo en producción?

- a) Agregar la columna `NOT NULL` con su `CHECK` en una sola sentencia sin `DEFAULT`, y corregir después las filas que fallen.
- b) Crear una tabla nueva con la definición final, copiar los datos y borrar la vieja en la misma ventana de mantenimiento.
- c) Crear primero el trigger de auditoría, para que quede registrado cómo se completan los valores históricos.
- d) Agregar la columna aceptando `NULL`, completar los históricos por lotes, validar que no queden nulos, y recién después aplicar `CHECK` y `NOT NULL` y habilitar el trigger.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Es la secuencia expandir → completar → validar → endurecer → programar. La opción a falla de entrada, porque las filas existentes no tienen valor. La b es recrear la tabla, justo lo que se quiere evitar. La c es una trampa: el trigger registraría 80 millones de "cambios" del completado histórico como si fueran operaciones reales.

</details>

**Pregunta 48** · Básica · *Rollback con pérdida de datos*

El rollback de v2 a v1 ejecuta `ALTER TABLE pedido DROP COLUMN estado`, y la v2 estuvo cinco días en producción. ¿Qué afirmación es correcta?

- a) Se pierden los estados generados en esos cinco días; conviene respaldarlos antes (backup o copia a una tabla de archivo) o preferir una corrección hacia adelante.
- b) No se pierde nada, porque el rollback restaura automáticamente los datos de v1.
- c) La columna se puede recuperar con `ROLLBACK`, porque el `DROP` todavía no se confirmó.
- d) Solo se pierde la auditoría, porque los estados se guardan en otra tabla.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Avanzar de versión suele ser seguro; retroceder es destructivo. `DROP COLUMN` elimina la información creada en la versión nueva. Un rollback razonable copia esos datos antes (por ejemplo con `CREATE TABLE ... AS SELECT`) o deja la columna y desactiva la lógica. En MySQL el DDL hace commit implícito, así que c es falsa.

</details>

**Pregunta 49** · Intermedia · *DDL dentro de una transacción*

Una migración de cuatro sentencias DDL, escrita entre `BEGIN` y `COMMIT`, falla en la tercera. ¿Qué diferencia hay entre los motores?

- a) Ninguna: los dos revierten las cuatro sentencias.
- b) MySQL revierte todo; PostgreSQL deja aplicadas las dos primeras.
- c) PostgreSQL puede revertir todo, porque su DDL es transaccional; en MySQL cada DDL hace commit implícito, y las dos primeras quedan aplicadas.
- d) Ninguno de los dos motores admite DDL dentro de una transacción.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** En PostgreSQL, un `ALTER TABLE` dentro de `BEGIN` se puede revertir: la migración es "todo o nada". En MySQL cada sentencia DDL confirma por su cuenta. Por eso, en MySQL cada paso de una migración debería ser idempotente o tener su reverso.

</details>

**Pregunta 50** · Básica · *Dónde vive la regla*

En la defensa preguntan si la regla "el saldo no puede ser negativo" debe estar en la base, en la aplicación o en ambas. ¿Qué respuesta se defiende mejor?

- a) Solo en la aplicación, para no acoplar el sistema al motor.
- b) Solo en la base, porque la aplicación no debería validar nada.
- c) En un trigger, porque es más flexible que un `CHECK`.
- d) En ambas: la aplicación valida para responder rápido al usuario, y la base garantiza la regla ante cualquier acceso que saltee la aplicación.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Es defensa en profundidad. La aplicación da una buena experiencia de usuario, y la base es la última línea de defensa: protege aunque alguien entre por consola o por otra aplicación. Para una regla simple, el mecanismo en la base es un `CHECK`, no un trigger (c).

</details>

---

## Unidad 5 · Conectividad, transacciones y concurrencia

**Pregunta 51** · Básica · *Conexión rechazada*

Desde otra PC, el cliente informa "Connection refused" al conectarse al MySQL de la VM. En la VM, `ss -lntp` muestra `127.0.0.1:3306`. ¿Cuál es la causa?

- a) El usuario no existe para el host desde el que se conecta.
- b) El firewall descarta los paquetes antes de que lleguen.
- c) El motor solo escucha en localhost: hay que configurar `bind-address` (por ejemplo `0.0.0.0` o la IP de la VM) y reiniciar el servicio.
- d) La base de datos indicada en la cadena de conexión no existe.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `127.0.0.1:3306` indica que el listener solo atiende conexiones locales, y por eso la remota se rechaza. Un firewall que descarta paquetes suele producir un *timeout*, no un rechazo (b). Los problemas de usuario o de base aparecen después de conectar, con otros mensajes (a y d).

</details>

**Pregunta 52** · Intermedia · *Regla de acceso en PostgreSQL*

En PostgreSQL, el servidor escucha en `0.0.0.0:5432` y el puerto es alcanzable desde la red del aula, pero el cliente recibe `no pg_hba.conf entry for host`. ¿Qué corresponde?

- a) Cambiar `listen_addresses` a `'*'` y reiniciar.
- b) Abrir el puerto 5432 en el firewall.
- c) Darle `SUPERUSER` al usuario que se conecta.
- d) Agregar en `pg_hba.conf` una regla para la subred necesaria, con `scram-sha-256`, y recargar la configuración.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El mensaje dice exactamente qué falta: una regla de acceso para ese origen. La red y el listener ya funcionan (a y b), y `SUPERUSER` no tiene relación con quién puede conectarse (c). La regla conviene limitarla a la subred del aula, no a `0.0.0.0/0`.

</details>

**Pregunta 53** · Intermedia · *Mínimo privilegio en la guardia DBA*

Cada integrante necesita ver las sesiones y los locks del servidor para la guardia DBA, pero no debe poder administrar el motor. ¿Qué configuración es más adecuada?

- a) Un único usuario compartido con `SUPERUSER` en PostgreSQL, o con privilegios globales en MySQL.
- b) Un usuario por integrante con privilegios de observación: `pg_monitor` en PostgreSQL; `PROCESS` y `SELECT` sobre `performance_schema` en MySQL.
- c) Que todos usen la cuenta `root` o `postgres` desde sus PCs.
- d) Ninguna: no se pueden observar sesiones sin ser administrador.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Los dos motores tienen privilegios pensados para observar sin administrar. Un usuario por persona permite además saber quién hizo qué. Una cuenta compartida con superusuario (a, c) funciona, pero viola el mínimo privilegio y se pierde la trazabilidad.

</details>

**Pregunta 54** · Intermedia · *Pool de conexiones*

Una aplicación usa un pool de conexiones. Ante un error, un desarrollador devuelve la conexión al pool sin hacer `COMMIT` ni `ROLLBACK`. ¿Qué riesgo aparece?

- a) Ninguno: el pool cierra solo las transacciones pendientes.
- b) El pool abre una sesión nueva por cada pedido, y se pierde la ventaja del pool.
- c) La próxima operación que reciba esa conexión hereda una transacción abierta, que puede retener locks.
- d) La conexión pierde la autenticación y el próximo uso falla.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La conexión conserva su estado de sesión. Si queda una transacción abierta, sus locks siguen tomados, y otro módulo de la aplicación trabaja sin saberlo dentro de ella. El pool gestiona conexiones; no resuelve por sí solo la concurrencia (a).

</details>

**Pregunta 55** · Intermedia · *Bloqueante ociosa en MySQL*

En MySQL, la sesión B quedó esperando al modificar la cuenta 1. En `SHOW PROCESSLIST` la sesión A, que la modificó antes, aparece como `Sleep`. ¿Cómo se interpreta?

- a) A está ociosa pero con una transacción abierta que retiene el lock; se confirma con `performance_schema.data_locks` y `data_lock_waits`, o con `information_schema.innodb_trx`.
- b) A no tiene relación con la espera, porque una sesión en `Sleep` no puede bloquear a otra.
- c) A está ejecutando una consulta lenta que todavía no terminó.
- d) A quedó en un deadlock con B.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** `Sleep` indica que la conexión no está ejecutando nada en ese momento, no que no tenga transacción. Una transacción sin `COMMIT` retiene sus locks aunque la sesión esté ociosa. Para relacionar a la bloqueante con la bloqueada se usan las vistas de locks.

</details>

**Pregunta 56** · Intermedia · *Evento de espera en PostgreSQL*

En PostgreSQL, la sesión bloqueada muestra `wait_event_type = Lock` y `wait_event = transactionid`. ¿Qué significa?

- a) Que espera lecturas de disco de la tabla.
- b) Que hay un deadlock confirmado entre dos transacciones.
- c) Que espera a que se libere una tabla completa, bloqueada con `LOCK TABLE`.
- d) Que espera a que termine la transacción que modificó la fila; la bloqueante se identifica con `pg_blocking_pids`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** PostgreSQL marca los locks de fila en la propia fila, y quien llega después espera a que termine la **transacción** que la modificó (de ahí `transactionid`). Una espera por E/S tendría otro tipo de evento (a). Un deadlock se detecta y se aborta; no queda esperando (b).

</details>

**Pregunta 57** · Básica · *Aislamiento por defecto en MySQL*

En MySQL con la configuración por defecto, A abre una transacción y lee un saldo de 15.000. B le suma 1.000 y confirma. A vuelve a leer dentro de la misma transacción. ¿Qué ve A?

- a) 16.000, porque `READ COMMITTED` toma un snapshot nuevo por sentencia.
- b) 15.000, porque `REPEATABLE READ` reutiliza el snapshot establecido en la primera lectura.
- c) A queda esperando a que B termine.
- d) A recibe un error de serialización.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El nivel por defecto de InnoDB es `REPEATABLE READ`: las lecturas normales usan la "foto" tomada en la primera lectura. En PostgreSQL, con `READ COMMITTED` por defecto, el mismo experimento muestra 16.000 (a). Por eso siempre se consulta primero el nivel real de la sesión.

</details>

**Pregunta 58** · Desafío · *Lectura con bloqueo*

Mismo escenario en MySQL (`REPEATABLE READ`), pero la segunda lectura de A es `SELECT saldo FROM cuenta WHERE cuenta_id = 3 FOR UPDATE`. ¿Qué ve A?

- a) 15.000, porque sigue usando el snapshot de la transacción.
- b) Un error, porque `FOR UPDATE` no está permitido en `REPEATABLE READ`.
- c) 16.000: una lectura con bloqueo lee la última versión confirmada, no el snapshot.
- d) `NULL`, porque la fila está bloqueada por otra sesión.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Las lecturas con bloqueo (`FOR UPDATE`, `FOR SHARE`) no usan MVCC: toman un lock sobre la versión más reciente confirmada, porque se van a usar para modificar. Es la diferencia entre una lectura consistente y una lectura con bloqueo.

</details>

**Pregunta 59** · Intermedia · *Lectores y escritores con MVCC*

A tiene una transacción abierta que modificó la fila de la cuenta 1. B ejecuta un `SELECT` simple (sin `FOR UPDATE`) sobre esa fila. ¿Qué ocurre en los dos motores, con la configuración por defecto?

- a) B no espera: lee la última versión confirmada gracias a MVCC, sin ver el cambio pendiente de A.
- b) B espera a que A termine, porque A tiene un lock exclusivo sobre la fila.
- c) B ve el cambio de A aunque todavía no esté confirmado.
- d) B recibe un error de deadlock.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Con MVCC, los lectores no bloquean a los escritores y los escritores no bloquean a los lectores. Los locks exclusivos frenan a otras **escrituras** o lecturas con bloqueo, no a una lectura normal (b). Ver datos no confirmados sería una lectura sucia (c).

</details>

**Pregunta 60** · Intermedia · *Actualización perdida*

Dos sesiones leen `stock = 10`, calculan 9 en la aplicación y ejecutan `UPDATE producto SET stock = 9`. El stock final queda en 9, aunque se vendieron dos unidades. ¿Qué solución lo evita de forma más directa?

- a) Aumentar el nivel de detalle del log del servidor.
- b) Crear un índice sobre `producto_id`.
- c) Usar `READ UNCOMMITTED` para ver antes los cambios de la otra sesión.
- d) Calcular en la propia sentencia (`SET stock = stock - 1`) o bloquear la fila con `SELECT ... FOR UPDATE` antes de calcular.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Con un `UPDATE` atómico, el motor calcula sobre la versión vigente de la fila. Si la lógica es más compleja, `FOR UPDATE` obliga a la segunda sesión a esperar y leer el valor actualizado. Leer datos no confirmados (c) empeora el problema.

</details>

**Pregunta 61** · Intermedia · *Detección de deadlocks en PostgreSQL*

¿Cuándo detecta PostgreSQL un deadlock?

- a) Inmediatamente, en el instante en que se cierra el ciclo.
- b) Nunca: la aplicación lo tiene que detectar con un timeout propio.
- c) Cuando una sesión lleva `deadlock_timeout` esperando (1 s por defecto): ahí corre la detección y, si encuentra el ciclo, aborta una transacción.
- d) En el siguiente checkpoint.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Revisar ciclos tiene un costo, así que PostgreSQL lo hace solo después de esperar `deadlock_timeout`. En la práctica, la víctima suele ser la sesión que cerró el ciclo. InnoDB, en cambio, detecta el ciclo apenas se forma (a describe a MySQL).

</details>

**Pregunta 62** · Desafío · *Estado de la víctima*

Después de un deadlock, ¿qué diferencia hay en el estado de la transacción víctima entre los dos motores?

- a) En MySQL toda la transacción víctima se revierte; en PostgreSQL queda abortada y rechaza cualquier comando hasta que se ejecute `ROLLBACK`.
- b) En los dos motores se revierte solo la última sentencia y la transacción sigue abierta normalmente.
- c) En MySQL la víctima queda abortada esperando un `ROLLBACK`; en PostgreSQL se revierte sola por completo.
- d) En los dos motores la víctima se confirma parcialmente hasta la sentencia anterior.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** InnoDB revierte la transacción completa de la víctima (error 1213). En PostgreSQL la sesión queda en estado `idle in transaction (aborted)` y responde *"current transaction is aborted, commands ignored until end of transaction block"* hasta el `ROLLBACK`. La opción c invierte los motores. Ninguno confirma una transacción a medias (d).

</details>

**Pregunta 63** · Básica · *Prevenir deadlocks*

Dos procesos de transferencias producen deadlocks frecuentes al actualizar pares de cuentas. ¿Qué medida ataca la causa?

- a) Agregar CPU y memoria al servidor.
- b) Aumentar `innodb_lock_wait_timeout`.
- c) Reiniciar el servidor todas las noches.
- d) Actualizar siempre las cuentas en un orden canónico (por ejemplo, `cuenta_id` ascendente), mantener las transacciones cortas y reintentar ante el error.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El deadlock es un problema **lógico**: dos transacciones toman los mismos recursos en orden inverso. Con un orden canónico no se puede formar un ciclo. Más hardware (a) o esperar más tiempo (b) no cambia el orden de acceso.

</details>

**Pregunta 64** · Básica · *Lentitud o bloqueo*

Un usuario dice que "la base está lenta". Su sesión lleva 4 minutos en un `UPDATE`, sin consumo de CPU ni lecturas de disco. ¿Qué hipótesis es más coherente y qué evidencia la confirma?

- a) Un plan lento; se confirma con `EXPLAIN ANALYZE`.
- b) Una espera por lock; se confirma con el estado de la sesión y las vistas de locks (`data_locks` o `pg_locks`, `pg_blocking_pids`).
- c) Falta de memoria; se confirma con el tamaño del buffer pool.
- d) Un deadlock; se confirma porque ya pasaron más de 4 minutos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Una consulta que trabaja consume CPU o E/S; una consulta que espera, no. La evidencia está en las vistas de sesiones y locks. No puede ser un deadlock (d), porque el motor lo habría detectado y abortado mucho antes.

</details>

**Pregunta 65** · Básica · *Fenómenos de aislamiento*

¿Qué fenómeno permite `READ COMMITTED` y evita `REPEATABLE READ`?

- a) La lectura no repetible.
- b) La lectura sucia.
- c) La pérdida de durabilidad.
- d) El deadlock.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** En `READ COMMITTED`, la misma fila puede devolver otro valor en una segunda lectura de la misma transacción. La lectura sucia ya la evita `READ COMMITTED` (b). La durabilidad no depende del aislamiento (c), y los deadlocks pueden ocurrir en cualquier nivel (d).

</details>

---

## Unidad 6 · Seguridad, backup, réplica y alta disponibilidad

**Pregunta 66** · Básica · *Permisos de la cuenta de aplicación*

La cuenta de la aplicación tiene `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE` y `DROP` sobre toda la base. ¿Qué riesgo es el más grave y qué corrección corresponde?

- a) Ninguno: la aplicación necesita todos esos permisos para funcionar.
- b) Un riesgo de rendimiento, que se corrige con índices.
- c) Una inyección SQL podría destruir tablas: se quitan los permisos DDL y los `DELETE` que no corresponden, y se otorgan permisos por tabla según la función.
- d) Se corrige cambiando la contraseña de la aplicación.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La aplicación no crea ni borra tablas en tiempo de ejecución: el DDL es para el DBA o para los scripts de migración. Con `DROP`, un ataque o un error puede destruir la estructura. Cambiar la contraseña (d) no reduce los permisos.

</details>

**Pregunta 67** · Básica · *Evidencia de mínimo privilegio*

¿Qué evidencia demuestra mejor que el rediseño de permisos funciona?

- a) Ejecutar con cada rol las operaciones permitidas (deben funcionar) y las prohibidas (deben fallar con el error de permisos esperado).
- b) Mostrar el script de `GRANT` que se ejecutó.
- c) Una captura de la lista de usuarios del servidor.
- d) Que la aplicación funcione un día entero sin errores.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** No alcanza con afirmar "no tiene permisos": hay que ejecutar una prueba que falle por la razón correcta (MySQL `ERROR 1142`; PostgreSQL `permission denied`). También hay que probar que lo legítimo sigue funcionando. Un script (b) muestra la intención, no el resultado.

</details>

**Pregunta 68** · Intermedia · *Rol sin activar en MySQL*

En MySQL se crea `rol_analista` con `SELECT`, se le asigna a `'ana'@'%'`, y al conectarse `ana` recibe `SELECT command denied`. ¿Cuál es la causa más probable?

- a) Falta ejecutar `FLUSH PRIVILEGES` después del `GRANT`.
- b) Los roles se deben crear con `IDENTIFIED BY`.
- c) MySQL no permite otorgar `SELECT` a un rol.
- d) El rol no está activo en la sesión: falta `SET DEFAULT ROLE` (o `activate_all_roles_on_login`).

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** En MySQL 8, los roles asignados no se activan solos al iniciar sesión. `FLUSH PRIVILEGES` (a) no hace falta después de `GRANT`: solo cuando se editan a mano las tablas de sistema. En PostgreSQL los roles se heredan por defecto.

</details>

**Pregunta 69** · Intermedia · *Secuencias en PostgreSQL*

En PostgreSQL, después del rediseño, la aplicación tiene `INSERT` sobre `movimiento`, pero los `INSERT` fallan con `permission denied for sequence movimiento_id_seq`. ¿Qué falta?

- a) Otorgar `DELETE` sobre `movimiento`.
- b) Otorgar `USAGE` (y `SELECT`) sobre la secuencia a la cuenta de la aplicación.
- c) Otorgar `SUPERUSER` a la cuenta de la aplicación.
- d) Eliminar la secuencia y cargar los IDs a mano.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Una columna `SERIAL` obtiene su valor con `nextval()` sobre una secuencia, que es un objeto con permisos propios. En MySQL `AUTO_INCREMENT` no requiere permisos extra. Las opciones a y c amplían los permisos sin resolver la causa.

</details>

**Pregunta 70** · Desafío · *TRUNCATE en cada motor*

En una prueba de accesos indebidos, se ejecuta `TRUNCATE` dentro de `BEGIN ... ROLLBACK` para no perder datos. ¿En qué motor funciona esa precaución?

- a) En los dos: `TRUNCATE` siempre es transaccional.
- b) Solo en MySQL.
- c) Solo en PostgreSQL: ahí `TRUNCATE` es transaccional; en MySQL es DDL con commit implícito y no se puede revertir.
- d) En ninguno de los dos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** En PostgreSQL `TRUNCATE` tiene un privilegio propio y se revierte con `ROLLBACK`. En MySQL requiere el privilegio `DROP` y confirma de inmediato: repetir esa prueba en MySQL vaciaría la tabla de verdad. Quitarle `DROP` a la cuenta de la aplicación en MySQL también le impide hacer `TRUNCATE`.

</details>

**Pregunta 71** · Básica · *Permisos sobre la auditoría*

¿Qué permiso corresponde a la cuenta de la aplicación sobre la tabla de auditoría?

- a) Solo `INSERT`: puede registrar eventos, pero no leerlos, modificarlos ni borrarlos.
- b) `SELECT`, `INSERT`, `UPDATE` y `DELETE`, para poder corregir registros con errores.
- c) Ninguno: la auditoría solo la escribe el DBA a mano.
- d) Solo `DELETE`, para depurar eventos antiguos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La auditoría debe estar protegida contra la alteración: si la aplicación pudiera borrarla, un atacante podría eliminar su propia huella. Leerla corresponde al rol auditor. Que la escriba solo el DBA a mano (c) no sirve para registrar lo que hace la aplicación.

</details>

**Pregunta 72** · Intermedia · *Tener backups no alcanza*

Un equipo afirma: "tenemos backups diarios, estamos cubiertos". ¿Qué objeción es la más pertinente?

- a) Los backups diarios son siempre insuficientes, en cualquier escenario.
- b) Tener copias no prueba que se pueda recuperar a tiempo y con los datos correctos: falta un restore probado, la cadena de logs que exige el RPO y el tiempo medido contra el RTO.
- c) Los backups solo son válidos si son físicos.
- d) Los backups dejan de ser necesarios si hay una réplica.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Backup no es recovery: un backup sin restore probado es una promesa no verificada. Para un RPO de 24 h, un backup diario puede alcanzar, así que a es un absoluto. La réplica no reemplaza al backup (d).

</details>

**Pregunta 73** · Básica · *Backup lógico consistente*

¿Para qué se usa la opción `--single-transaction` de `mysqldump`?

- a) Para que todo el volcado se escriba en una sola sentencia `INSERT`.
- b) Para bloquear todas las tablas durante la copia y garantizar la consistencia.
- c) Para incluir los usuarios y los roles en el volcado.
- d) Para obtener una copia consistente de las tablas InnoDB sin bloquearlas, usando un snapshot de `REPEATABLE READ`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Abre una transacción y aprovecha MVCC: la copia refleja un único instante y la operación normal sigue sin bloqueos. La opción b describe lo contrario (bloquear tablas). Los usuarios no se incluyen en el volcado de una base (c).

</details>

**Pregunta 74** · Básica · *Punto objetivo de recuperación*

Hay un backup a las 10:00, operaciones válidas hasta las 10:45, un `DELETE` erróneo a las 10:47 y la detección a las 11:00. ¿Qué recuperación cumple el objetivo?

- a) Restaurar el backup de las 10:00.
- b) Restaurar el backup y reaplicar todo el log hasta las 11:00.
- c) Restaurar el backup y reaplicar el log hasta inmediatamente antes de la transacción del `DELETE`.
- d) Promover la réplica de alta disponibilidad.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Restaurar solo el backup pierde las operaciones válidas (a). Reaplicar todo el log repite el `DELETE` (b). La réplica ya aplicó el borrado (d). El PITR combina el backup base con los logs hasta el punto elegido.

</details>

**Pregunta 75** · Desafío · *Corte por fecha en mysqlbinlog*

Para el PITR en MySQL se usa `mysqlbinlog --stop-datetime` con la fecha que figura en la columna `fecha` de los movimientos insertados. ¿Qué problema tiene?

- a) Ninguno: el binlog indexa los eventos según esa columna.
- b) El binlog registra la hora en que el servidor ejecutó cada evento, no los valores cargados en las filas; además, con varias transacciones en el mismo segundo el corte es impreciso. Es más seguro `--stop-position`.
- c) `--stop-datetime` solo funciona en PostgreSQL.
- d) `mysqlbinlog` no admite cortes por tiempo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Si un `INSERT` cargó `fecha = '10:05'` pero se ejecutó a las 15:30, el binlog lo registra a las 15:30. El método preciso es ubicar la posición del evento con `SHOW BINLOG EVENTS` o `mysqlbinlog`, y cortar con `--stop-position`. El corte por tiempo existe (d), pero usa la hora de ejecución.

</details>

**Pregunta 76** · Desafío · *pg_dump y PITR*

Un equipo con PostgreSQL solo tiene backups hechos con `pg_dump`. Tras un `DELETE` accidental, restauran la tabla desde el volcado y reinsertan a mano dos operaciones posteriores que conocían por la auditoría. ¿Qué evaluación es correcta?

- a) Es un PITR completo, equivalente al que se logra en MySQL con el binlog.
- b) Es incorrecto, porque `pg_restore` no puede restaurar una sola tabla.
- c) Es la única forma posible de recuperar datos en PostgreSQL.
- d) Funciona en el laboratorio, pero no es PITR: en producción no se conocen todas las operaciones posteriores; el PITR en PostgreSQL requiere un backup físico (`pg_basebackup`) y el WAL archivado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** `pg_dump` es una foto lógica de un instante. Para reconstruir hasta un punto exacto hace falta el historial de cambios, y en PostgreSQL ese historial (el WAL) es físico: se aplica sobre un backup físico. `pg_restore -t` sí restaura una tabla (b es falsa).

</details>

**Pregunta 77** · Intermedia · *La réplica copia el error*

Un sistema tiene replicación síncrona. Un operador ejecuta un `UPDATE` sin `WHERE` sobre todos los saldos. ¿Qué afirmación es correcta?

- a) La réplica aplica el mismo `UPDATE`: la recuperación requiere backup y logs (PITR), o una réplica con retardo si existe.
- b) La réplica conserva los saldos correctos, porque es síncrona.
- c) Alcanza con promover la réplica para volver al estado anterior.
- d) La replicación síncrona impide ejecutar un `UPDATE` sin `WHERE`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Que sea síncrona significa justamente que la réplica tiene el mismo cambio (b y c son falsas). La alta disponibilidad protege contra fallas físicas, no contra errores lógicos. Una réplica con retardo da una ventana para frenar el cambio antes de que se aplique.

</details>

**Pregunta 78** · Intermedia · *Síncrona frente a asíncrona*

¿Qué compromiso describe correctamente la replicación síncrona frente a la asíncrona?

- a) La síncrona tiene menor latencia de escritura, pero más riesgo de perder datos.
- b) Son equivalentes en pérdida potencial de datos; solo cambia el costo de licencias.
- c) La síncrona reduce la pérdida potencial ante la caída del primario, a cambio de más latencia y acoplamiento; la asíncrona impacta menos, pero puede perder lo que esté en el lag.
- d) La asíncrona garantiza un RPO igual a cero.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La síncrona espera la confirmación de la réplica en cada commit: menos pérdida, más latencia, y si la réplica cae el primario puede quedar bloqueado. La asíncrona confirma sin esperar. La opción a invierte el compromiso. La semisíncrona de MySQL queda en el medio y vuelve a asíncrona si la réplica no responde a tiempo.

</details>

**Pregunta 79** · Intermedia · *Arquitectura proporcional*

Un sistema interno de RR.HH. se usa en horario laboral, con RPO de 8 h, RTO de 12 h, presupuesto bajo y el pedido explícito de evitar la sobrearquitectura. ¿Qué propuesta es más coherente?

- a) Un clúster de tres nodos con replicación síncrona y failover automático.
- b) Backup completo diario fuera de horario más logs archivados, con restore probado periódicamente y sin réplica.
- c) Una réplica asíncrona, sin backups.
- d) Un backup semanal sin logs.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Cumple el RPO (los logs archivados lo bajan incluso a minutos) y el RTO (hay horas para restaurar en otro servidor), al menor costo. La opción a es sobrearquitectura. La c no protege contra errores humanos. La d tiene un RPO de hasta una semana.

</details>

**Pregunta 80** · Intermedia · *Dos nodos sin árbitro*

Una arquitectura de dos nodos con failover automático pierde el enlace entre ellos. ¿Qué riesgo aparece y cómo se mitiga?

- a) Aumenta el lag de replicación; se mitiga con más ancho de banda.
- b) Se produce un deadlock distribuido; se mitiga ordenando las transacciones.
- c) Se pierde el backup; se mitiga con la regla 3-2-1.
- d) *Split brain*: los dos nodos se promueven como primarios. Se mitiga con quórum o un testigo, aislando al nodo viejo (*fencing*) o con un failover asistido cuando la señal es ambigua.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Sin un tercer participante, cada nodo puede creer que el otro murió y aceptar escrituras propias, y los datos divergen. Las mitigaciones apuntan a que solo un nodo pueda ser primario. Las otras opciones mezclan conceptos de otras unidades.

</details>

---

## Clave de respuestas

| Unidad | Respuestas |
| :--- | :--- |
| U1 | 1 b · 2 c · 3 a · 4 d · 5 c · 6 a · 7 d · 8 b · 9 a · 10 d |
| U2 | 11 c · 12 a · 13 d · 14 b · 15 c · 16 d · 17 c · 18 a · 19 d · 20 b · 21 c · 22 a · 23 d · 24 c |
| U3 | 25 d · 26 b · 27 a · 28 c · 29 d · 30 a · 31 c · 32 b · 33 a · 34 c · 35 b · 36 d · 37 a |
| U4 | 38 c · 39 b · 40 d · 41 a · 42 b · 43 d · 44 a · 45 c · 46 b · 47 d · 48 a · 49 c · 50 d |
| U5 | 51 c · 52 d · 53 b · 54 c · 55 a · 56 d · 57 b · 58 c · 59 a · 60 d · 61 c · 62 a · 63 d · 64 b · 65 a |
| U6 | 66 c · 67 a · 68 d · 69 b · 70 c · 71 a · 72 b · 73 d · 74 c · 75 b · 76 d · 77 a · 78 c · 79 b · 80 d |
