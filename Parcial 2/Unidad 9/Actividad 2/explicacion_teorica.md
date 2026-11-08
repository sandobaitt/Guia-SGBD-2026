# Fundamentos Teóricos: U9 - Actividad 2 (Batalla de arquitecturas multimodelo)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)
**Tópicos:** persistencia políglota, análisis de requerimientos y patrones de acceso, dimensionamiento, propiedades ACID y BASE, CAP y PACELC, modelos de consistencia y aislamiento, los cinco modelos de datos (relacional, documental, clave-valor, columnas anchas y grafos), método de decisión multicriterio, costo de sumar motores, integración de datos (outbox, CDC, idempotencia), duplicación y concurrencia, protección de datos personales, disponibilidad y recuperación, y técnica de defensa y contraargumentación.

> Este documento explica **por qué** se tomó cada decisión de la actividad, no solo **qué** se decidió. Cada sección termina con la aplicación a OmniMarket. Al final hay preguntas de defensa con respuesta.

---

## 1. Persistencia políglota

### 1.1. Qué es
**Persistencia políglota** es usar **más de un motor de base de datos** en un mismo sistema, eligiendo para cada parte el modelo que mejor encaja con sus datos y su forma de acceso. Se opone a la idea de "una base de datos para todo".

### 1.2. Por qué existe
Ningún modelo es el mejor en todas las propiedades a la vez. Cada diseño **sacrifica algo para ganar otra cosa**:

| Si queremos… | Normalmente cedemos… |
| :--- | :--- |
| Integridad transaccional fuerte entre muchas tablas | Escala de escritura horizontal sencilla |
| Latencia de milisegundos por clave | Capacidad de consulta ad hoc y volumen más allá de la memoria |
| Escritura masiva distribuida | Transacciones y consultas arbitrarias |
| Recorrer relaciones con rapidez | Escala horizontal y agregaciones masivas |
| Esquema totalmente flexible | Garantías de forma y uniones |

La persistencia políglota aprovecha cada fortaleza donde importa, a cambio de **complejidad de integración**. Esa contrapartida es el centro de la actividad.

### 1.3. El error contrario: más motores no es mejor
Cada motor agregado trae costos que no se ven en la primera demostración (sección 7). La consigna lo dice expresamente: **"no gana quien usa más tecnologías"**. Por eso el criterio no es "¿qué motor sirve para esto?" sino **"¿el motor que ya tengo no alcanza para esto?"**.

### 1.4. Aplicación a OmniMarket
La plataforma tiene dominios con exigencias opuestas: **inventario y pagos** exigen consistencia estricta, **sesiones** exigen milisegundos y expiración, **navegación** exige escribir miles de eventos por segundo y **recomendaciones** exigen recorrer relaciones. Por eso la pregunta guía ("¿cómo justificar una arquitectura cuando las áreas exigen propiedades diferentes?") tiene sentido: no existe un motor que sea el mejor en todo.

---

## 2. Análisis de requerimientos

### 2.1. Requisitos funcionales y no funcionales
- **Funcionales:** qué datos hay y qué operaciones y consultas se hacen (alta de cliente, reservar stock, historial de un usuario).
- **No funcionales:** *cuánto*, *cuán rápido* y *con qué garantías*: volumen, frecuencia, crecimiento, integridad, latencia, disponibilidad, seguridad.

Los motores se diferencian casi siempre en los **no funcionales**. Dos dominios con las mismas operaciones pueden requerir motores distintos si su volumen o su tolerancia a fallas difieren.

### 2.2. Patrón de acceso: la pregunta que ordena todo
El **patrón de acceso** es la forma en que se leen y escriben los datos. Tres preguntas lo describen:
1. ¿Se accede **por clave** (un dato exacto), **por rango** (los últimos N de un usuario), **por filtro libre** o **recorriendo relaciones**?
2. ¿Predomina la **lectura** o la **escritura**? ¿Las escrituras modifican o solo agregan?
3. ¿Se necesita atomicidad **entre varios datos**?

| Patrón de acceso | Modelo que suele encajar |
| :--- | :--- |
| Clave exacta con latencia mínima y vencimiento | Clave-valor |
| Historial por usuario y fecha con escritura masiva | Columnas anchas |
| Filtros y uniones entre muchas entidades con integridad | Relacional |
| Documento completo de forma variable | Documental |
| Recorridos de 2 o más saltos | Grafos |

### 2.3. Obligatorio frente a preferencia
Separar lo que **no se puede incumplir** de lo que **conviene** evita decidir por gusto:
- **Obligatorio:** deriva del enunciado o de una norma (no vender más de lo disponible; proteger datos personales).
- **Preferencia:** mejora la solución pero es negociable (recomendaciones en minutos, pocos motores).

