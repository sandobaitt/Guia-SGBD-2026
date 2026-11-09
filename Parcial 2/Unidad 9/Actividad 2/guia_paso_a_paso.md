# Guía Paso a Paso: U9 - Actividad 2 (Batalla de arquitecturas multimodelo)
**Grupo:** G11 (Escenario: OmniMarket)
**Motores implementados:** Redis (`redis-cli`) y Neo4j Community (`cypher-shell`) · **Diseñados:** MySQL (relacional) y Cassandra
**Archivos:** `bitacora_resuelta.md` (informe) · `redis-omnimarket.txt` y `neo4j-omnimarket.cypher` (scripts de los modelos NoSQL) · `evidencias_terminal_act2.sh` (sesión guiada para las capturas) · `diagrama_arquitectura.png/.svg` y `diagrama_relacional.png/.svg` (diagramas)

> Esta guía sirve para tres cosas: **reproducir** la parte NoSQL y sacar las capturas, **armar el informe** con todos los entregables de la consigna y **preparar la defensa** (batalla entre grupos).

---

## 0. Qué pide la consigna, en palabras simples

| Fase | Qué hay que hacer | Dónde está resuelto |
| :--- | :--- | :--- |
| **1. Diagnóstico** | Listar qué datos y operaciones tiene cada área del negocio, y **explicar los supuestos** de volumen. Separar lo obligatorio de lo que es solo preferencia | Informe, sección 1 |
| **2. Selección y arquitectura** | Elegir un motor por área, **justificar la elegida y al menos una descartada**, dibujar la arquitectura, decir cuál es la fuente de verdad y justificar el **costo de sumar motores** | Informe, sección 2 y diagrama |
| **3. Modelado e implementación** | Modelar. Implementar **al menos dos** motores NoSQL distintos con datos de prueba: altas, modificaciones, bajas, lecturas y **dos consultas de negocio** cada uno. Mostrar un **intercambio de datos** entre componentes y explicar qué se hace ante duplicación y concurrencia | Informe, sección 3 y 4; scripts y sesión guiada |
| **4. Batalla** | Presentar (8 min), cuestionar al rival (5 min), responder objeciones (4 min) | Informe, sección 5; esta guía, sección 6 |

La idea central de la actividad: **no gana quien usa más tecnologías**, sino quien justifica mejor con evidencia. Por eso la decisión se tomó con un método (criterios con peso y una regla para sumar motores) y no por gusto.

---

## 1. Preparación

### 1.1. Qué tiene que estar instalado
```bash
redis-server --version      # Redis (cualquier versión reciente)
neo4j --version             # Neo4j Community
cypher-shell --version
```
No hace falta que los servicios de la Actividad 1 estén detenidos ni activos: la sesión de esta actividad levanta **instancias aparte**, con otros puertos y otras carpetas, y no los toca.

| Instancia | Puerto | Carpeta |
| :--- | :---: | :--- |
| Redis de la Actividad 2 | 6381 | `~/u9_act2/redis` |
| Neo4j de la Actividad 2 (Bolt / HTTP) | 7690 / 7477 | `~/u9_act2/neo4j` |

### 1.2. Recursos y terminal
- Libres unos 1,5 GB de memoria (Neo4j usa hasta 512 MB de heap; Redis casi nada).
- Terminal ancha (140 columnas o más) para que las tablas no se corten. Si algo no entra, achicá la letra con `Ctrl` + `-`.
- **No hace falta `sudo`.** Solo se pide una contraseña: la de Neo4j (la elegís vos, mínimo 8 caracteres, con entrada oculta). **Anotala.**

---

## 2. Ejecutar la sesión guiada

```bash
cd "Parcial 2/Unidad 9/Actividad 2"
./evidencias_terminal_act2.sh
```

En cada paso se muestra el comando, se ejecuta y se detiene con `[Enter] para continuar`: **ahí sacás la captura**. Los comandos de Redis y de Neo4j que ves son **exactamente los de `redis-omnimarket.txt` y `neo4j-omnimarket.cypher`**, así que esos archivos son tu script entregable y la sesión es su demostración.

