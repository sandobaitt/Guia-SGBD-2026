-- =============================================================================
-- UNIDAD 7: ACTIVIDAD 2 - LABORATORIO BISAGRA
-- GRUPO 11: CATÁLOGO TÉCNICO MULTIRUBRO
-- Capacidad seleccionada (Radar Act. 1): Full-Text Search (índice FULLTEXT
-- invertido + MATCH ... AGAINST) con complemento de índice multivaluado JSON.
-- Motor: MySQL Community Server 9.7.2 LTS (InnoDB) - Ubuntu 24.04 LTS
-- Ejecución: sudo mysql -t -vvv < solucion_u7_actividad2.sql
--            (o sección por sección; las secciones marcadas [BASH] van en la
--             terminal de Linux, no en MySQL)
-- =============================================================================


-- =============================================================================
-- SECCIÓN 0: FASE A.1 - BASELINE DEL ENTORNO
-- =============================================================================
SELECT '--- BASELINE DEL ENTORNO ---' AS etapa;
SELECT VERSION() AS version, @@version_comment AS edicion, @@hostname AS host,
       @@default_storage_engine AS motor_default,
       @@innodb_buffer_pool_size / 1024 / 1024 AS buffer_pool_mb;

-- Parámetros de Full-Text de InnoDB (valores de fábrica)
SHOW VARIABLES LIKE 'innodb_ft%';
SHOW VARIABLES LIKE 'ngram_token_size';

-- Plugins asociados: parser ngram y tablas de diagnóstico INNODB_FT_*
SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_TYPE
FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'ngram' OR PLUGIN_NAME LIKE 'INNODB_FT%';

-- Stopwords por defecto (lista en inglés: incluye "de", "en", "la" pero no "para", "con")
SELECT COUNT(*) AS stopwords_default FROM information_schema.INNODB_FT_DEFAULT_STOPWORD;
SELECT GROUP_CONCAT(value ORDER BY value SEPARATOR ' ') AS lista
FROM information_schema.INNODB_FT_DEFAULT_STOPWORD;


-- =============================================================================
-- SECCIÓN 1: FASE A.4 - PRUEBA DE HUMO (VERIFICACIÓN CON CONFIGURACIÓN DE FÁBRICA)
-- Demuestra que FTS funciona, y detecta la limitación con siglas de 2 letras.
-- =============================================================================
DROP DATABASE IF EXISTS sgbd_u7_act2;
CREATE DATABASE sgbd_u7_act2 CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sgbd_u7_act2;

CREATE TABLE prueba_humo (
  id INT PRIMARY KEY,
  texto VARCHAR(200) NOT NULL,
  FULLTEXT KEY ft_texto (texto)
) ENGINE = InnoDB;

INSERT INTO prueba_humo VALUES
  (1, 'Smart TV 4K con HDR y Google TV'),
  (2, 'Notebook gaming con placa RTX'),
  (3, 'Cafetera espresso de 15 bar');

-- Funciona: palabra de 3+ letras
SELECT id, texto, MATCH(texto) AGAINST('gaming') AS score
FROM prueba_humo WHERE MATCH(texto) AGAINST('gaming');

-- Limitación: 'TV' y '4K' tienen 2 caracteres < innodb_ft_min_token_size (3)
-- => no existen en el índice invertido => 0 filas
SELECT COUNT(*) AS filas_tv_4k FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');

-- Contenido real del índice invertido (no aparecen 'tv' ni '4k').
-- Las filas recién insertadas aún están en la caché del índice (INDEX_CACHE),
-- todavía no se volcaron a las tablas auxiliares en disco (INDEX_TABLE).
SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/prueba_humo';
SELECT WORD, DOC_COUNT FROM information_schema.INNODB_FT_INDEX_CACHE ORDER BY WORD;
SELECT COUNT(*) AS palabras_en_disco FROM information_schema.INNODB_FT_INDEX_TABLE;


