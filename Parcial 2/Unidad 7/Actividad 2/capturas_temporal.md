# Capturas temporales — U7 Actividad 2 (G11)

> **Archivo temporal para sacar capturas.** Cada bloque reproduce, con formato de terminal, salidas **reales** de la VM `LinuxE` (MySQL 9.7.2) guardadas en `evidencias_salidas/`. Donde la corrida original no registró el tiempo de una sentencia, la línea se muestra sin tiempo.
>
> Abrilo con la vista previa de VS Code (`Cmd+Shift+V`) y sacá una captura por evidencia. Al terminar se puede borrar.


## Evidencia 1 — Verificación del entorno (Fase A.1)


```text
vboxuser@LinuxE:~$ mysql --version
mysql  Ver 9.7.2 for Linux on x86_64 (MySQL Community Server - GPL)
vboxuser@LinuxE:~$ sudo mysql

mysql> SELECT VERSION() AS version, @@version_comment AS edicion, @@hostname AS host,
    ->        @@default_storage_engine AS motor_default;
+---------+------------------------------+--------+---------------+
| version | edicion                      | host   | motor_default |
+---------+------------------------------+--------+---------------+
| 9.7.2   | MySQL Community Server - GPL | LinuxE | InnoDB        |
+---------+------------------------------+--------+---------------+
1 row in set

mysql> SHOW VARIABLES LIKE 'innodb_ft%';
+---------------------------------+------------+
| Variable_name                   | Value      |
+---------------------------------+------------+
| innodb_ft_aux_table             |            |
| innodb_ft_cache_size            |    8000000 |
| innodb_ft_enable_diag_print     | OFF        |
| innodb_ft_enable_stopword       | ON         |
| innodb_ft_max_token_size        |         84 |
| innodb_ft_min_token_size        |          3 |
| innodb_ft_num_word_optimize     |       2000 |
| innodb_ft_result_cache_limit    | 2000000000 |
| innodb_ft_server_stopword_table |            |
| innodb_ft_sort_pll_degree       |          2 |
| innodb_ft_total_cache_size      |  640000000 |
| innodb_ft_user_stopword_table   |            |
+---------------------------------+------------+
12 rows in set

mysql> SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_TYPE FROM information_schema.PLUGINS
    -> WHERE PLUGIN_NAME = 'ngram' OR PLUGIN_NAME LIKE 'INNODB_FT%';
+----------------------------+---------------+--------------------+
| PLUGIN_NAME                | PLUGIN_STATUS | PLUGIN_TYPE        |
+----------------------------+---------------+--------------------+
| INNODB_FT_DEFAULT_STOPWORD | ACTIVE        | INFORMATION SCHEMA |
| INNODB_FT_DELETED          | ACTIVE        | INFORMATION SCHEMA |
| INNODB_FT_BEING_DELETED    | ACTIVE        | INFORMATION SCHEMA |
| INNODB_FT_CONFIG           | ACTIVE        | INFORMATION SCHEMA |
| INNODB_FT_INDEX_CACHE      | ACTIVE        | INFORMATION SCHEMA |
| INNODB_FT_INDEX_TABLE      | ACTIVE        | INFORMATION SCHEMA |
| ngram                      | ACTIVE        | FTPARSER           |
+----------------------------+---------------+--------------------+
7 rows in set
```

## Evidencia 2 — Confirmación de habilitación (Fase A.3 – A.5)


**2a. Limitación detectada con la configuración de fábrica (prueba de humo):**


```text
mysql> SELECT id, texto, MATCH(texto) AGAINST('gaming') AS score
    -> FROM prueba_humo WHERE MATCH(texto) AGAINST('gaming');
+----+-------------------------------+---------------------+
| id | texto                         | score               |
+----+-------------------------------+---------------------+
|  2 | Notebook gaming con placa RTX | 0.22764469683170319 |
+----+-------------------------------+---------------------+
1 row in set (0.002 sec)

mysql> SELECT COUNT(*) AS filas_tv_4k FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');
+-------------+
| filas_tv_4k |
+-------------+
|           0 |
+-------------+
1 row in set (0.005 sec)

mysql> SELECT WORD, DOC_COUNT FROM information_schema.INNODB_FT_INDEX_CACHE ORDER BY WORD;
+----------+-----------+
| WORD     | DOC_COUNT |
+----------+-----------+
| bar      |         1 |
| cafetera |         1 |
| con      |         2 |
| con      |         2 |
| espresso |         1 |
| gaming   |         1 |
| google   |         1 |
| hdr      |         1 |
| notebook |         1 |
| placa    |         1 |
| rtx      |         1 |
| smart    |         1 |
+----------+-----------+
12 rows in set (0.001 sec)
```

