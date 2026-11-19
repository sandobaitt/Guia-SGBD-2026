/*
============================================================================
LABORATORIO INTEGRADOR - SISTEMAS DE GESTIÓN DE BASES DE DATOS (SGBD)
GRUPO: 11
INTEGRANTES: Aguirre Egea Emiliano, Ghione Lucas, Pagno Agustin, Sandoval Lautaro
CONSOLIDADO DE SCRIPTS (BLOQUES 2 Y 3)
Motores: MySQL 9.7.2 + MySQL Shell 9.7.1 (VM LinuxE) · MongoDB 8.0.34 (VM mv-sgbd)
Nota: Las credenciales se piden por teclado (mysql/mongosh/mongoimport sin la
clave en la línea de comandos, passwordPrompt()). Los comentarios de bloque
que contienen comandos se ejecutan en Bash o en mongosh, según se indica.
============================================================================
*/

/* ****************************************************************************
BLOQUE 2: DATOS SEMIESTRUCTURADOS EN MYSQL 9.7 (JSON)
**************************************************************************** */

-- ============================================================================
-- EJERCICIO 7: Importación de Documentos JSON
-- ============================================================================

-- 7.0 Preparación: MySQL Shell no venía instalado en la VM (repositorio oficial de MySQL)
-- Ejecución (Bash):
/*
sudo apt install mysql-shell
mysqlsh --version      # mysqlsh Ver 9.7.1 for Linux on x86_64
*/

-- 7.1 Base zakila_json y permisos para usr_g11 (como root)
-- Ejecución: sudo mysql -t < ej07_0_base_y_permisos.sql
CREATE DATABASE IF NOT EXISTS zakila_json CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- usr_g11 (Ejercicio 1.1) administra las bases del laboratorio: se le suma la nueva
GRANT ALL PRIVILEGES ON zakila_json.* TO 'usr_g11'@'%' WITH GRANT OPTION;

SHOW GRANTS FOR 'usr_g11'@'%';

-- 7.2 Tablas con columna de tipo nativo JSON y clave primaria generada (como usr_g11)
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 < ej07_1_tablas_json.sql
USE zakila_json;

DROP TABLE IF EXISTS customers, films, stores;