| Opción | Para qué |
| :--- | :--- |
| `PASO_DESDE=12 ./evidencias_terminal_act2.sh` | Retomar desde un paso. **Solo sirve si las instancias siguen activas** (respondiste `n` al final): si se detuvieron, Redis arranca vacío y el script te avisa. Te pide la clave de Neo4j |
| `REINICIAR=1 ./evidencias_terminal_act2.sh` | Borrar el laboratorio y empezar de cero (para que las capturas queden con los mismos números que el informe) |
| `SIN_PAUSA=1 ./evidencias_terminal_act2.sh` | Correr todo sin pausas, solo para verificar que funciona |

> **Para sacar las capturas definitivas conviene `REINICIAR=1`.** Si repetís la sesión sin reiniciar, Neo4j conserva los datos de la corrida anterior (el pedido `PED-0002` ya existe) y los conteos de la integración no coincidirán con los del informe.

### 2.1. Tabla de pasos

El número de **captura** del informe es el número del paso. Obligatorio = lo pide la consigna; recomendado = respalda una explicación del informe.

| Paso | Qué muestra | Qué escribís | Obligatorio |
| :---: | :--- | :--- | :---: |
| 1 | Se crean Redis y Neo4j aislados; versiones y puertos | **La clave de Neo4j** (oculta) y Enter | Sí |
| 2 | Redis responde (`PING`) | Solo Enter | Opcional |
| 3 a 5 | Carga del modelo: sesiones, carritos, ranking y promociones | Solo Enter | Opcional |
| 6 | Tipo de cada estructura (`TYPE`) y total de claves | Solo Enter | **Sí** |
| 7 | Redis · **Altas** | Solo Enter | **Sí** |
| 8 | Redis · **Lecturas** | Solo Enter | **Sí** |
| 9 | Redis · **Modificaciones** | Solo Enter | **Sí** |
| 10 | Redis · **Bajas** | Solo Enter | **Sí** |
| 11 | Expiración: la sesión inactiva desaparece sola (espera 4 s) | Solo Enter | Recomendado |
| 12 | Consulta de negocio 1: top 3 de productos más vistos | Solo Enter | **Sí** |
| 13 | Consulta de negocio 2: unidades en el carrito (script Lua) | Solo Enter | **Sí** |
| 14 y 15 | Consultas 3 y 4: sesión vigente y promociones activas | Solo Enter | Opcional |
| 16 | Neo4j: versión y edición `community` | Solo Enter | Recomendado |
| 17 | Restricciones de unicidad (incluye la de la relación `COMPRO`) | Solo Enter | Recomendado |
| 18 y 19 | Carga de clientes, catálogo, compras, seguimientos y vistas | Solo Enter | Opcional |
| 20 | Conteos: 16 nodos y 34 relaciones | Solo Enter | **Sí** |
| 21 | Neo4j · **Alta** | Solo Enter | **Sí** |
| 22 | Neo4j · **Lectura** | Solo Enter | **Sí** |
| 23 | Neo4j · **Modificación** | Solo Enter | **Sí** |
| 24 | Neo4j · **Baja** (relación y nodo) | Solo Enter | **Sí** |
| 25 | Consulta de negocio 1: recomendaciones para U01 | Solo Enter | **Sí** |
| 26 | Consulta de negocio 2: productos que se compran juntos | Solo Enter | **Sí** |
| 27 | Consulta de negocio 3: segmento de remarketing | Solo Enter | Recomendado |
| 28 | Versión: el evento viejo se descarta | Solo Enter | Recomendado |
| 29 | Idempotencia: aplicar dos veces el mismo pedido (4 y 4) | Solo Enter | Recomendado |
| 30 | La restricción rechaza una línea duplicada | Solo Enter | Recomendado |
| 31 | Integración 1: carrito de U01 en Redis | Solo Enter | **Sí** |
| 32 | Integración 2: el evento (mensaje del outbox) | Solo Enter | **Sí** |
| 33 | Integración 3: el consumidor lo aplica en Neo4j (2 → 4 compras) | Solo Enter | **Sí** |
| 34 | Integración 4: reentrega del mismo evento (siguen 4) | Solo Enter | **Sí** |
| 35 | Integración 5: Neo4j calcula y Redis sirve las recomendaciones (TTL 3600) | Solo Enter | **Sí** |
| 36 | Integración 6: se vacía el carrito | Solo Enter | Recomendado |
| 37 y 38 | Concurrencia: 200 con la operación atómica y un valor muy inferior sin ella | Solo Enter | Recomendado |

