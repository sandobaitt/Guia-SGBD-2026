# Guía Paso a Paso: U7 - Actividad 2 (Laboratorio Bisagra)
**Grupo:** G11 (Caso: Catálogo técnico multirubro)  
**Motor:** MySQL Community Server 9.7.2 LTS sobre Ubuntu 24.04 (VM `LinuxE`)  
**Capacidad:** Full-Text Search (FULLTEXT + `MATCH ... AGAINST`) + índice multivaluado JSON  
**Archivos:** `solucion_u7_actividad2.sql` (script completo) · `evidencias_salidas/` (salidas reales de referencia)

---

## 0. Conexión a la VM (por SSH o desde la consola de VirtualBox)

### 0.1. Conectarse
Desde otra PC de la misma red:
```bash
ssh vboxuser@192.168.1.42
```
*(Si la IP cambió, en la VM ejecutar `ip -4 addr` y buscar la interfaz en modo puente.)*

### 0.2. Copiar el script a la VM
Desde la PC donde está el repositorio:
```bash
scp "Parcial 2/Unidad 7/Actividad 2/solucion_u7_actividad2.sql" vboxuser@192.168.1.42:~/u7_act2/
```
*(Crear la carpeta antes con `ssh vboxuser@192.168.1.42 'mkdir -p ~/u7_act2'`.)*

### 0.3. Entrar a MySQL como administrador
En Ubuntu, `root@localhost` se autentica con `auth_socket`: no usa contraseña de MySQL sino el usuario del sistema.
```bash
sudo mysql                 # pide la contraseña de Linux de vboxuser
```
Para ejecutar un bloque del script mostrando cada sentencia y su tiempo:
```bash
sudo mysql -t -vvv < bloque.sql
```
> **Tip para las capturas:** `-t` dibuja las tablas con bordes y `-vvv` imprime la sentencia y `(x.xxx sec)`, lo que sirve de evidencia de tiempos.

---

## 1. Fase A.1: Baseline del entorno (Sección 0 del script)

```bash
mysql --version
```
```sql
SELECT VERSION(), @@version_comment, @@hostname, @@default_storage_engine;
SHOW VARIABLES LIKE 'innodb_ft%';
SHOW VARIABLES LIKE 'ngram_token_size';
SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_TYPE FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'ngram' OR PLUGIN_NAME LIKE 'INNODB_FT%';
SELECT COUNT(*) FROM information_schema.INNODB_FT_DEFAULT_STOPWORD;
```
**Valores esperados (de fábrica):**
- `9.7.2` — MySQL Community Server - GPL — InnoDB
- `innodb_ft_min_token_size = 3`, `innodb_ft_enable_stopword = ON`
- `ngram` ACTIVE, tablas `INNODB_FT_*` ACTIVE
- 36 stopwords por defecto (en inglés)

*(Tomar captura: **Evidencia 1 — verificación del entorno**.)*

---

## 2. Fase A.3: Prueba de humo con configuración de fábrica (Sección 1)

Ejecutar la Sección 1 del script. Crea la base `sgbd_u7_act2` y una tabla `prueba_humo` con 3 filas e índice FULLTEXT.

**Resultados esperados:**
| Consulta | Resultado |
| :--- | :--- |
| `MATCH(texto) AGAINST('gaming')` | id 2, score ≈ 0,2276 → FTS funciona |
| `COUNT(*) ... AGAINST('TV 4K')` | **0** → las siglas de 2 letras no se indexan |
| `INNODB_FT_INDEX_CACHE` | aparecen `gaming`, `rtx`, `hdr`… pero **no** `tv`, `4k`, `15` |
| `COUNT(*) FROM INNODB_FT_INDEX_TABLE` | 0 → las filas recién insertadas siguen en la caché |

> **Antes de consultar las tablas `INNODB_FT_*`** hay que indicar qué tabla inspeccionar:  
> `SET GLOBAL innodb_ft_aux_table = 'sgbd_u7_act2/prueba_humo';`  
> Para volver al valor original usar `SET GLOBAL innodb_ft_aux_table = DEFAULT;` (con `''` da ERROR 1231).

---

## 3. Fase A.4: Activación / configuración (bloque [BASH])