CREATE TABLE customers (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

CREATE TABLE films (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

CREATE TABLE stores (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_KEY, EXTRA
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'zakila_json'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 7.3 Importación con util.importJson (ej07_2_importar.js, sesión X Protocol)
-- Ejecución (Bash + MySQL Shell): mysqlsh --mysqlx -u usr_g11 -h 127.0.0.1 -P 33060 --file ej07_2_importar.js
/*
const carpeta = os.getenv("DATOS") || os.getenv("HOME") + "/lab_integrador_g11/datos";

for (const tabla of ["customers", "films", "stores"]) {
  print(`\n=== ${tabla}.json -> zakila_json.${tabla}(doc)\n`);
  util.importJson(`${carpeta}/${tabla}.json`, {
    schema: "zakila_json",
    table: tabla,
    tableColumn: "doc"
  });
}
*/

-- 7.4 Verificación de la carga
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 < ej07_3_verificar.sql
USE zakila_json;

-- Filas por tabla (esperado: 599 / 1000 / 2)
SELECT 'customers' AS tabla, COUNT(*) AS filas FROM customers
UNION ALL SELECT 'films', COUNT(*) FROM films
UNION ALL SELECT 'stores', COUNT(*) FROM stores;

-- El tipo de la columna es JSON nativo y cada valor es un objeto válido
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'zakila_json' AND COLUMN_NAME = 'doc';
SELECT JSON_TYPE(doc) AS tipo, COUNT(*) AS documentos FROM customers GROUP BY tipo;

-- Arreglos anidados: alquileres por cliente (esperado: 16044 en total, 12 a 46)
SELECT COUNT(*) AS clientes, SUM(JSON_LENGTH(doc, '$.Rentals')) AS alquileres,
       MIN(JSON_LENGTH(doc, '$.Rentals')) AS min_alq, MAX(JSON_LENGTH(doc, '$.Rentals')) AS max_alq
FROM customers;
SELECT id, doc->>'$.City' AS ciudad, doc->>'$.Country' AS pais,
       JSON_LENGTH(doc, '$.Inventory') AS items_inventario
FROM stores;

-- Muestra: un cliente y una película con extracción de rutas JSON
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       doc->>'$.Country' AS pais, doc->>'$.Rentals[0]."Film Title"' AS primer_alquiler
FROM customers WHERE id = 1;
SELECT id, doc->>'$.Title' AS titulo, doc->>'$.Category' AS categoria,
       JSON_LENGTH(doc, '$.Actors') AS actores
FROM films WHERE id = 1;

-- ============================================================================
-- EJERCICIO 8: Consultas, JSON Schema y Cruce Multimodelo
-- ============================================================================

-- 8.1 Actualización documental con JSON_SET()
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 < ej08_1_cliente_vip.sql
USE zakila_json;
SET NAMES utf8mb4;

-- 1. ANTES: clientes que cumplen la condición (cantidad de elementos de $.Rentals)
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       JSON_LENGTH(doc, '$.Rentals') AS alquileres,
       JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP') AS tiene_vip
FROM customers
WHERE JSON_LENGTH(doc, '$.Rentals') >= 40
ORDER BY alquileres DESC, id;

-- 2. Actualización: JSON_SET agrega la clave si no existe (o la reemplaza si existe)
START TRANSACTION;
UPDATE customers
SET doc = JSON_SET(doc, '$.ClienteVIP', 'SÍ')
WHERE JSON_LENGTH(doc, '$.Rentals') >= 40;
SELECT ROW_COUNT() AS filas_actualizadas;
COMMIT;

-- 3. DESPUÉS: clientes marcados como VIP (deben ser exactamente los mismos)
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       JSON_LENGTH(doc, '$.Rentals') AS alquileres, doc->>'$.ClienteVIP' AS ClienteVIP
FROM customers
WHERE doc->>'$.ClienteVIP' = 'SÍ'
ORDER BY alquileres DESC, id;

-- 4. Control: ningún cliente con menos de 40 alquileres quedó marcado
SELECT SUM(JSON_LENGTH(doc, '$.Rentals') >= 40) AS con_40_o_mas,
       SUM(JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP')) AS marcados_vip,
       SUM(JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP') AND JSON_LENGTH(doc, '$.Rentals') < 40) AS marcados_por_error
FROM customers;

-- 5. La clave quedó dentro del documento (claves de primer nivel de un cliente VIP)
SELECT id, JSON_KEYS(doc) AS claves FROM customers
WHERE doc->>'$.ClienteVIP' = 'SÍ' ORDER BY id LIMIT 1;

-- 8.2 Restricción de esquema: CHECK con JSON_SCHEMA_VALID() (2 válidas, 2 rechazadas)
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 --force < ej08_2_check_json_schema.sql
-- (--force: los INSERT 9003 y 9004 deben fallar con ERROR 3819 y el script continúa)
USE zakila_json;
SET NAMES utf8mb4;

-- Esquema (JSON Schema draft 4, el que implementa MySQL):
--   _id entero; First Name, Last Name y Country texto no vacío; Rentals arreglo;
--   ClienteVIP es opcional, pero si aparece solo puede valer "SÍ" o "NO".
SET @esquema = '{
  "type": "object",
  "required": ["_id", "First Name", "Last Name", "Country", "Rentals"],
  "properties": {
    "_id":          { "type": "integer" },
    "First Name":   { "type": "string", "minLength": 1 },
    "Last Name":    { "type": "string", "minLength": 1 },
    "Country":      { "type": "string", "minLength": 1 },
    "Rentals":      { "type": "array" },
    "ClienteVIP":   { "type": "string", "enum": ["SÍ", "NO"] }
  }
}';

-- 1. Antes de crear la restricción: los 599 documentos existentes deben cumplirla,
--    porque MySQL valida todas las filas al agregar un CHECK
SELECT COUNT(*) AS documentos,
       SUM(JSON_SCHEMA_VALID(@esquema, doc)) AS validos,
       SUM(NOT JSON_SCHEMA_VALID(@esquema, doc)) AS invalidos
FROM customers;

-- 2. Restricción (el CHECK no admite variables: el esquema va escrito literal,
--    idéntico a @esquema)
ALTER TABLE customers ADD CONSTRAINT chk_customers_esquema CHECK (JSON_SCHEMA_VALID('{
  "type": "object",
  "required": ["_id", "First Name", "Last Name", "Country", "Rentals"],
  "properties": {
    "_id":          { "type": "integer" },
    "First Name":   { "type": "string", "minLength": 1 },
    "Last Name":    { "type": "string", "minLength": 1 },
    "Country":      { "type": "string", "minLength": 1 },
    "Rentals":      { "type": "array" },
    "ClienteVIP":   { "type": "string", "enum": ["SÍ", "NO"] }
  }
}', doc));

SELECT CONSTRAINT_NAME, ENFORCED FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'zakila_json' AND TABLE_NAME = 'customers' AND CONSTRAINT_TYPE = 'CHECK';

-- 3. Inserción VÁLIDA 1: cliente nuevo sin ClienteVIP (la clave es opcional)
INSERT INTO customers (doc) VALUES ('{"_id": 9001, "First Name": "LUCIA", "Last Name": "BENITEZ",
  "Country": "Argentina", "City": "Resistencia", "Rentals": []}');

-- 4. Inserción VÁLIDA 2: cliente con ClienteVIP = "NO" (valor permitido por el enum)
INSERT INTO customers (doc) VALUES ('{"_id": 9002, "First Name": "MARTIN", "Last Name": "ACOSTA",
  "Country": "Paraguay", "Rentals": [], "ClienteVIP": "NO"}');

-- 5. Inserción INVÁLIDA 1: falta "Last Name" (campo requerido)
INSERT INTO customers (doc) VALUES ('{"_id": 9003, "First Name": "SIN",
  "Country": "Chile", "Rentals": []}');

-- 6. Inserción INVÁLIDA 2: ClienteVIP con un valor fuera del enum
INSERT INTO customers (doc) VALUES ('{"_id": 9004, "First Name": "ANA", "Last Name": "ROJAS",
  "Country": "Uruguay", "Rentals": [], "ClienteVIP": "TAL VEZ"}');

-- 7. Motivo de cada rechazo según el validador (regla que falló y dónde)
SELECT r.id,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$.valid'))                   AS valido,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."schema-failed-keyword"')) AS regla_fallida,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."document-location"'))     AS ubicacion_en_doc,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."schema-location"'))       AS ubicacion_en_esquema
FROM (
  SELECT 9003 AS id, JSON_SCHEMA_VALIDATION_REPORT(@esquema,
    '{"_id": 9003, "First Name": "SIN", "Country": "Chile", "Rentals": []}') AS rep
  UNION ALL
  SELECT 9004, JSON_SCHEMA_VALIDATION_REPORT(@esquema,
    '{"_id": 9004, "First Name": "ANA", "Last Name": "ROJAS",
      "Country": "Uruguay", "Rentals": [], "ClienteVIP": "TAL VEZ"}')
) AS r;

-- 8. Resultado: solo entraron las dos válidas
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       doc->>'$.Country' AS pais, IFNULL(doc->>'$.ClienteVIP', '(sin clave)') AS ClienteVIP
FROM customers WHERE id >= 9000 ORDER BY id;

-- 9. Limpieza: se quitan los documentos de prueba para que customers vuelva a
--    los 599 originales (no alteran el cruce del 8.3). La restricción queda activa.
DELETE FROM customers WHERE id IN (9001, 9002);
SELECT COUNT(*) AS customers_final FROM customers;

-- 8.3 Cruce multimodelo: Top 10 de películas más alquiladas en América del Sur
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 < ej08_3_cruce_multimodelo.sql
SET NAMES utf8mb4;

-- 1. Países de América del Sur en world_x y clientes de cada uno (control del cruce)
SELECT ci.doc->>'$.Name' AS pais, ci.doc->>'$.Code' AS codigo, COUNT(c.id) AS clientes
FROM world_x.countryinfo AS ci
LEFT JOIN zakila_json.customers AS c ON c.doc->>'$.Country' = ci.doc->>'$.Name'
WHERE ci.doc->>'$.geography.Continent' = 'South America'
GROUP BY pais, codigo
ORDER BY clientes DESC, pais;

-- 2. Top 10 de películas más alquiladas en América del Sur
--    Desempate por título: hay varias películas con 6 alquileres en el corte.
WITH alquileres_sa AS (
  SELECT r.film_id, r.titulo, ci.doc->>'$.Name' AS pais
  FROM zakila_json.customers AS c
  JOIN world_x.countryinfo AS ci
    ON ci.doc->>'$.Name' = c.doc->>'$.Country'
   AND ci.doc->>'$.geography.Continent' = 'South America'
  JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (
         film_id INT          PATH '$.filmId',
         titulo  VARCHAR(100) PATH '$."Film Title"'
       )) AS r
)
SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, a.titulo) AS puesto,
       a.titulo AS pelicula,
       f.doc->>'$.Category' AS categoria,
       COUNT(*) AS alquileres,
       COUNT(DISTINCT a.pais) AS paises
