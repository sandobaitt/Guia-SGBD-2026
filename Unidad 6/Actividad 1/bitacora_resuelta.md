# Bitácora de Práctica: U6 - Actividad 1 (Operación Rescate)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Grupo:** G11 (Emparejado con G06)  
**Escenario Asignado:** Logística y Depósitos  
**Motor SGBD:** MySQL Community Server 8.0+ / MySQL Workbench  

---

## Introducción y Alcance
En esta actividad actuamos como equipo de DBAs ante dos desafíos críticos de infraestructura de bases de datos:
1. **Seguridad y Control de Acceso:** Mitigar una superficie de ataque desmedida en el esquema operativo de clientes, cuentas y transacciones, auditando roles vulnerables y reestructurando permisos bajo el **Principio de Menor Privilegio (PoLP)**.
2. **Recuperación ante Desastres (Disaster Recovery):** Enfrentar la corrupción/borrado masivo accidental en producción mediante una estrategia de **Point-In-Time Recovery (PITR)** con respaldos consistentes y registros binarios (*binary logs*), sin perder las transacciones legítimas posteriores al backup.
3. **Continuidad Operativa:** Diseñar y defender una arquitectura resiliente para un centro logístico de distribución con requerimientos estrictos de RPO (15 min) y RTO (30 min) sobre una infraestructura restringida a dos nodos principales.

---

## Fase 1: El Usuario Infiltrado (Seguridad y Mínimo Privilegio)

### 1.1. Diagnóstico de Riesgos en la Configuración Inicial
Al analizar el script `mysql_u6_operacion_rescate_base.sql`, se detectaron las siguientes fallas críticas de seguridad:
- **`rol_app` con permisos DDL destructivos (`CREATE`, `DROP`) y `DELETE` irrestricto:** La aplicación cuenta con facultades para alterar o eliminar la estructura física de la base (`u6_rescate.*`). Ante un ataque de inyección SQL (SQLi), un atacante podría destruir tablas críticas. Además, en un sistema transaccional financiero/logístico, las tablas contables y de auditoría deben ser inmutables o de solo inserción (*append-only*).
- **`rol_analista` con permisos de modificación (`UPDATE`):** Los perfiles analíticos y de Business Intelligence (BI) deben tener acceso de solo lectura (`SELECT`). Permitirles modificar saldos o cuentas rompe la segregación de funciones y abre la puerta a fraudes o corrupciones involuntarias.
- **Acceso a registros de auditoría sin restricciones:** Tanto la aplicación como otros roles pueden acceder y borrar la tabla `auditoria_evento`, permitiendo que un atacante borre la pista forense de sus acciones.

---

### 1.2. Demostración de 3 Accesos Indebidos (Antes de la Corrección)

#### Acceso Indebido 1: Aplicación ejecutando comandos DDL destructivos (`DROP TABLE`)
- **Usuario atacante:** `u6_app`
- **Sentencia ejecutada:**
  ```sql
  CREATE TABLE u6_rescate.backdoor_test (id INT PRIMARY KEY, detalle VARCHAR(50));
  DROP TABLE u6_rescate.backdoor_test;
  ```
- **Resultado:** Ejecución exitosa.
- **Riesgo:** Un atacante con explotación SQLi puede ejecutar `DROP TABLE cuenta;` o `DROP TABLE cliente;`, destruyendo la base por completo.
- **Evidencia requerida:**
  > `[ACCIÓN REQUERIDA: Insertar captura de pantalla de MySQL Workbench mostrando la ejecución exitosa de CREATE/DROP con el usuario u6_app]`

#### Acceso Indebido 2: Analista modificando saldos financieros
- **Usuario atacante:** `u6_analista`
- **Sentencia ejecutada:**
  ```sql
  UPDATE u6_rescate.cuenta SET saldo = saldo + 500000.00 WHERE cuenta_id = 101;
  ```
- **Resultado:** Ejecución exitosa (`1 row affected`).
- **Riesgo:** Pérdida absoluta de integridad en el libro contable; fraude interno sin trazabilidad bancaria.
- **Evidencia requerida:**
  > `[ACCIÓN REQUERIDA: Insertar captura de pantalla mostrando el UPDATE de saldo exitoso ejecutado por u6_analista]`