Al final te pregunta si querés detener las instancias: respondé `S` (o Enter) para liberar memoria, o `n` si querés seguir probando a mano (sección 3).

> **Los pasos 37 y 38 dan un número distinto en cada corrida** (el segundo, muy por debajo de 200). Ese valor es el que va en el informe (sección 3.6, tabla del experimento): reemplazá el texto `[completar: valor muy inferior a 200]` por lo que viste.

---

## 3. Si querés probar a mano

Al terminar la sesión, respondé `n` a "¿Detenerlas ahora?". Las instancias quedan activas:
```bash
redis-cli -p 6381                                   # consola de Redis (salir: exit)
cypher-shell -a bolt://localhost:7690 -u neo4j      # pide la clave; cada sentencia termina en ";" (salir: :exit)
```
Cuando termines:
```bash
redis-cli -p 6381 shutdown nosave
NEO4J_CONF=$HOME/u9_act2/neo4j/conf neo4j stop
```
Para ejecutar un script completo sin la sesión guiada (con las instancias activas):
```bash
export NEO4J_PASSWORD='<tu clave>'
cypher-shell -a bolt://localhost:7690 -u neo4j -p "$NEO4J_PASSWORD" -f neo4j-omnimarket.cypher
grep -v '^#' redis-omnimarket.txt | grep -v '^$' | redis-cli -p 6381    # sin las esperas ni los pasos
```

---

## 4. Armar el informe PDF

La bitácora (`bitacora_resuelta.md`) ya está escrita con el formato del informe. Para entregarla:

1. **Completar los datos:** integrantes del grupo, y el valor del experimento de concurrencia (sección 3.6).
2. **Pegar cada captura** en su marcador `*[INSERTAR CAPTURA N: ...]*` (el número es el del paso de la tabla 2.1). Si descartás una captura opcional, borrá su marcador.
3. **Insertar los dos diagramas** (`diagrama_arquitectura.png` en la sección 2.5 y `diagrama_relacional.png` en la 3.1).
4. **Revisar que ninguna captura muestre la clave de Neo4j.** La sesión la pide con entrada oculta y los comandos no la contienen.
5. **Decidir con el grupo los supuestos de volumen** (sección 1.1): son números nuestros. Si los cambian, cambia la matriz; la regla de la sección 2.1 indica qué decisión se modifica.
6. **Completar el registro de objeciones** (sección 5.4) durante o después de la batalla.

**Cómo pasarla a PDF.** La bitácora es Markdown. Lo más simple es abrirla en VS Code con la vista previa de Markdown, copiar el contenido a Google Docs o Word (las tablas se conservan), insertar ahí las capturas y los dos diagramas y exportar a PDF. Revisá que las tablas anchas (la matriz de decisión y la de requisitos) no se corten en la página; si pasa, pasá esa página a horizontal.

### 4.1. Entregables de la consigna y dónde están

| Entregable | Archivo o sección |
| :--- | :--- |
| Informe PDF: matriz de requisitos, matriz de decisión de los cinco modelos, alternativas descartadas | Secciones 1 y 2 de la bitácora |
| Diagrama de arquitectura | `diagrama_arquitectura.png` (editable: `.svg`) |
| Modelos NoSQL: diseños, scripts, capturas y resultados | Sección 3.2 a 3.5; `redis-omnimarket.txt` y `neo4j-omnimarket.cypher` |
| Diseño relacional (sin implementación) | Sección 3.1, `diagrama_relacional.png` y Anexo A |
| Presentación para defensa y objeciones | Guion y objeciones en la sección 5 de la bitácora; diapositivas armadas según la sección 6.1 de esta guía (ver la nota al final de esa sección: hay que completar dos datos) |
| Estrategia de integración | Sección 4 de la bitácora |