FROM alquileres_sa AS a
JOIN zakila_json.films AS f ON f.id = a.film_id
GROUP BY a.film_id, a.titulo, categoria
ORDER BY alquileres DESC, pelicula
LIMIT 10;

-- 3. Empate en el corte: películas con la misma cantidad que el puesto 10
WITH alquileres_sa AS (
  SELECT r.titulo
  FROM zakila_json.customers AS c
  JOIN world_x.countryinfo AS ci
    ON ci.doc->>'$.Name' = c.doc->>'$.Country'
   AND ci.doc->>'$.geography.Continent' = 'South America'
  JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (titulo VARCHAR(100) PATH '$."Film Title"')) AS r
),
ranking AS (
  SELECT titulo, COUNT(*) AS alquileres,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rango
  FROM alquileres_sa GROUP BY titulo
)
SELECT rango, titulo AS pelicula, alquileres
FROM ranking
WHERE alquileres = (SELECT alquileres FROM ranking ORDER BY alquileres DESC, titulo LIMIT 9, 1)
ORDER BY titulo;

-- 4. Totales del universo analizado
SELECT COUNT(DISTINCT c.id) AS clientes_sa, COUNT(*) AS alquileres_sa,
       COUNT(DISTINCT r.titulo) AS peliculas_distintas