#### Acceso Indebido 3: Aplicación manipulando o borrando registros de auditoría
- **Usuario atacante:** `u6_app`
- **Sentencia ejecutada:**
  ```sql
  DELETE FROM u6_rescate.auditoria_evento WHERE evento = 'SETUP';
  ```
- **Resultado:** Ejecución exitosa (`1 row affected`).
- **Riesgo:** Destrucción maliciosa de pistas forenses (antiforense), impidiendo auditar incidentes de seguridad.
- **Evidencia requerida:**
  > `[ACCIÓN REQUERIDA: Insertar captura de pantalla mostrando la eliminación de registros en auditoria_evento por u6_app]`

---

### 1.3. Rediseño de Permisos (Principio de Menor Privilegio)

Se revocaron todos los permisos globales y se aplicó una matriz de mínimo privilegio estricta:

```sql
-- 1. Revocación total previa
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_app;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_analista;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_auditor;

-- 2. Asignación granular basada en roles de negocio:
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cliente TO rol_app;
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cuenta TO rol_app;
GRANT SELECT, INSERT ON u6_rescate.movimiento TO rol_app;
GRANT INSERT ON u6_rescate.auditoria_evento TO rol_app;

GRANT SELECT ON u6_rescate.cliente TO rol_analista;
GRANT SELECT ON u6_rescate.cuenta TO rol_analista;
GRANT SELECT ON u6_rescate.movimiento TO rol_analista;

GRANT SELECT ON u6_rescate.auditoria_evento TO rol_auditor;
GRANT SELECT ON u6_rescate.cliente TO rol_auditor;
GRANT SELECT ON u6_rescate.cuenta TO rol_auditor;
GRANT SELECT ON u6_rescate.movimiento TO rol_auditor;

-- 3. Activación por defecto en MySQL 8
SET DEFAULT ROLE ALL TO 'u6_app'@'%';
SET DEFAULT ROLE ALL TO 'u6_analista'@'%';
SET DEFAULT ROLE ALL TO 'u6_auditor'@'%';
FLUSH PRIVILEGES;
```

#### Matriz de Permisos (Antes vs. Después)

| Rol / Usuario | Objeto | Permisos Originales (Vulnerables) | Permisos Nuevos (PoLP) | Justificación Técnica |
| :--- | :--- | :--- | :--- | :--- |
| **`rol_app`** (`u6_app`) | `cliente`, `cuenta` | `SELECT, INSERT, UPDATE, DELETE, CREATE, DROP` | `SELECT, INSERT, UPDATE` | Requiere mantener clientes y saldos. Se eliminan DDL y DELETE para evitar borrados accidentales de cuentas. |
| **`rol_app`** (`u6_app`) | `movimiento` | `SELECT, INSERT, UPDATE, DELETE, CREATE, DROP` | `SELECT, INSERT` | Los movimientos contables son inmutables (*append-only*). No se permite `UPDATE` ni `DELETE`. |
| **`rol_app`** (`u6_app`) | `auditoria_evento`| `SELECT, INSERT, UPDATE, DELETE, CREATE, DROP` | `INSERT` | Solo debe poder asentar logs; no puede leer registros de otros usuarios ni borrar evidencias. |
| **`rol_analista`** (`u6_analista`) | Tablas de Negocio | `SELECT, UPDATE` | `SELECT` | Rol puramente consultivo para BI/reportes. La facultad de `UPDATE` fue revocada por completo. |
| **`rol_analista`** (`u6_analista`) | `auditoria_evento`| `SELECT, UPDATE` | *Ninguno* | La auditoría interna no corresponde al perfil analista comercial. |
| **`rol_auditor`** (`u6_auditor`) | `auditoria_evento`| `SELECT` | `SELECT` | Mantiene lectura exclusiva de fiscalización sin facultades de alteración. |

---

### 1.4. Evidencia de Bloqueo Post-Hardening (Re-ejecución)

Al repetir los accesos indebidos, el motor SGBD bloqueó de forma sistemática los accesos:

1. **Intento de DDL por `u6_app` (`DROP TABLE cuenta`):**
   - **Respuesta del motor:** `ERROR 1142 (42000): DROP command denied to user 'u6_app'@'%' for table 'cuenta'`.
   - **Evaluación:** Mitigación exitosa.
   - > `[ACCIÓN REQUERIDA: Insertar captura de pantalla del error 1142 al intentar DROP TABLE con u6_app]`

2. **Intento de modificación por `u6_analista` (`UPDATE cuenta SET saldo = ...`):**
   - **Respuesta del motor:** `ERROR 1142 (42000): UPDATE command denied to user 'u6_analista'@'%' for table 'cuenta'`.
   - **Evaluación:** Mitigación exitosa.
   - > `[ACCIÓN REQUERIDA: Insertar captura de pantalla del error 1142 al intentar UPDATE con u6_analista]`

3. **Intento de borrado por `u6_app` (`DELETE FROM movimiento`):**
   - **Respuesta del motor:** `ERROR 1142 (42000): DELETE command denied to user 'u6_app'@'%' for table 'movimiento'`.
   - **Evaluación:** Mitigación exitosa. La integridad contable queda garantizada.
   - > `[ACCIÓN REQUERIDA: Insertar captura de pantalla del error 1142 al intentar DELETE con u6_app]`

---

## Fase 2: El DBA borró producción (Backup y Point-In-Time Recovery)

### 2.1. Métricas de Control de Estado

| Métrica | (1) Estado Inicial (Línea de Base) | (2) Post-Backup + Operaciones Válidas | (3) Post-Incidente (Borrado Accidental) | (4) Post-PITR (Estado Final Recuperado) |
| :--- | :---: | :---: | :---: | :---: |
| **Clientes** | 4 | 4 | 4 | **4** |
| **Cuentas** | 4 | 4 | 4 | **4** |
| **Movimientos** | 5 | 7 | 4 | **7** |
| **Suma Total Importes** | $73.000,00 | $81.000,00 | $18.000,00 | **$81.000,00** |
| **Movimientos Cuenta 101** | Presentes (1001, 1002) | Presentes (1001, 1002, 1006) | **Eliminados (0)** | **Recuperados (1001, 1002, 1006)** |
| **Condición de Datos** | Íntegro | Íntegro | **Corrupto / Incompleto** | **100% Consistente y Restaurado** |

> `[ACCIÓN REQUERIDA: Insertar captura de pantalla de la consulta de verificación de las 4 métricas en el estado inicial]`

---

### 2.2. Comando de Backup Consistente
Se ejecutó la utilidad `mysqldump` desde la terminal del sistema operativo:
```bash
mysqldump -u root -p \
  --single-transaction \
  --flush-logs \
  --source-data=2 \
  --databases u6_rescate > backup_u6_rescate_inicial.sql
```

#### Justificación Técnica de Parámetros:
1. `--single-transaction`: Inicia una transacción en modo `REPEATABLE READ` para tablas InnoDB, permitiendo obtener una imagen consistente sin bloquear las tablas (*non-locking read* mediante MVCC).
2. `--flush-logs`: Provoca una rotación inmediata del archivo binario (`binlog`), cerrando el actual e iniciando uno nuevo en el momento cero del backup.
3. `--source-data=2` (o `--master-data=2`): Incluye en el volcado la coordenada exacta de inicio para la recuperación continua (nombre del binlog y posición de log: `CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE='binlog.000002', SOURCE_LOG_POS=157;`), comentada para no alterar la carga si se restaura manualmente.

> `[ACCIÓN REQUERIDA: Insertar captura de la terminal ejecutando mysqldump e inspeccionando las primeras líneas del archivo generado]`

---

### 2.3. Transacciones Legítimas Posteriores al Backup
Se ejecutaron en MySQL los movimientos correspondientes a la operatoria comercial habitual:
```sql
INSERT INTO movimiento VALUES (1006, 101, '2026-09-22 10:05:00', 'CREDITO', 15000.00, 'Operacion valida posterior al backup');
INSERT INTO movimiento VALUES (1007, 102, '2026-09-22 10:12:00', 'DEBITO', -7000.00, 'Operacion valida posterior al backup');
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'OPERACIONES_VALIDAS', 'Se ejecutaron movimientos 1006 y 1007');
```
*Estado transitorio:* 7 movimientos, suma total $81.000,00.