`innodb_ft_min_token_size` **no se puede cambiar con `SET GLOBAL`** (es de solo lectura). Se agrega un archivo de opciones propio, así se puede revertir sin tocar el `mysqld.cnf` original:

```bash
sudo tee /etc/mysql/mysql.conf.d/u7_fulltext.cnf <<'EOF'
[mysqld]
# U7 Act. 2 - indexar siglas tecnicas de 2 caracteres (TV, 4K, HP, Hz)
innodb_ft_min_token_size = 2
EOF

sudo systemctl restart mysql
systemctl is-active mysql                     # debe decir: active
sudo tail -n 3 /var/log/mysql/error.log       # "ready for connections. Version: '9.7.2'"
```
*(El reinicio tarda ~11 s. Si el servicio no levanta, revisar el `error.log`: un error de tipeo en el `.cnf` impide el arranque.)*

---

## 4. Fase A.5: Verificación post-activación (Sección 2)

```sql
USE sgbd_u7_act2;
SELECT VARIABLE_NAME, VARIABLE_VALUE, VARIABLE_SOURCE, VARIABLE_PATH
FROM performance_schema.variables_info
JOIN performance_schema.global_variables USING (VARIABLE_NAME)
WHERE VARIABLE_NAME = 'innodb_ft_min_token_size';
```
**Esperado:** `2 | GLOBAL | /etc/mysql/mysql.conf.d/u7_fulltext.cnf`.

Luego:
1. `SELECT COUNT(*) ... AGAINST('TV 4K')` → **sigue en 0**: el índice viejo no se actualiza solo.
2. Reconstruir el índice **en dos sentencias separadas**:
   ```sql
   ALTER TABLE prueba_humo DROP INDEX ft_texto;
   ALTER TABLE prueba_humo ADD FULLTEXT KEY ft_texto (texto);
   ```
   > ⚠️ **Trampa comprobada:** `ALTER TABLE prueba_humo DROP INDEX ft_texto, ADD FULLTEXT KEY ft_texto (texto);` en **una sola** sentencia **no** reconstruye nada (InnoDB ve la misma definición y solo toca metadatos). El resultado sigue en 0.
3. `AGAINST('TV 4K')` → **id 1, score ≈ 0,6829**. En `INNODB_FT_INDEX_TABLE` ahora aparecen `15`, `4k` y `tv`.

*(Tomar captura: **Evidencia 2 — confirmación de habilitación**.)*

---

## 5. Fase B.1: Esquema híbrido y carga (Sección 3)

La sección hace cuatro cosas:
1. Crea `stopwords_es` (30 palabras vacías en español). Hace falta porque con mínimo 2 se indexarían `el`, `un`, `con`…
2. Carga el JSONL **tal cual** en `catalogo_raw (linea JSON)`, una línea por fila.
3. Carga `descripcion_carga` con 20 descripciones comerciales (el texto libre para FTS).
4. Crea `producto` (núcleo relacional + `atributos JSON` + `tags JSON` + `descripcion TEXT`) y lo puebla con `INSERT ... SELECT` usando `->` y `->>`.

**Validación esperada:**
| productos | categorias | esquemas_de_atributos_distintos |
| :---: | :---: | :---: |
| 20 | 9 | 17 |

> **Alternativa a pegar el JSONL en el script:** copiar `U7_catalogo_multimodelo.jsonl` a `/var/lib/mysql-files/` (directorio de `secure_file_priv`) y cargarlo con  
> `LOAD DATA INFILE '/var/lib/mysql-files/U7_catalogo_multimodelo.jsonl' INTO TABLE catalogo_raw (linea);`

---

## 6. Fase B.2: Consultas ANTES de la intervención (Sección 4)

| Consulta | Qué demuestra | Plan esperado |
| :--- | :--- | :--- |
| **Q1** `precio BETWEEN 300000 AND 900000 AND stock >= 5` | filtro escalar relacional → 8 filas | `Index range scan ... using idx_precio` |
| **Q2a** `'gaming' MEMBER OF (tags)` | etiqueta en array JSON → Titan 16, Monitor Game 32 | `Table scan on producto` |
| **Q2b** `42 MEMBER OF (atributos->'$.talles')` | colección anidada → Zapatilla Run X, Bota Trek Pro | `Table scan` |
| **Q2c** `atributos->'$.ram_gb' >= 16 AND atributos->>'$.gpu' <> 'integrada'` | atributo anidado → Titan 16 | `Table scan` |
| **Q3** `descripcion LIKE '%gaming%' OR nombre LIKE '%gaming%'` | texto sin FTS | `Table scan` |

