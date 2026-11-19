# Referencia del Laboratorio Integrador · SGBD 2026 · Grupo 11

> **Para qué sirve este archivo.** Reúne lo que el grupo usó en las Unidades 1 a 8 y 10 (MySQL y MongoDB) para resolver cualquier consigna del laboratorio integrador sobre la VM del grupo y MongoDB Atlas. Está pensado para que **una persona o un agente** busque una tarea y copie el procedimiento.
>
> **Cómo buscar.** Cada sección tiene un código estable: `E` entorno, `R` router de tareas, `M` MySQL, `D` MongoDB en la VM, `A` Atlas, `B` entrega (informe `GrupoN.pdf`), `T` trampas, `F` fuentes. Con `grep -n "^## \|^### " referencia_laboratorio.md` se ve el índice completo. Empezá por **R. Router**.
>
> **Verificación.** Los comandos marcados **[VERIFICADO]** se ejecutaron el 16/11/2026 en MySQL 9.7.4 y MongoDB 8.0.38 (mismas series que la VM), en instancias aisladas. Los marcados **[DOC]** salen de la documentación oficial. Los marcados **[REPO]** son los que usó el grupo en la unidad indicada. Los marcados **[CONSIGNA]** salen de la consigna y la guía oficiales del laboratorio (17/11/2026).

---

## E. Entorno del laboratorio

### E1. Qué pide la cátedra
- **VM con Ubuntu Server 24.04** con **MySQL 9.7** y **MongoDB 8.0** instalados y funcionando.
- **Un servidor (cluster) creado y funcionando en MongoDB Atlas.**

### E2. Datos del grupo

| Elemento | Valor |
| :--- | :--- |
| Grupo | G11 — Aguirre Egea, Emiliano · Ghione, Lucas Emanuel · Pagno, Agustin Mario · Sandoval, Lautaro Emanuel |
| Escenario histórico del grupo | Logística y Depósitos / Distribución interprovincial |
| VM | Ubuntu Server 24.04 · hostname e IP: *[completar el día del laboratorio: `hostname` e `ip -br a`]* |
| MySQL en la VM | Servicio `mysql` · puerto 3306 · config `/etc/mysql/mysql.conf.d/mysqld.cnf` · datos `/var/lib/mysql` · log de errores `/var/log/mysql/error.log` |
| MongoDB en la VM | Servicio `mongod` · puerto 27017 · config `/etc/mongod.conf` · datos `/var/lib/mongodb` · log `/var/log/mongodb/mongod.log` |
| Atlas | Proyecto `Project 0` · cluster `SGBD-U10-Grupo11` · tier `M0` (Free) · AWS São Paulo (`sa-east-1`) · MongoDB 8.0.37 |
| Endpoint Atlas | `mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/` (no contiene credenciales) |
| Usuarios Atlas (motor) | `admin_grupo11` (`atlasAdmin`) · `lector_g11` (`read@practicaU10.productos`) |
| Base de práctica Atlas | `practicaU10.productos` (4 productos tras el CRUD de la U10) |

**Credenciales:** nunca en este archivo ni en los scripts. Siempre `<clave>`, o que la herramienta la pida (`-p` sin valor en `mysql`, `--username` sin `--password` en `mongosh`).

### E3. Verificación previa (correr en la VM antes del laboratorio)

Copiar y pegar en la terminal de la VM. Pide la clave de root de MySQL una vez.

```bash
echo "== Sistema";   lsb_release -ds; hostname; ip -br a | grep -v '^lo'
echo "== Servicios"; systemctl is-active mysql mongod
echo "== Puertos";   sudo ss -lntp | grep -E ':3306|:33060|:27017'
echo "== Versiones"; mysql --version; mongod --version | head -1; mongosh --version; mongodump --version | head -1
echo "== MySQL";     mysql -u root -p -e "SELECT VERSION(), @@transaction_isolation, @@log_bin, @@log_bin_basename, @@binlog_format, @@gtid_mode, @@explain_format, @@bind_address; SHOW DATABASES;"
echo "== MongoDB";   grep -A3 -E '^net:|^security:' /etc/mongod.conf
```

Atlas (pide la clave de `admin_grupo11`):

```bash
mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 --username admin_grupo11 \
  --eval 'print(db.version()); printjson(db.hello().hosts); print(db.getSiblingDB("practicaU10").productos.countDocuments())'
```

**Resultado esperado:** `mysql` y `mongod` en `active`; MySQL 9.7.x y MongoDB 8.0.x; Atlas responde con 3 nodos y `4` productos.

### E4. Si algo falla en la verificación

| Síntoma | Causa probable | Solución |
| :--- | :--- | :--- |
| `inactive` o `failed` en un servicio | El servicio no arrancó | `sudo systemctl start mysql` o `sudo systemctl start mongod`; ver `sudo journalctl -u mongod -n 30` o `sudo tail -30 /var/log/mysql/error.log` |
| `mongosh` hacia Atlas se queda colgado o da *timeout* | **La IP pública cambió** (otra red, por ejemplo la del aula) | Atlas → *Security → Network Access → Add IP Address → Add Current IP Address*. No usar `0.0.0.0/0` |
| `querySrv ENOTFOUND` | Host mal escrito o sin DNS | Copiar el host desde Atlas → *Connect* |
| `Authentication failed` en Atlas | Usuario o clave mal, o usuario recién creado | Revisar *Database Access*; esperar un minuto |
| `ERROR 1045 (28000): Access denied for user 'root'@'localhost'` | En Ubuntu, `root` puede autenticar por socket | Usar `sudo mysql` |
| `Can't connect to MySQL server on 'IP'` desde otra PC | MySQL escucha solo en `127.0.0.1` o el firewall bloquea | Ver **M1** |
| El cluster de Atlas aparece pausado | 30 días sin conexiones | Botón *Resume* |

---

## R. Router: si la consigna pide X, ir a Y

| Si la consigna pide… | Ir a | Unidad de origen |
| :--- | :--- | :--- |
| Identificar motor, versión, configuración, entorno | M0, D0, A1 | U1, U7, U8, U10 |
| Conectar clientes remotos, abrir el puerto, crear usuario de laboratorio | M1 | U5 A1 |
| Monitorear sesiones, espacio, catálogo, metadatos | M2 | U5 A1 |
| Plan de ejecución, índices, medir antes y después | M3 | U2, U5 A1 |
| Consultas analíticas: CTE, ventanas, recursividad | M4 | U3 A1 |
| Reglas de negocio: `CHECK`, trigger, función, procedimiento | M5 | U3 A2 |
| Migración con versión, pruebas y *rollback* | M6 | U3 A3 |
| Transacciones, bloqueos, aislamiento, deadlock | M7 | U5 A2 |
| Usuarios, roles, mínimo privilegio | M8 | U6 |
| Backup lógico y restauración | M9 | U6 |
| Recuperación a un punto (PITR) después de un borrado | M10 | U6 |
| Alta disponibilidad, réplica, RPO y RTO | M11 | U6 |
| JSON, índice multivaluado, `FULLTEXT`, capacidades no relacionales en MySQL | M12 | U7 |
| Modelado documental, CRUD, consultas en MongoDB | D1, D2 | U8 A1 |
| Agregaciones, índices y `explain` en MongoDB | D3, D4 | U8 A1 |
| Autenticación, roles y pruebas de permisos en MongoDB | D5 | U8 A2 |
| Red y TLS en MongoDB | D6 | U8 A2 |
| `mongodump` y `mongorestore` en la VM | D7 | U8 A2 |
| Atlas: conectar, CRUD, permisos, respaldo | A1 a A4 | U10 |
| Comparar VM contra DBaaS | A5 | U10 |
| Migrar datos entre la VM y Atlas | A6 | U8 + U10 |
| Formato del PDF `Grupo11.pdf`, carátula, estructura por ejercicio | B1 | Consigna del laboratorio |
| Matriz de roles, notas DBA (ej. 5 y 6), declaración de IA | B2 | Consigna del laboratorio |
| Mínimos y límites de cada ejercicio (qué exige la guía) | B3 | Guía del laboratorio |
| Estilo de redacción y reglas de evidencia | B4, B5 | Todas |
| Algo falla y no se sabe por qué | T | Todas |

---

## M. MySQL 9.7 en la VM

**Convención:** `mysql -u root -p` (o `sudo mysql`) para administrar. Para pruebas de permisos, conectarse con cada usuario: `mysql -h 127.0.0.1 -u <usuario> -p <base>`.