-- =============================================================================
-- [BASH] FASE A.3 - ACTIVACIÓN / CONFIGURACIÓN DEL SERVIDOR
-- innodb_ft_min_token_size es de solo lectura (no admite SET GLOBAL):
-- se define en un archivo de opciones y se reinicia mysqld.
-- Fuente: MySQL 9.7 Ref. Manual, 14.9.6 "Fine-Tuning MySQL Full-Text Search"
-- -----------------------------------------------------------------------------
-- sudo tee /etc/mysql/mysql.conf.d/u7_fulltext.cnf <<'EOF'
-- [mysqld]
-- # U7 Act. 2 - indexar siglas tecnicas de 2 caracteres (TV, 4K, HP, Hz)
-- innodb_ft_min_token_size = 2
-- EOF
-- sudo systemctl restart mysql
-- systemctl is-active mysql
--
-- Reversión: sudo rm /etc/mysql/mysql.conf.d/u7_fulltext.cnf && sudo systemctl restart mysql
-- =============================================================================


-- =============================================================================
-- SECCIÓN 2: FASE A.4 - VERIFICACIÓN POST-ACTIVACIÓN
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- VERIFICACIÓN POST-REINICIO ---' AS etapa;
SHOW VARIABLES LIKE 'innodb_ft_min_token_size';
SELECT VARIABLE_NAME, VARIABLE_VALUE, VARIABLE_SOURCE, VARIABLE_PATH
FROM performance_schema.variables_info
JOIN performance_schema.global_variables USING (VARIABLE_NAME)
WHERE VARIABLE_NAME = 'innodb_ft_min_token_size';

-- El índice existente NO cambia solo: hay que reconstruirlo (DROP + ADD).
-- Ojo: "ALTER TABLE ... DROP INDEX ft_texto, ADD FULLTEXT KEY ft_texto (texto)"
-- en UNA sola sentencia no reconstruye nada (InnoDB detecta la misma definición
-- y solo toca metadatos): deben ser dos sentencias separadas.
SELECT COUNT(*) AS filas_tv_4k FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');
ALTER TABLE prueba_humo DROP INDEX ft_texto;
ALTER TABLE prueba_humo ADD FULLTEXT KEY ft_texto (texto);
SELECT id, texto, MATCH(texto) AGAINST('TV 4K') AS score
FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');

-- Efecto colateral: con mínimo 2 se indexan palabras vacías del español ("con");
-- "de" no aparece porque es stopword de la lista inglesa por defecto.
-- Tras reconstruir el índice, los términos ya están en INDEX_TABLE (disco).
SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/prueba_humo';
SELECT WORD, DOC_COUNT FROM information_schema.INNODB_FT_INDEX_TABLE ORDER BY WORD;


-- =============================================================================
-- SECCIÓN 3: FASE B.1 - ESQUEMA HÍBRIDO Y POBLADO DEL CATÁLOGO
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- ESQUEMA HÍBRIDO Y CARGA ---' AS etapa;

-- 3.1. Stopwords en español (reemplaza la lista inglesa para los índices que
--      se creen en la sesión con innodb_ft_user_stopword_table)
CREATE TABLE stopwords_es (value VARCHAR(30) NOT NULL) ENGINE = InnoDB;
INSERT INTO stopwords_es (value) VALUES
  ('a'),('al'),('con'),('de'),('del'),('el'),('en'),('es'),('la'),('las'),
  ('lo'),('los'),('o'),('para'),('por'),('se'),('sin'),('su'),('sus'),('un'),
  ('una'),('y'),('que'),('como'),('mas'),('muy'),('e'),('u'),('le'),('les');