FROM zakila_json.customers AS c
JOIN world_x.countryinfo AS ci
  ON ci.doc->>'$.Name' = c.doc->>'$.Country'
 AND ci.doc->>'$.geography.Continent' = 'South America'
JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (titulo VARCHAR(100) PATH '$."Film Title"')) AS r;

-- 8.4 Exportación de world_x.city a JSON {"Ciudad", "CodP"} (ej08_4_exportar_city.sh)
-- Ejecución (Bash): ./ej08_4_exportar_city.sh ciudades.json
/*
set -euo pipefail
SALIDA="${1:-ciudades.json}"
MYSQL=(mysql -h 127.0.0.1 -u usr_g11 -N -B -r)

"${MYSQL[@]}" -e "
  SELECT CONCAT('{\"Ciudad\": ', JSON_QUOTE(Name), ', \"CodP\": ', JSON_QUOTE(CountryCode), '}')
  FROM world_x.city
  ORDER BY ID" > "$SALIDA"

echo "Archivo: $SALIDA"
wc -l < "$SALIDA" | xargs echo "Líneas (documentos):"
"${MYSQL[@]}" -e "SELECT COUNT(*) FROM world_x.city" | xargs echo "Filas en world_x.city:"
*/

-- 8.4 Evidencia del archivo generado
-- Ejecución (Bash):
/*
head -3 ciudades.json
grep -n "Resistencia\|Corrientes\|São Paulo" ciudades.json     # 98:{"Ciudad": "Resistencia", "CodP": "ARG"}
ls -lh ciudades.json
*/

-- 8.4 Verificación: orden de claves de JSON_OBJECT() y validez de los 4079 documentos
-- Ejecución: mysql -t -h 127.0.0.1 -u usr_g11 < ej08_4_verificar.sql
SET NAMES utf8mb4;

-- 1. Por qué no alcanza JSON_OBJECT(): el tipo JSON reordena las claves
SELECT JSON_OBJECT('Ciudad', 'Resistencia', 'CodP', 'ARG') AS con_json_object;

-- 2. Documento armado con CONCAT + JSON_QUOTE: respeta el orden y es JSON válido
SELECT CONCAT('{"Ciudad": ', JSON_QUOTE(Name), ', "CodP": ', JSON_QUOTE(CountryCode), '}') AS exportado
FROM world_x.city WHERE Name = 'Resistencia';

-- 3. Todas las filas generan un JSON válido (incluidos nombres con acentos o comillas)
SELECT COUNT(*) AS ciudades,
       SUM(JSON_VALID(CONCAT('{"Ciudad": ', JSON_QUOTE(Name), ', "CodP": ', JSON_QUOTE(CountryCode), '}'))) AS json_validos
FROM world_x.city;

-- 8.4 Exportación de países para el Ejercicio 10.2 (world_x.countryinfo, documentos JSON)
-- Ejecución (Bash):
/*
mysql -h 127.0.0.1 -u usr_g11 -N -B -r -e "SELECT doc FROM world_x.countryinfo ORDER BY doc->>'$.Code'" > paises.json
wc -l paises.json      # 239
*/