### 4.2. Los diagramas
- Los `.png` se insertan directamente en el PDF.
- Los `.svg` son editables con draw.io, Inkscape o PowerPoint si el grupo quiere cambiar colores, textos o agregar un componente.

---

## 5. Cómo leer la decisión (para poder defenderla)

Antes de la batalla, cada integrante tiene que poder explicar **sin mirar** estas seis cosas:

1. **Por qué hay un núcleo relacional:** siete de diez dominios necesitan integridad entre sí (un pedido descuenta stock, registra el pago y acredita puntos en una sola transacción).
2. **Por qué MySQL:** es el motor de todas las unidades anteriores y la consigna lo admite. Su costo concreto: no tiene un índice general sobre JSON (como el `GIN` de PostgreSQL), así que cada atributo filtrado necesita su índice. Se verificó que alcanza.
3. **Cuándo se suma un motor NoSQL:** solo si hay un criterio de peso 3 que el relacional no cubre bien. Eso pasa en tres dominios: sesiones (expiración), navegación (escritura masiva) y recomendaciones (recorridos).
4. **Por qué no MongoDB:** en el catálogo empata con el relacional (23 a 23) y una columna `JSON` con índices cubre la flexibilidad (sección 7 de esta guía lo comprueba con 150.000 productos). Sumarlo no se justifica.
5. **Qué es la fuente de verdad y el outbox:** cada dato tiene un dueño; los demás motores reciben copias por eventos que se guardan en la misma transacción del pedido y se reintentan hasta aplicarse.
6. **Qué demuestran los experimentos:** reentregar un evento no duplica (idempotencia), un evento viejo no pisa uno nuevo (versión), y la operación atómica no pierde actualizaciones (200 contra un valor muy inferior).

La teoría detallada de cada punto está en `explicacion_teorica.md`.

---

## 6. Preparar la defensa

### 6.1. Presentación de 8 minutos: diapositivas sugeridas

| N.º | Diapositiva | Contenido | Tiempo |
| :---: | :--- | :--- | :---: |
| 1 | Título y pregunta guía | OmniMarket; "¿existe una única arquitectura correcta?" | 0:30 |
| 2 | Diagnóstico | Los 10 dominios; obligatorios frente a preferencias | 1:00 |
| 3 | Supuestos de volumen | 4 cifras clave: 30 M de eventos por día, 400.000 sesiones, 100.000 pedidos por día, 50 M de relaciones | 0:30 |
| 4 | Método de decisión | 8 criterios con peso y la regla para sumar un motor | 1:00 |
| 5 | Resultado | Matriz de los cinco modelos; resaltar Catálogo (empate) y Marketing | 1:00 |
| 6 | Arquitectura | Diagrama; núcleo MySQL y tres motores especializados | 1:00 |
| 7 | Fuente de verdad e integración | Outbox, evento, consumidor idempotente | 0:45 |
| 8 | Evidencia | Carrito → evento → Neo4j → recomendación en Redis (capturas 31 a 35) | 1:00 |
| 9 | Duplicación y concurrencia | Idempotencia, versión y el experimento 200 contra N | 0:45 |
| 10 | Costo y cierre | Costo por motor y cuándo se daría de baja; mensaje final | 0:30 |

Mensaje final sugerido: *"No elegimos la arquitectura con más tecnologías, sino la que menos motores necesita para cumplir cada requisito, y dejamos escrito cuándo cambiaríamos de opinión."*

**Las diapositivas ya están armadas** (11 para presentar y 3 de respaldo, con notas del orador y los tiempos de la tabla): <https://claude.ai/artifact/Cu7akuapHDaToqdq1tmDTL>. El contenido sale de la bitácora; la tabla anterior las numera 1 a 10 y el mensaje final tiene su propia diapositiva (la 11). Antes de presentar hay que completar **dos datos**:

| Dónde | Qué completar |
| :--- | :--- |
| Diapositiva 1 (portada) | `[Integrantes del grupo]` |
| Diapositiva 9 (concurrencia) | `[N]`: el valor del paso 38, el mismo que va en la bitácora (sección 3.6) |