-- 3.2. Staging: el archivo U7_catalogo_multimodelo.jsonl se carga tal cual,
--      una línea JSON por fila (JSON Lines)
CREATE TABLE catalogo_raw (linea JSON NOT NULL) ENGINE = InnoDB;
INSERT INTO catalogo_raw (linea) VALUES
('{"id":1,"nombre":"Notebook Atlas 14","categoria":"notebook","precio":1250000,"stock":12,"atributos":{"ram_gb":16,"ssd_gb":512,"cpu":"Ryzen 7","gpu":"integrada"},"tags":["portable","trabajo","wifi6"]}'),
('{"id":2,"nombre":"Notebook Titan 16","categoria":"notebook","precio":2100000,"stock":5,"atributos":{"ram_gb":32,"ssd_gb":1024,"cpu":"Core Ultra 9","gpu":"RTX 5070"},"tags":["gaming","gpu","alta-gama"]}'),
('{"id":3,"nombre":"Ultrabook Air 13","categoria":"notebook","precio":1450000,"stock":8,"atributos":{"ram_gb":16,"ssd_gb":512,"peso_kg":1.1,"pantalla":"13.3"},"tags":["portable","liviana","viaje"]}'),
('{"id":4,"nombre":"Heladera Polar 420","categoria":"heladera","precio":980000,"stock":4,"atributos":{"litros":420,"no_frost":true,"puertas":2,"eficiencia":"A"},"tags":["hogar","no-frost"]}'),
('{"id":5,"nombre":"Heladera Compact 280","categoria":"heladera","precio":690000,"stock":9,"atributos":{"litros":280,"no_frost":false,"puertas":2,"eficiencia":"A+"},"tags":["hogar","compacta"]}'),
('{"id":6,"nombre":"Freezer Arctic 300","categoria":"freezer","precio":760000,"stock":3,"atributos":{"litros":300,"tipo":"horizontal","temperatura_min":-24},"tags":["frio","comercial"]}'),
('{"id":7,"nombre":"Zapatilla Run X","categoria":"calzado","precio":145000,"stock":35,"atributos":{"talles":[39,40,41,42,43],"material":"mesh","uso":"running"},"tags":["deporte","running","liviana"]}'),
('{"id":8,"nombre":"Bota Trek Pro","categoria":"calzado","precio":230000,"stock":18,"atributos":{"talles":[40,41,42,43,44],"material":"cuero","impermeable":true},"tags":["trekking","outdoor","impermeable"]}'),
('{"id":9,"nombre":"Sandalia Urban","categoria":"calzado","precio":89000,"stock":26,"atributos":{"talles":[36,37,38,39,40],"material":"sintetico"},"tags":["verano","urbano"]}'),
('{"id":10,"nombre":"Taladro Pro 18V","categoria":"herramienta","precio":310000,"stock":14,"atributos":{"voltaje":18,"bateria_ah":4,"rpm":1800,"percutor":true},"tags":["taller","inalambrico","profesional"]}'),
('{"id":11,"nombre":"Amoladora 900W","categoria":"herramienta","precio":165000,"stock":11,"atributos":{"potencia_w":900,"disco_mm":115,"rpm":11000},"tags":["taller","corte"]}'),
('{"id":12,"nombre":"Compresor 50L","categoria":"herramienta","precio":540000,"stock":6,"atributos":{"litros":50,"presion_bar":8,"potencia_hp":2},"tags":["taller","aire"]}'),
('{"id":13,"nombre":"Smart TV Nova 55","categoria":"televisor","precio":820000,"stock":7,"atributos":{"pulgadas":55,"resolucion":"4K","hdr":true,"so":"Google TV"},"tags":["hogar","4k","streaming"]}'),
('{"id":14,"nombre":"Smart TV Cinema 65","categoria":"televisor","precio":1350000,"stock":4,"atributos":{"pulgadas":65,"resolucion":"4K","panel":"OLED","hdr":true},"tags":["hogar","oled","cine"]}'),
('{"id":15,"nombre":"Monitor Work 27","categoria":"monitor","precio":420000,"stock":13,"atributos":{"pulgadas":27,"resolucion":"QHD","hz":75,"panel":"IPS"},"tags":["trabajo","ips"]}'),
('{"id":16,"nombre":"Monitor Game 32","categoria":"monitor","precio":690000,"stock":8,"atributos":{"pulgadas":32,"resolucion":"QHD","hz":165,"panel":"VA"},"tags":["gaming","alta-frecuencia"]}'),
('{"id":17,"nombre":"Cafetera Barista","categoria":"cafetera","precio":350000,"stock":10,"atributos":{"presion_bar":15,"deposito_l":1.8,"vaporizador":true},"tags":["cocina","cafe","espresso"]}'),
('{"id":18,"nombre":"Cafetera Filtro 12","categoria":"cafetera","precio":99000,"stock":22,"atributos":{"tazas":12,"programable":true,"filtro":"permanente"},"tags":["cocina","cafe"]}'),
('{"id":19,"nombre":"Router Mesh AX3000","categoria":"redes","precio":280000,"stock":16,"atributos":{"wifi":"6","puertos_gigabit":3,"mesh":true,"bandas":2},"tags":["redes","wifi6","mesh"]}'),
('{"id":20,"nombre":"Switch 24G Managed","categoria":"redes","precio":510000,"stock":5,"atributos":{"puertos":24,"gestionable":true,"poe":false,"rack":true},"tags":["redes","empresa","rack"]}');