### M0. Identificar el entorno [VERIFICADO]

```sql
SELECT VERSION();                         -- 9.7.x
SELECT @@transaction_isolation;           -- REPEATABLE-READ por defecto
SELECT @@log_bin, @@log_bin_basename;     -- 1 y <datadir>/binlog (binlog activo por defecto)
SELECT @@gtid_mode;                       -- ver M10: cambia el procedimiento de PITR
SELECT @@explain_format;                  -- TREE en 9.7 (ver M3)
SHOW BINARY LOG STATUS;                   -- archivo y posición actual del binlog
SHOW DATABASES;
```
```bash
mysql --version
sudo systemctl status mysql --no-pager
sudo ss -lntp | grep 3306
```

> En MySQL 9.7, `SHOW MASTER STATUS` **ya no existe** (da error de sintaxis 1064): usar `SHOW BINARY LOG STATUS`.

### M1. Conectividad remota y usuario de laboratorio [REPO U5 A1]

**Cuándo:** "que todos los integrantes se conecten al mismo servidor", "configurar acceso remoto".

1. **Red de la VM:** en VirtualBox, *Configuración → Red → Adaptador puente*. En la VM: `ip -br a` para ver la IP.
2. **Escuchar en la red:**
   ```bash
   sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf     # bind-address = 0.0.0.0
   sudo systemctl restart mysql
   sudo ss -lntp | grep 3306                         # debe mostrar 0.0.0.0:3306
   ```
3. **Firewall:** `sudo ufw status`; si está activo, `sudo ufw allow 3306/tcp`.
4. **Usuario de laboratorio** (nunca `root` remoto):
   ```sql
   CREATE USER 'lab_g11'@'%' IDENTIFIED BY '<clave>';
   GRANT SELECT, INSERT, UPDATE, DELETE ON <base>.* TO 'lab_g11'@'%';
   ```
   Más seguro: `'lab_g11'@'192.168.1.%'` (solo la subred del aula).
5. **Probar desde otra PC:** `nc -vz <IP_VM> 3306` (puerto) y luego Workbench o `mysql -h <IP_VM> -u lab_g11 -p`.

**Diagnóstico por capas:** puerto cerrado → firewall o `bind-address`; `Access denied` → usuario, host o clave; `command denied` → privilegios (M8).

### M2. Monitoreo, catálogo y espacio [REPO U5 A1]

```sql
-- Sesiones y qué ejecutan
SELECT ID, USER, HOST, DB, COMMAND, TIME, STATE, LEFT(INFO, 80) AS consulta
FROM information_schema.PROCESSLIST ORDER BY TIME DESC;

-- Objetos de una base
SELECT TABLE_NAME, TABLE_TYPE, ENGINE, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA = '<base>';
SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = '<base>';
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = '<base>';

-- Metadatos de una tabla: columnas, PK, FK, índices
SHOW CREATE TABLE <tabla>;
SHOW INDEX FROM <tabla>;
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = '<base>' AND TABLE_NAME = '<tabla>';

-- Espacio por tabla (MB)
SELECT TABLE_NAME, ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS mb
FROM information_schema.TABLES WHERE TABLE_SCHEMA = '<base>' ORDER BY mb DESC;

-- Indicadores generales
SHOW GLOBAL STATUS WHERE Variable_name IN ('Threads_connected','Threads_running','Uptime','Questions','Slow_queries','Innodb_buffer_pool_reads','Innodb_buffer_pool_read_requests');
```

En Workbench: *Administration → Client Connections / Dashboard / Server Logs / Users and Privileges*; *Database → Reverse Engineer* para el diagrama ERD; *Table Inspector* para metadatos.

### M3. Planes de ejecución, índices y medición [VERIFICADO] [REPO U2]

**Cuándo:** "obtener el plan", "proponer índices", "medir antes y después", "justificar el costo de escritura".

```sql
EXPLAIN <consulta>;                       -- en 9.7 sale en formato ÁRBOL (explain_format = TREE)
EXPLAIN FORMAT=TRADITIONAL <consulta>;    -- la tabla clásica: type, key, rows, filtered, Extra
EXPLAIN ANALYZE <consulta>;               -- ejecuta y muestra tiempos y filas reales
```

**Cómo leer el árbol:** se lee de adentro hacia afuera. Comparar `rows` estimadas contra `actual ... rows`. Señales de problema: `Table scan`, `Sort` (ordenamiento en memoria o disco) y estimaciones muy alejadas de lo real.

**Ejemplo real** (100.000 pedidos, consulta "últimos 20 pedidos de un cliente"):

| | Sin índice | Con `idx_cliente_fecha (cliente_id, fecha)` |
| :--- | :--- | :--- |
| Plan | `Table scan` → `Filter` → `Sort` → `Limit` | `Index lookup ... (reverse)` → `Limit` |
| Filas leídas | 100.000 | 20 |
| Tiempo | ≈ 52 ms | ≈ 0,12 ms |

```sql
CREATE INDEX idx_cliente_fecha ON pedido (cliente_id, fecha);   -- igualdad primero, orden/rango después
ANALYZE TABLE pedido;                                           -- actualizar estadísticas
SHOW INDEX FROM pedido;                                         -- columnas y cardinalidad
```

**Protocolo de medición** (el de la U2): correr cada consulta **3 veces y registrar la mediana**; escribir la hipótesis **antes** de crear el índice; no reiniciar ni limpiar cachés; guardar planes antes y después.

```sql
-- Tiempo de una consulta
SET @t := NOW(6);
<consulta>;
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @t, NOW(6)) / 1000, 3) AS ms;

-- Trabajo real del motor (filas leídas)
FLUSH STATUS;
<consulta>;
SHOW SESSION STATUS LIKE 'Handler_read%';   -- rnd_next alto = recorrido completo; key/next/prev = uso de índice

-- Costo de escritura: medir un lote dentro de una transacción y revertirlo
START TRANSACTION;
SET @t := NOW(6);
INSERT INTO pedido (...) SELECT ... ;       -- lote de prueba
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @t, NOW(6)) / 1000, 2) AS ms_insercion;
ROLLBACK;
```

**Reglas para elegir índices:** columnas de igualdad primero, después la de rango u orden; un índice compuesto `(a, b)` sirve para filtros por `a` y por `a + b`, no por `b` sola; si el índice cubre todas las columnas pedidas, `Extra` muestra `Using index` (índice de cobertura); cada índice encarece `INSERT`, `UPDATE` y `DELETE`, así que hay que medir ese costo.

**Por qué el optimizador puede no usar un índice:** baja selectividad, función sobre la columna (`WHERE YEAR(fecha) = 2026`), conversión de tipos, `LIKE '%texto'` o estadísticas viejas (`ANALYZE TABLE`).

### M4. SQL avanzado [REPO U3 A1]

```sql
-- Última venta de cada cliente (CTE + ventana)
WITH ult AS (
  SELECT v.*, ROW_NUMBER() OVER (PARTITION BY v.cliente_id ORDER BY v.fecha DESC) AS rn
  FROM venta v)
SELECT c.cliente_id, c.nombre, u.venta_id, u.fecha, u.total
FROM ult u JOIN cliente c ON c.cliente_id = u.cliente_id
WHERE u.rn = 1;

-- Acumulado por cliente conservando el detalle
SELECT venta_id, cliente_id, fecha, total,
       SUM(total) OVER (PARTITION BY cliente_id ORDER BY fecha
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado
FROM venta;

-- Ranking por segmento
WITH totales AS (
  SELECT c.cliente_id, c.segmento, COALESCE(SUM(v.total), 0) AS total_vendido
  FROM cliente c LEFT JOIN venta v ON v.cliente_id = c.cliente_id
  GROUP BY c.cliente_id, c.segmento)
SELECT *, DENSE_RANK() OVER (PARTITION BY segmento ORDER BY total_vendido DESC) AS posicion
FROM totales;

-- Jerarquía (CTE recursiva)
WITH RECURSIVE jerarquia AS (
  SELECT empleado_id, nombre, jefe_id, 1 AS nivel, CAST(nombre AS CHAR(500)) AS camino
  FROM empleado WHERE jefe_id IS NULL
  UNION ALL
  SELECT e.empleado_id, e.nombre, e.jefe_id, j.nivel + 1, CONCAT(j.camino, ' > ', e.nombre)
  FROM empleado e JOIN jerarquia j ON e.jefe_id = j.empleado_id)
SELECT * FROM jerarquia ORDER BY camino;
```

