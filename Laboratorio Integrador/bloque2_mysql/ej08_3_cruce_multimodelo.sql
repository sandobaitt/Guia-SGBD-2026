-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 8.3 - Cruce multimodelo: documentos JSON de clientes (zakila_json)
-- con la tabla countryinfo de world_x -> Top 10 de películas más alquiladas en
-- América del Sur
--   mysql -t -h 127.0.0.1 -u usr_g11 < ej08_3_cruce_multimodelo.sql
--
-- Cruce: customers.doc->>'$.Country' (nombre del país, en inglés)
--        = countryinfo.doc->>'$.Name', filtrando geography.Continent.
-- JSON_TABLE convierte el arreglo Rentals de cada cliente en filas relacionales.
-- =============================================================================
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