-- 3.3. Descripciones comerciales de texto libre (el insumo de Full-Text Search;
--      el dataset de la cátedra no trae texto largo)
CREATE TABLE descripcion_carga (
  id INT PRIMARY KEY,
  descripcion TEXT NOT NULL
) ENGINE = InnoDB;
INSERT INTO descripcion_carga VALUES
(1,  'Notebook liviana de 14 pulgadas con procesador Ryzen 7, 16 GB de RAM y SSD de 512 GB. Gráficos integrados, conectividad WiFi 6 y batería de larga duración, ideal para trabajo remoto y estudio.'),
(2,  'Notebook gaming de alta gama con procesador Core Ultra 9, placa de video RTX 5070 y 32 GB de RAM. Pantalla de 16 pulgadas de alta frecuencia para juegos exigentes, edición de video y renderizado 3D.'),
(3,  'Ultrabook ultraliviana de 1,1 kg con pantalla de 13,3 pulgadas, 16 GB de RAM y SSD de 512 GB. Pensada para viajar: carcasa de aluminio, carga rápida USB-C y teclado retroiluminado.'),
(4,  'Heladera no frost de 420 litros con freezer superior, dos puertas y eficiencia energética A. Control electrónico de temperatura, dispensador de agua y estantes de vidrio templado.'),
(5,  'Heladera compacta de 280 litros con sistema cíclico, dos puertas y eficiencia A+. Ideal para departamentos y cocinas chicas, bajo consumo eléctrico.'),
(6,  'Freezer horizontal de 300 litros que alcanza -24 grados. Tapa con cerradura, uso doméstico o comercial para conservar congelados en almacenes y comercios gastronómicos.'),
(7,  'Zapatilla de running con capellada de mesh transpirable y suela de espuma con amortiguación. Liviana y flexible, para entrenamiento diario y carreras de calle.'),
(8,  'Bota de trekking de cuero impermeable con membrana respirable y suela de goma antideslizante. Protección de tobillo para senderismo, montaña y actividades outdoor.'),
(9,  'Sandalia urbana de material sintético con tiras regulables y plantilla acolchada. Cómoda para el verano y el uso diario en la ciudad.'),
(10, 'Taladro percutor inalámbrico de 18V con batería de litio de 4 Ah y 1800 rpm. Mandril metálico, luz LED y maletín, para uso profesional en taller y obra.'),
(11, 'Amoladora angular de 900W con disco de 115 mm y 11000 rpm. Empuñadura lateral antivibración para corte y desbaste de metal en el taller.'),
(12, 'Compresor de aire de 50 litros, 2 HP y 8 bar de presión. Ruedas para traslado, manómetro y salida rápida para inflado, pintura y herramientas neumáticas de taller.'),
(13, 'Smart TV de 55 pulgadas con resolución 4K y HDR. Sistema Google TV con aplicaciones de streaming, control por voz y WiFi integrado para el living del hogar.'),
(14, 'Smart TV OLED de 65 pulgadas 4K con HDR y negros perfectos. Experiencia de cine en casa con sonido envolvente y modo filmmaker.'),
(15, 'Monitor de 27 pulgadas con panel IPS, resolución QHD y 75 Hz. Colores precisos y soporte ergonómico regulable para oficina y trabajo de diseño.'),
(16, 'Monitor gaming curvo de 32 pulgadas con panel VA, resolución QHD y 165 Hz de alta frecuencia. Tiempo de respuesta de 1 ms y FreeSync para juegos competitivos.'),
(17, 'Cafetera espresso de 15 bar con depósito de 1,8 litros y vaporizador para espumar leche. Café de especialidad, capuchino y latte en la cocina.'),
(18, 'Cafetera de filtro programable para 12 tazas con filtro permanente lavable. Mantiene el café caliente y se programa la hora de inicio.'),
(19, 'Router mesh AX3000 con WiFi 6, doble banda y 3 puertos gigabit. Cobertura total del hogar sin zonas muertas y control parental desde la app.'),
(20, 'Switch gestionable de 24 puertos gigabit para montaje en rack. VLAN, QoS y monitoreo SNMP para redes de empresa; no incluye PoE.');