**Comparar alternativas** (lo pedía la consigna): ejecutar `EXPLAIN ANALYZE` de las dos versiones (por ejemplo subconsulta frente a CTE, `GROUP BY` frente a ventana, `EXISTS` frente a `JOIN`) y comparar filas y tiempo.

**Trampas:** `ROW_NUMBER` desempata arbitrariamente (agregar una segunda columna al `ORDER BY`); `RANK` deja huecos y `DENSE_RANK` no; en la CTE recursiva, el `CAST(... AS CHAR(n))` del ancla fija el largo de la columna `camino` (si es corto, se trunca); la recursión tiene un límite de 1000 niveles por defecto (`SET SESSION cte_max_recursion_depth = ...`); `NOT IN` con un `NULL` en la subconsulta devuelve vacío, así que conviene usar `NOT EXISTS`.

### M5. Reglas de negocio en el motor [VERIFICADO] [REPO U3 A2]

**Decisión (lo que pide la defensa):**

| Necesidad | Mecanismo | Pregunta guía |
| :--- | :--- | :--- |
| Regla simple sobre una fila | `CHECK`, `NOT NULL`, `UNIQUE`, `FOREIGN KEY` | ¿Se puede expresar declarativamente? Entonces nada de trigger |
| Cálculo reutilizable dentro de consultas | Función almacenada | ¿Devuelve un valor? |
| Proceso de varios pasos | Procedimiento con transacción | ¿Es una operación explícita? |
| Reacción automática a cambios (auditoría) | Trigger | ¿Debe ocurrir ante cualquier `INSERT`, `UPDATE` o `DELETE`? |

```sql
ALTER TABLE cuenta ADD CONSTRAINT chk_saldo_no_negativo CHECK (saldo >= 0);
-- Caso inválido → ERROR 3819 (HY000): Check constraint 'chk_saldo_no_negativo' is violated.

DELIMITER //
CREATE TRIGGER trg_auditar_precio AFTER UPDATE ON producto FOR EACH ROW
BEGIN
  IF OLD.precio <> NEW.precio THEN
    INSERT INTO auditoria_precio (producto_id, precio_anterior, precio_nuevo)
    VALUES (OLD.producto_id, OLD.precio, NEW.precio);
  END IF;
END //

CREATE TRIGGER trg_validar BEFORE INSERT ON movimiento FOR EACH ROW
BEGIN
  IF NEW.importe = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un movimiento no puede tener importe 0';
  END IF;
END //
-- Caso inválido → ERROR 1644 (45000): Un movimiento no puede tener importe 0

CREATE FUNCTION clasificar_cliente(p_cliente INT, p_anio INT) RETURNS VARCHAR(10)
DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2);
  SELECT COALESCE(SUM(total), 0) INTO v_total FROM venta
  WHERE cliente_id = p_cliente AND YEAR(fecha) = p_anio;
  RETURN CASE WHEN v_total > 50000000 THEN 'Oro' WHEN v_total >= 2000000 THEN 'Plata' ELSE 'Bronce' END;
END //

CREATE PROCEDURE sp_transferir(IN p_origen INT, IN p_destino INT, IN p_monto DECIMAL(12,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  UPDATE cuenta SET saldo = saldo - p_monto WHERE cuenta_id = p_origen;
  UPDATE cuenta SET saldo = saldo + p_monto WHERE cuenta_id = p_destino;
  COMMIT;
END //
DELIMITER ;
```

**Probado:** `CALL sp_transferir(1, 2, 5000)` con saldo insuficiente → `ERROR 3819` y **ningún saldo cambia** (el handler hace `ROLLBACK`); con monto válido, los dos saldos cambian y el trigger deja dos filas de auditoría.

**Pruebas mínimas que siempre pide la cátedra:** caso **válido** (acepta), caso **inválido** (rechaza, con el código de error), caso **límite** (por ejemplo saldo que queda exactamente en 0, o total en el borde de una categoría) y, si hay auditoría, mostrar la fila generada.

**Otros errores útiles:** `ERROR 1452` → violación de clave foránea; `ERROR 1062` → clave duplicada.

### M6. Migración versionada con *rollback* [REPO U3 A3]

**Cuándo:** "evolucionar la base sin borrar datos", "v1 → v2".

**Estructura de entrega:** `01_schema_v1.sql`, `02_datos_v1.sql`, `03_migracion_v2.sql`, `04_programabilidad_v2.sql`, `05_pruebas_v2.sql`, `06_rollback_v2.sql`.

```sql
-- 03_migracion_v2.sql: solo cambios aditivos, con valores por defecto para los datos existentes
ALTER TABLE pedido ADD COLUMN estado ENUM('pendiente','pagado','enviado','cancelado') NOT NULL DEFAULT 'pendiente';
CREATE TABLE auditoria_estado_pedido (
  auditoria_id INT AUTO_INCREMENT PRIMARY KEY, pedido_id INT NOT NULL,
  estado_anterior VARCHAR(20), estado_nuevo VARCHAR(20) NOT NULL,
  fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id));
ALTER TABLE pedido ADD CONSTRAINT chk_total_positivo CHECK (total >= 0);

-- 06_rollback_v2.sql: en orden inverso
DROP TRIGGER IF EXISTS trg_auditoria_estado;
DROP FUNCTION IF EXISTS calcular_total_cliente;
ALTER TABLE pedido DROP CONSTRAINT chk_total_positivo;
ALTER TABLE pedido DROP COLUMN estado;               -- PIERDE el estado de los pedidos: documentarlo
DROP TABLE IF EXISTS auditoria_estado_pedido;        -- PIERDE el historial: documentarlo
```

**Pruebas:** recuentos de v1 **antes y después** de migrar (deben coincidir), los nuevos estados funcionan, la auditoría registra, la restricción rechaza un total negativo. **Antes de migrar, `mysqldump` (M9).**

**Trampa:** `ALTER TABLE ... ADD CONSTRAINT CHECK` falla si ya hay filas que no cumplen: verificar primero con `SELECT COUNT(*) FROM pedido WHERE total < 0;`.

### M7. Transacciones, bloqueos, aislamiento y deadlock [VERIFICADO] [REPO U5 A2]

**Cuándo:** "dos sesiones, un mismo dato". Abrir **dos terminales** (Sesión A y Sesión B) y, si se puede, una tercera para el diagnóstico. Si se usa Workbench, desactivar el *autocommit* o usar `START TRANSACTION` explícito.

**Experimento 1 — espera por bloqueo**
```sql
-- A
START TRANSACTION;
UPDATE cuenta SET saldo = saldo - 100 WHERE cuenta_id = 1;      -- no confirmar
-- B (queda esperando)
UPDATE cuenta SET saldo = saldo + 50 WHERE cuenta_id = 1;
-- Diagnóstico (tercera sesión, mientras B espera)
SELECT waiting_pid, waiting_query, blocking_pid, blocking_query, wait_age,
       locked_table, locked_index, locked_type, sql_kill_blocking_connection
FROM sys.innodb_lock_waits;
SELECT ENGINE_TRANSACTION_ID, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_STATUS, LOCK_DATA
FROM performance_schema.data_locks;
SHOW PROCESSLIST;
-- A libera
COMMIT;   -- o ROLLBACK; B continúa en el acto
```
**Lo que se ve (probado):** en `data_locks`, A tiene `RECORD X,REC_NOT_GAP GRANTED` sobre `LOCK_DATA = 1` y B el mismo bloqueo en `WAITING`; en `sys.innodb_lock_waits`, `locked_table = lab.cuenta`, `locked_index = PRIMARY` y `sql_kill_blocking_connection = KILL <id>`. Si B espera más de `innodb_lock_wait_timeout` (50 s por defecto) → `ERROR 1205 Lock wait timeout exceeded`.

> **Ojo:** `blocking_query` muestra lo que la sesión bloqueante ejecuta **en ese momento** (puede ser `NULL` o cualquier otra sentencia), no el `UPDATE` que tomó el bloqueo. La prueba del bloqueo es `data_locks`.

**Experimento 2 — aislamiento**
```sql
SELECT @@transaction_isolation;       -- copiar el valor real: REPEATABLE-READ
-- A
START TRANSACTION;
SELECT saldo FROM cuenta WHERE cuenta_id = 2;    -- 2000
-- B
UPDATE cuenta SET saldo = saldo + 999 WHERE cuenta_id = 2;   -- autocommit
-- A
SELECT saldo FROM cuenta WHERE cuenta_id = 2;    -- sigue en 2000 (lectura consistente MVCC)
COMMIT;
SELECT saldo FROM cuenta WHERE cuenta_id = 2;    -- 2999
```
**Explicación:** en `REPEATABLE READ`, InnoDB lee desde la foto (*snapshot*) tomada en la primera lectura de la transacción: no hay lectura no repetible. Con `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` antes de `START TRANSACTION`, A vería 2999 en la segunda lectura. Para leer el último valor y bloquearlo dentro de la transacción: `SELECT ... FOR UPDATE`.