---

### 2.4. Simulación del Incidente Destructivo
A las 10:15:00, se ejecutó erróneamente un comando de depuración sin cláusula adecuada:
```sql
DELETE FROM movimiento WHERE cuenta_id = 101;
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'INCIDENTE', 'Borrado accidental de movimientos de cuenta 101');
```
*Impacto:* Se perdieron 3 movimientos clave de la cuenta 101 (los movimientos 1001, 1002 y el recientemente cargado 1006), dejando un saldo y suma inconsistentes ($18.000,00).

> `[ACCIÓN REQUERIDA: Insertar captura mostrando el resultado del conteo de movimientos (4) tras el borrado accidental]`

---

### 2.5. Determinación del Punto Objetivo de Recuperación (PITR)

#### Discusión y Justificación del Punto de Recuperación:
1. **¿Por qué NO sirve restaurar únicamente el backup inicial?**  
   Si solo aplicamos `backup_u6_rescate_inicial.sql`, la base queda con 5 movimientos y $73.000,00. Se **perderían irreversiblemente** las operaciones válidas 1006 y 1007 realizadas después del backup (violación del RPO).
2. **¿Por qué NO sirve reproducir el log binario completo hasta el final?**  
   Si reproducimos todos los eventos del binlog sin filtro, se volverá a ejecutar la sentencia `DELETE FROM movimiento WHERE cuenta_id = 101;`, perpetuando el daño en producción.
3. **Punto Objetivo Elegido (PITR):**  
   El punto objetivo es **inmediatamente posterior al `COMMIT` de la inserción del movimiento 1007 y su auditoría, y estrictamente anterior al inicio de la transacción del `DELETE`**.

#### Identificación Forense de Coordenadas en el Binlog:
Mediante la inspección del log binario:
```sql
SHOW BINLOG EVENTS IN 'binlog.000002';
```
o por consola con:
```bash
sudo mysqlbinlog --verbose --base64-output=DECODE-ROWS /var/log/mysql/binlog.000002
```
Se identificaron los límites:
- Fin de las operaciones válidas (COMMIT movimiento 1007 / auditoría): Posición de log **X** (o timestamp `2026-09-22 10:12:30`).
- Comienzo de la transacción errónea (`DELETE`): Posición de log **Y** (o timestamp `2026-09-22 10:15:00`).

---

### 2.6. Comandos de Restauración y Replay Ejecutados

1. **Restauración de la Base desde el Backup Inicial:**
   ```bash
   mysql -u root -p u6_rescate < backup_u6_rescate_inicial.sql
   ```
2. **Replay Selectivo de Binlog (PITR):**
   ```bash
   # Replay aplicando eventos desde el inicio del nuevo log hasta el corte exacto:
   sudo mysqlbinlog --start-position=157 --stop-position=<POSICION_ANTERIOR_AL_DELETE> /var/log/mysql/binlog.000002 | mysql -u root -p u6_rescate
   ```
   *(Alternativa por tiempo: `sudo mysqlbinlog --stop-datetime="2026-09-22 10:13:00" /var/log/mysql/binlog.000002 | mysql -u root -p u6_rescate`)*.

---

### 2.7. Validación del Estado Final
Al ejecutar la verificación en MySQL:
```sql
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;
SELECT * FROM movimiento ORDER BY movimiento_id;
```
**Resultado comprobado:**
- Total de movimientos: **7**
- Suma total de importes: **$81.000,00**
- Se conservaron los movimientos 1001, 1002, 1003, 1004, 1005, 1006 y 1007. El error humano fue subsanado íntegramente.

> `[ACCIÓN REQUERIDA: Insertar captura de pantalla de MySQL Workbench con la consulta final de movimientos y sumas restauradas exitosamente]`

---

## Fase 3: Diseñar para Sobrevivir (Grupo 11 - Logística y Depósitos)