**2b. Configuración del servidor y reinicio:**


```text
vboxuser@LinuxE:~$ sudo tee /etc/mysql/mysql.conf.d/u7_fulltext.cnf <<'EOF'
> [mysqld]
> # U7 Act. 2 - indexar siglas tecnicas de 2 caracteres (TV, 4K, HP, Hz)
> innodb_ft_min_token_size = 2
> EOF
[mysqld]
# U7 Act. 2 - indexar siglas tecnicas de 2 caracteres (TV, 4K, HP, Hz)
innodb_ft_min_token_size = 2
vboxuser@LinuxE:~$ sudo systemctl restart mysql
vboxuser@LinuxE:~$ systemctl is-active mysql
active
vboxuser@LinuxE:~$ sudo tail -n 2 /var/log/mysql/error.log
2026-10-25T20:30:28.767519Z 0 [System] [MY-011323] [Server] X Plugin ready for connections. Bind-address: '::' port: 33060, socket: /var/run/mysqld/mysqlx.sock
2026-10-25T20:30:28.767934Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '9.7.2'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
```

**2c. Verificación post-activación y reconstrucción del índice:**


```text
mysql> SELECT VARIABLE_NAME, VARIABLE_VALUE, VARIABLE_SOURCE, VARIABLE_PATH
    -> FROM performance_schema.variables_info
    -> JOIN performance_schema.global_variables USING (VARIABLE_NAME)
    -> WHERE VARIABLE_NAME = 'innodb_ft_min_token_size';
+--------------------------+----------------+-----------------+-----------------------------------------+
| VARIABLE_NAME            | VARIABLE_VALUE | VARIABLE_SOURCE | VARIABLE_PATH                           |
+--------------------------+----------------+-----------------+-----------------------------------------+
| innodb_ft_min_token_size |              2 | GLOBAL          | /etc/mysql/mysql.conf.d/u7_fulltext.cnf |
+--------------------------+----------------+-----------------+-----------------------------------------+
1 row in set (0.012 sec)

mysql> SELECT COUNT(*) AS filas_tv_4k FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');
+-------------+
| filas_tv_4k |
+-------------+
|           0 |
+-------------+
1 row in set (0.030 sec)

mysql> ALTER TABLE prueba_humo DROP INDEX ft_texto;
Query OK, 0 rows affected (0.204 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> ALTER TABLE prueba_humo ADD FULLTEXT KEY ft_texto (texto);
Query OK, 0 rows affected (0.389 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> SELECT id, texto, MATCH(texto) AGAINST('TV 4K') AS score
    -> FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');
+----+---------------------------------+--------------------+
| id | texto                           | score              |
+----+---------------------------------+--------------------+
|  1 | Smart TV 4K con HDR y Google TV | 0.6829341053962708 |
+----+---------------------------------+--------------------+
1 row in set (0.003 sec)

mysql> SELECT WORD, DOC_COUNT FROM information_schema.INNODB_FT_INDEX_TABLE ORDER BY WORD;
+----------+-----------+
| WORD     | DOC_COUNT |
+----------+-----------+
|       15 |         1 |
| 4k       |         1 |
| bar      |         1 |
| cafetera |         1 |
| con      |         2 |
| con      |         2 |
| espresso |         1 |
| gaming   |         1 |
| google   |         1 |
| hdr      |         1 |
| notebook |         1 |
| placa    |         1 |
| rtx      |         1 |
| smart    |         1 |
| tv       |         1 |
| tv       |         1 |
+----------+-----------+
16 rows in set (0.001 sec)
```

## Evidencia 3 — Consultas sobre el catálogo, antes de indexar (Fase B.2)


