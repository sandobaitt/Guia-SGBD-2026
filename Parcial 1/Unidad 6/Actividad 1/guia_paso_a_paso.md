# Guía Paso a Paso: U6 - Actividad 1 (Operación Rescate)
**Grupo:** G11 (Escenario: Logística y Depósitos)  
**Motor:** MySQL 8.0+ / MySQL Workbench  

---

## 1. Preparación del Entorno

### 1.1. Cargar la Base de Datos Inicial
Desde MySQL Workbench (o consola de Linux como usuario `root`):
```bash
mysql -u root -p < mysql_u6_operacion_rescate_base.sql
```
Esto creará la base `u6_rescate`, las tablas (`cliente`, `cuenta`, `movimiento`, `auditoria_evento`), los datos iniciales y los usuarios de laboratorio (`u6_app`, `u6_analista`, `u6_auditor`) con contraseña `Cambiar_2026!`.

### 1.2. Verificar Activación del Binary Log (Binlog)
El registro binario es **indispensable** para realizar recuperaciones puntuales (PITR - *Point-In-Time Recovery*).  
Ejecutar en MySQL:
```sql
SHOW VARIABLES LIKE 'log_bin';
```
- Si el valor es `ON`, MySQL ya tiene habilitado el binlog (por defecto en MySQL 8).
- Si estuviera en `OFF`, editar `/etc/mysql/mysql.conf.d/mysqld.cnf` y agregar:
  ```ini
  [mysqld]
  server-id = 1
  log_bin = /var/log/mysql/mysql-bin.log
  binlog_format = ROW
  ```
  y reiniciar el servicio con `sudo systemctl restart mysql`.

---

## 2. Fase 1: El Usuario Infiltrado (Seguridad y Mínimo Privilegio)

### 2.1. Conexión como Usuarios de Prueba
En MySQL Workbench, crear 3 conexiones adicionales (o usar terminal):
- **Conexión App:** Usuario `u6_app`, Clave `Cambiar_2026!`, Base `u6_rescate`
- **Conexión Analista:** Usuario `u6_analista`, Clave `Cambiar_2026!`, Base `u6_rescate`
- **Conexión Auditor:** Usuario `u6_auditor`, Clave `Cambiar_2026!`, Base `u6_rescate`

### 2.2. Demostración de los 3 Accesos Indebidos (Antes de Corregir)
Ejecutar cada consulta desde la sesión del usuario correspondiente y **tomar captura**:

1. **Acceso Indebido 1 (`u6_app` ejecutando DDL destructivo):**
   *Abrir pestaña con usuario `u6_app`:*
   ```sql
   CREATE TABLE u6_rescate.backdoor_test (id INT PRIMARY KEY, nota VARCHAR(50));
   DROP TABLE u6_rescate.backdoor_test;
   ```
   *Evidencia:* Las sentencias se ejecutan sin error. Una app web con `DROP` o `CREATE` permite que una vulnerabilidad (como SQL Injection) destruya la base.
2. **Acceso Indebido 2 (`u6_analista` modificando saldos bancarios):**
   *Abrir pestaña con usuario `u6_analista`:*
   ```sql
   UPDATE u6_rescate.cuenta SET saldo = saldo + 500000.00 WHERE cuenta_id = 101;
   ```
   *Evidencia:* Modificación exitosa de saldos por un perfil que solo debería consultar reportes.
   *(Revertir con `UPDATE u6_rescate.cuenta SET saldo = saldo - 500000.00 WHERE cuenta_id = 101;` para mantener la base limpia).*
3. **Acceso Indebido 3 (`u6_app` borrando registros de auditoría):**
   *Abrir pestaña con usuario `u6_app`:*
   ```sql
   DELETE FROM u6_rescate.auditoria_evento WHERE evento = 'SETUP';
   ```
   *Evidencia:* Un usuario operativo borra registros del sistema de trazabilidad forense.
   *(Re-insertar desde `root`: `INSERT INTO u6_rescate.auditoria_evento(usuario, evento, detalle) VALUES ('root@localhost', 'SETUP', 'Base inicial');`).*

---

### 2.3. Aplicación del Hardening (Mínimo Privilegio - PoLP)
Desde la sesión de administrador (`root`), abrir y ejecutar la **Sección 2** de `solucion_u6_actividad1.sql`:
```sql
USE u6_rescate;

-- Revocación de permisos peligrosos
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_app;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_analista;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_auditor;

-- Asignación estricta por función:
-- rol_app: DML de negocio (sin DDL y sin DELETE en movimientos)
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cliente TO rol_app;
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cuenta TO rol_app;
GRANT SELECT, INSERT ON u6_rescate.movimiento TO rol_app;
GRANT INSERT ON u6_rescate.auditoria_evento TO rol_app;

-- rol_analista: Estrictamente SELECT de negocio
GRANT SELECT ON u6_rescate.cliente TO rol_analista;
GRANT SELECT ON u6_rescate.cuenta TO rol_analista;
GRANT SELECT ON u6_rescate.movimiento TO rol_analista;

-- rol_auditor: Solo lectura en auditoría y negocio
GRANT SELECT ON u6_rescate.auditoria_evento TO rol_auditor;
GRANT SELECT ON u6_rescate.cliente TO rol_auditor;
GRANT SELECT ON u6_rescate.cuenta TO rol_auditor;
GRANT SELECT ON u6_rescate.movimiento TO rol_auditor;

-- Activar roles por defecto en MySQL 8
SET DEFAULT ROLE ALL TO 'u6_app'@'%';
SET DEFAULT ROLE ALL TO 'u6_analista'@'%';
SET DEFAULT ROLE ALL TO 'u6_auditor'@'%';

FLUSH PRIVILEGES;
```