**Experimento 3 — deadlock**
```sql
-- A: START TRANSACTION; UPDATE cuenta SET saldo = saldo - 1 WHERE cuenta_id = 1;
-- B: START TRANSACTION; UPDATE cuenta SET saldo = saldo - 1 WHERE cuenta_id = 2;
-- A: UPDATE cuenta SET saldo = saldo + 1 WHERE cuenta_id = 2;     -- espera
-- B: UPDATE cuenta SET saldo = saldo + 1 WHERE cuenta_id = 1;     -- ciclo
-- Una de las dos recibe:
--   ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
SHOW ENGINE INNODB STATUS;   -- sección LATEST DETECTED DEADLOCK
```
**Lo que muestra la sección:** `*** (1) TRANSACTION` y `*** (2) TRANSACTION` con sus sentencias, `HOLDS THE LOCK(S)`, `WAITING FOR THIS LOCK TO BE GRANTED` y `*** WE ROLL BACK TRANSACTION (2)` (la víctima). La otra transacción continúa.

**Medidas preventivas** (desafío final): acceder siempre a las filas **en el mismo orden** (por ejemplo, por `cuenta_id` ascendente); **transacciones cortas**, sin esperar al usuario con la transacción abierta; **índices** en las columnas del `WHERE` para no bloquear de más; **reintentar** ante el error 1213 en la aplicación; `SELECT ... FOR UPDATE` al inicio para tomar los bloqueos de una vez.

### M8. Usuarios, roles y mínimo privilegio [VERIFICADO] [REPO U6 Fase 1]

**Secuencia que pide la cátedra:** mostrar los accesos indebidos **antes**, corregir y volver a probar **después** (matriz de permisos con resultado esperado y obtenido).

```sql
-- Diagnóstico
SELECT user, host, account_locked FROM mysql.user;
SHOW GRANTS FOR 'u6_app'@'%';
SHOW GRANTS FOR 'u6_app'@'%' USING rol_app;     -- incluye lo que aportan los roles

-- Rediseño
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_app;
CREATE ROLE IF NOT EXISTS rol_lector, rol_operador;
GRANT SELECT ON base.* TO rol_lector;
GRANT SELECT, INSERT, UPDATE ON base.cuenta TO rol_operador;
GRANT SELECT, INSERT ON base.movimiento TO rol_operador;      -- sin DELETE ni DDL
CREATE USER 'lector'@'%' IDENTIFIED BY '<clave>';
GRANT rol_lector TO 'lector'@'%';
SET DEFAULT ROLE ALL TO 'lector'@'%';     -- SIN esto, el rol no está activo al conectarse
-- (FLUSH PRIVILEGES no hace falta con GRANT/REVOKE/CREATE USER)
```

**Verificar desde el usuario:** `SELECT CURRENT_USER(), CURRENT_ROLE();` debe mostrar el rol.

**Errores reales (probado):**
- `ERROR 1142 (42000): UPDATE command denied to user 'lector'@'localhost' for table 'cuenta'`
- `ERROR 1142 (42000): DELETE command denied to user 'operador'@'localhost' for table 'movimiento'`
- `ERROR 1142 (42000): DROP command denied to user 'operador'@'localhost' for table 'cuenta'`
- `ERROR 1227 (42000): Access denied; you need (at least one of) the CREATE USER privilege(s) for this operation`

**Accesos indebidos típicos para mostrar "antes":** usuario de aplicación con DDL (`CREATE`/`DROP TABLE`); analista que puede hacer `UPDATE`; usuario operativo que borra la tabla de auditoría.

### M9. Backup lógico y restauración [VERIFICADO] [REPO U6 Fase 2]

```bash
# Backup consistente de una base (InnoDB, sin bloquear la operación)
mysqldump -u root -p --single-transaction --flush-logs --source-data=2 \
  --set-gtid-purged=OFF --routines --triggers --events \
  --databases <base> > backup_<base>_$(date +%Y%m%d_%H%M).sql

# Coordenadas del binlog guardadas en el backup (para PITR)
grep -m1 "CHANGE REPLICATION SOURCE TO" backup_<base>_*.sql
#  -- CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE='binlog.000002', SOURCE_LOG_POS=198;

# Restaurar
mysql -u root -p < backup_<base>_XXXX.sql
```

| Opción | Para qué |
| :--- | :--- |
| `--single-transaction` | Foto consistente sin bloquear (InnoDB) |
| `--flush-logs` | Empieza un binlog nuevo en el momento del backup |
| `--source-data=2` | Escribe archivo y posición del binlog como comentario (antes `--master-data`) |
| `--set-gtid-purged=OFF` | **Imprescindible si `gtid_mode=ON`** y se restaura en el mismo servidor (ver M10) |
| `--routines --triggers --events` | Incluye la programabilidad |
| `--databases <base>` | Incluye `CREATE DATABASE` y `USE` en el archivo |

**Restaurar con otro nombre** (para comparar sin pisar la original): hacer el dump **sin** `--databases` (`mysqldump ... <base> > b.sql`), crear la base nueva y `mysql -u root -p <base>_restore < b.sql`.

**Validar siempre:** recuentos y sumas de control antes y después (`SELECT COUNT(*), SUM(importe) FROM ...`).

### M10. Recuperación a un punto (PITR) [VERIFICADO] [REPO U6 Fase 2]

**Cuándo:** "un usuario borró datos", "recuperar sin perder las operaciones válidas posteriores al backup".

> **Primero mirar `SELECT @@gtid_mode;`.** En el MySQL 9.7.4 de prueba estaba en **`ON` por defecto**. Con GTID activo, el procedimiento de la U6 tal cual **falla**: el dump trae `SET @@GLOBAL.GTID_PURGED` (→ `ERROR 3546`) y, si se reaplica el binlog sin `--skip-gtids`, **el servidor descarta en silencio las transacciones ya ejecutadas**. Resultado probado: la base queda en el estado del backup y se pierden las operaciones válidas, **sin ningún mensaje de error**. El procedimiento de abajo funciona **con GTID activo y desactivado** (probado en los dos casos).

```bash
# 0. Estado inicial y backup (M9, con --source-data=2 y --set-gtid-purged=OFF)
# 1. Operaciones válidas posteriores al backup → estado objetivo
# 2. Incidente (por ejemplo DELETE FROM movimiento WHERE cuenta_id = 101;)

# 3. Archivo y posición de inicio: los del backup
grep -m1 "CHANGE REPLICATION SOURCE TO" backup.sql        # SOURCE_LOG_FILE y SOURCE_LOG_POS (start)

# 4. Ubicar la transacción del incidente
mysql -u root -p -e "SHOW BINARY LOGS"
mysql -u root -p -e "SHOW BINLOG EVENTS IN 'binlog.000002'"
#   Buscar el evento Delete_rows (o Query con el DROP/UPDATE). La posición de corte (stop)
#   es el End_log_pos del Xid (COMMIT) ANTERIOR: es donde empieza la transacción mala.
sudo mysqlbinlog --base64-output=DECODE-ROWS --verbose /var/lib/mysql/binlog.000002 | less
#   Buscar "### DELETE FROM" y mirar la línea "# at NNN" anterior al BEGIN / Gtid de esa transacción.

# 5. Restaurar el backup
mysql -u root -p < backup.sql

# 6. Reaplicar el binlog desde el backup hasta justo antes del incidente
sudo mysqlbinlog --skip-gtids --start-position=<SOURCE_LOG_POS> --stop-position=<inicio_trx_mala> \
  /var/lib/mysql/binlog.000002 | mysql -u root -p

# 7. Validar: recuentos y sumas deben coincidir con el estado objetivo (paso 1)
```

**Ejemplo real de `SHOW BINLOG EVENTS`:**

| Pos | Event_type | End_log_pos | Significado |
| :---: | :--- | :---: | :--- |
| 198 | Gtid | 277 | Inicio de la transacción válida (= `SOURCE_LOG_POS` del backup) |
| 353 | Table_map | 412 | |
| 412 | Write_rows | 477 | Los `INSERT` válidos |
| 477 | Xid | **508** | `COMMIT` de la transacción válida |
| 508 | Gtid | 587 | **Inicio de la transacción mala → `--stop-position=508`** |
| 720 | Delete_rows | 800 | El `DELETE` accidental |