```text
mysql> SELECT id, nombre, categoria, precio, stock
    -> FROM producto
    -> WHERE precio BETWEEN 300000 AND 900000 AND stock >= 5
    -> ORDER BY precio;
+----+----------------------+-------------+-----------+-------+
| id | nombre               | categoria   | precio    | stock |
+----+----------------------+-------------+-----------+-------+
| 10 | Taladro Pro 18V      | herramienta | 310000.00 |    14 |
| 17 | Cafetera Barista     | cafetera    | 350000.00 |    10 |
| 15 | Monitor Work 27      | monitor     | 420000.00 |    13 |
| 20 | Switch 24G Managed   | redes       | 510000.00 |     5 |
| 12 | Compresor 50L        | herramienta | 540000.00 |     6 |
|  5 | Heladera Compact 280 | heladera    | 690000.00 |     9 |
| 16 | Monitor Game 32      | monitor     | 690000.00 |     8 |
| 13 | Smart TV Nova 55     | televisor   | 820000.00 |     7 |
+----+----------------------+-------------+-----------+-------+
8 rows in set (0.002 sec)

mysql> EXPLAIN SELECT id, nombre, precio FROM producto
    -> WHERE precio BETWEEN 300000 AND 900000 AND stock >= 5\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: (producto.stock >= 5)  (cost=4.31 rows=3)
    -> Index range scan on producto using idx_precio over (300000.00 <= precio <= 900000.00), with index condition: (producto.precio between 300000 and 900000)  (cost=4.31 rows=9)

1 row in set (0.002 sec)

mysql> SELECT id, nombre, tags FROM producto WHERE 'gaming' MEMBER OF (tags);
+----+-------------------+--------------------------------+
| id | nombre            | tags                           |
+----+-------------------+--------------------------------+
|  2 | Notebook Titan 16 | ["gaming", "gpu", "alta-gama"] |
| 16 | Monitor Game 32   | ["gaming", "alta-frecuencia"]  |
+----+-------------------+--------------------------------+
2 rows in set (0.001 sec)

mysql> EXPLAIN SELECT id, nombre FROM producto WHERE 'gaming' MEMBER OF (tags)\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: <cache>('gaming') member of (producto.tags)  (cost=2.25 rows=20)
    -> Table scan on producto  (cost=2.25 rows=20)

1 row in set (0.001 sec)

mysql> SELECT id, nombre, atributos->'$.talles' AS talles, atributos->>'$.material' AS material
    -> FROM producto
    -> WHERE categoria = 'calzado' AND 42 MEMBER OF (atributos->'$.talles');
+----+-----------------+----------------------+----------+
| id | nombre          | talles               | material |
+----+-----------------+----------------------+----------+
|  7 | Zapatilla Run X | [39, 40, 41, 42, 43] | mesh     |
|  8 | Bota Trek Pro   | [40, 41, 42, 43, 44] | cuero    |
+----+-----------------+----------------------+----------+
2 rows in set (0.002 sec)

mysql> EXPLAIN SELECT id, nombre FROM producto
    -> WHERE descripcion LIKE '%gaming%' OR nombre LIKE '%gaming%'\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: ((producto.descripcion like '%gaming%') or (producto.nombre like '%gaming%'))  (cost=2.25 rows=4.2)
    -> Table scan on producto  (cost=2.25 rows=20)

1 row in set (0.001 sec)

mysql> SELECT id FROM producto WHERE MATCH(nombre, descripcion) AGAINST('gaming');
ERROR 1191 (HY000): Can't find FULLTEXT index matching the column list
```

## Evidencia 4 — Habilitación sobre el caso: intervención física (Fase B.3)