Las tres diapositivas finales son de **respaldo** (núcleo relacional, catálogo en MySQL medido y las seis objeciones más probables): no se presentan, se muestran solo si el rival pregunta por ese tema. Si se cambian los supuestos de volumen o la matriz, hay que actualizar también las diapositivas 3, 5 y 10.

### 6.2. Cuestionar a la propuesta rival (5 minutos)

1. Mientras presentan, anotá **qué motor eligieron para cada dominio** y buscá los dominios donde hay más de un motor posible.
2. Preparate 3 preguntas, elegidas entre las de la sección 5.3 de la bitácora. Las más fuertes suelen ser:
   - "¿Cuál es la fuente de verdad de este dato y cómo se sincroniza?"
   - "¿Qué pasa si falla la segunda de dos escrituras a motores distintos?"
   - "¿Cómo evitan vender por encima del stock y en qué motor está ese dato?"
   - "¿Qué evidencia ejecutada respalda esta decisión?"
3. Preguntá por **evidencia, no por opinión.** Una pregunta que se responde con "porque es más rápido" no se sostiene sin una medición.
4. No cuestiones por cuestionar: elegí los puntos donde su justificación sea débil o falte una alternativa descartada.

### 6.3. Responder objeciones (4 minutos)

- La sección 5.2 de la bitácora trae **16 objeciones anticipadas con respuesta**. Repartan en el grupo quién responde cuáles.
- Estructura de cada respuesta: **qué evaluamos → qué decidimos → por qué → qué evidencia tenemos → cuándo cambiaríamos de opinión.**
- Si no tenés una respuesta, decí qué dato falta y cómo lo obtendrías. Es mejor que inventar.
- **Anotá cada objeción recibida y tu respuesta** en la tabla de la sección 5.4 de la bitácora (es un entregable).

### 6.4. Ensayo
- Cronometrá la presentación completa: 8 minutos justos.
- Que alguien del grupo haga de rival y haga las 8 preguntas de la sección 5.3.
- Cada integrante tiene que poder explicar la matriz y el diagrama.

---

## 7. Prueba de factibilidad del catálogo en MySQL (opcional, refuerza la defensa)

**Para qué sirve.** El ataque más probable contra nuestro diseño es *"el catálogo con atributos heterogéneos es un caso de MongoDB"*. Nuestra respuesta es que una columna `JSON` con índices en MySQL alcanza. Esta prueba lo demuestra con **150.000 productos** y deja una captura propia para el informe (sección 3.1.1 de la bitácora). **No es la implementación del componente relacional**: es una prueba de factibilidad en una base de laboratorio que se borra al final.

**Requisito:** MySQL 8.0 o superior (el de las unidades anteriores). Todo se hace en una base aparte, `omnimarket_prueba`.