-- 3.4. Tabla híbrida: núcleo relacional estable + documento JSON variable + texto libre
CREATE TABLE producto (
  id          INT            PRIMARY KEY,
  nombre      VARCHAR(120)   NOT NULL,
  categoria   VARCHAR(40)    NOT NULL,
  precio      DECIMAL(12,2)  NOT NULL CHECK (precio >= 0),
  stock       INT            NOT NULL CHECK (stock >= 0),
  atributos   JSON           NOT NULL,           -- RAM/GPU, litros/no_frost, talles...
  tags        JSON           NOT NULL,           -- etiquetas (array JSON)
  descripcion TEXT           NOT NULL,           -- texto libre para Full-Text Search
  CONSTRAINT chk_tags_array CHECK (JSON_TYPE(tags) = 'ARRAY'),
  KEY idx_precio (precio)
) ENGINE = InnoDB;

INSERT INTO producto (id, nombre, categoria, precio, stock, atributos, tags, descripcion)
SELECT r.linea->>'$.id',
       r.linea->>'$.nombre',
       r.linea->>'$.categoria',
       r.linea->>'$.precio',
       r.linea->>'$.stock',
       r.linea->'$.atributos',
       r.linea->'$.tags',
       d.descripcion
FROM catalogo_raw r
JOIN descripcion_carga d ON d.id = r.linea->>'$.id';

SELECT COUNT(*) AS productos, COUNT(DISTINCT categoria) AS categorias,
       COUNT(DISTINCT JSON_KEYS(atributos)) AS esquemas_de_atributos_distintos
FROM producto;
SELECT categoria, COUNT(*) AS cant, JSON_KEYS(ANY_VALUE(atributos)) AS claves_ejemplo
FROM producto GROUP BY categoria ORDER BY categoria;


-- =============================================================================
-- SECCIÓN 4: FASE B.2 - CONSULTAS DE VALIDACIÓN (ANTES DE LA INTERVENCIÓN)
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- CONSULTAS ANTES DE INDEXAR ---' AS etapa;

-- Consulta 1: filtro por atributo escalar relacional (B-Tree idx_precio)
SELECT id, nombre, categoria, precio, stock
FROM producto
WHERE precio BETWEEN 300000 AND 900000 AND stock >= 5
ORDER BY precio;
EXPLAIN SELECT id, nombre, precio FROM producto
WHERE precio BETWEEN 300000 AND 900000 AND stock >= 5;

-- Consulta 2a: búsqueda por etiqueta dentro del array JSON
SELECT id, nombre, tags FROM producto WHERE 'gaming' MEMBER OF (tags);
EXPLAIN SELECT id, nombre FROM producto WHERE 'gaming' MEMBER OF (tags);

-- Consulta 2b: atributo anidado (colección de talles dentro del documento)
SELECT id, nombre, atributos->'$.talles' AS talles, atributos->>'$.material' AS material
FROM producto
WHERE categoria = 'calzado' AND 42 MEMBER OF (atributos->'$.talles');

-- Consulta 2c: atributo anidado escalar con extracción de ruta JSON
SELECT id, nombre, atributos->>'$.ram_gb' AS ram_gb, atributos->>'$.gpu' AS gpu
FROM producto
WHERE atributos->'$.ram_gb' >= 16 AND atributos->>'$.gpu' <> 'integrada';

-- Consulta 3 (sin capacidad FTS): la única alternativa es LIKE '%...%'
SELECT id, nombre FROM producto
WHERE descripcion LIKE '%gaming%' OR nombre LIKE '%gaming%';
EXPLAIN SELECT id, nombre FROM producto
WHERE descripcion LIKE '%gaming%' OR nombre LIKE '%gaming%';

-- Sin índice FULLTEXT, InnoDB rechaza MATCH():
-- ERROR 1191 (HY000): Can't find FULLTEXT index matching the column list
-- SELECT id FROM producto WHERE MATCH(nombre, descripcion) AGAINST('gaming');


-- =============================================================================
-- SECCIÓN 5: FASE B.3 - INTERVENCIÓN FÍSICA (ÍNDICES ESPECIALIZADOS)
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- INTERVENCIÓN FÍSICA ---' AS etapa;