---

### 2.4. Demostración de Bloqueo (Re-ejecución)
Volver a ejecutar las pruebas indebidas desde cada usuario:
1. Con `u6_app`:
   ```sql
   DROP TABLE u6_rescate.cuenta;
   ```
   **Resultado:** `ERROR 1142 (42000): DROP command denied to user 'u6_app'@'%' for table 'cuenta'`. *(Tomar captura)*.
2. Con `u6_analista`:
   ```sql
   UPDATE u6_rescate.cuenta SET saldo = 999999 WHERE cuenta_id = 101;
   ```
   **Resultado:** `ERROR 1142 (42000): UPDATE command denied to user 'u6_analista'@'%' for table 'cuenta'`. *(Tomar captura)*.
3. Con `u6_app`:
   ```sql
   DELETE FROM u6_rescate.movimiento WHERE movimiento_id = 1001;
   ```
   **Resultado:** `ERROR 1142 (42000): DELETE command denied to user 'u6_app'@'%' for table 'movimiento'`. *(Tomar captura)*.

---

## 3. Fase 2: El DBA borró producción (Backup y PITR)

### 3.1. Medición de la Línea de Base
Desde la sesión de administrador (`root`), ejecutar:
```sql
USE u6_rescate;
SELECT COUNT(*) AS total_clientes FROM cliente;
SELECT COUNT(*) AS total_cuentas FROM cuenta;
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;
```
**Valores esperados:**
- Clientes: 4
- Cuentas: 4
- Movimientos: 5
- Suma de importes: **$73.000,00** (50000 - 12000 + 30000 - 5000 + 10000)

---

### 3.2. Generación del Backup Lógico Consistente
Abrir la terminal del sistema operativo (en la máquina donde corre MySQL):
```bash
mysqldump -u root -p \
  --single-transaction \
  --flush-logs \
  --source-data=2 \
  --databases u6_rescate > backup_u6_rescate_inicial.sql
```
*(Nota: si se utiliza una versión de MySQL anterior a 8.0.26, usar `--master-data=2` en lugar de `--source-data=2`).*

> **¿Qué hace cada parámetro?**
> - `--single-transaction`: Crea una transacción consistente en InnoDB sin bloquear lecturas ni escrituras en producción.
> - `--flush-logs`: Rota el archivo binlog en el instante exacto del backup, cerrando el anterior e iniciando uno nuevo.
> - `--source-data=2`: Escribe en las primeras líneas del archivo `.sql` el nombre del binlog y la posición exacta de corte (ej. `CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE='binlog.000002', SOURCE_LOG_POS=157;`).

Para comprobar las coordenadas registradas en el archivo:
```bash
head -n 30 backup_u6_rescate_inicial.sql | grep -i "source_log" || head -n 30 backup_u6_rescate_inicial.sql | grep -i "master_log"
```

---

### 3.3. Ejecutar Operaciones Válidas Posteriores al Backup
En MySQL Workbench (o consola de MySQL como `root`):
```sql
USE u6_rescate;

INSERT INTO movimiento VALUES (1006, 101, '2026-09-22 10:05:00', 'CREDITO', 15000.00, 'Operacion valida posterior al backup');
INSERT INTO movimiento VALUES (1007, 102, '2026-09-22 10:12:00', 'DEBITO', -7000.00, 'Operacion valida posterior al backup');
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'OPERACIONES_VALIDAS', 'Se ejecutaron movimientos 1006 y 1007');
```
*Estado intermedio legítimo:*
- Movimientos: **7**
- Suma de importes: **$81.000,00** ($73.000 + 15.000 - 7.000).

---

### 3.4. Simulación del Incidente de Borrado Accidental
Ejecutar el comando erróneo en MySQL:
```sql
USE u6_rescate;

DELETE FROM movimiento WHERE cuenta_id = 101;
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'INCIDENTE', 'Borrado accidental de movimientos de cuenta 101');
```
Verificar el desastre en la base:
```sql
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;
```
*Estado dañado:*
- Movimientos: bajan a **4** (se perdieron los movimientos 1001, 1002 y el 1006, todos de la cuenta 101).
- Suma de importes: queda en **$18.000,00**.

---

### 3.5. Procedimiento Forense y Determinación del PITR
Para recuperar la base **sin perder los movimientos legítimos 1006 y 1007**, debemos aplicar las transacciones del log binario deteniéndonos **inmediatamente antes** de la sentencia `DELETE`.