```sql
CREATE DATABASE omnimarket_prueba CHARACTER SET utf8mb4;
USE omnimarket_prueba;
CREATE TABLE categoria (categoria_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, nombre VARCHAR(80) NOT NULL UNIQUE) ENGINE=InnoDB;
CREATE TABLE producto (
  producto_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, sku VARCHAR(30) NOT NULL UNIQUE, nombre VARCHAR(150) NOT NULL,
  categoria_id INT UNSIGNED NOT NULL, precio_ars DECIMAL(12,2) NOT NULL, atributos JSON NOT NULL,
  pantalla_pulgadas DECIMAL(4,1) GENERATED ALWAYS AS (CAST(JSON_UNQUOTE(JSON_EXTRACT(atributos, '$.pantalla_pulgadas')) AS DECIMAL(4,1))) VIRTUAL,
  marca VARCHAR(40) GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(atributos, '$.marca'))) VIRTUAL,
  KEY idx_producto_pantalla (categoria_id, pantalla_pulgadas),
  KEY idx_producto_marca (marca),
  KEY idx_producto_etiquetas ((CAST(atributos -> '$.etiquetas' AS CHAR(30) ARRAY)))
) ENGINE=InnoDB;

SET SESSION cte_max_recursion_depth = 200000;
INSERT INTO categoria (nombre) SELECT CONCAT('cat_', n) FROM (WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n < 60) SELECT n FROM s) t;
INSERT INTO producto (sku, nombre, categoria_id, precio_ars, atributos)
SELECT CONCAT('P', 100000 + n), CONCAT('Producto ', n), 1 + (n MOD 60), 1000 + (n MOD 5000),
  CASE (n MOD 60) MOD 3                                   -- el tipo de atributos depende de la categoría
    WHEN 0 THEN JSON_OBJECT('marca', ELT(1 + ((n DIV 60) MOD 5), 'Acme', 'Zeta', 'Orion', 'Nova', 'Kilo'), 'pantalla_pulgadas', 13 + ((n DIV 60) MOD 5) * 0.7,
                            'ram_gb', CAST(ELT(1 + ((n DIV 60) MOD 3), 8, 16, 32) AS UNSIGNED),
                            'etiquetas', JSON_ARRAY('tecnologia', ELT(1 + ((n DIV 60) MOD 4), 'oferta', 'nuevo', 'premium', 'outlet')))
    WHEN 1 THEN JSON_OBJECT('marca', ELT(1 + ((n DIV 60) MOD 5), 'Acme', 'Zeta', 'Orion', 'Nova', 'Kilo'), 'talle', ELT(1 + ((n DIV 60) MOD 4), 'S', 'M', 'L', 'XL'),
                            'color', ELT(1 + ((n DIV 60) MOD 6), 'rojo', 'azul', 'verde', 'negro', 'blanco', 'gris'), 'etiquetas', JSON_ARRAY('indumentaria', 'oferta'))
    ELSE JSON_OBJECT('autor', CONCAT('Autor ', (n DIV 60) MOD 500), 'paginas', 100 + ((n DIV 60) MOD 700),
                     'color', ELT(1 + ((n DIV 60) MOD 6), 'rojo', 'azul', 'verde', 'negro', 'blanco', 'gris'), 'etiquetas', JSON_ARRAY('libros'))
  END
FROM (WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n < 150000) SELECT n FROM s) t;

SELECT COUNT(*) AS productos FROM producto;
```

Cada consulta se ejecuta con `EXPLAIN ANALYZE`, que muestra el **plan** y el **tiempo real** de cada paso (la salida cambia de una máquina a otra, pero el orden de magnitud se mantiene):

```sql
-- 1) Atributo con columna generada indexada (tecnología, 15,1 pulgadas): debe decir "Index lookup ... idx_producto_pantalla"
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto WHERE categoria_id = 1 AND pantalla_pulgadas = 15.1;

-- 2) Atributo sin índice propio, acotado por categoría: recorre solo las filas de esa categoría
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto WHERE categoria_id = 1 AND JSON_EXTRACT(atributos, '$.ram_gb') = 16;

-- 3) Peor caso: atributo sin índice y sin categoría (libros de un autor); recorre las 150.000 filas
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto WHERE atributos->>'$.autor' = 'Autor 123';

-- 4) El mismo filtro con un índice funcional creado a pedido: la consulta debe usar la misma expresión
CREATE INDEX idx_autor ON producto ((CAST(atributos->>'$.autor' AS CHAR(40)) COLLATE utf8mb4_bin));
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto WHERE CAST(atributos->>'$.autor' AS CHAR(40)) COLLATE utf8mb4_bin = 'Autor 123';

-- 5) Índice multivalor sobre el arreglo de etiquetas
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto WHERE 'outlet' MEMBER OF (atributos->'$.etiquetas');
```

**Qué tiene que verse (y qué se concluye)**