/* ****************************************************************************
BLOQUE 3: BASE DE DATOS NOSQL DOCUMENTAL (MongoDB 8.0)
**************************************************************************** */

-- ============================================================================
-- EJERCICIO 9: Autenticación e Importación Documental
-- ============================================================================

-- 9.1 Creación del usuario administrador en la base admin (mongosh, clave oculta)
/*
use admin
db.createUser({
  user: "admin_g11",
  pwd: passwordPrompt(),
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    "readWriteAnyDatabase",
    "dbAdminAnyDatabase",
    "clusterAdmin"
  ]
})
*/
-- 9.1 Activación del control de acceso en /etc/mongod.conf (indentar con ESPACIOS, YAML no admite tabuladores)
-- Ejecución (Bash):
/*
sudo nano /etc/mongod.conf
#   security:
#     authorization: enabled
sudo systemctl restart mongod
systemctl is-active mongod
*/
-- 9.1 Autenticación con mongosh
-- Ejecución (Bash):
/*
mongosh -u "admin_g11" -p --authenticationDatabase "admin"
*/
-- 9.2 Carga masiva con mongoimport (pide la clave en cada comando)
-- Ejecución (Bash):
/*
mongoimport --host localhost --port 27017 --username admin_g11 --authenticationDatabase admin --db LabMongoDB --collection customers --file customers.json
mongoimport --host localhost --port 27017 --username admin_g11 --authenticationDatabase admin --db LabMongoDB --collection films --file films.json
mongoimport --host localhost --port 27017 --username admin_g11 --authenticationDatabase admin --db LabMongoDB --collection stores --file stores.json
*/
-- 9.2 Verificación en mongosh
/*
use LabMongoDB
db.customers.countDocuments()   // 599
db.films.countDocuments()       // 1000
db.stores.countDocuments()      // 2
*/

-- ============================================================================
-- EJERCICIO 10: Modelado Documental e Importación de Apoyo
-- ============================================================================

-- 10.1 Evidencia del diseño de esquema: tamaños embebidos e integridad de referencias (ej10_1_modelo.js)
-- Ejecución (Bash + mongosh): mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej10_1_modelo.js
/*
db = db.getSiblingDB("LabMongoDB");

const medir = (coleccion, arreglo) => db.getCollection(coleccion).aggregate([
  { $project: { b: { $bsonSize: "$$ROOT" }, n: { $size: "$" + arreglo } } },
  { $group: { _id: null, docs: { $sum: 1 }, b_prom: { $avg: "$b" }, b_max: { $max: "$b" },
              n_prom: { $avg: "$n" }, n_max: { $max: "$n" } } }
]).toArray()[0];

print("1. EMBEBIDOS: tamaño de documentos y arreglos (límite de un documento BSON: 16 MB)\n");
print("Colección  Arreglo embebido  Docs  Elem.prom  Elem.max  KB prom  KB max");
[["customers", "Rentals"], ["films", "Actors"], ["stores", "Inventory"]].forEach(([c, a]) => {
  const m = medir(c, a);
  print(c.padEnd(10) + "  " + a.padEnd(16) + String(m.docs).padStart(6) +
        m.n_prom.toFixed(1).padStart(11) + String(m.n_max).padStart(10) +
        (m.b_prom / 1024).toFixed(1).padStart(9) + (m.b_max / 1024).toFixed(1).padStart(8));
});
const pagos = db.customers.aggregate([{ $unwind: "$Rentals" },
  { $group: { _id: null, max: { $max: { $size: "$Rentals.Payments" } } } }]).toArray()[0].max;
print("Pagos por alquiler (máximo): " + pagos);

print("\n2. REFERENCIAS: ¿apuntan a documentos existentes?\n");
const huerfanos = (desde, campo, unwind, hacia, clave) => db.getCollection(desde).aggregate([
  ...(unwind ? [{ $unwind: "$" + unwind }] : []),
  { $group: { _id: "$" + campo } },
  { $lookup: { from: hacia, localField: "_id", foreignField: clave, as: "x" } },
  { $group: { _id: null, distintos: { $sum: 1 }, sin_destino: { $sum: { $cond: [{ $eq: [{ $size: "$x" }, 0] }, 1, 0] } } } }
]).toArray()[0];
[
  ["customers.Rentals.filmId -> films._id", "customers", "Rentals.filmId", "Rentals", "films", "_id"],
  ["stores.Inventory.filmId  -> films._id", "stores", "Inventory.filmId", "Inventory", "films", "_id"],
  ["customers.Country        -> paises.Name", "customers", "Country", null, "paises", "Name"],
  ["ciudades.CodP            -> paises.Code", "ciudades", "CodP", null, "paises", "Code"]
].forEach(([t, ...r]) => { const h = huerfanos(...r); print(t + "   valores distintos: " + h.distintos + "   sin destino: " + h.sin_destino); });

print("\n3. Veces que se repite cada película en los alquileres (si se embebiera completa)");
printjson(db.customers.aggregate([{ $unwind: "$Rentals" }, { $group: { _id: "$Rentals.filmId", n: { $sum: 1 } } },
  { $group: { _id: null, alquileres: { $sum: "$n" }, peliculas: { $sum: 1 }, max_repeticiones: { $max: "$n" } } },
  { $project: { _id: 0 } }]).toArray()[0]);
*/