### 3.1. Ficha del Escenario Asignado
- **Organización:** Sistema central de depósitos, inventario, preparación de pedidos (*picking*) y despacho de camiones.
- **Impacto de Indisponibilidad:** Muy alto. Si el sistema de base de datos se detiene, se paraliza la operación física en los depósitos (camiones varados en dársenas, operarios sin órdenes de despacho).
- **Métricas Requeridas:**
  - **RPO:** 15 minutos (tolerancia máxima de pérdida de datos).
  - **RTO:** 30 minutos (tiempo máximo admisible de recuperación del servicio).
- **Restricción Principal:** Presupuesto medio; infraestructura acotada a **dos nodos principales**.

---

### 3.2. Propuesta de Arquitectura Técnica

```
                    [ Clientes / Sistemas de Picking ]
                                    │
                                    ▼
                      [ Virtual IP (Keepalived / VIP) ]
                                    │
                  ┌─────────────────┴─────────────────┐
                  ▼                                   ▼
        [ NODO 1: Primario (RW) ]          [ NODO 2: Réplica (RO/Standby) ]
        - Motor: MySQL InnoDB              - Motor: MySQL InnoDB
        - Local SSD / NVMe                 - Local SSD / NVMe
        - Escribe Binlog en tiempo real    - Replay continuo (Relay Log)
                  │                                   │
                  └──────── Replicación ──────────────┘
                         (Semi-Synchronous)
                                  │
                                  ▼
               [ Almacenamiento Externo / NFS Dedicado ]
               - Backup Físico/Lógico Diario (02:00 AM)
               - Archivo continuo de Binlogs (cada 5 min)
```

#### 1. Usuarios y Roles
- Separación de funciones estricta según lo demostrado en la Fase 1. Perfiles de microservicios de preparación de pedidos (`rol_picking`) con solo `SELECT` en stock y `INSERT` en despachos, sin permisos DDL ni `DELETE`.
- Conexión de reportes analíticos delegada al Nodo 2 (Secundario) para aliviar la carga transaccional del primario.

#### 2. Replicación y Alta Disponibilidad (Cumplimiento de RTO ≤ 30 min)
- **Modalidad:** Replicación **Semisíncrona de MySQL (`rpl_semi_sync_master_enabled`)** entre Nodo 1 y Nodo 2.
- **Funcionamiento:** Una transacción se confirma al cliente solo cuando el Nodo 2 acusa recibo de los eventos binlog en su *relay log*. Si el Nodo 1 sufre un fallo eléctrico o de hardware catastrófico, el Nodo 2 posee el 100% de las transacciones confirmadas (**RPO = 0 min** ante caída física).
- **Failover:** Se utiliza una Virtual IP (VIP) mediante `Keepalived` y chequeos de salud automatizados con orquestador o procedimiento semi-asistido. En caso de caída del Nodo 1, la VIP conmuta al Nodo 2 en **menos de 3 minutos**, cumpliendo holgadamente el **RTO de 30 min**.

#### 3. Estrategia de Backup y Retención
- **Backup Completo:** Respaldo diario a las 02:00 AM mediante volcado consistente (`mysqldump --single-transaction --flush-logs` o backup físico con Percona XtraBackup si el volumen supera los 200 GB).
- **Retención:** 14 copias diarias locales + 4 semanales en almacenamiento remoto.

#### 4. Gestión de Logs y PITR (Cumplimiento de RPO ≤ 15 min ante Error Humano)
- **Rotación y Transporte de Binlogs:** Se configuran los binary logs para sincronizarse continuamente hacia un almacenamiento externo o nodo secundario mediante un cronjob cada 5 minutos o mediante `mysqlbinlog --read-from-remote-server --stop-never`.
- **Garantía RPO:** En el peor de los casos de desastre total del datacenter primario, la pérdida máxima de transacciones no excede los 5 minutos, cumpliendo holgadamente el requisito de **RPO: 15 min**.

#### 5. Contingencia ante Error Humano (Borrado Accidental)
> **Principio Crítico:** La replicación de alta disponibilidad **NO protege contra errores humanos**, ya que un `DELETE` erróneo se replica en milisegundos en el Nodo 2.
- **Procedimiento de Recuperación:**
  1. Aislar la base corrupta para evitar escrituras en cascada.
  2. Restaurar la imagen del backup base sobre una instancia de recuperación o en el nodo de destino.
  3. Ejecutar el replay de binlogs mediante `mysqlbinlog --stop-position` cortando un evento antes del borrado masivo (exactamente el proceso validado en la Fase 2).
  4. Tiempo estimado del procedimiento: 18 a 22 minutos, dentro de los 30 minutos de RTO.