| Consulta | Resultado esperado | Conclusión |
| :---: | :--- | :--- |
| 1 | Búsqueda por índice sobre ≈ 500 filas; menos de 1 ms (≈ 0,3 ms) | Los atributos más filtrados se resuelven por índice |
| 2 | Recorre las ≈ 2.500 filas de la categoría (≈ 834 coincidencias); unos 10 ms | Con la categoría, aun sin índice propio, el costo es bajo |
| 3 | Recorre las 150.000 filas (100 coincidencias); ≈ 90 ms | El peor caso: con 500 lecturas por segundo sería insostenible (≈ 44 segundos de procesador por segundo) |
| 4 | Pasa a búsqueda por índice sobre 100 filas; ≈ 0,3 ms | Un atributo no previsto se indexa con **una sola sentencia** |
| 5 | Búsqueda por índice multivalor (12.500 coincidencias); unos 50 ms | Los arreglos (etiquetas) también se indexan; el tiempo lo domina contar muchas filas (≈ 48 ms) |

**Conclusión para la defensa:** una columna `JSON` con índices alcanza para el catálogo; el costo frente a PostgreSQL es que hay que **declarar** un índice por cada atributo que se filtra. Si el negocio exigiera filtrar libremente por cualquier atributo sin planificarlo, ese sería el momento de reevaluar (criterio de revisión de la bitácora, sección 2.3).

Cuando termines: `DROP DATABASE omnimarket_prueba;`

*Captura sugerida:* las consultas 1, 3 y 4 con su `EXPLAIN ANALYZE` (se ve el salto de recorrer todo a buscar por índice).

---

## 8. Checklist final de entrega

| Criterio de evaluación | Peso | ¿Qué lo respalda? | Listo |
| :--- | :---: | :--- | :---: |
| Análisis de requerimientos | 15 % | Matriz de requisitos (funcional y no funcional), supuestos y obligatorios frente a preferencias | ☐ |
| Selección y justificación de modelos | 25 % | Matriz de los cinco modelos, regla de adopción, alternativa descartada por dominio, costo de motores | ☐ |
| Modelado | 20 % | Diseño relacional con diagrama y DDL, diseños de Redis, Neo4j y Cassandra | ☐ |
| Implementación NoSQL y consultas | 20 % | Capturas de los pasos obligatorios y la integración | ☐ |
| Defensa y contraargumentación | 20 % | Presentación ensayada y registro de objeciones | ☐ |

Revisión final:
- ☐ Integrantes completados.
- ☐ Todas las capturas pegadas y legibles; ninguna muestra contraseñas.
- ☐ Ambos diagramas insertados.
- ☐ Valor del experimento de concurrencia completado.
- ☐ Scripts incluidos (`redis-omnimarket.txt`, `neo4j-omnimarket.cypher`) y sin credenciales.
- ☐ **Diapositivas** (sección 6.1) con la portada y el valor `[N]` de la diapositiva 9 completados, y presentación ensayada en 8 minutos.
- ☐ Informe pasado a PDF (ver nota de la sección 4).
- ☐ Tabla de objeciones recibidas completada tras la batalla.

---

## 9. Problemas frecuentes

| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `Clave incorrecta` al retomar | La clave de Neo4j no coincide con la del primer arranque | Repetir con `REINICIAR=1` (borra solo la carpeta `~/u9_act2`) |
| Neo4j no arranca o el puerto 7690 está ocupado | Quedó una instancia de una corrida anterior | `NEO4J_CONF=$HOME/u9_act2/neo4j/conf neo4j stop` y repetir |
| Redis: `Address already in use` | Quedó el Redis de la actividad corriendo | `redis-cli -p 6381 shutdown nosave` |
| Los conteos del paso 33 no son 2 y 4 | Se repitió la sesión sin reiniciar | `REINICIAR=1` |
| `El carrito de U01 está vacío` | Se retomó con `PASO_DESDE` después de detener las instancias (Redis pierde sus datos al detenerse) | `REINICIAR=1` |
| El paso 38 da exactamente 200 | La máquina ejecutó los procesos casi en serie (es posible, aunque raro) | Repetir los pasos 37 y 38 con `PASO_DESDE=37`; el valor varía en cada corrida |
| Poca memoria | Hay otros motores activos (Cassandra, Neo4j de la Actividad 1) | Detenerlos con `sudo systemctl stop cassandra neo4j` |
| Una captura no entra en pantalla | Terminal angosta | Maximizar la terminal o achicar la letra con `Ctrl` + `-` |