-- 10.2 Importación de las colecciones auxiliares (archivos exportados en el 8.4)
-- Ejecución (Bash):
/*
scp vboxuser@10.13.100.64:'~/lab_integrador_g11/bloque3_datos/{ciudades,paises}.json' ~/lab_mongo/
mongoimport -u admin_g11 --authenticationDatabase admin --db LabMongoDB --collection ciudades --drop --file ciudades.json
mongoimport -u admin_g11 --authenticationDatabase admin --db LabMongoDB --collection paises --drop --file paises.json
*/

-- 10.2 Verificación de ciudades y paises (ej10_2_verificar.js)
-- Ejecución (Bash + mongosh): mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej10_2_verificar.js
/*
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto

print("Colecciones: " + JSON.stringify(db.getCollectionNames().sort()));
print("ciudades: " + db.ciudades.countDocuments() + "   (esperado 4079)");
print("paises:   " + db.paises.countDocuments() + "   (esperado 239)");

print("\n--- Una ciudad y su país (referencia CodP -> Code) ---");
printjson(db.ciudades.findOne({ Ciudad: "Resistencia" }, { _id: 0 }));
printjson(db.paises.findOne({ Code: "ARG" }, { _id: 0, Code: 1, Name: 1, geography: 1 }));

print("\n--- Países de América del Sur (filtro del Ejercicio 11) ---");
db.paises.find({ "geography.Continent": "South America" }, { _id: 0, Code: 1, Name: 1 })
  .sort({ Name: 1 }).forEach(p => print("  " + p.Code + "  " + p.Name));

print("\n--- Clientes cuyo Country no tiene país en paises (esperado: solo Runion) ---");
printjson(db.customers.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "p" } },
  { $match: { p: { $size: 0 } } },
  { $group: { _id: "$Country", clientes: { $sum: 1 } } }
]).toArray());

// Índices de apoyo para los $lookup del Ejercicio 11 (paises.Name) y para ciudades por país
print("\n--- Índices de apoyo ---");
print(db.paises.createIndex({ Name: 1 }) + " / " + db.ciudades.createIndex({ CodP: 1 }));
*/

-- ============================================================================
-- EJERCICIO 11: Pipeline de Agregación Complejo
-- ============================================================================

-- 11. Top 10 de películas más alquiladas en América del Sur (ej11_pipeline.js)
-- Ejecución (Bash + mongosh): mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej11_pipeline.js
/*
db = db.getSiblingDB("LabMongoDB");

const pipeline = [
  // 1. Cliente -> país (referencia por nombre: customers.Country = paises.Name)
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" },
  // 2. Solo clientes de América del Sur
  { $match: { "pais.geography.Continent": "South America" } },
  // 3. Un documento por alquiler (el arreglo Rentals está embebido en el cliente)
  { $unwind: "$Rentals" },
  // 4. Alquileres por película y países distintos donde se alquiló
  { $group: { _id: "$Rentals.filmId", alquileres: { $sum: 1 }, paises: { $addToSet: "$pais.Name" } } },
  // 5. Película (referencia filmId -> films._id) para el título y la categoría
  { $lookup: { from: "films", localField: "_id", foreignField: "_id", as: "pelicula" } },
  { $unwind: "$pelicula" },
  { $project: { _id: 0, filmId: "$_id", pelicula: "$pelicula.Title", categoria: "$pelicula.Category",
                alquileres: 1, paises: { $size: "$paises" } } },
  // 6. Mayor cantidad primero; desempate alfabético (13 películas empatan con 6)
  { $sort: { alquileres: -1, pelicula: 1 } },
  { $limit: 10 }
];

const top = db.customers.aggregate(pipeline).toArray();
print("Top 10 de películas más alquiladas en América del Sur\n");
print("Pos  Película                  Categoría     Alq  Países");
top.forEach((p, i) => print(
  String(i + 1).padStart(3) + "  " + p.pelicula.padEnd(24) + "  " + p.categoria.padEnd(12) +
  "  " + String(p.alquileres).padStart(3) + "  " + String(p.paises).padStart(5)));

// Control del empate en el corte: películas con la misma cantidad que el puesto 10
const corte = top[top.length - 1].alquileres;
const empatadas = db.customers.aggregate(pipeline.slice(0, 5).concat([
  { $match: { alquileres: corte } }, { $count: "n" }
])).toArray()[0].n;
print("\nPelículas con " + corte + " alquileres (empate en el corte): " + empatadas);
*/