Probar además (a mano, porque corta la ejecución del script):
```sql
SELECT id FROM producto WHERE MATCH(nombre, descripcion) AGAINST('gaming');
-- ERROR 1191 (HY000): Can't find FULLTEXT index matching the column list
```
*(Tomar captura: **Evidencia 3 — consultas sobre el catálogo**.)*

---

## 7. Fase B.3: Intervención física (Sección 5)

```sql
SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';  -- ¡antes de crear el índice!
CREATE FULLTEXT INDEX ft_producto_texto ON producto (nombre, descripcion);
SHOW WARNINGS;   -- Warning 124: InnoDB rebuilding table to add column FTS_DOC_ID
CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));
SHOW INDEX FROM producto;
```
**Esperado:**
- `SHOW INDEX`: `PRIMARY`, `idx_precio` (BTREE), `idx_tags_mv` (BTREE con `Expression = cast(tags as char(30) array)`), `ft_producto_texto` (FULLTEXT, 2 columnas).
- 289 términos en el índice; los más frecuentes son `pulgadas` (7) y `litros` (5).
- Están `4k`, `hp`, `hz`, `ms`, `tv`, `va` y **no** están `de`, `con`, `para`.
- 11 tablas auxiliares `fts_..._index_1..6`, `deleted`, `config`… de 112 KB cada una (1,2 MB en total contra 0,2 MB de la tabla).

> El `SET SESSION innodb_ft_user_stopword_table` solo afecta a los índices creados **en esa misma sesión**. Si se crea el índice desde otra conexión sin ese `SET`, queda con la lista en inglés.

*(Tomar captura: **Evidencia 4 — habilitación sobre el caso**.)*

---

## 8. Fase B.4: Consultas DESPUÉS de la intervención (Sección 6)

| Consulta | Resultado esperado |
| :--- | :--- |
| `EXPLAIN ... 'gaming' MEMBER OF (tags)` | `Index lookup on producto using idx_tags_mv` (cost 0.7) |
| `EXPLAIN ... JSON_OVERLAPS(tags,'["gaming","oled"]')` | `Index range scan ... idx_tags_mv` → 3 filas |
| Natural `'notebook gaming RTX'` | Titan 16 (4,69) > Atlas 14 (2,0) > Monitor Game 32 (1,0) — plan `Full-text index search` |
| Booleano `'+gaming -notebook'` | Monitor Game 32 |
| Frase `'"alta frecuencia"'` | Titan 16, Monitor Game 32 |
| Comodín `'inalambr*'` | Taladro Pro 18V |
| `'+TV +4K'` | los dos Smart TV (gracias a la Fase A) |
| `'cafe'` | las dos cafeteras ("café" con tilde) |
| Híbrida FTS + precio + `JSON_CONTAINS_PATH` | Smart TV Nova 55, Monitor Work 27, Monitor Game 32 |
| `'espresso' WITH QUERY EXPANSION` | cafeteras + ruido (compresor, heladeras, freezer) |
| Límites `juegos / juego / notebok / juego*` | 2 / 0 / 0 / 2 |
| `EXPLAIN ... LIKE '%gaming%'` (con índice ya creado) | sigue `Table scan` |

---

## 9. Fase B.4: Medición a escala con 200.000 filas (Sección 7)

**Duración total aproximada: 1,5 a 2 minutos** (inserción ~15 s, índice ~50 s).

1. Crea `producto_masivo` (misma estructura sin FULLTEXT) y le inserta 200.000 filas (20 productos × 10.000 copias, cada una con un código `SKU0000001…SKU0200000` en la descripción).
2. **ANTES:** mide `LIKE` con `FLUSH STATUS` → consulta → `SHOW SESSION STATUS LIKE 'Handler_read%'`, `EXPLAIN ANALYZE` y `EXPLAIN FORMAT=JSON`, más un `UPDATE` de 20.000 filas.
3. Crea el índice FULLTEXT (medir el tiempo del `ALTER`).
4. **DESPUÉS:** las mismas mediciones con `MATCH ... AGAINST`, más el top-10 por relevancia y el mismo `UPDATE`.