**Por fecha:** `--stop-datetime="2026-11-16 23:49:22"` (formato `AAAA-MM-DD hh:mm:ss`; las líneas `#261116 23:49:23` del binlog son `AAMMDD`). Es menos preciso que la posición si hay varias operaciones en el mismo segundo.

**Ubicación del binlog:** `SELECT @@log_bin_basename;` → en Ubuntu, `/var/lib/mysql/binlog` (no `/var/log/mysql`, como decía la guía de la U6).

**Justificar el punto elegido** (lo pide la consigna): restaurar solo el backup pierde las operaciones válidas; reaplicar todo el binlog vuelve a ejecutar el error. El punto correcto es **el `COMMIT` inmediatamente anterior a la transacción del incidente**.

### M11. Continuidad: réplica, alta disponibilidad, RPO y RTO [REPO U6 Fase 3]

**Escenario del grupo (G11, Logística y depósitos):** RPO 15 min, RTO 30 min, presupuesto medio, dos nodos.

| Componente | Propuesta del grupo |
| :--- | :--- |
| Nodos | Primario (lectura y escritura) + secundario con **replicación semisíncrona** (el `COMMIT` espera a que la réplica reciba la transacción) |
| Backup | `mysqldump`/backup físico diario fuera de hora pico, guardado **fuera** del servidor |
| Binlogs | Copia continua cada 5 min a almacenamiento externo → cumple RPO de 15 min aunque se pierdan los dos nodos |
| Failover | IP virtual (Keepalived) o ProxySQL; conmutación asistida en minutos → RTO ≤ 30 min |
| Riesgo | Con 2 nodos no hay quórum: riesgo de *split-brain* con failover automático, por eso es asistido |
| Error humano | **La réplica replica también el `DELETE`**: solo el backup + binlog (PITR, M10) lo resuelve |

**Conceptos para defender:** RPO = cuántos datos se pueden perder; RTO = cuánto tarda volver a operar; **HA ≠ backup** (la HA protege contra la caída de un servidor, el backup contra errores y corrupción); replicación asíncrona (puede perder las últimas transacciones) frente a semisíncrona (más segura, más latencia); probar la restauración periódicamente.

### M12. Capacidades no relacionales: JSON, índice multivaluado y FULLTEXT [VERIFICADO] [REPO U7]

```sql
CREATE TABLE producto (
  id INT PRIMARY KEY, nombre VARCHAR(80) NOT NULL, precio DECIMAL(10,2) NOT NULL,
  atributos JSON NOT NULL,                         -- variables por categoría
  tags JSON NOT NULL,                              -- arreglo de etiquetas
  descripcion TEXT,
  CONSTRAINT chk_tags_array CHECK (JSON_TYPE(tags) = 'ARRAY'),
  INDEX idx_tags ((CAST(tags AS CHAR(30) ARRAY))),  -- índice multivaluado
  FULLTEXT KEY ft_desc (descripcion));

SELECT id, atributos->>'$.ram_gb' AS ram FROM producto WHERE atributos->>'$.ram_gb' >= 16;   -- atributo anidado
SELECT id FROM producto WHERE 'oferta' MEMBER OF (tags);                                    -- usa idx_tags
SELECT id FROM producto WHERE JSON_CONTAINS(tags, '"gaming"');
SELECT id FROM producto WHERE JSON_OVERLAPS(tags, '["hogar","deporte"]');
SELECT id, MATCH(descripcion) AGAINST('gamer') AS score FROM producto WHERE MATCH(descripcion) AGAINST('gamer');
```

**Probado:** el `EXPLAIN` de `MEMBER OF` muestra `Index lookup on producto using idx_tags`; insertar un `tags` que no es arreglo da `ERROR 3819`.

**Trampas:** `->>` devuelve texto (comparar números con `CAST(... AS UNSIGNED)` si hace falta orden numérico); FULLTEXT ignora palabras de menos de 3 caracteres (`innodb_ft_min_token_size`) y las *stopwords*; para indexar un atributo JSON escalar, crear una columna generada o un índice funcional: `INDEX ((CAST(atributos->>'$.ram_gb' AS UNSIGNED)))`.

---

## D. MongoDB 8.0 en la VM

**Convención:** `mongosh` para todo. Con autenticación: `mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u <usuario>` (pide la clave).

### D0. Identificar el entorno [REPO U8 A2]

```javascript
db.version()
db.adminCommand({ getCmdLineOpts: 1 }).parsed      // net.bindIp, net.port, security.authorization
db.adminCommand({ listDatabases: 1 })
db.getSiblingDB("<base>").getCollectionNames()
db.serverStatus().connections
db.runCommand({ connectionStatus: 1 }).authInfo    // quién soy y qué roles tengo
```
```bash
sudo systemctl status mongod --no-pager
sudo ss -lntp | grep 27017
cat /etc/mongod.conf
```

### D1. Modelado documental [REPO U8 A1]

**Regla de la cátedra:** el modelo se deriva de los **patrones de acceso** (qué consultas hace la aplicación), no de un esquema relacional traducido a JSON.

| Decisión | Cuándo |
| :--- | :--- |
| **Embeber** (subdocumento o arreglo) | Se lee junto con el padre, crece acotado (por ejemplo, los paquetes de un envío) |
| **Referenciar** (`envio_id`) | Crece sin límite, se consulta por separado o se comparte (por ejemplo, los eventos de seguimiento) |
| **Duplicar** (desnormalizar) | Lectura muy frecuente de un dato que cambia poco; hay que justificar el costo de mantener las copias |

**Límites:** documento de 16 MB como máximo; un arreglo que crece sin control degrada el rendimiento.

**Validación de esquema** (opcional, suma puntos):
```javascript
db.createCollection("envios", { validator: { $jsonSchema: {
  bsonType: "object", required: ["_id", "estado_actual", "fecha_despacho"],
  properties: { estado_actual: { enum: ["PREPARADO", "EN_TRANSITO", "ENTREGADO", "DEVUELTO"] } } } } })
// Documento inválido → "Document failed validation"
```

### D2. Carga, CRUD y consultas [VERIFICADO] [REPO U8 A1, U10]

```javascript
// Dentro de un archivo .js NO usar "use base": mongosh --file lo ignora sin avisar.
db = db.getSiblingDB("u8_g11");

db.envios.insertMany([ { _id: "ENV-2026-001", estado_actual: "EN_TRANSITO", ruta: "Resistencia - Rosario",
                         fecha_despacho: ISODate("2026-11-10T08:00:00Z"),
                         transportista: { nombre: "Transportes del Norte" },
                         paquetes: [ { codigo: "P1", tipo: "caja", peso_kg: 2.5 } ] }, /* ... */ ])
db.envios.countDocuments()
db.envios.find({ estado_actual: "EN_TRANSITO" }, { _id: 1, ruta: 1 }).sort({ fecha_despacho: -1 })
db.envios.find({ "transportista.nombre": "Transportes del Norte" })              // subdocumento
db.envios.find({ paquetes: { $elemMatch: { tipo: "caja", peso_kg: { $gt: 2 } } } })  // arreglo, misma posición
db.envios.updateOne({ _id: "ENV-2026-001", estado_actual: "EN_TRANSITO" },       // filtro con el estado esperado
                    { $set: { estado_actual: "ENTREGADO" }, $currentDate: { actualizado: true } })
db.envios.deleteOne({ _id: "ENV-TEST-999" })
```

**Trampas:** `{ "paquetes.tipo": "caja", "paquetes.peso_kg": { $gt: 2 } }` puede combinar condiciones de **elementos distintos** del arreglo; usar `$elemMatch` si deben cumplirse en el mismo elemento. Hacer el CRUD sobre la base del grupo y no sobre `test` (pasó en la U8).

### D3. Agregación [VERIFICADO] [REPO U8 A1]

```javascript
db.envios.aggregate([
  { $match: { estado_actual: "ENTREGADO" } },
  { $group: { _id: "$ruta", envios: { $sum: 1 }, peso_total: { $sum: "$peso_kg" }, demora_prom: { $avg: "$minutos_demora" } } },
  { $sort: { envios: -1 } },
  { $limit: 5 }
])
// Otras etapas usadas: $unwind (abrir un arreglo), $lookup (unir con otra colección), $project, $addFields
db.envios.aggregate([
  { $lookup: { from: "eventos_seguimiento", localField: "_id", foreignField: "envio_id", as: "eventos" } },
  { $project: { _id: 1, cantidad_eventos: { $size: "$eventos" } } }
])
```