Una técnica conocida para ordenarlos es **MoSCoW** (*must, should, could, won't*). Las decisiones se justifican primero con los obligatorios; las preferencias desempatan.

### 2.4. Supuestos explícitos
Cuando el enunciado no da cifras, hay que **inventarlas de forma declarada**. Un supuesto bien escrito:
- tiene **valor y unidad** (30 M de eventos por día);
- indica de dónde sale o que es una estimación;
- permite saber **qué decisión cambiaría** si el valor cambia.

Si el grupo rival objeta una cifra, la respuesta correcta es: *"es un supuesto declarado; con la cifra que ustedes proponen, la regla de decisión da este otro resultado"*. Defender la decisión **condicionada a los supuestos** es más sólido que defender los números.

### 2.5. Dimensionamiento (cálculo de orden de magnitud)
Antes de elegir un motor hay que saber de qué tamaño es el problema. Se hace con cuentas simples:

| Cálculo | Resultado |
| :--- | :--- |
| Eventos por segundo promedio = 30.000.000 ÷ 86.400 | ≈ 347 por segundo |
| Pico (≈ 8 veces el promedio) | ≈ 2.800 por segundo |
| Eventos por año = 30 M × 365 | ≈ 10.950 M |
| Espacio por año (≈ 200 bytes por evento) | ≈ 2,2 TB sin replicar; ≈ 6,6 TB con tres copias |
| Pedidos por segundo = 100.000 ÷ 86.400 | ≈ 1,2 por segundo promedio |
| Memoria de sesiones y carritos = 400.000 × 2 × 1 KB | ≈ 800 MB |

Lectura de las cifras: **1,2 pedidos por segundo es una carga que un solo servidor relacional resuelve sin dificultad**, así que no hay razón técnica para sacar los pedidos de PostgreSQL. En cambio **2.800 eventos por segundo sostenidos y 11.000 millones por año** presionan a un único nodo en escritura y en espacio: ahí empieza a justificarse otro modelo. Y 800 MB de sesiones caben en memoria sin problema.

### 2.6. Cómo se validarían los supuestos
Un supuesto se convierte en dato con una medición. Herramientas oficiales de cada motor:

| Motor | Herramienta | Qué se mide |
| :--- | :--- | :--- |
| PostgreSQL | `pgbench` y `EXPLAIN (ANALYZE)` | Transacciones por segundo y plan de las consultas críticas |
| Redis | `redis-benchmark` | Operaciones por segundo y latencia por comando |
| Cassandra | `cassandra-stress` | Escritura y lectura sostenida por nodo |
| Neo4j | `PROFILE` en Cypher | Filas procesadas y accesos a la base por consulta |

En esta actividad no se hicieron pruebas de carga: **las decisiones se basan en los supuestos declarados y en la evidencia de funcionamiento**, no en benchmarks. Decirlo expresamente es parte de la honestidad técnica.

---

## 3. Propiedades que importan al elegir un motor

### 3.1. ACID
Propiedades de una **transacción**:

| Propiedad | Significado | Ejemplo en OmniMarket |
| :--- | :--- | :--- |
| **A**tomicidad | La transacción se aplica completa o no se aplica | Descontar stock, registrar el pago y acreditar puntos: todo o nada |
| **C**onsistencia | Lleva la base de un estado válido a otro válido, respetando restricciones | `CHECK (cantidad_reservada <= cantidad_fisica)` no se viola nunca |
| **A**islamiento | Las transacciones simultáneas no se interfieren | Dos clientes que compran lo último no se pisan |
| **D**urabilidad | Lo confirmado sobrevive a una caída | Un pedido pagado no se pierde si se reinicia el servidor |

**Atención:** la "C" de ACID (respetar reglas de integridad) **no es** la "C" de CAP (todas las lecturas ven lo último escrito). Confundirlas es un error muy frecuente.

### 3.2. NoSQL no significa "sin ACID"
Cada motor ofrece garantías distintas y de alcance distinto:

| Propiedad | Redis | Cassandra | Neo4j | PostgreSQL |
| :--- | :--- | :--- | :--- | :--- |
| Atomicidad | Cada comando es atómico; `MULTI`/`EXEC` ejecuta un bloque sin retroceso tradicional | Atómica **por partición**; transacciones ligeras con Paxos para casos puntuales | Transacciones completas | Transacciones completas |
| Consistencia | Depende de las reglas de la aplicación | Configurable entre réplicas | Mantiene las restricciones definidas | Restricciones declarativas |
| Aislamiento | Comandos en secuencia; sin aislamiento SQL | Sin aislamiento general entre particiones | Aislamiento transaccional con bloqueos | Varios niveles (ver 3.5) |
| Durabilidad | Según RDB o AOF | *Commit log* más SSTables | Registro de transacciones y recuperación | Registro de escritura previa (WAL) |

La conclusión que importa: **el alcance de la garantía cambia**. En Cassandra la atomicidad vale dentro de una partición; en PostgreSQL vale entre tablas. Por eso los dominios que necesitan atomicidad **entre varias entidades** (pedido, stock, pago) se ubican en el motor que la ofrece.

### 3.3. BASE
Alternativa de diseño frecuente en sistemas distribuidos: ***B**asically **A**vailable, **S**oft state, **E**ventual consistency*. Prioriza responder siempre, aceptando que las copias converjan con el tiempo. Es una **actitud de diseño**, no un producto.

### 3.4. CAP
El teorema CAP (Brewer; demostrado por Gilbert y Lynch) habla de un sistema distribuido que almacena datos:

| Letra | Significado exacto |
| :--- | :--- |
| **C** (consistencia) | Cada lectura ve la última escritura confirmada, o recibe un error |
| **A** (disponibilidad) | Cada solicitud a un nodo que no falló recibe una respuesta |
| **P** (tolerancia a particiones) | El sistema sigue funcionando aunque la red pierda mensajes entre nodos |

**Formulación correcta:** si la red se **particiona**, hay que elegir entre devolver **error** (consistencia) o devolver una respuesta que puede estar **desactualizada** (disponibilidad). La partición no es opcional en una red real, por lo que la elección ocurre **durante la falla**.

Lo que **no** significa (error común de las exposiciones):
- **No es un menú** de "dos de tres" a elegir una vez para siempre. Sin particiones se puede tener C y A a la vez.
- **No es una etiqueta fija por producto.** Un mismo motor cambia de comportamiento según su configuración (nivel de consistencia, réplicas, modo de despliegue).
- **No habla de latencia ni de ACID.**

### 3.5. PACELC
Completa a CAP: **si hay Partición (P)**, se elige entre Disponibilidad (A) y Consistencia (C); **si no (Else)**, se elige entre **Latencia (L)** y **Consistencia (C)**. Explica por qué incluso sin fallas un sistema replicado suele pagar latencia para ver datos más actualizados.

### 3.6. Modelos de consistencia
| Modelo | Qué garantiza | Ejemplo |
| :--- | :--- | :--- |
| **Fuerte** | Toda lectura ve la última escritura | Una reserva de stock en PostgreSQL |
| **Eventual** | Si no hay más escrituras, las copias convergen | Una recomendación en Neo4j respecto de una compra reciente |
| **Leer lo propio** | Quien escribe ve su escritura | El cliente ve su carrito recién modificado |
| **Monótona** | No se ve un dato más viejo después de uno más nuevo | Un precio que no "retrocede" |

### 3.7. Niveles de aislamiento en bases relacionales
| Fenómeno | Descripción |
| :--- | :--- |
| Lectura sucia | Leer datos de otra transacción no confirmada |
| Lectura no repetible | Releer una fila y encontrarla modificada |
| Fantasma | Repetir una consulta y que aparezcan filas nuevas |
| **Actualización perdida** | Dos transacciones leen el mismo valor y la segunda pisa a la primera |
| Sesgo de escritura | Dos transacciones leen datos solapados y escriben cosas que juntas rompen una regla |

PostgreSQL ofrece Read Committed (el predeterminado), Repeatable Read y Serializable, con **control de concurrencia multiversión (MVCC)**: los lectores no bloquean a los escritores. Para la reserva de stock no hace falta el nivel más alto: alcanza con una **sentencia atómica con condición** (sección 9.3).

### 3.8. Replicación y consistencia ajustable en Cassandra
- **RF (factor de replicación):** cuántas copias de cada partición se mantienen. Con RF = 3 hay tres copias.
- **CL (nivel de consistencia):** cuántas réplicas deben responder para dar por buena una lectura o escritura. **Es una decisión por operación**, distinta de RF.
- **QUORUM** = mayoría = ⌊RF ÷ 2⌋ + 1. Con RF = 3, son 2 réplicas.
- **Regla de consistencia fuerte:** si **R + W > RF** (réplicas leídas más réplicas escritas superan al factor de replicación), la lectura intersecta a la última escritura. Con RF = 3, escribir y leer en QUORUM (2 + 2 = 4 > 3) es fuertemente consistente.
- **CL = ONE:** basta una réplica; más rápido y disponible, pero puede devolver un valor viejo.
- **No hay nodo maestro:** el cliente envía la operación a cualquier nodo y ese nodo actúa como **coordinador** solo para esa operación.
- **Dónde vive un dato:** la **clave de partición** se transforma con una función hash en un **token** que determina qué nodos son dueños del dato.

> **Advertencia de laboratorio:** con **un solo nodo y RF = 1** no se puede observar tolerancia a fallas ni diferencias entre niveles de consistencia. **No se debe afirmar tolerancia a fallas sin ensayar un clúster real** (mínimo tres nodos). Es la razón por la que en esta actividad Cassandra se diseñó pero no se implementó.

---

## 4. Los cinco modelos en detalle

Para cada modelo: cómo guarda los datos, fortalezas, límites y cuándo **no** usarlo.

### 4.1. Relacional (PostgreSQL)
- **Cómo guarda:** tablas con filas y columnas tipadas; relaciones con claves foráneas; consultas con SQL.
- **Fortalezas:** integridad declarativa (`PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY`, `CHECK`), transacciones ACID entre varias tablas, consultas con uniones y agregaciones, índices variados, madurez y herramientas.
- **Normalización:** descomponer los datos para que cada hecho viva en un solo lugar y evitar anomalías de actualización. Reduce duplicación a cambio de uniones al leer.
- **`JSONB`:** tipo de PostgreSQL para guardar documentos JSON en forma binaria, con operadores de contención (`@>`) y un **índice `GIN`** que acelera filtros sobre claves y valores. Permite una columna de **atributos que varían por fila** dentro de un modelo relacional.
- **Límites:** un único primario de escritura; escalar la escritura horizontalmente exige particionar (por rango, hash o fecha) o fragmentar; las uniones sobre recorridos profundos se encarecen.
- **Cuándo no:** expiración nativa de datos con latencia de milisegundos, o escritura de miles de millones de eventos por año sin particionado cuidadoso.

### 4.2. Documental (MongoDB)
- **Cómo guarda:** documentos (JSON/BSON) en colecciones, anidados y de forma variable.
- **Fortalezas:** esquema flexible, un documento contiene datos que se leen juntos (menos uniones), índices compuestos, índices con vencimiento (TTL), colecciones de series temporales, fragmentación horizontal nativa.
- **Embeber o referenciar:** **embeber** lo que se lee junto y tiene tamaño acotado; **referenciar** lo que crece sin límite o se comparte.
- **Límites:** las uniones (`$lookup`) son menos expresivas que en SQL; las transacciones entre documentos existen pero son más costosas; la integridad referencial no es declarativa.
- **Cuándo no:** cuando los datos son muy relacionales y la integridad entre entidades es obligatoria.

### 4.3. Clave-valor (Redis)
- **Cómo guarda:** un espacio de claves en **memoria**; cada clave apunta a una estructura (`STRING`, `HASH`, `LIST`, `SET`, `SORTED SET`, entre otras).
- **Fortalezas:** latencia de microsegundos a milisegundos, comandos **atómicos**, **vencimiento por clave (TTL)**, estructuras listas para casos comunes (ranking, contadores, conjuntos).
- **Vencimiento:** `EXPIRE` o `SET ... EX`. Redis elimina una clave vencida al accederla y además con un proceso en segundo plano. `TTL` devuelve los segundos restantes; `-2` indica que la clave no existe y `-1` que existe sin vencimiento.
- **Persistencia:** **RDB** (fotografías periódicas, con posible pérdida de lo reciente) y **AOF** (registro de operaciones, mayor durabilidad según configuración).
- **Arquitecturas:** instancia única; **réplica** (copia habitualmente asíncrona); **Sentinel** (vigilancia y conmutación automática); **Cluster** (distribuye las claves en 16.384 *slots*, requiere configuración explícita).
- **Límites:** capacidad acotada por la memoria; sin consultas ad hoc ni uniones; la replicación asíncrona puede perder las últimas escrituras en una conmutación.
- **Política de expulsión:** al llenarse la memoria Redis puede expulsar claves (`allkeys-lru`, `volatile-ttl`, etc.) o rechazar escrituras (`noeviction`); debe elegirse a conciencia.
- **Cuándo no:** como **única** fuente de datos que no se pueden perder o reconstruir.

### 4.4. Columnas anchas (Cassandra)
- **Cómo guarda:** tablas cuyo **diseño parte de la consulta**. Cada tabla se organiza por una **clave de partición** (dónde vive el dato) y **columnas de clustering** (cómo se ordenan las filas dentro de la partición).
- **Camino de escritura:** el dato se anota en el *commit log* y en una estructura en memoria (*memtable*) y luego se vuelca a archivos inmutables (**SSTables**), que se combinan en segundo plano (*compaction*). Por eso la escritura es muy rápida y sostenida.
- **Fortalezas:** escritura masiva distribuida, escalado horizontal agregando nodos, sin nodo maestro, vencimiento por fila (`TTL`).
- **Reglas de consulta:** toda consulta eficiente indica la **clave de partición**; los rangos y `ORDER BY` solo valen sobre las **columnas de clustering**; filtrar por otra columna sin partición exige `ALLOW FILTERING` (recorre todo, no es solución).
- **Una tabla por consulta:** cuando se necesita otra forma de consulta, se crea **otra tabla** con los datos duplicados (desnormalización deliberada) y la aplicación escribe en ambas.
- **Particiones acotadas:** una partición que crece sin límite degrada el rendimiento. Se acota agregando un **cubo** a la clave de partición, por ejemplo `(usuario_id, dia)`.
- **Borrados:** un `DELETE` marca la fila con una lápida (*tombstone*) que se limpia más tarde; muchos borrados degradan las lecturas.
- **Escrituras condicionales:** las **transacciones ligeras** (`IF NOT EXISTS`, `IF` condición) usan el protocolo Paxos; son más lentas y se reservan para casos puntuales.
- **Límites:** sin uniones, sin transacciones entre particiones, consultas ad hoc limitadas.
- **Cuándo no:** cuando se necesita consistencia estricta entre varias entidades o consultas cambiantes.

### 4.5. Grafos (Neo4j)
- **Cómo guarda:** **grafo de propiedades**: nodos con etiquetas y propiedades, unidos por **relaciones con tipo y dirección**, que también pueden tener propiedades.
- **Cypher:** lenguaje declarativo por patrones: `(c:Cliente)-[:COMPRO]->(p:Producto)` se lee "un cliente que compró un producto".
- **Por qué recorre rápido:** las relaciones se almacenan junto a los nodos, de modo que **recorrerlas no requiere buscar por clave en otra estructura**. El costo de una consulta depende de **la parte del grafo que se explora**, no del tamaño total de los datos. En SQL equivale a uniones cuya dificultad crece con la profundidad.
- **Fortalezas:** recomendaciones, redes, detección de patrones, relaciones de longitud variable.
- **Restricciones:** unicidad de propiedades en nodos y en relaciones; transacciones ACID.
- **Límites:** los **nodos muy conectados** (*supernodos*, por ejemplo una categoría con millones de productos) encarecen los recorridos; las agregaciones masivas sobre todo el conjunto no son su punto fuerte; **la edición Community no incluye clúster, roles ni respaldo en caliente** (son de Enterprise).
- **Cuándo no:** cuando no se recorren relaciones o cuando la integridad tabular y las agregaciones son lo central.

### 4.6. Comparación sintética
| | Relacional | Documental | Clave-valor | Columnas anchas | Grafos |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Unidad de dato | Fila | Documento | Valor (estructura) | Fila en partición | Nodo y relación |
| Mejor patrón | Uniones e integridad | Agregado de forma variable | Clave directa con TTL | Escritura masiva por clave y rango | Recorridos |
| Transacciones | Entre tablas | Entre documentos (costosas) | Por comando o script | Por partición | Completas |
| Escala de escritura | Vertical; particionado | Horizontal (fragmentación) | Memoria; Cluster | **Horizontal nativa** | Limitada (Community: nodo único) |
| Punto débil | Escritura masiva horizontal | Integridad entre entidades | Capacidad y consultas | Consultas ad hoc y uniones | Agregaciones masivas |

---

## 5. Método de decisión multicriterio

### 5.1. Por qué un método
Elegir "porque es más rápido" o "porque lo usa todo el mundo" no resiste una contraargumentación. Un método tiene tres virtudes: es **explícito** (se puede discutir criterio por criterio), **repetible** (otro grupo llega al mismo resultado con los mismos datos) y **sensible** (se ve qué cambia si cambia un supuesto).

### 5.2. La matriz ponderada
1. Se definen **criterios** a partir de los requisitos: integridad (I), flexibilidad de esquema (F), latencia por clave (L), escala de escritura en disco (E), recorridos de relaciones (R), expiración nativa (T), consultas ad hoc y filtros (Q), lectura por rango ordenado (S).
2. Cada **modelo** recibe una **aptitud** de 0 a 3 en cada criterio.
3. Cada **dominio** recibe un **peso** de 0 a 3 en cada criterio.
4. **Puntaje** de un modelo en un dominio = Σ (peso × aptitud).

**Ejemplo calculado: Sesiones y carritos** (pesos I=1, F=1, L=3, E=2, R=0, T=3, Q=0, S=0)

| Modelo | Cuenta | Total |
| :--- | :--- | :-: |
| Clave-valor (aptitudes 1, 2, 3, 1, 0, 3, 0, 1) | 1×1 + 1×2 + 3×3 + 2×1 + 0 + 3×3 + 0 + 0 | **23** |
| Relacional (aptitudes 3, 2, 2, 1, 1, 0, 3, 2) | 1×3 + 1×2 + 3×2 + 2×1 + 0 + 3×0 + 0 + 0 | **13** |

La diferencia (10 puntos de 30 posibles) la producen sobre todo la **latencia** y la **expiración**: dos criterios de peso 3 donde el relacional tiene aptitud baja.

### 5.3. Limitación del puntaje: por eso hace falta una regla
Un puntaje solo puede inducir a error cuando los modelos quedan cerca. **Ejemplo: Catálogo** (pesos I=1, F=3, L=2, E=1, R=0, T=0, Q=3, S=0)

| Modelo | Total |
| :--- | :-: |
| Relacional con `JSONB` | 1×3 + 3×2 + 2×2 + 1×1 + 3×3 = **23** |
| Documental | 1×2 + 3×3 + 2×2 + 1×2 + 3×2 = **23** |

**Empate.** Con solo el puntaje no se puede decidir. Por eso se fija de antemano una **regla de adopción de un motor adicional**:

> Un motor NoSQL se suma a un dominio solo si **(a)** existe un criterio de peso 3 que el motor base (relacional) cubre con aptitud 1 o menos, **(b)** el candidato lo cubre con aptitud 3, y **(c)** su puntaje total supera al del relacional.

Aplicada al catálogo: el criterio de peso 3 es la flexibilidad (F), pero el relacional con `JSONB` tiene aptitud 2, es decir, **no es una carencia**. La regla da "queda en el relacional". Es el método que concreta el principio *"no gana quien usa más tecnologías"*.

### 5.4. Análisis de sensibilidad
Se pregunta qué pasaría si un peso cambiara. **Ejemplo:** si en el catálogo el peso de las consultas con filtros (Q) bajara de 3 a 1, el relacional sumaría 17 y el documental 19. El documental ganaría por 2 puntos, **pero la regla seguiría sin sumarlo**, porque la flexibilidad sigue cubierta por `JSONB`. Es una decisión **robusta** a ese cambio. En cambio, si los atributos fueran tan variables que el filtrado con `GIN` no alcanzara la latencia pedida, la aptitud de F del relacional bajaría a 1 y la regla sí habilitaría al documental: ese es el **criterio de revisión** escrito en el informe.

### 5.5. Honestidad sobre las aptitudes
Las aptitudes y los pesos son una **valoración cualitativa** basada en la documentación y el material de la materia, no una medición. Sirven para que la discusión sea sobre criterios concretos. Una pregunta válida del rival es *"¿por qué le pusieron 2 y no 3 a tal criterio?"*; la respuesta es el fundamento de cada aptitud (sección 4) y la sensibilidad del resultado.

### 5.6. Dónde se iteró (error real del proceso)
La primera versión tenía siete criterios y dejaba a Navegación **empatada entre documental, clave-valor y columnas anchas (17 puntos)**, lo que no refleja la necesidad de escritura masiva sobre disco. Se agregó el criterio **S** y se separó la escala de escritura **en disco** de la latencia (Redis escala en memoria). Lo importante: **la regla de adopción se fijó antes de mirar el resultado final**, para que el criterio no se ajustara a la conclusión deseada.

---

## 6. Resultado: asignación por dominio y por qué

| Dominio | Motor | Razón técnica principal | Qué descartamos |
| :--- | :--- | :--- | :--- |
| Clientes | PostgreSQL | Unicidad de identidad y relación con pedidos con integridad | Documental: duplicaría datos en los pedidos |
| Catálogo | PostgreSQL + `JSONB` | `JSONB` cubre la flexibilidad; se une con inventario y precios | MongoDB: empate; un quinto motor no se justifica |
| Inventario | PostgreSQL | No sobrevender exige atomicidad y restricciones | Redis y Cassandra: eventual o volátil |
| Ventas y pagos | PostgreSQL | Integridad y trazabilidad entre pedido, pago y comprobante | Documental y Cassandra: integridad entre entidades más débil |
| Sesiones y carritos | Redis | TTL nativo y latencia de milisegundos | Relacional: expiración manual y latencia mayor |
| Navegación | Cassandra | Escritura sostenida y consulta por usuario y rango | Relacional particionado y documental |
| Recomendaciones | Neo4j | Recorridos de 2 a 3 saltos sobre decenas de millones de relaciones | Relacional recursivo; Redis solo sirve resultados |
| Marketing | PostgreSQL | Datos estructurados con vigencia, combinados con clientes y categorías | Documental: +2 puntos sin cumplir la regla |
| Logística | PostgreSQL | ≈ 7 eventos por segundo no justifican otro motor | Cassandra |
| Fidelización | PostgreSQL | Libro mayor auditable con transacciones | Contadores de Redis o Cassandra |

**Idea de conjunto:** un **núcleo relacional** con los datos que requieren integridad entre sí, y **motores especializados** solo donde el relacional falla en un criterio crítico. Los motores especializados guardan datos **temporales o derivados**: si se pierden, se reconstruyen.

---

## 7. Costo de sumar motores

### 7.1. Dimensiones del costo
| Dimensión | Qué implica un motor más |
| :--- | :--- |
| **Operación** | Instalar, actualizar, parchear, dimensionar y vigilar un sistema más |
| **Disponibilidad** | Replicación y conmutación propias; un modo de falla nuevo |
| **Respaldo y recuperación** | Un procedimiento más, con su propio tiempo de restauración |
| **Seguridad** | Otro modelo de usuarios, permisos y cifrado (en Neo4j Community no hay roles; en Redis hay ACL; en Cassandra hay roles) |
| **Conocimiento** | El equipo debe dominar otro modelo y otro lenguaje de consulta |
| **Integración** | Un camino más de sincronización, con duplicados, orden y reintentos |
| **Consistencia** | Más lugares donde un dato puede estar desactualizado |

### 7.2. El costo de integración crece con la forma de la arquitectura
Con **n** motores:
- en **estrella** (un motor central que alimenta a los demás), los caminos de sincronización son **n − 1**;
- en **malla** (todos con todos), son **n × (n − 1) ÷ 2**.

Con cinco motores, una malla tendría **10** caminos; la estrella de OmniMarket con cuatro motores tiene **3**. Esa es la razón estructural para **centralizar la fuente de verdad en PostgreSQL** y proyectar desde ahí.

### 7.3. Criterio de baja
Cada motor debe poder **justificar su permanencia** y tener una condición explícita de salida (por ejemplo: "si los eventos bajan de 2 millones por día, Cassandra se reemplaza por una tabla particionada en PostgreSQL"). Una arquitectura sin criterio de baja acumula motores por inercia.

---

## 8. Integración de datos entre motores

### 8.1. El problema de la escritura doble
Escribir en PostgreSQL y luego en Neo4j desde la aplicación parece simple, pero **no es atómico**: si el proceso cae entre las dos escrituras, los motores quedan **inconsistentes** y nadie se entera. Una transacción distribuida entre motores (*two-phase commit*) no está disponible entre estos motores y, aunque lo estuviera, bloquea y reduce la disponibilidad.

### 8.2. Patrones de integración
| Patrón | Idea | Cuándo | Costo |
| :--- | :--- | :--- | :--- |
| **Outbox transaccional** | Se escribe el evento en una tabla del mismo motor, **en la misma transacción** del negocio; un proceso lo publica | Volumen moderado; control total | Un proceso relay y una tabla |
| **Captura de cambios (CDC)** | Se lee el registro de transacciones (WAL) del motor y se publica cada cambio | Volumen alto; no tocar el código | Un componente más (p. ej. Debezium) |
| **Carga por lote (ETL)** | Se extrae y carga periódicamente | La latencia no importa (horas) | Datos desactualizados entre cargas |
| **Eventos como fuente (*event sourcing*)** | El registro de eventos es el dato primario | Auditoría total | Complejidad de modelado y reproducción |
| **Saga** | Secuencia de transacciones locales con compensaciones | Procesos de negocio largos entre servicios | Lógica de compensación |

OmniMarket usa **outbox**, con **CDC como evolución** natural y **lote** para las vistas agregadas desde Cassandra.

### 8.3. Garantías de entrega e idempotencia
- **Como máximo una vez:** puede perder mensajes.
- **Al menos una vez:** no pierde, pero **puede duplicar**.
- **Exactamente una vez:** en la práctica se logra combinando **al menos una vez** con un **consumidor idempotente**.

Un consumidor es **idempotente** si aplicar el mismo mensaje varias veces deja el mismo resultado que aplicarlo una. En el laboratorio se logra con `MERGE` sobre una **clave única de la línea de compra** (`linea_id`) y una **restricción de unicidad** que impide duplicarla.

### 8.4. Orden y versión
No hace falta orden global; basta orden **por entidad**. Cada evento lleva una `version`; el consumidor solo aplica si es **mayor** que la ya aplicada. Así un evento atrasado no pisa a uno más nuevo.

### 8.5. Fallas, reintentos y reconstrucción
- **Reintentos con espera creciente**, y una cola de eventos fallidos para revisión humana tras varios intentos.
- **Reconciliación:** una tarea periódica compara conteos y sumas de control entre la fuente y las proyecciones, y repara.
- **Reconstrucción:** como Neo4j y Redis son derivados, se rehacen reaplicando el historial con cargas idempotentes.
- **Degradación elegante:** si un motor secundario cae, el sistema sigue vendiendo con una versión reducida (por ejemplo, mostrar los más vistos en lugar de recomendaciones personalizadas).

### 8.6. Aplicación a OmniMarket
Cada pedido confirmado inserta una fila en `outbox` dentro de la **misma transacción** que descuenta stock y registra el pago. El relay entrega `PEDIDO_CONFIRMADO` al consumidor de Neo4j, que aplica las líneas con `MERGE` sobre `linea_id`. Si el relay cae o el mensaje llega dos veces, **no se pierde ni se duplica ninguna compra**. Esto es exactamente lo que se demostró en los pasos 31 a 36 del laboratorio.

---

## 9. Duplicación y concurrencia

### 9.1. Duplicación de datos
- **Deliberada (desnormalización o proyección):** el nombre y el precio de un producto existen en PostgreSQL, en Neo4j y en una caché de Redis. Se acepta por rendimiento, pero exige **una fuente de verdad** y un mecanismo para propagar cambios.
- **Accidental:** el mismo evento procesado dos veces. Se evita con idempotencia.

Regla: **un dato tiene un único dueño**. Las demás copias son proyecciones que (a) se actualizan por eventos y (b) se pueden reconstruir.

### 9.2. Invalidación de caché
Las dos formas de mantener una caché razonablemente fresca son el **vencimiento** (TTL corto) y la **invalidación por evento** (`PRODUCTO_ACTUALIZADO` elimina la clave). Se usa ambas: el evento acelera la actualización y el TTL acota el daño si el evento se perdiera. En una caché **nunca** se guarda un dato que exija exactitud inmediata, como el **stock**.

### 9.3. Concurrencia: dos escrituras sobre el mismo dato
| Estrategia | Idea | Ejemplo |
| :--- | :--- | :--- |
| **Operación atómica del motor** | El motor ejecuta la modificación completa como una unidad | `HINCRBY` en Redis; `UPDATE ... SET x = x + n` en SQL |
| **Actualización condicional** | La modificación solo se aplica si la condición sigue siendo cierta | `UPDATE stock ... WHERE cantidad_fisica - cantidad_reservada >= n` |
| **Bloqueo optimista** | Se lee la `version`; se escribe solo si no cambió | `UPDATE pedido ... WHERE pedido_id = ? AND version = ?` |
| **Bloqueo pesimista** | Se bloquea la fila mientras se trabaja | `SELECT ... FOR UPDATE` |
| **Última escritura gana (LWW)** | Gana la escritura con mayor marca de tiempo | Cassandra por defecto; riesgoso si los relojes difieren |
| **Tipos convergentes (CRDT)** | Estructuras que se combinan sin conflicto | Contadores distribuidos |
| **Transacción con vigilancia** | El bloque falla si una clave cambió | `WATCH` y `MULTI`/`EXEC` en Redis; scripts Lua |

### 9.4. La actualización perdida, explicada con el experimento
Doscientos procesos suman 1 al mismo contador:
- **Con `HINCRBY`:** el motor hace la lectura y la escritura como **una sola operación indivisible**. Resultado: **200**.
- **Leyendo con `HGET` y escribiendo con `HSET`:** muchos procesos leen el **mismo valor**, le suman 1 y escriben el **mismo resultado**, pisándose. Resultado: **un valor muy inferior a 200**, distinto en cada corrida.

Es la **condición de carrera** de lectura-modificación-escritura. Aplicado al negocio: si la aplicación lee el stock disponible y luego escribe el nuevo valor, dos clientes pueden comprar la última unidad. Por eso **las operaciones críticas se delegan al motor** en una sola sentencia atómica con condición.

### 9.5. Eventos fuera de orden
Un evento de precio con `version 1` que llega **después** del de `version 2` no debe pisarlo. Se resuelve con la condición `WHERE p.version < <versión del evento>`. En el laboratorio el evento viejo afectó 0 filas.

---

## 10. Seguridad y protección de datos personales

### 10.1. Marco normativo
En Argentina, la **Ley 25.326 de Protección de los Datos Personales** establece principios como **finalidad**, **calidad del dato**, **consentimiento**, **seguridad** y los derechos de **acceso, rectificación y supresión**. Una arquitectura con varios motores multiplica los lugares donde pueden quedar datos personales.

### 10.2. Medidas de diseño
| Medida | Cómo se aplica en OmniMarket |
| :--- | :--- |
| **Minimización** | Los motores secundarios guardan solo identificadores (`U01`), nunca DNI, email ni dirección |
| **Fuente única de datos personales** | Solo PostgreSQL contiene datos personales: un único lugar para proteger, auditar y suprimir |
| **Derecho de supresión** | Baja lógica en PostgreSQL y evento `CLIENTE_ELIMINADO` que borra el identificador y sus relaciones en Neo4j y las claves en Redis |
| **Mínimo privilegio** | Un usuario por aplicación y por motor, con permisos limitados (ACL en Redis, roles en PostgreSQL y Cassandra) |
| **Auditoría** | Tablas de solo inserción para movimientos de puntos e historial de estados |
| **Credenciales** | Fuera de los scripts y de las capturas |
| **Cifrado** | En tránsito entre componentes y en reposo para los datos personales |

### 10.3. Seguridad según el motor
- **Redis:** ACL por usuario con patrones de claves y categorías de comandos; el usuario `default` debe protegerse.
- **Cassandra:** autenticación y autorización desactivadas por defecto; se habilitan en la configuración y se administran con roles.
- **Neo4j Community:** autenticación con usuario y contraseña, **sin roles ni privilegios** (son de Enterprise); la protección depende de la contraseña, del acceso por red y del sistema operativo.

---

## 11. Disponibilidad, respaldo y recuperación

### 11.1. Objetivos
- **Disponibilidad:** 99,9 % equivale a ≈ 8,8 horas de caída por año; 99,95 % a ≈ 4,4 horas.
- **RPO** (objetivo de punto de recuperación): cuántos datos se pueden perder.
- **RTO** (objetivo de tiempo de recuperación): cuánto se puede tardar en volver.

### 11.2. Qué es crítico y qué es reconstruible
| Componente | ¿Se puede perder? | Estrategia |
| :--- | :--- | :--- |
| PostgreSQL | **No** | Réplica con conmutación; respaldo con recuperación a un punto en el tiempo (WAL) |
| Cassandra | Parcialmente (navegación) | Replicación entre nodos y snapshots |
| Redis | Sí (temporal) | Persistencia y réplica para acortar la recuperación; las sesiones se rehacen |
| Neo4j | Sí (derivado) | Dump periódico y, sobre todo, **reconstrucción desde las fuentes** |

### 11.3. Respaldo en cada motor
- **PostgreSQL:** respaldo físico más archivo de WAL, que permite volver a un instante.
- **Redis:** RDB (fotografía) o AOF; se restaura levantando otra instancia con el archivo.
- **Cassandra:** *snapshots* (enlaces a las SSTables) y restauración copiándolas.
- **Neo4j Community:** *dump* **fuera de línea** con `neo4j-admin` (con el servicio detenido).

### 11.4. Degradación elegante
Un fallo de un componente secundario **no debe impedir vender**. Si cae Neo4j, la API muestra los productos más vistos desde Redis; si cae Cassandra, los eventos de navegación esperan en una cola local. Solo PostgreSQL es indispensable para confirmar un pedido.

---

## 12. Técnica de defensa y contraargumentación

### 12.1. Estructura de una respuesta sólida
**Afirmación → evidencia → razonamiento → límite.**
1. *Qué decidimos.* ("El catálogo queda en PostgreSQL con JSONB.")
2. *Con qué evidencia.* ("En la matriz empata con el documental, 23 a 23, y la regla no habilita sumar un motor.")
3. *Por qué.* ("JSONB con índice GIN cubre atributos variables; el catálogo se une con inventario y precios.")
4. *Hasta dónde vale.* ("Si el filtrado no alcanzara la latencia pedida, lo revisaríamos.")

Reconocer el **límite** de la decisión **fortalece** la posición.

### 12.2. Falacias frecuentes (para no cometerlas y para detectarlas)
| Falacia | Por qué falla |
| :--- | :--- |
| "NoSQL es más rápido" | Depende del patrón de acceso; para uniones e integridad el relacional es más adecuado |
| "Es el más usado" | La popularidad no es un requisito del negocio |
| "Más motores, más preparada la arquitectura" | Cada motor suma costo e integración; la consigna lo penaliza |
| "Cassandra no tiene consistencia" | Tiene consistencia ajustable por operación |
| "Redis pierde datos" | Depende de RDB, AOF y réplica; y no debe ser fuente única de lo crítico |
| "CAP: eligen dos de tres" | Es un compromiso **ante una partición**, no un menú permanente |
| "Neo4j reemplaza a SQL" | Es mejor para recorridos; no para todo lo tabular |

### 12.3. Cómo cuestionar a la propuesta rival
Buscar los **puntos donde falta evidencia o alternativa descartada**:
1. ¿Hay una **fuente de verdad** por dato compartido y una estrategia de sincronización?
2. ¿Qué pasa si falla la segunda de dos escrituras a motores distintos?
3. ¿Dónde está el **stock** y cómo evitan vender por encima del disponible?
4. ¿Usan un motor por moda? ¿Qué dejarían de poder hacer sin él?
5. ¿Qué cifras de volumen supusieron y cambiaría su decisión si fueran menores?
6. ¿Dónde están los **datos personales** y cómo se suprimen?
7. ¿Qué evidencia ejecutada respalda cada decisión?

Una buena pregunta es **concreta, verificable y no se responde con una opinión**.

### 12.4. Cómo responder objeciones
- No improvisar: **tener preparadas** las objeciones previsibles (están en el informe).
- Si la objeción es válida, **reconocerla** y decir qué se haría.
- Si falta un dato, decir **qué dato falta y cómo se mediría**.
- No cambiar de tema: responder primero a lo preguntado.

---

## 13. Preguntas de defensa (respuestas breves)

### Diagnóstico y decisión
1. **¿Por qué no usar una sola base relacional para todo?** Sería lo más simple y es la opción por defecto. Con los volúmenes supuestos falla en la expiración de sesiones con latencia de milisegundos, en la escritura de 11.000 M de eventos por año y en recorridos sobre decenas de millones de relaciones. Y dejamos escrito el umbral en que volveríamos a ella.
2. **¿Cómo eligieron los motores?** Con una matriz de ocho criterios ponderados por dominio y una regla de adopción: un motor NoSQL se suma solo si el relacional falla en un criterio crítico y el candidato lo cubre del todo.
3. **¿Por qué el catálogo no va en MongoDB?** Empata con el relacional (23 a 23). `JSONB` con índice `GIN` cubre los atributos variables y el catálogo se une con inventario y precios. La regla no justifica un motor más.
4. **¿Por qué Marketing no va en el documental si saca más puntos?** Gana por 2 puntos, pero la necesidad crítica (consultas con filtros) ya la cubre el relacional. La regla evita sumar un motor por una ventaja marginal.
5. **¿Qué pasa si cambian los supuestos de volumen?** Cambia el puntaje; la regla indica qué dominio cambiaría de motor. Por ejemplo, con menos de 2 M de eventos por día, Cassandra se reemplaza por una tabla particionada de PostgreSQL.
6. **¿Qué diferencia hay entre aptitud y peso?** La aptitud es qué tan bien cubre un modelo un criterio; el peso es cuánto importa ese criterio en un dominio. El puntaje combina ambos.

### Arquitectura e integración
7. **¿Cuál es la fuente de verdad de cada dato?** PostgreSQL para clientes, productos, pedidos, stock y puntos; Cassandra para la navegación; Redis para sesiones y carritos temporales; Neo4j es un derivado reconstruible.
8. **¿Qué es el patrón outbox y por qué lo usan?** Se guarda el evento en una tabla del mismo motor dentro de la misma transacción del negocio, y un proceso lo publica. Evita la escritura doble, que deja datos inconsistentes si falla la segunda.
9. **¿Por qué no escribir directo en Neo4j desde la aplicación?** Porque dos escrituras a motores distintos no son atómicas: si falla la segunda, los datos divergen sin aviso.
10. **¿Qué garantiza la entrega "al menos una vez"?** Que no se pierde ningún evento, pero puede duplicarse. Se compensa con un consumidor idempotente.
11. **¿Cómo se logra la idempotencia en Neo4j?** `MERGE` sobre una clave única de la línea (`linea_id`) y una restricción de unicidad que rechaza duplicados.
12. **¿Y si los eventos llegan desordenados?** Cada evento lleva `version`; el consumidor solo aplica si es mayor que la almacenada.
13. **¿Qué pasa si cae Neo4j?** Se muestran los más vistos desde Redis; los eventos esperan en el outbox y se aplican al volver.
14. **¿Cómo se reconstruye Neo4j?** Reaplicando compras y vistas desde las fuentes con cargas idempotentes.
15. **¿Cuántos caminos de sincronización hay y por qué importa?** Tres, porque es una estrella centrada en PostgreSQL. Una malla de cinco motores tendría diez.

### Propiedades y consistencia
16. **¿La "C" de CAP es la misma que la de ACID?** No. La de ACID es respetar las reglas de integridad; la de CAP es que cada lectura vea la última escritura.
17. **¿Qué significa CAP en una frase correcta?** Ante una partición de red hay que elegir entre responder con datos posiblemente desactualizados o devolver error.
18. **¿Dónde ubican cada motor en CAP?** No hay etiqueta fija: depende de la configuración (réplicas, nivel de consistencia, instancia única o clúster).
19. **¿Qué es QUORUM y cuándo da consistencia fuerte?** Mayoría de réplicas (con RF = 3, dos). Si lecturas y escrituras en QUORUM suman más que RF (2 + 2 > 3), la lectura ve la última escritura.
20. **¿Por qué no implementaron Cassandra?** Con un nodo y RF = 1 no se observa lo que la justifica (distribución y tolerancia a fallas) y no se debe afirmar sin un clúster real. El diseño está completo.
21. **¿NoSQL significa sin ACID?** No. Cada motor ofrece garantías distintas y de alcance distinto: por comando en Redis, por partición en Cassandra, completas en Neo4j.

### Concurrencia e integridad
22. **¿Cómo evitan la sobreventa?** Reserva con una sentencia atómica condicionada al disponible, más un `CHECK` que impide reservar más que el stock físico.
23. **¿Qué es una actualización perdida?** Dos procesos leen el mismo valor y el segundo pisa al primero. En el experimento, 200 procesos con `HGET` más `HSET` dieron un valor muy inferior a 200; con `HINCRBY`, exactamente 200.
24. **¿Optimista o pesimista?** El optimista (columna `version`) conviene cuando los conflictos son poco frecuentes: no bloquea y detecta el choque al escribir. El pesimista (`FOR UPDATE`) conviene cuando el conflicto es frecuente y costoso.
25. **¿Por qué el stock no va en una caché?** Porque exige exactitud inmediata; una caché puede estar desactualizada y permitir vender de más.

### Datos personales y operación
26. **¿Dónde están los datos personales?** Solo en PostgreSQL. Los demás motores guardan identificadores.
27. **¿Cómo cumplen una solicitud de baja?** Baja lógica en PostgreSQL y evento `CLIENTE_ELIMINADO` que elimina el identificador y las relaciones en Neo4j y las claves en Redis.
28. **¿Qué es crítico perder y qué no?** Pedidos y pagos no se pueden perder (PostgreSQL con réplica y WAL). Sesiones, recomendaciones y caché son reconstruibles.
29. **¿Cuándo daría de baja un motor?** Cuando deja de cumplir su condición: Redis si las sesiones concurrentes bajan de ≈ 5.000, Cassandra si los eventos bajan de ≈ 2 M por día, Neo4j si alcanza con una tabla de co-ocurrencias por lote.
30. **¿Qué evidencia ejecutada respaldan?** El flujo carrito → evento → Neo4j → recomendación en Redis, la reentrega sin duplicados, el evento viejo descartado, la restricción que rechaza duplicados y el experimento de concurrencia.

---

## 14. Glosario

| Término | Definición breve |
| :--- | :--- |
| **Persistencia políglota** | Usar varios motores, cada uno donde mejor encaja |
| **Fuente de verdad** | El motor dueño de un dato; las demás copias derivan de él |
| **Proyección** | Copia derivada de la fuente de verdad, reconstruible |
| **Outbox** | Tabla de eventos escrita en la misma transacción del negocio |
| **CDC** | Captura de cambios leyendo el registro de transacciones |
| **Idempotencia** | Aplicar una operación varias veces equivale a aplicarla una vez |
| **Al menos una vez** | Garantía de entrega sin pérdida, pero con posibles duplicados |
| **Bloqueo optimista** | Detectar el choque al escribir mediante una versión |
| **Condición de carrera** | Resultado que depende del orden en que se ejecutan procesos simultáneos |
| **TTL** | Tiempo de vida; vencimiento automático de un dato |
| **Partición (datos)** | Subconjunto de datos que vive junto en un nodo |
| **Partición (red)** | Pérdida de comunicación entre nodos de un sistema distribuido |
| **RF / CL** | Cantidad de copias / cantidad de réplicas que deben responder |
| **Supernodo** | Nodo de un grafo con una cantidad enorme de relaciones |
| **Degradación elegante** | Seguir funcionando con menos prestaciones cuando algo falla |