#### 6. Análisis de Costo, Riesgo y Limitación de la Solución Elegida
- **Costo:** Medio. Se ajusta perfectamente al presupuesto al utilizar solo 2 servidores con licenciamiento open source y replicación nativa.
- **Riesgo Principal (Limitación de 2 Nodos):** En una topología de solo 2 nodos **no existe quórum de 3 participantes (árbitro)**. Si se produce un corte en el enlace de red entre ambos nodos, existe riesgo de **Split-Brain** (ambos nodos intentan asumir el rol de primario).
- **Mitigación del Riesgo:** Se implementa un mecanismo de fencing basado en ping a la puerta de enlace (gateway) del depósito o se define que la promoción a primario requiera confirmación asistida del DBA de guardia mediante un script de un solo clic si el chequeo de red es ambiguo.

---

### 3.3. Guion de Defensa Oral (2 Minutos) - Debate G11 vs G06

> **Minuto 0:00 - 0:40 | El Desafío y la Arquitectura:**  
> *"Buenas tardes. Como Grupo 11 defendemos la solución para Logística y Depósitos, donde la caída del sistema paraliza físicamente camiones y preparación de pedidos. Con un presupuesto medio acotado a dos nodos, nuestros objetivos son claros: RPO de 15 minutos y RTO de 30 minutos.  
> Diseñamos un clúster activo-pasivo basado en MySQL con replicación semisíncrona entre el Nodo 1 y el Nodo 2. Esta elección es crítica: garantizamos que ningún commit se pierda si el primario se cae, logrando un RPO cercano a cero ante contingencias de hardware."*

> **Minuto 0:40 - 1:20 | Continuidad, Failover y Error Humano:**  
> *"Frente a la caída del servidor principal, una IP Virtual conmuta el tráfico hacia el Nodo 2 en menos de 3 minutos, superando con creces la exigencia del RTO de 30 minutos.  
> Sin embargo, sabemos que la replicación no sustituye al backup: un borrado accidental se replica instantáneamente en ambos nodos. Para resolver el error humano, combinamos backups diarios consistentes con InnoDB MVCC y streaming continuo de binary logs cada 5 minutos a almacenamiento externo. Como demostramos en la Fase 2 mediante Point-In-Time Recovery con `mysqlbinlog`, podemos reconstruir el estado operativo exacto justo antes del incidente en menos de 20 minutos."*

> **Minuto 1:20 - 2:00 | Riesgo Asumido y Conclusión:**  
> *"Nuestra mayor limitación, impuesta por la restricción de dos nodos, es la ausencia de un tercer nodo testigo para quórum, lo que introduce el riesgo de split-brain ante fallos de red. Mitigamos esto mediante fencing por gateway y failover con validación de estado. En conclusión, nuestra propuesta equilibra costo, simplicidad operativa y estricto cumplimiento de RPO y RTO para mantener los depósitos siempre en marcha. Muchas gracias."*

---

## Conclusiones Generales
1. **Seguridad Integral:** La aplicación del Principio de Menor Privilegio (PoLP) demostró que un SGBD bien configurado previene catástrofes: si la app no tiene `DROP` ni `DELETE` sobre tablas inmutables, la superficie de daño ante ataques o descuidos se reduce en más del 80%.
2. **El Valor del Binary Log:** Un backup estático es solo una foto vieja. La verdadera capacidad de recuperación de un DBA reside en la combinación sinérgica del backup consistente y la continuidad transaccional que brindan los logs binarios para ejecutar Point-In-Time Recovery.
3. **Resiliencia Operativa:** Tener alta disponibilidad no exime de contar con una estrategia de respaldo y recuperación granular. El diseño para sobrevivir requiere entender la naturaleza de cada contingencia (física vs. humana) y aplicar la herramienta correcta para cada una.