-- ============================================================================
-- EJERCICIO 12: Validación de Esquemas y Backup Cloud
-- ============================================================================

-- 12.1 Regla $jsonSchema sobre tiendas (stores): 2 inserciones válidas y 2 rechazadas (ej12_1_validacion.js)
-- Ejecución (Bash + mongosh): mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej12_1_validacion.js
/*
db = db.getSiblingDB("LabMongoDB");

const esquema = {
  bsonType: "object",
  required: ["_id", "Address", "City", "Country", "Inventory"],
  properties: {
    _id:            { bsonType: "int", description: "número de tienda (entero)" },
    Address:        { bsonType: "string", minLength: 1 },
    City:           { bsonType: "string", minLength: 1 },
    Country:        { bsonType: "string", minLength: 1 },
    Phone:          { bsonType: "string" },
    // En stores.json viene como texto ("1"): se valida que sea texto numérico
    managerStaffId: { bsonType: "string", pattern: "^[0-9]+$" },
    Staff:          { bsonType: "array" },
    Inventory: {
      bsonType: "array",
      items: {
        bsonType: "object",
        required: ["filmId", "inventoryId", "Film Title"],
        properties: {
          filmId:       { bsonType: "int" },
          inventoryId:  { bsonType: "int" },
          "Film Title": { bsonType: "string" }
        }
      }
    }
  }
};

// 1. Antes de aplicar la regla: las tiendas existentes deben cumplirla (esperado 0).
//    Si no, mongorestore (12.2) crea la regla antes de cargar los datos y las rechaza.
print("Tiendas que NO cumplen el esquema: " + db.stores.countDocuments({ $nor: [{ $jsonSchema: esquema }] }));

// 2. Aplicar la regla a la colección existente
printjson(db.runCommand({ collMod: "stores", validator: { $jsonSchema: esquema },
                          validationLevel: "strict", validationAction: "error" }));
printjson(db.getCollectionInfos({ name: "stores" })[0].options.validationAction);

const probar = (titulo, doc) => {
  print("\n--- " + titulo + " ---");
  try {
    printjson(db.stores.insertOne(doc));
  } catch (e) {
    print(e.name + ": " + e.message);
    const det = e.errInfo && e.errInfo.details && e.errInfo.details.schemaRulesNotSatisfied;
    if (det) printjson(det);
  }
};

// 3. Inserciones VÁLIDAS
probar("VÁLIDA 1: tienda nueva con un ítem de inventario", {
  _id: 3, Address: "Av. 9 de Julio 1100", City: "Resistencia", Country: "Argentina",
  Phone: "3624000000", Staff: [],
  Inventory: [{ filmId: 1, inventoryId: 9001, "Film Title": "ACADEMY DINOSAUR" }] });
probar("VÁLIDA 2: tienda nueva con inventario vacío", {
  _id: 4, Address: "Junín 1500", City: "Corrientes", Country: "Argentina", Inventory: [] });

// 4. Inserciones INVÁLIDAS
probar("INVÁLIDA 1: falta el campo obligatorio City", {
  _id: 5, Address: "Calle sin ciudad 1", Country: "Argentina", Inventory: [] });
probar("INVÁLIDA 2: filmId del inventario como texto", {
  _id: 6, Address: "Calle 2", City: "Formosa", Country: "Argentina",
  Inventory: [{ filmId: "uno", inventoryId: 9002, "Film Title": "ACADEMY DINOSAUR" }] });

// 5. Resultado y limpieza (se borran las de prueba; la regla queda activa)
print("\nTiendas: " + JSON.stringify(db.stores.find({}, { _id: 1, City: 1 }).sort({ _id: 1 }).toArray()));
print("Borradas las de prueba: " + db.stores.deleteMany({ _id: { $in: [3, 4] } }).deletedCount +
      " | tiendas finales: " + db.stores.countDocuments());
*/