-- 5.1. Índice invertido FULLTEXT con stopwords en español
SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';
CREATE FULLTEXT INDEX ft_producto_texto ON producto (nombre, descripcion);
-- Warning 124: InnoDB rebuilding table to add column FTS_DOC_ID
SHOW WARNINGS;

-- 5.2. Índice multivaluado sobre el array JSON de tags (complemento para Consulta 2)
CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));

SHOW INDEX FROM producto;

-- 5.3. Inspección del índice invertido (términos más frecuentes)
SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/producto';
SELECT COUNT(DISTINCT WORD) AS terminos_indexados FROM information_schema.INNODB_FT_INDEX_TABLE;
SELECT WORD, DOC_COUNT FROM information_schema.INNODB_FT_INDEX_TABLE
GROUP BY WORD, DOC_COUNT ORDER BY DOC_COUNT DESC, WORD LIMIT 12;
-- Las stopwords en español no están en el índice; las siglas de 2 letras sí
SELECT DISTINCT WORD FROM information_schema.INNODB_FT_INDEX_TABLE
WHERE WORD IN ('de','con','para','tv','4k','hp','hz','ms','va');

-- Tablas auxiliares que InnoDB crea para el índice invertido de producto
-- (su nombre lleva el TABLE_ID en hexadecimal: fts_<table_id>_...)
SELECT ts.NAME, ts.FILE_SIZE / 1024 AS kb
FROM information_schema.INNODB_TABLESPACES ts
JOIN information_schema.INNODB_TABLES t ON t.NAME = 'sgbd_u7_act2/producto'
WHERE ts.NAME = t.NAME
   OR ts.NAME LIKE CONCAT('sgbd_u7_act2/fts_', LPAD(HEX(t.TABLE_ID), 16, '0'), '%')
ORDER BY ts.NAME;


-- =============================================================================
-- SECCIÓN 6: FASE B.2/B.4 - CONSULTAS DESPUÉS DE LA INTERVENCIÓN
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- CONSULTAS DESPUÉS DE INDEXAR ---' AS etapa;

-- Consulta 2a con índice multivaluado
EXPLAIN SELECT id, nombre FROM producto WHERE 'gaming' MEMBER OF (tags);
EXPLAIN SELECT id, nombre FROM producto WHERE JSON_OVERLAPS(tags, '["gaming","oled"]');
SELECT id, nombre, tags FROM producto WHERE JSON_OVERLAPS(tags, '["gaming","oled"]');

-- Consulta 3a: lenguaje natural ordenado por relevancia
SELECT id, nombre,
       ROUND(MATCH(nombre, descripcion) AGAINST('notebook gaming RTX'), 4) AS relevancia
FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('notebook gaming RTX')
ORDER BY relevancia DESC;
EXPLAIN SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('notebook gaming RTX');

-- Consulta 3b: modo booleano (obligatorio +, exclusión -, comodín *, frase "")
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('+gaming -notebook' IN BOOLEAN MODE);
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('"alta frecuencia"' IN BOOLEAN MODE);
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('inalambr*' IN BOOLEAN MODE);

-- Consulta 3c: siglas de 2 caracteres (habilitadas por la configuración de Fase A)
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('+TV +4K' IN BOOLEAN MODE);

-- Consulta 3d: insensibilidad a acentos (colación utf8mb4_0900_ai_ci)
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('cafe');

-- Consulta 3e: consulta híbrida = texto (FTS) + escalar relacional + ruta JSON
SELECT id, nombre, precio,
       atributos->>'$.pulgadas' AS pulgadas,
       atributos->>'$.resolucion' AS resolucion,
       ROUND(MATCH(nombre, descripcion) AGAINST('pulgadas resolución HDR QHD'), 4) AS relevancia
FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('pulgadas resolución HDR QHD')
  AND precio <= 1000000
  AND JSON_CONTAINS_PATH(atributos, 'one', '$.pulgadas')
ORDER BY relevancia DESC;

-- Consulta 3f: expansión de consulta (blind query expansion)
SELECT id, nombre FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('espresso' WITH QUERY EXPANSION);