```text
mysql> SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';
Query OK, 0 rows affected

mysql> CREATE FULLTEXT INDEX ft_producto_texto ON producto (nombre, descripcion);
Query OK, 0 rows affected, 1 warning (0.832 sec)
Records: 0  Duplicates: 0  Warnings: 1

mysql> SHOW WARNINGS;
+---------+------+--------------------------------------------------+
| Level   | Code | Message                                          |
+---------+------+--------------------------------------------------+
| Warning |  124 | InnoDB rebuilding table to add column FTS_DOC_ID |
+---------+------+--------------------------------------------------+
1 row in set

mysql> CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));
Query OK, 0 rows affected (0.211 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> SHOW INDEX FROM producto\G
*************************** 1. row ***************************
        Table: producto
   Non_unique: 0
     Key_name: PRIMARY
 Seq_in_index: 1
  Column_name: id
    Collation: A
  Cardinality: 20
     Sub_part: NULL
       Packed: NULL
         Null: 
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
*************************** 2. row ***************************
        Table: producto
   Non_unique: 1
     Key_name: idx_precio
 Seq_in_index: 1
  Column_name: precio
    Collation: A
  Cardinality: 19
     Sub_part: NULL
       Packed: NULL
         Null: 
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
*************************** 3. row ***************************
        Table: producto
   Non_unique: 1
     Key_name: idx_tags_mv
 Seq_in_index: 1
  Column_name: NULL
    Collation: A
  Cardinality: 20
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: cast(`tags` as char(30) array)
*************************** 4. row ***************************
        Table: producto
   Non_unique: 1
     Key_name: ft_producto_texto
 Seq_in_index: 1
  Column_name: nombre
    Collation: NULL
  Cardinality: 20
     Sub_part: NULL
       Packed: NULL
         Null: 
   Index_type: FULLTEXT
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
*************************** 5. row ***************************
        Table: producto
   Non_unique: 1
     Key_name: ft_producto_texto
 Seq_in_index: 2
  Column_name: descripcion
    Collation: NULL
  Cardinality: 20
     Sub_part: NULL
       Packed: NULL
         Null: 
   Index_type: FULLTEXT
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
5 rows in set (0.147 sec)

mysql> SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/producto';
Query OK, 0 rows affected

mysql> SELECT COUNT(DISTINCT WORD) AS terminos_indexados FROM information_schema.INNODB_FT_INDEX_TABLE;
+--------------------+
| terminos_indexados |
+--------------------+
|                289 |
+--------------------+
1 row in set (0.005 sec)

mysql> SELECT DISTINCT WORD FROM information_schema.INNODB_FT_INDEX_TABLE
    -> WHERE WORD IN ('de','con','para','tv','4k','hp','hz','ms','va');
+------+
| WORD |
+------+
| 4k   |
| hp   |
| hz   |
| ms   |
| tv   |
| va   |
+------+
6 rows in set (0.002 sec)
```

**4b. (opcional) El índice ya se usa en las consultas:**


```text
mysql> SELECT id, nombre,
    ->        ROUND(MATCH(nombre, descripcion) AGAINST('notebook gaming RTX'), 4) AS relevancia
    -> FROM producto
    -> WHERE MATCH(nombre, descripcion) AGAINST('notebook gaming RTX')
    -> ORDER BY relevancia DESC;
+----+-------------------+------------+
| id | nombre            | relevancia |
+----+-------------------+------------+
|  2 | Notebook Titan 16 |     4.6927 |
|  1 | Notebook Atlas 14 |          2 |
| 16 | Monitor Game 32   |          1 |
+----+-------------------+------------+
3 rows in set (0.002 sec)

mysql> EXPLAIN SELECT id, nombre FROM producto
    -> WHERE MATCH(nombre, descripcion) AGAINST('notebook gaming RTX')\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: (match producto.nombre,producto.descripcion against ('notebook gaming RTX'))  (cost=0.35 rows=1)
    -> Full-text index search on producto using ft_producto_texto (nombre = 'notebook gaming RTX')  (cost=0.35 rows=1)

1 row in set (0.001 sec)

mysql> EXPLAIN SELECT id, nombre FROM producto WHERE 'gaming' MEMBER OF (tags)\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: json'"gaming"' member of (cast(tags as char(30) array))  (cost=0.7 rows=2)
    -> Index lookup on producto using idx_tags_mv (cast(tags as char(30) array) = json'"gaming"')  (cost=0.7 rows=2)

1 row in set (0.002 sec)

mysql> SELECT id, nombre FROM producto
    -> WHERE MATCH(nombre, descripcion) AGAINST('+TV +4K' IN BOOLEAN MODE);
+----+--------------------+
| id | nombre             |
+----+--------------------+
| 13 | Smart TV Nova 55   |
| 14 | Smart TV Cinema 65 |
+----+--------------------+
2 rows in set (0.003 sec)
```

## Evidencia 5 — Comparación de planes y métricas con 200.000 filas (Fase B.4)


**5a. ANTES — sin índice FULLTEXT (`LIKE`):**


```text
mysql> SELECT COUNT(*) AS filas FROM producto_masivo;
+--------+
| filas  |
+--------+
| 200000 |
+--------+
1 row in set (0.025 sec)

mysql> FLUSH STATUS;
Query OK, 0 rows affected

mysql> SELECT id, nombre FROM producto_masivo WHERE descripcion LIKE '%SKU0123457%';
+--------+------------------------+
| id     | nombre                 |
+--------+------------------------+
| 123457 | Cafetera Barista #6172 |
+--------+------------------------+
1 row in set (0.638 sec)

mysql> SHOW SESSION STATUS LIKE 'Handler_read%';
+-----------------------+--------+
| Variable_name         | Value  |
+-----------------------+--------+
| Handler_read_first    |      1 |
| Handler_read_key      |      1 |
| Handler_read_last     |      0 |
| Handler_read_next     |      0 |
| Handler_read_prev     |      0 |
| Handler_read_rnd      |      0 |
| Handler_read_rnd_next | 200001 |
+-----------------------+--------+
7 rows in set (0.001 sec)

mysql> EXPLAIN ANALYZE SELECT id, nombre FROM producto_masivo WHERE descripcion LIKE '%SKU0123457%'\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: (producto_masivo.descripcion like '%SKU0123457%')  (cost=22541 rows=23130) (actual time=408..632 rows=1 loops=1)
    -> Table scan on producto_masivo  (cost=22541 rows=208187) (actual time=0.0383..213 rows=200000 loops=1)

1 row in set (0.633 sec)
```