1. **Identificar los binlogs activos en MySQL:**
   ```sql
   SHOW BINARY LOGS;
   ```
2. **Inspeccionar los eventos del binlog:**
   Podemos ver los eventos directamente desde SQL:
   ```sql
   -- Sustituir por el nombre del binlog que inició tras el flush-logs (ej. binlog.000002)
   SHOW BINLOG EVENTS IN 'binlog.000002';
   ```
   O desde la terminal de Linux inspeccionando el texto decodificado:
   ```bash
   sudo mysqlbinlog --verbose --base64-output=DECODE-ROWS /var/log/mysql/binlog.000002 > binlog_analisis.sql
   ```
   Buscar la palabra `DELETE FROM movimiento`:
   - Encontrar la posición (`end_log_pos`) del último `COMMIT` antes del `DELETE`. Supongamos que el `DELETE` comienza en la posición `1245` y el `COMMIT` de las operaciones válidas terminó en la posición `980`.
   - O bien tomar la hora exacta (`--stop-datetime="2026-09-22 10:13:00"`).

---

### 3.6. Ejecución del Restore y Point-In-Time Recovery (PITR)
En la terminal de Linux:

**Paso 1: Restaurar el Backup Lógico Base**
```bash
mysql -u root -p u6_rescate < backup_u6_rescate_inicial.sql
```
*(En este punto, la base vuelve al estado con 5 movimientos y $73.000,00).*

**Paso 2: Replay del Binlog hasta el Punto Objetivo**
Aplicar las transacciones ocurridas entre el backup y el momento justo antes del borrado:
```bash
# Método A: Por posición exacta (el más seguro y preciso)
sudo mysqlbinlog --start-position=157 --stop-position=<POSICION_JUSTO_ANTES_DEL_DELETE> /var/log/mysql/binlog.000002 | mysql -u root -p u6_rescate

# Método B: Por fecha/hora
sudo mysqlbinlog --stop-datetime="2026-09-22 10:13:00" /var/log/mysql/binlog.000002 | mysql -u root -p u6_rescate
```

---

### 3.7. Validación del Estado Final
En MySQL Workbench (o consola):
```sql
USE u6_rescate;

SELECT COUNT(*) AS total_clientes FROM cliente;
SELECT COUNT(*) AS total_cuentas FROM cuenta;
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;

-- Confirmar que están todos los movimientos de la cuenta 101 intactos:
SELECT * FROM movimiento ORDER BY movimiento_id;
```
**Resultado validado con éxito:**
- Total Clientes: **4**
- Total Cuentas: **4**
- Total Movimientos: **7** (incluyendo el 1001, 1002, 1003, 1004, 1005, 1006 y 1007).
- Suma Total de Importes: **$81.000,00**.
*(Tomar captura del resultado final)*.

---

## 4. Fase 3: Diseñar para Sobrevivir (G11 - Logística y Depósitos)

### 4.1. Requisitos del Escenario G11
- **Negocio:** Control central de stock, preparación de pedidos (picking) y despachos para múltiples depósitos. Si el sistema se cae, los operarios y camiones quedan detenidos físicamente en las plantas.
- **RPO:** 15 minutos (máxima pérdida de datos tolerada ante desastre).
- **RTO:** 30 minutos (tiempo máximo permitido para restablecer la operatoria).
- **Restricción:** Presupuesto medio; infraestructura limitada a **dos nodos principales**.

### 4.2. Síntesis de la Arquitectura Propuesta
1. **Topología de Nodos:**
   - **Nodo 1 (Primario / Read-Write):** Atiende la operatoria transaccional continua de los depósitos.
   - **Nodo 2 (Secundario / Read-Only & Standby):** Réplica con **MySQL Semi-Synchronous Replication**. Los commits se confirman cuando al menos el nodo secundario escribió la transacción en su Relay Log, garantizando **RPO = 0** ante caída física del servidor primario.
2. **Estrategia de Backup y PITR (para Error Humano):**
   - Backup físico/lógico completo diario fuera de hora pico (02:00 AM) comprimido hacia almacenamiento secundario.
   - Streaming/archivo continuo de Binary Logs cada 5 minutos hacia un almacenamiento NFS/S3 externo. Esto garantiza cumplir con el **RPO de 15 min** incluso si se destruyen ambos nodos locales.
   - Procedimiento de PITR documentado y ensayado periódicamente.
3. **Mecanismo de Failover (RTO ≤ 30 min):**
   - Utilización de IP Virtual con Keepalived o ProxySQL frente a los dos nodos. Conmutación automática o semi-asistida en < 2 minutos.
4. **Riesgo y Limitación Reconocida:**
   - Al contar con solo 2 nodos, no existe quórum de 3 nodos (riesgo de split-brain ante partición de red si el failover es automático desatendido). Por eso se implementa un switch asistido con health check o ping a gateway externo.
   - La replicación propaga los errores humanos en milisegundos; por ende, la réplica NO protege contra el borrado accidental, para lo cual es estrictamente necesario el respaldo con binlogs (PITR).