**Valores de referencia obtenidos en la VM:**
| Métrica | ANTES (LIKE) | DESPUÉS (FTS) |
| :--- | :--- | :--- |
| `gaming` (COUNT) | 0,32–0,63 s · `Handler_read_rnd_next = 200001` | 0,018–0,020 s · `Handler_read_rnd_next = 0` |
| `notebook`+`gaming`+`RTX` | 0,52–0,56 s | 0,049–0,060 s |
| `SKU0123457` | 0,53–0,64 s · costo 22.540,95 | 0,001–0,005 s · costo 1,10 |
| Top-10 por relevancia | no se puede | 14–23 ms |
| `UPDATE` 20.000 filas | 0,60–0,69 s | 2,83–3,84 s |
| Creación del índice | — | 50,2–50,7 s |

*(Tomar captura: **Evidencia 5 — comparación de planes/métricas**. La más clara es el `EXPLAIN ANALYZE` del SKU antes y después.)*

---

## 10. Análisis de costos (Sección 8)

**Esperado:**
- `producto_masivo`: tabla 104 MB, índice FULLTEXT 58–67 MB en 11 archivos.
- `INNODB_FT_CONFIG` con `stopword_table_name = sgbd_u7_act2/stopwords_es`.
- 210.261 términos distintos (la consulta tarda ~26 s porque recorre todo el índice).
- `INNODB_FT_DELETED = 20000` después del `UPDATE` (cada fila actualizada = borrado lógico + reinserción).
- Una pasada de `OPTIMIZE TABLE` (~11 s) **no** los purga: procesa solo 2.000 términos (`innodb_ft_num_word_optimize`).

---

## 11. Fase C: Veredicto
Completar la matriz de 5 dimensiones y la conclusión (150–200 palabras) a partir de los números medidos. La versión resuelta está en `bitacora_resuelta.md`, sección Fase C. **Veredicto: relacional extendido**, con evolución híbrida solo si aparecen requisitos de búsqueda avanzada.

---

## 12. Limpieza / reversión (al terminar)
```sql
DROP DATABASE sgbd_u7_act2;
```
```bash
sudo rm /etc/mysql/mysql.conf.d/u7_fulltext.cnf
sudo systemctl restart mysql
mysql -e "SHOW VARIABLES LIKE 'innodb_ft_min_token_size'"   # vuelve a 3
```
> Si se borra el `.cnf` pero no la base, los índices ya creados **conservan** los tokens de 2 letras hasta que se reconstruyan.

---

## 13. Problemas frecuentes
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `ERROR 1191 Can't find FULLTEXT index matching the column list` | Las columnas de `MATCH()` no coinciden **exactamente** con las de un índice FULLTEXT | Usar el mismo orden y conjunto: `MATCH(nombre, descripcion)` |
| `TV`/`4K` no aparecen aunque la variable vale 2 | Índice creado antes del cambio, o reconstruido con un solo `ALTER` combinado | `DROP INDEX` y `ADD FULLTEXT` en **dos** sentencias |
| `INNODB_FT_INDEX_TABLE` vacía | Las filas están en la caché del índice | Consultar `INNODB_FT_INDEX_CACHE` u `OPTIMIZE TABLE` |
| `ERROR 1231 ... innodb_ft_aux_table can't be set to the value of ''` | No acepta cadena vacía | `SET GLOBAL innodb_ft_aux_table = DEFAULT;` |
| `ERROR 1238 Variable 'innodb_ft_min_token_size' is a read only variable` | Se intentó `SET GLOBAL` | Archivo `.cnf` + reinicio |
| Stopwords en español ignoradas | El índice se creó en otra sesión sin `innodb_ft_user_stopword_table` | Hacer el `SET SESSION` y crear el índice en la misma conexión |
| `sudo: a terminal is required` al usar `sudo mysql` en comandos remotos (`ssh host 'comando'`) | Sin TTY, `sudo` no puede pedir la contraseña | Conectarse con `ssh -t` o abrir una sesión interactiva (`ssh vboxuser@...`) y ejecutar ahí |