**5b. Intervención — creación del índice sobre 200.000 filas:**


```text
mysql> ALTER TABLE producto_masivo ADD FULLTEXT KEY ft_masivo_texto (nombre, descripcion);
Query OK, 0 rows affected, 1 warning (50.199 sec)
Records: 0  Duplicates: 0  Warnings: 1

mysql> SHOW WARNINGS;
+---------+------+--------------------------------------------------+
| Level   | Code | Message                                          |
+---------+------+--------------------------------------------------+
| Warning |  124 | InnoDB rebuilding table to add column FTS_DOC_ID |
+---------+------+--------------------------------------------------+
1 row in set (0.002 sec)
```

**5c. DESPUÉS — con índice FULLTEXT (`MATCH ... AGAINST`):**


```text
mysql> FLUSH STATUS;
Query OK, 0 rows affected

mysql> SELECT id, nombre FROM producto_masivo
    -> WHERE MATCH(nombre, descripcion) AGAINST('+SKU0123457' IN BOOLEAN MODE);
+--------+------------------------+
| id     | nombre                 |
+--------+------------------------+
| 123457 | Cafetera Barista #6172 |
+--------+------------------------+
1 row in set (0.005 sec)

mysql> SHOW SESSION STATUS LIKE 'Handler_read%';
+-----------------------+-------+
| Variable_name         | Value |
+-----------------------+-------+
| Handler_read_first    |     0 |
| Handler_read_key      |     0 |
| Handler_read_last     |     0 |
| Handler_read_next     |     0 |
| Handler_read_prev     |     0 |
| Handler_read_rnd      |     0 |
| Handler_read_rnd_next |     0 |
+-----------------------+-------+
7 rows in set (0.003 sec)

mysql> EXPLAIN ANALYZE SELECT id, nombre FROM producto_masivo
    -> WHERE MATCH(nombre, descripcion) AGAINST('+SKU0123457' IN BOOLEAN MODE)\G
*************************** 1. row ***************************
EXPLAIN: -> Filter: (match producto_masivo.nombre,producto_masivo.descripcion against ('+SKU0123457' in boolean mode))  (cost=1.1 rows=1) (actual time=0.085..0.0857 rows=1 loops=1)
    -> Full-text index search on producto_masivo using ft_masivo_texto (nombre = '+SKU0123457')  (cost=1.1 rows=1) (actual time=0.0298..0.0304 rows=1 loops=1)

1 row in set (0.002 sec)
```

**5d. (opcional) Término frecuente y costo de escritura:**


```text
-- ANTES (sin índice)
mysql> SELECT COUNT(*) AS m1_like FROM producto_masivo
    -> WHERE nombre LIKE '%gaming%' OR descripcion LIKE '%gaming%';
+---------+
| m1_like |
+---------+
|   20000 |
+---------+
1 row in set (0.322 sec)

mysql> UPDATE producto_masivo SET descripcion = CONCAT(descripcion, ' ') WHERE id <= 20000;
Query OK, 20000 rows affected (0.597 sec)
Rows matched: 20000  Changed: 20000  Warnings: 0

-- DESPUÉS (con índice FULLTEXT)
mysql> SELECT COUNT(*) AS m1_fts FROM producto_masivo
    -> WHERE MATCH(nombre, descripcion) AGAINST('gaming' IN BOOLEAN MODE);
+--------+
| m1_fts |
+--------+
|  20000 |
+--------+
1 row in set (0.020 sec)

mysql> UPDATE producto_masivo SET descripcion = CONCAT(descripcion, ' ') WHERE id <= 20000;
Query OK, 20000 rows affected (2.830 sec)
Rows matched: 20000  Changed: 20000  Warnings: 0
```