La consigna pedía **al menos tres etapas**. Poner `$match` primero para que use índices.

### D4. Índices y `explain` [VERIFICADO] [REPO U8 A1]

```javascript
const consulta = () => db.envios.find({ ruta: "R7", estado: "ENTREGADO" }).sort({ fecha: -1 });
const ex = consulta().explain("executionStats");
ex.queryPlanner.winningPlan                    // buscar COLLSCAN (recorrido) o IXSCAN (índice)
ex.executionStats.nReturned
ex.executionStats.totalKeysExamined
ex.executionStats.totalDocsExamined
ex.executionStats.executionTimeMillis

db.envios.createIndex({ ruta: 1, estado: 1, fecha: -1 })    // igualdad, igualdad, orden (regla ESR)
db.envios.getIndexes()
db.envios.aggregate([{ $indexStats: {} }])                  // cuántas veces se usó cada índice
```

**Probado (3000 documentos):** sin índice `COLLSCAN` con `totalDocsExamined = 3000`; con el índice, `IXSCAN` y `totalDocsExamined` igual a los devueltos.

**Cómo concluir:** lo importante es `totalDocsExamined` frente a `nReturned` (ideal: iguales). Con pocos datos los tiempos dan 0 ms en ambos casos y no prueban nada: generar volumen (la U8 usó 200.000 documentos) o argumentar con documentos examinados. Separar la primera ejecución (caché fría) y repetir 5 veces.

**Regla ESR:** en un índice compuesto, primero los campos de **E**quality (igualdad), después los de **S**ort (orden) y al final los de **R**ange (rango).

### D5. Autenticación y roles [VERIFICADO] [REPO U8 A2]

```javascript
// 1. Con la autenticación todavía apagada (o por la excepción de localhost): crear el administrador
db.getSiblingDB("admin").createUser({ user: "adminG11", pwd: passwordPrompt(),
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, { role: "readWriteAnyDatabase", db: "admin" }, { role: "clusterMonitor", db: "admin" } ] })
```
```bash
# 2. Activar el control de acceso
sudo nano /etc/mongod.conf
#   security:
#     authorization: enabled
sudo systemctl restart mongod
mongosh --quiet --eval 'db.getSiblingDB("u8_g11").envios.findOne()'   # sin credenciales
#   → MongoServerError: Command find requires authentication
```
```javascript
// 3. Usuarios de la base (conectado como adminG11)
const lab = db.getSiblingDB("u8_g11");
lab.createUser({ user: "u8_g11_lector",   pwd: passwordPrompt(), roles: [ { role: "read",      db: "u8_g11" } ] })
lab.createUser({ user: "u8_g11_operador", pwd: passwordPrompt(), roles: [ { role: "readWrite", db: "u8_g11" } ] })
db.getSiblingDB("admin").createUser({ user: "u8_g11_respaldo", pwd: passwordPrompt(), roles: [ { role: "backup", db: "admin" } ] })
lab.getUsers()
```
```bash
# 4. Conectarse con cada uno (authenticationDatabase = la base donde se creó el usuario)
mongosh "mongodb://127.0.0.1:27017/u8_g11" --authenticationDatabase u8_g11 -u u8_g11_lector
```

**Pruebas mínimas y resultados reales:**

| Identidad | Acción | Esperado | Respuesta del servidor |
| :--- | :--- | :---: | :--- |
| Lector | `find()` | Permitida | Devuelve documentos |
| Lector | `insertOne()` | Denegada | `MongoServerError: not authorized on <base> to execute command { insert: ...` |
| Operador | `updateOne()` | Permitida | `matchedCount: 1, modifiedCount: 1` |
| Operador | `createUser()` | Denegada | `MongoServerError: not authorized on <base> to execute command { createUser: ...` |

**Diagnóstico por capas** (incidente "puede leer pero no modificar"): 1) **conexión** (`ping`); 2) **autenticación** (`connectionStatus` muestra el usuario); 3) **autorización** (`authenticatedUserRoles` muestra `read` y no `readWrite`). La solución es `grantRolesToUser`, y revertir con `revokeRolesFromUser` si era una prueba.

**Trampa:** el rol `restore` permite crear usuarios (es amplio): no dárselo a cuentas de uso diario.

### D6. Red y TLS [REPO U8 A2]

**Revisar exposición:** `bindIp` (debe ser `127.0.0.1` o una IP concreta, nunca `0.0.0.0` sin autenticación), puerto y modo TLS. Para acceso remoto: `bindIp: 127.0.0.1,<IP_VM>` y `sudo ufw allow from <subred> to any port 27017`.

**TLS con una CA propia** (probado en la U8):
```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -subj "/O=UTN FRRe SGBD/CN=CA Laboratorio G11" -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/O=UTN FRRe SGBD/CN=localhost" -out server.csr
printf 'subjectAltName=DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n' > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile server.ext
cat server.key server.crt > server.pem
```
```yaml
# /etc/mongod.conf (bloque net)
net:
  port: 27017
  bindIp: 127.0.0.1
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/server.pem
    CAFile: /etc/ssl/mongodb/ca.crt
    allowConnectionsWithoutCertificates: true
```
```bash
mongosh --host localhost --tls --tlsCAFile ca.crt -u adminG11 --authenticationDatabase admin
echo | openssl s_client -connect localhost:27017 -CAfile ca.crt 2>/dev/null | grep -E "Protocol|Cipher is|Verify return code"
```
**Pruebas:** sin `--tls` la conexión se rechaza; con la CA, `Verify return code: 0 (ok)`. Los archivos `.pem` deben ser legibles por el usuario `mongodb` (`sudo chown mongodb: /etc/ssl/mongodb/*`).

### D7. `mongodump` y `mongorestore` en la VM [VERIFICADO] [REPO U8 A2]

```bash
# Estado previo (recuentos)
mongosh ... --eval 'db = db.getSiblingDB("u8_g11"); print(db.envios.countDocuments(), db.eventos_seguimiento.countDocuments())'

# Respaldo con el usuario de rol backup (pide la clave)
mongodump --host 127.0.0.1:27017 -u u8_g11_respaldo --authenticationDatabase admin --db u8_g11 --out ~/backup_u8_g11

# Verificar los archivos: .bson (datos) + .metadata.json (índices y opciones)
ls -lh ~/backup_u8_g11/u8_g11/
bsondump --quiet ~/backup_u8_g11/u8_g11/envios.bson | wc -l      # debe coincidir con el recuento

# Restaurar en una base alternativa (no pisa la original)
mongorestore --host 127.0.0.1:27017 -u <usuario_con_rol_restore> --authenticationDatabase admin \
  --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' ~/backup_u8_g11
#  → "N document(s) restored successfully. 0 document(s) failed to restore."

# Recuperar una colección borrada
mongorestore ... --nsInclude 'u8_g11.prueba_borrado' ~/backup_u8_g11
```

**Trampas:** restaurar sobre una colección con datos **no sobrescribe** (errores de clave duplicada): usar `--drop` si se quiere reemplazar; `--dryRun` muestra qué haría sin hacerlo; `mongodump` es una foto del momento (para consistencia con escrituras en curso en un *replica set*: `--oplog`); los usuarios no viajan salvo con `--dumpDbUsersAndRoles`.

---

## A. MongoDB Atlas (DBaaS)

### A1. Conectar y verificar [REPO U10]

```bash
mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 --username admin_grupo11
```
Antes de conectar desde una red nueva: **Atlas → Network Access → Add Current IP Address**.

| Dato | Valor (U10) |
| :--- | :--- |
| Motor | MongoDB 8.0.37 (no se elige versión en el plan Free) |
| Plan | `M0` Free: 512 MB, RAM y vCPU compartidas, 500 conexiones, 100 operaciones/s, 10 GB de transferencia cada 7 días |
| Topología | *Replica set* de 3 nodos (1 primario, 2 secundarios) |
| Endpoint | SRV con TLS obligatorio; el DNS resuelve los nodos |
| Inactividad | Se pausa tras 30 días sin conexiones |

### A2. CRUD [REPO U10 `consigna3.js`]