-- 12.2 Respaldo con mongodump y restauración en LabMongoDB_Restore (ej12_2_backup.sh)
-- Ejecución (Bash): ./ej12_2_backup.sh
/*
set -euo pipefail
AUTH=(--host 127.0.0.1:27017 --username admin_g11 --authenticationDatabase admin)
[ -n "${MONGO_TOOLS_CONFIG:-}" ] && AUTH+=(--config "$MONGO_TOOLS_CONFIG")
DESTINO="$HOME/backup_labmongodb"

echo "=== 1. Respaldo de LabMongoDB"
rm -rf "$DESTINO"
mongodump "${AUTH[@]}" --db LabMongoDB --out "$DESTINO"

echo; echo "=== 2. Archivos generados (.bson = datos, .metadata.json = índices y opciones)"
ls -lh "$DESTINO/LabMongoDB/"
echo "documentos en stores.bson: $(bsondump --quiet "$DESTINO/LabMongoDB/stores.bson" | wc -l)"

echo; echo "=== 3. Restauración en LabMongoDB_Restore (no pisa la base original)"
mongorestore "${AUTH[@]}" --drop \
  --nsInclude 'LabMongoDB.*' --nsFrom 'LabMongoDB.*' --nsTo 'LabMongoDB_Restore.*' \
  "$DESTINO"
*/

-- 12.2 Comparación LabMongoDB vs LabMongoDB_Restore (ej12_2_verificar.js)
-- Ejecución (Bash + mongosh): mongosh "mongodb://127.0.0.1:27017/admin" --authenticationDatabase admin -u admin_g11 --file ej12_2_verificar.js
/*
const orig = db.getSiblingDB("LabMongoDB"), rest = db.getSiblingDB("LabMongoDB_Restore");

print("Colección     LabMongoDB  LabMongoDB_Restore  Índices(orig/rest)  ¿Igual?");
orig.getCollectionNames().sort().forEach(c => {
  const a = orig.getCollection(c).countDocuments(), b = rest.getCollection(c).countDocuments();
  const ia = orig.getCollection(c).getIndexes().length, ib = rest.getCollection(c).getIndexes().length;
  print(c.padEnd(12) + String(a).padStart(11) + String(b).padStart(20) +
        (ia + "/" + ib).padStart(20) + "  " + (a === b && ia === ib ? "SÍ" : "NO"));
});

// La regla $jsonSchema del 12.1 viaja en el .metadata.json y queda activa en la copia
const v = rest.getCollectionInfos({ name: "stores" })[0].options;
print("\nValidador en LabMongoDB_Restore.stores: " + (v.validator ? "presente (" + v.validationAction + ")" : "NO"));

// El mismo pipeline del Ejercicio 11 sobre la copia da el mismo primer puesto
printjson(rest.customers.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" }, { $match: { "pais.geography.Continent": "South America" } },
  { $unwind: "$Rentals" }, { $group: { _id: "$Rentals.Film Title", alquileres: { $sum: 1 } } },
  { $sort: { alquileres: -1, _id: 1 } }, { $limit: 1 }
]).toArray());
*/

-- 12.2 (Alternativa cloud) Restauración del mismo respaldo en MongoDB Atlas (cluster SGBD-U10-Grupo11)
-- Requisito: IP pública autorizada en Atlas > Security > Network Access
-- Ejecución (Bash):
/*
mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --quiet --eval 'printjson({ conectado: db.hello().isWritablePrimary, nodos: db.hello().hosts.length })'
mongorestore --uri "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --username admin_grupo11 --nsInclude 'LabMongoDB.*' --nsFrom 'LabMongoDB.*' --nsTo 'LabMongoDB_Restore.*' --drop ~/backup_labmongodb
mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/LabMongoDB_Restore" --username admin_grupo11 --quiet --eval 'db.getCollectionNames().sort().forEach(c => print(c.padEnd(12) + db.getCollection(c).countDocuments()))'
*/