-- Límites: sin stemming en español ni tolerancia a errores de tipeo
-- (resultado esperado: juegos=2, juego=0, typo_notebok=0, juego_comodin=2)
SELECT (SELECT COUNT(*) FROM producto WHERE MATCH(nombre, descripcion) AGAINST('juegos')) AS juegos,
       (SELECT COUNT(*) FROM producto WHERE MATCH(nombre, descripcion) AGAINST('juego')) AS juego,
       (SELECT COUNT(*) FROM producto WHERE MATCH(nombre, descripcion) AGAINST('notebok')) AS typo_notebok,
       (SELECT COUNT(*) FROM producto WHERE MATCH(nombre, descripcion) AGAINST('juego*' IN BOOLEAN MODE)) AS juego_comodin;

-- LIKE no se beneficia del índice FULLTEXT: sigue siendo escaneo completo
EXPLAIN SELECT id, nombre FROM producto WHERE descripcion LIKE '%gaming%';


-- =============================================================================
-- SECCIÓN 7: FASE B.4 - MEDICIÓN A ESCALA (200.000 PRODUCTOS)
-- Con 20 filas cualquier plan tarda < 1 ms; se replica el catálogo para que la
-- diferencia de E/S sea observable.
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- MEDICIÓN A ESCALA ---' AS etapa;

CREATE TABLE digito (d TINYINT PRIMARY KEY) ENGINE = InnoDB;
INSERT INTO digito VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Misma estructura que producto, sin índices especializados
CREATE TABLE producto_masivo (
  id          INT            PRIMARY KEY,
  nombre      VARCHAR(120)   NOT NULL,
  categoria   VARCHAR(40)    NOT NULL,
  precio      DECIMAL(12,2)  NOT NULL,
  stock       INT            NOT NULL,
  atributos   JSON           NOT NULL,
  tags        JSON           NOT NULL,
  descripcion TEXT           NOT NULL,
  KEY idx_precio (precio)
) ENGINE = InnoDB;

INSERT INTO producto_masivo
SELECT n.n * 20 + p.id,
       CONCAT(p.nombre, ' #', n.n),
       p.categoria,
       ROUND(p.precio * (0.80 + (n.n MOD 41) / 100), 2),
       (p.stock + n.n) MOD 60,
       p.atributos,
       p.tags,
       CONCAT(p.descripcion, ' Código interno SKU', LPAD(n.n * 20 + p.id, 7, '0'), '.')
FROM producto p
CROSS JOIN (SELECT a.d + 10 * b.d + 100 * c.d + 1000 * e.d AS n
            FROM digito a, digito b, digito c, digito e) n;

ANALYZE TABLE producto_masivo;
SELECT COUNT(*) AS filas FROM producto_masivo;

-- 7.1. ANTES (sin índice FULLTEXT)
-- M1: término frecuente (10.000 coincidencias = 5%)
FLUSH STATUS;
SELECT COUNT(*) AS m1_like FROM producto_masivo
WHERE nombre LIKE '%gaming%' OR descripcion LIKE '%gaming%';
SHOW SESSION STATUS LIKE 'Handler_read%';
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto_masivo
WHERE nombre LIKE '%gaming%' OR descripcion LIKE '%gaming%';

-- M2: búsqueda multi-término (los tres deben aparecer)
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto_masivo
WHERE descripcion LIKE '%notebook%' AND descripcion LIKE '%gaming%' AND descripcion LIKE '%RTX%';

-- M3: código altamente selectivo (1 coincidencia)
FLUSH STATUS;
SELECT id, nombre FROM producto_masivo WHERE descripcion LIKE '%SKU0123457%';
SHOW SESSION STATUS LIKE 'Handler_read%';
EXPLAIN ANALYZE SELECT id, nombre FROM producto_masivo WHERE descripcion LIKE '%SKU0123457%';
EXPLAIN FORMAT=JSON SELECT id, nombre FROM producto_masivo WHERE descripcion LIKE '%SKU0123457%';

-- Costo de escritura SIN índice FULLTEXT (20.000 filas)
UPDATE producto_masivo SET descripcion = CONCAT(descripcion, ' ') WHERE id <= 20000;

-- 7.2. INTERVENCIÓN: creación del índice FULLTEXT (medir tiempo de construcción)
SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';
ALTER TABLE producto_masivo ADD FULLTEXT KEY ft_masivo_texto (nombre, descripcion);
SHOW WARNINGS;
ANALYZE TABLE producto_masivo;