Los mismos comandos que en la VM (D2). Ejemplo usado:
```javascript
db = db.getSiblingDB("practicaU10");
db.productos.insertMany([ { codigo: "PROD-01", nombre: "Notebook Dell Inspiron", categoria: "Computación", precio: 850000, stock: 10, disponible: true }, /* 4 más */ ]);
db.productos.find({ disponible: true, precio: { $gte: 50000 } });
db.productos.updateOne({ codigo: "PROD-04" }, { $set: { stock: 12, disponible: true, precio: 68000 } });
db.productos.deleteOne({ codigo: "PROD-05" });
db.productos.countDocuments();   // 4
```

### A3. Permisos: plataforma frente a motor [REPO U10]

| | Plataforma (consola Atlas) | Motor (*Database Access*) |
| :--- | :--- | :--- |
| Controla | Clusters, red, usuarios de BD, facturación, invitaciones | Operaciones sobre los datos |
| Identidades | Cuentas de MongoDB Cloud con roles de organización y de proyecto (*Organization Owner*, *Project Owner*, *Project Read Only*) | Usuarios de base de datos con SCRAM y roles (`atlasAdmin`, `readWrite`, `read`) |
| Dónde se crea | Consola web | **También en la consola web** |

- **Usuarios del motor:** *Security → Database Access → Add New Database User → Add Specific Privilege* (por ejemplo `read` sobre `practicaU10.productos`).
- **`db.createUser()` está bloqueado en Atlas**, aun para `atlasAdmin` [DOC]: los usuarios solo se crean desde la plataforma.
- **Error real del lector al insertar:** `MongoServerError[AtlasError]: user is not allowed to do action [insert] on [practicaU10.productos]`.

### A4. Respaldo en el plan Free [VERIFICADO con simulación] [REPO U10]

- **Administrado:** no incluido. La pestaña Backup ofrece *Purchase Daily Backups* (pago, con medio de pago) o pasar a un plan pago. **No activar.**
- **La replicación no es respaldo:** un `deleteOne` se replica a los 3 nodos.
- **Respaldo lógico:** sí funciona [DOC]. Se puede hacer todo contra el cloud:

```bash
mongodump --uri "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --username admin_grupo11 --db practicaU10 --out ~/backup_u10
bsondump --quiet ~/backup_u10/practicaU10/productos.bson | wc -l
# Restaurar en el mismo cluster, en otra base (requiere atlasAdmin)
mongorestore --uri "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --username admin_grupo11 \
  --nsFrom 'practicaU10.*' --nsTo 'practicaU10_restore.*' ~/backup_u10
```
- **Verificar:** misma consulta en las dos bases; los `_id` deben ser **los mismos** (prueba de copia fiel).
- **No disponible en Free:** `--oplog`, `--dumpDbUsersAndRoles`, `--restoreDbUsersAndRoles` [DOC].

### A5. Matriz VM frente a DBaaS (resuelta en la U10)

| Aspecto | VM | Atlas M0 | ¿Quién administra en DBaaS? |
| :--- | :--- | :--- | :--- |
| Instalación y SO | `apt install`, `mongod.conf`, parches a mano | Se elige plan y región; sin acceso al SO | Proveedor |
| Conectividad | `bindIp`, puerto, firewall, TLS a mano | Endpoint SRV, TLS obligatorio, lista de IP | Compartida |
| CRUD | `mongosh` | Los mismos comandos | Equipo |
| Permisos | `db.createUser()` en el motor | Usuarios desde la consola; `createUser` bloqueado | Compartida |
| Backup / Restore | `mongodump`/`mongorestore` propios | Snapshots solo pagos; en Free, `mongodump` | Equipo (Free) |
| Monitoreo | Logs, `serverStatus`, `top`, `df` | Panel *Metrics* (4 métricas en Free); sin descarga de logs | Compartida |
| Costos | La VM consume recursos siempre | Gratis con límites (512 MB, 100 ops/s) | Proveedor fija; equipo controla |

**Conclusión defendida:** DBaaS **transforma** el rol del DBA, no lo elimina. Delega la infraestructura y mantiene el diseño, la seguridad, la red, la continuidad y los costos.

### A6. Migrar datos entre la VM y Atlas [DOC] [no ensayado en el repo]

```bash
# De la VM a Atlas
mongodump --host 127.0.0.1:27017 -u adminG11 --authenticationDatabase admin --db u8_g11 --out ~/migracion
mongorestore --uri "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --username admin_grupo11 \
  --nsFrom 'u8_g11.*' --nsTo 'u8_g11_atlas.*' ~/migracion

# De Atlas a la VM
mongodump --uri "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --username admin_grupo11 --db practicaU10 --out ~/desde_atlas
mongorestore --host 127.0.0.1:27017 -u adminG11 --authenticationDatabase admin ~/desde_atlas
```
Verificar con recuentos en origen y destino. Vigilar el límite de 512 MB del plan Free.

---

## B. Entrega: informe `GrupoN.pdf`

### B1. Formato de entrega del laboratorio integrador [CONSIGNA]

**Qué se entrega:** **un único archivo PDF** subido a la tarea del laboratorio en Moodle, con el nombre exacto `GrupoN.pdf`. Para este grupo: **`Grupo11.pdf`** (ejemplos de la cátedra: `Grupo01.pdf`, `Grupo05.pdf`). Tiempo máximo orientativo: **4 horas (240 min)**.

**Contenido exigido** (consigna, apartado *Contenido exigido en `GrupoN.pdf`*):

| # | Elemento | Qué debe incluir |
| :-: | :--- | :--- |
| 1 | **Carátula** | Nombre del grupo y **apellido y nombre de los integrantes presentes** |
| 2 | **Enunciados** | El enunciado **completo** de cada ejercicio (copiado de la guía) |
| 3 | **Código y comandos** | Sentencias SQL, scripts `.sql` / `.js` / `.sh` e instrucciones o comandos de terminal ejecutados |
| 4 | **Evidencias** | Capturas de pantalla **legibles** con los resultados de cada ejecución y/o imágenes que permitan **comprobar objetivamente** que la solución resuelve el problema |
| 5 | **Nota aclaratoria** *(opcional)* | Al final de **cada ejercicio**: aclaraciones, inconvenientes técnicos o casos límite encontrados |

**Estructura del PDF** (orden de la guía; los ejercicios van numerados del 1 al 12 y el Bloque 4 como 4.1 a 4.3):

```
Carátula
Bloque 1 · Administración y rendimiento relacional (MySQL 9.7)      Ejercicios 1 a 6
Bloque 2 · Datos semiestructurados en MySQL (JSON)                   Ejercicios 7 y 8
Bloque 3 · NoSQL documental (MongoDB 8.0)                            Ejercicios 9 a 12
Bloque 4 · Competencias CGSPA y transparencia                        4.1 Matriz de roles · 4.2 Notas DBA · 4.3 Declaración de IA
```

**Bloque de cada ejercicio** (repetir en cada uno, sin saltear ninguno):

```
Ejercicio N.x — <título>
  Enunciado  : texto completo de la guía
  Código     : sentencias / script / comandos ejecutados
  Evidencias : captura(s) legible(s) + una frase de qué demuestra cada una
  Nota aclaratoria (opcional): inconvenientes o casos límite
```

### B2. Bloque 4: qué hay que redactar [CONSIGNA]

**4.1 Matriz de distribución de roles y coevaluación (Cap. 5.1).** Indicar qué integrante **lideró** o **colaboró** en cada función durante las 4 horas, más **un texto de máximo 5 líneas** sobre cómo el grupo resolvió los desacuerdos técnicos. La consigna recomienda **hacer las asignaciones al inicio** del laboratorio.

| Función / dimensión técnica | Integrante que lanza / lidera | Integrante colaborador | Evidencia / entregable |
| :--- | :--- | :--- | :--- |
| Navegación de fuentes oficiales | *Nombre y apellido* | *Nombre y apellido* | Comandos y sintaxis verificada |
| Operación técnica en VM Ubuntu | *Nombre y apellido* | *Nombre y apellido* | Capturas de terminal y scripts SQL/Bash |
| Verificación y análisis de métricas | *Nombre y apellido* | *Nombre y apellido* | Planes `EXPLAIN` y logs de auditoría |
| Documentación y redacción final | *Nombre y apellido* | *Nombre y apellido* | Consolidación del PDF `GrupoN.pdf` |

**4.2 Notas de diagnóstico para Operaciones / DBA (Cap. 6.1).** Nota técnica **profesional** sobre la incidencia del **Ejercicio 5 (bloqueos)** y del **Ejercicio 6 (restauración PITR)**. Cada una con tres partes: **a) causa raíz**, **b) solución técnica aplicada**, **c) recomendaciones de prevención**.

**4.3 Declaración de transparencia de herramientas de apoyo e IA.** Incluir: **tareas en las que se usó asistencia tecnológica** (por ejemplo depuración de sintaxis SQL, optimización de comandos bash, estructura del informe) y **al menos un caso de verificación y corrección**: una sugerencia o comando que hubo que corregir respecto de la versión oficial del motor, con cómo se detectó y cómo se validó en la documentación. Casos reales ya ocurridos del grupo: `SHOW MASTER STATUS` no existe en MySQL 9.7 (usar `SHOW BINARY LOG STATUS`), `\G` dentro de `mysql -e` (usar `-E`), y `use base` dentro de un `.js` con `mongosh --file` (ver **T**).

### B3. Mínimos y límites que fija la guía [CONSIGNA]

| Ejercicio | Exigencia explícita |
| :--- | :--- |
| 1.2 | Justificar **en comentarios** la necesidad de cada privilegio de `usr_backup` |
| 2.3 | Registrar **tiempo y filas procesadas** de la carga masiva |
| 3.e | Comparar **filas, tiempo (ms) y costo**, antes y después de los índices |
| 3.g | Tabla comparativa + informe de rendimiento de **máximo 15 renglones** |
| 6.4 | **5 modificaciones identificables** entre el backup y la pérdida |
| 8.2 | **2 inserciones válidas y 2 inválidas** documentadas |
| 10.1 | Modelo documental **justificando** *embedding* frente a *referencing* |
| 12.1 | **2 inserciones válidas y 2 rechazadas** |
| 4.1 | Texto de desacuerdos de **máximo 5 líneas** |

### B4. Estilo del grupo
- Redactada como el grupo: "decidimos", "comprobamos", "notamos". Nada de instrucciones al lector.
- Cada resultado con su **interpretación** (qué demuestra), no solo la salida.
- Capturas con marcador `*[INSERTAR CAPTURA N: qué muestra]*` mientras se arma el borrador; **ninguno puede quedar en el PDF final**.
- Errores con el formato **Falla / Detección / Corrección** (alimenta las notas 4.2 y el caso de 4.3).
- Pruebas de permisos como tabla: identidad, acción, esperado, obtenido.

### B5. Reglas de evidencia
- **No inventar salidas.** Toda salida pegada sale de una ejecución real.
- **No mostrar contraseñas** en capturas ni archivos (`-p` sin valor, `passwordPrompt()`, `<clave>`).
- Cada captura debe **permitir comprobar objetivamente** el resultado: mostrar el **prompt, el comando y la salida** juntos, con texto legible (sin cortes ni recuadros partidos).
- Una captura de "backup activado" **no prueba** una restauración: hay que restaurar y comparar.
- Medir con repeticiones (mediana de 3, o 5 con la primera separada) y declarar el entorno.

### B6. Plantilla de las bitácoras por unidad (Parcial 1, usada en las Unidades 1 a 10)
No es el formato del laboratorio integrador (ver **B1**), pero sirve como guía para ordenar un ejercicio largo:
1. **Problema a resolver.**
2. **Decisiones técnicas:** qué construcciones u objetos se eligieron y por qué.
3. **Comandos y evidencias:** comandos, resultados, planes o capturas.
4. **Pruebas realizadas:** caso válido, caso inválido, caso límite.
5. **Errores y diagnóstico:** qué falló, cómo se detectó y cómo se corrigió.
6. **Uso de IA:** para qué, qué se validó y qué se descartó.
7. **Aprendizajes.**

Si la consigna trae su propia numeración, **seguir la de la consigna**.

---

## T. Trampas conocidas (todas ocurrieron o se comprobaron)

| Trampa | Síntoma | Solución |
| :--- | :--- | :--- |
| `gtid_mode=ON` en MySQL 9.7 | `ERROR 3546 ... GTID_PURGED` al restaurar; o PITR que "funciona" pero pierde las operaciones válidas sin avisar | `mysqldump --set-gtid-purged=OFF` y `mysqlbinlog --skip-gtids` (M10) |
| `SHOW MASTER STATUS` | `ERROR 1064` en 9.7 | `SHOW BINARY LOG STATUS` |
| `EXPLAIN` sale en árbol | No aparecen las columnas `type`, `key`, `Extra` | `EXPLAIN FORMAT=TRADITIONAL` |
| `\G` en `mysql -e "..."` | `Unknown command '\G'` | Usar `mysql -E -e "..."` (salida vertical) |
| Binlog en `/var/log/mysql` | `mysqlbinlog` no encuentra el archivo | `SELECT @@log_bin_basename;` → `/var/lib/mysql/binlog.*` |
| Rol creado pero sin efecto | El usuario sigue sin permisos | `SET DEFAULT ROLE ALL TO 'u'@'%';` |
| `blocking_query` engañosa | Muestra otra sentencia o `NULL` | La prueba del bloqueo es `performance_schema.data_locks` |
| `root` de MySQL en Ubuntu | `Access denied` con clave | `sudo mysql` (autenticación por socket) |
| `use base` en un `.js` con `mongosh --file` | No ejecuta nada y no avisa | `db = db.getSiblingDB("base")` |
| CRUD en la base equivocada | El prompt dice `test>` | Revisar el prompt o `db.getName()` |
| Condiciones sobre un arreglo | Resultados que mezclan elementos | `$elemMatch` |
| `mongorestore` sobre datos existentes | Errores de clave duplicada | `--drop` o restaurar con `--nsFrom`/`--nsTo` |
| Tiempos de 0 ms en `explain` | No se puede comparar | Más volumen y comparar `totalDocsExamined` |
| IP nueva en el aula | Atlas no responde (*timeout*) | *Network Access → Add Current IP Address* |
| `db.createUser()` en Atlas | Rechazado aun como `atlasAdmin` | Crear el usuario en *Database Access* |
| Volver a correr un script con `drop()` en Atlas | Cambian los `_id` y las capturas dejan de coincidir | No re-ejecutar scripts de carga sobre datos ya capturados |
| Pausa interactiva dentro de `while read < archivo` | El script se "come" líneas | Leer el archivo por otro descriptor (`read -u 9`, `done 9< archivo`) |
| `pgrep -f <patrón>` en un script | Mata la propia shell | Buscar por PID o puerto (`ss -lntp`) |

---

## F. Fuentes en el repo (para profundizar)

| Tema | Archivo |
| :--- | :--- |
| Teoría de Unidades 1 a 6 (MySQL, con preguntas) | `Parcial 1/apunte_parcial_1.md` |
| Diseño físico, índices, medición | `Parcial 1/Unidad 2/Actividad 2 /` (`Kit_Estudiantes_MySQL/`, `bitacora-entregable.md`) |
| SQL avanzado | `Parcial 1/Unidad 3 y 4/Actividad 1/resolucion_actividad1.sql` |
| Reglas: CHECK, trigger, función, procedimiento | `Parcial 1/Unidad 3 y 4/Actividad 2/resolucion_actividad2.sql` y `pruebas_actividad2.sql` |
| Migración v1 → v2 con rollback | `Parcial 1/Unidad 3 y 4/Actividad 3/01_*.sql` a `06_*.sql` |
| Conectividad y Workbench | `Parcial 1/Unidad 5/Actividad 1/guia_paso_a_paso.md` y `U5-Actividad1-Etapa1-Conectividad-Guiada-2026.md` |
| Bloqueos, aislamiento, deadlock | `Parcial 1/Unidad 5/Actividad 2/U5_A2_MySQL_3_experimentos_estudiantes.sql` |
| Permisos, backup, PITR, HA | `Parcial 1/Unidad 6/Actividad 1/` (`solucion_u6_actividad1.sql`, `guia_paso_a_paso.md`) |
| JSON, FULLTEXT, índice multivaluado | `Parcial 2/Unidad 7/Actividad 2/solucion_u7_actividad2.sql` |
| Modelado, CRUD, agregación, índices MongoDB | `Parcial 2/Unidad 8/Actividad 1/solucion_u8_actividad1.js` |
| Autenticación, roles, TLS, respaldo MongoDB | `Parcial 2/Unidad 8/Actividad 2/solucion_u8_actividad2.sh` y `solucion_u8_actividad2_mongosh.js` |
| Atlas | `Parcial 2/Unidad 10/Actividad 1/` (`consigna3.js`, `consigna4_accesos.js`, `consigna5_backup.txt`) |
| Documentación oficial Atlas Free | https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/ |