-- 7.3. DESPUÉS (con índice FULLTEXT)
FLUSH STATUS;
SELECT COUNT(*) AS m1_fts FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('gaming' IN BOOLEAN MODE);
SHOW SESSION STATUS LIKE 'Handler_read%';
EXPLAIN ANALYZE SELECT COUNT(*) FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('gaming' IN BOOLEAN MODE);

EXPLAIN ANALYZE SELECT COUNT(*) FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('+notebook +gaming +RTX' IN BOOLEAN MODE);

FLUSH STATUS;
SELECT id, nombre FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('+SKU0123457' IN BOOLEAN MODE);
SHOW SESSION STATUS LIKE 'Handler_read%';
EXPLAIN ANALYZE SELECT id, nombre FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('+SKU0123457' IN BOOLEAN MODE);
EXPLAIN FORMAT=JSON SELECT id, nombre FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('+SKU0123457' IN BOOLEAN MODE);

-- Top-10 por relevancia: algo que LIKE no puede hacer
EXPLAIN ANALYZE SELECT id, nombre, MATCH(nombre, descripcion) AGAINST('notebook gaming RTX') AS rel
FROM producto_masivo
WHERE MATCH(nombre, descripcion) AGAINST('notebook gaming RTX')
ORDER BY rel DESC LIMIT 10;

-- Costo de escritura CON índice FULLTEXT (mismas 20.000 filas)
UPDATE producto_masivo SET descripcion = CONCAT(descripcion, ' ') WHERE id <= 20000;


-- =============================================================================
-- SECCIÓN 8: ANÁLISIS DE COSTOS Y LÍMITES
-- =============================================================================
USE sgbd_u7_act2;
SELECT '--- COSTOS DE ALMACENAMIENTO ---' AS etapa;

-- Espacio: tabla base vs. tablas auxiliares de su índice invertido (fts_<table_id>_*)
SELECT t.NAME AS tabla_base,
       ROUND(MAX(CASE WHEN ts.NAME = t.NAME THEN ts.FILE_SIZE END) / 1024 / 1024, 1) AS tabla_mb,
       SUM(ts.NAME LIKE '%/fts%') AS archivos_fts,
       ROUND(SUM(CASE WHEN ts.NAME LIKE '%/fts%' THEN ts.FILE_SIZE ELSE 0 END) / 1024 / 1024, 1) AS indice_fulltext_mb
FROM information_schema.INNODB_TABLES t
JOIN information_schema.INNODB_TABLESPACES ts
  ON ts.NAME = t.NAME
  OR ts.NAME LIKE CONCAT('sgbd_u7_act2/fts_', LPAD(HEX(t.TABLE_ID), 16, '0'), '%')
WHERE t.NAME IN ('sgbd_u7_act2/producto', 'sgbd_u7_act2/producto_masivo')
GROUP BY t.NAME;

-- Metadatos del índice: la tabla de stopwords queda asociada al índice
SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/producto_masivo';
SELECT * FROM information_schema.INNODB_FT_CONFIG;
SELECT COUNT(DISTINCT WORD) AS terminos_distintos FROM information_schema.INNODB_FT_INDEX_TABLE;

-- Un UPDATE sobre columnas indexadas = borrado lógico + reinserción con nuevo
-- FTS_DOC_ID: los doc_id viejos quedan pendientes de purga
SELECT COUNT(*) AS doc_ids_borrados_pendientes FROM information_schema.INNODB_FT_DELETED;

-- Mantenimiento: OPTIMIZE con innodb_optimize_fulltext_only reorganiza solo el índice,
-- pero procesa innodb_ft_num_word_optimize (2000) términos por pasada: con ~210.000
-- términos hacen falta ~105 pasadas para purgar por completo.
SET GLOBAL innodb_optimize_fulltext_only = ON;
OPTIMIZE TABLE producto_masivo;
SET GLOBAL innodb_optimize_fulltext_only = OFF;
SELECT COUNT(*) AS doc_ids_borrados_post_1_pasada FROM information_schema.INNODB_FT_DELETED;

SET GLOBAL innodb_ft_aux_table = DEFAULT;

-- =============================================================================
-- LIMPIEZA (opcional, al terminar el laboratorio)
-- DROP DATABASE sgbd_u7_act2;
-- [BASH] sudo rm /etc/mysql/mysql.conf.d/u7_fulltext.cnf && sudo systemctl restart mysql
-- =============================================================================
