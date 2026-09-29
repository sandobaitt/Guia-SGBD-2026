# Fundamentos Teóricos: U6 - Actividad 1 (Operación Rescate)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Tópicos:** Seguridad, Mínimo Privilegio (PoLP), Roles MySQL 8, Backups Consistentes, Binary Logs, Point-In-Time Recovery (PITR), RPO/RTO y Alta Disponibilidad vs Backups.  

---

## 1. Seguridad en SGBD y Principio de Menor Privilegio (PoLP)

### 1.1. Principio de Menor Privilegio (Principle of Least Privilege - PoLP)
El **Principio de Menor Privilegio (PoLP)** establece que cualquier entidad del sistema (usuario, proceso, microservicio, rol) debe poseer únicamente el conjunto mínimo y necesario de privilegios para llevar a cabo la función de negocio asignada, durante el tiempo estrictamente necesario.

En la arquitectura de bases de datos relacionales, el PoLP se traduce en:
1. **Segregación Estricta entre DDL y DML:**
   - **DDL (Data Definition Language):** Sentencias como `CREATE`, `ALTER`, `DROP`, `TRUNCATE`. Pertenecen exclusivamente a los DBAs, scripts de migración o procesos de despliegue automatizado (CI/CD). **Una aplicación en tiempo de ejecución jamás debe poseer privilegios DDL en un entorno productivo.**
   - **Riesgo:** Si un atacante vulnera la aplicación mediante Inyección SQL (SQLi) y el usuario de conexión posee permisos DDL, el atacante puede ejecutar `DROP TABLE` o `ALTER TABLE` y destruir el catálogo de datos.
2. **Inmutabilidad y Tablas Append-Only:**
   - En sistemas financieros, contables o logísticos (como en el escenario del Grupo 11), las transacciones y movimientos no se deben modificar ni eliminar. Un error contable se compensa con una contrapartida (un nuevo movimiento de signo contrario), no borrando el registro original.
   - Por ende, a la aplicación se le deben otorgar permisos de `SELECT` e `INSERT` sobre tablas de movimientos, revocando explícitamente `UPDATE` y `DELETE`.
3. **Segregación de Funciones (Separation of Duties - SoD):**
   - **Rol Analista / BI:** Requiere visibilidad de negocio para generar reportes y dashboards, pero no debe tener facultades de modificación (`UPDATE`/`DELETE`). Concederle `UPDATE` expone la base a manipulaciones fraudulentas o errores humanos.
   - **Rol Auditor:** Debe tener permisos de lectura sobre las tablas de trazabilidad y eventos de seguridad (`auditoria_evento`), garantizando que ni la aplicación ni los analistas puedan alterar o expurgar sus propios registros.

### 1.2. Implementación de Roles en MySQL 8.0+
MySQL 8 introdujo el estándar ANSI de **Control de Acceso Basado en Roles (RBAC)**:
- Un rol es un conjunto con nombre de privilegios (`CREATE ROLE rol_analista;`).
- Los privilegios se otorgan al rol (`GRANT SELECT ON base.* TO rol_analista;`).
- Los roles se asignan a usuarios (`GRANT rol_analista TO 'usuario'@'%';`).
- **Particularidad crítica en MySQL 8:** Por defecto, los roles asignados a un usuario no se activan automáticamente al iniciar sesión, salvo que se configure explícitamente:
  ```sql
  SET DEFAULT ROLE ALL TO 'usuario'@'%';
  ```
  o configurando la variable del sistema `activate_all_roles_on_login = ON`.

---

## 2. Clasificación y Mecanismos de Backup en SGBD

### 2.1. Backups Lógicos vs. Físicos

| Dimensión | Backup Lógico (ej. `mysqldump`) | Backup Físico (ej. `Percona XtraBackup`) |
| :--- | :--- | :--- |
| **Mecanismo** | Lee datos vía SQL y genera un archivo de texto con sentencias `CREATE TABLE` e `INSERT INTO`. | Copia bit a bit los archivos de datos subyacentes (`.ibd`, tablas de sistema, redo logs). |
| **Portabilidad** | Muy alta. Se puede restaurar en distintas arquitecturas, sistemas operativos o versiones del motor. | Restringida. Generalmente requiere la misma versión del motor y estructura de directorios. |
| **Velocidad de Backup** | Moderada/Baja en bases de datos de gran tamaño (requiere serialización SQL). | Extremadamente alta (limitada únicamente por la velocidad del disco/I/O). |
| **Velocidad de Restore** | Lenta en bases grandes (debe reinsertar datos y reconstruir índices secuencialmente). | Inmediata (solo requiere aplicar el redo log y montar los archivos de datos). |
| **Ideal para** | Bases pequeñas o medianas (< 50-100 GB), migraciones, análisis selectivo de esquemas. | Bases de datos de gran tamaño (> 100 GB), entornos de misión crítica con RTO muy exigente. |

### 2.2. Consistencia Transaccional con MVCC (`--single-transaction`)
En motores transaccionales como InnoDB, bloquear las tablas para hacer una copia (`LOCK TABLES`) es inaceptable en producción porque congela la operación del negocio.

El parámetro `--single-transaction` aprovecha el motor de **Control de Concurrencia Multiversión (MVCC)** de InnoDB:
1. Al comenzar el volcado, `mysqldump` ejecuta `START TRANSACTION WITH CONSISTENT SNAPSHOT`.
2. Se fija una vista consistente de la base bajo el nivel de aislamiento `REPEATABLE READ`.
3. El volcado lee las versiones de las filas correspondientes al instante exacto en que inició la transacción.
4. **Beneficio fundamental:** Las demás conexiones pueden seguir insertando, actualizando o borrando datos en producción sin interrupciones, mientras que el volcado lee una "fotografía" matemáticamente consistente en el tiempo.

### 2.3. Rotación de Logs y Coordenadas de Sincronización
- `--flush-logs`: Fuerza a MySQL a cerrar el archivo de log binario actual (ej. `binlog.000001`) y abrir uno inmediatamente correlativo (`binlog.000002`). Esto delimita claramente que todo lo volcado en el dump termina en el log previo, y todas las transacciones nuevas a partir del backup se registrarán en el nuevo archivo.
- `--source-data=2` (o `--master-data=2`): Escribe en las primeras líneas del archivo dump el nombre del binlog activo y la posición exacta en bytes al momento de la foto. Esa coordenada es el **punto de inicio (Start Position)** indispensable para cualquier proceso de recuperación incremental o PITR.

---

## 3. Logs de Transacciones y el Binary Log de MySQL

### 3.1. Diferencia entre Redo Log y Binary Log
En MySQL existen dos subsistemas de logs fundamentales que a menudo se confunden:

1. **Redo Log (Nivel Motor - InnoDB):**
   - Propósito: Garantizar la **Durabilidad (la 'D' de ACID)** y recuperación ante caídas del servidor (*Crash Recovery*).
   - Estructura: Buffer circular de tamaño fijo. Registra modificaciones físicas en páginas de disco.
   - Alcance: Exclusivo del motor InnoDB. No se utiliza para replicación ni para backups externos.
2. **Binary Log (Nivel Servidor MySQL):**
   - Propósito: **Replicación** a réplicas/lectores y **Recuperación Puntual (Point-In-Time Recovery)**.
   - Estructura: Secuencia histórica de archivos que crecen continuamente hasta un límite (`max_binlog_size`) y luego rotan (`binlog.000001`, `binlog.000002`, etc.).
   - Contenido: Registra todas las transacciones que modifican la estructura o los datos de la base de datos (DML y DDL).

### 3.2. Formatos de Registro del Binlog
- **STATEMENT:** Registra la sentencia SQL textual tal como fue emitida.  
  *Problema:* No es determinista (funciones como `NOW()`, `UUID()`, o sentencias sin `ORDER BY` pueden producir datos diferentes al reproducirse).
- **ROW (Predeterminado en MySQL 8):** Registra el cambio exacto a nivel de filas individuales (el valor anterior de las columnas y el nuevo valor). Es completamente determinista, inmune a no-determinismos de SQL y esencial para una recuperación consistente.
- **MIXED:** Utiliza `STATEMENT` por defecto y conmuta automáticamente a `ROW` ante sentencias no deterministas.

---

## 4. Point-In-Time Recovery (PITR)

### 4.1. El Dilema del Desastre Lógico (Error Humano)
Cuando ocurre un borrado accidental (`DELETE` sin cláusula `WHERE` o con filtro erróneo) o una actualización destructiva masiva, el DBA enfrenta una paradoja:
- **Si restaura únicamente el último backup completo:** Se recuperan las filas borradas por error, pero **se pierden todas las transacciones legítimas** que los usuarios realizaron entre la hora del backup y la hora del accidente.
- **Si reproduce el log binario completo hasta el final:** Las transacciones legítimas se recuperan, pero también **se vuelve a ejecutar la sentencia destructiva**, dejando la base en el mismo estado corrupto.

### 4.2. Principio y Mecánica del PITR
El **Point-In-Time Recovery (PITR)** es la técnica que permite reconstruir el estado de la base de datos exactamente al instante previo al incidente:

```
[ BACKUP BASE ] ──────> [ TX 1006 Válida ] ───> [ TX 1007 Válida ] ───┬─> [ INCIDENTE DELETE ]
 (mysqldump)                 (Binlog)                (Binlog)         │         (Binlog)
                                                                      │
                                                             [ CORTE PITR ]
                                                         (Stop Position / Datetime)
```

1. **Restauración de la Base Base:** Se carga el volcado (`mysqldump`), llevando la base al estado en que se encontraba al momento de la foto inicial.
2. **Análisis Forense del Binlog:** Con `mysqlbinlog` o `SHOW BINLOG EVENTS`, el DBA inspecciona el historial de eventos para localizar la posición del último `COMMIT` legítimo y la posición de inicio del comando erróneo.
3. **Replay Selectivo:** Se extraen y ejecutan en la base los eventos del binlog delimitando el punto de detención:
   ```bash
   mysqlbinlog --start-position=POS_INICIO --stop-position=POS_CORTE binlog.000002 | mysql -u root -p base
   ```
4. **Resultado:** Se obtienen todos los datos del backup base, más todas las transacciones válidas posteriores, omitiendo por completo el error humano.

---

## 5. Continuidad Operativa: RPO, RTO y Alta Disponibilidad

### 5.1. Definición de Métricas Clave

#### RPO (Recovery Point Objective - Objetivo de Punto de Recuperación)
- **Concepto:** Representa la **cantidad máxima de datos (medida en tiempo) que la organización está dispuesta a perder** ante un desastre.
- **Impacto:** Si un sistema tiene un RPO de 15 minutos, significa que ante un desastre catastrófico no pueden perderse más de 15 minutos de transacciones.
- **Dependencia Técnica:** Está determinado por la **frecuencia de respaldos** y la **frecuencia con que los logs transaccionales son transmitidos** fuera del servidor local.

#### RTO (Recovery Time Objective - Objetivo de Tiempo de Recuperación)
- **Concepto:** Representa el **tiempo máximo admisible que el sistema puede permanecer fuera de servicio** antes de que el impacto en el negocio sea inaceptable.
- **Impacto:** Si un sistema tiene un RTO de 30 minutos, el equipo técnico debe diagnosticar la falla, conmutar la infraestructura, levantar los servicios y verificar la consistencia en menos de 30 minutos.
- **Dependencia Técnica:** Está determinado por la **automatización del failover**, el tamaño de los datos a restaurar y la velocidad de procesamiento de I/O.

### 5.2. ¿Por qué la Replicación NO Reemplaza al Backup?
Uno de los errores conceptuales más frecuentes en gestión de TI es asumir que tener un nodo de réplica en tiempo real (*High Availability*) exime de tener una estrategia de backups.

> **Principio Fundamental:**  
> La replicación protege contra **fallos físicos de hardware o conectividad** (si se quema la placa madre del primario, la réplica toma el control).  
> Sin embargo, la replicación es un transmisor ciego de eventos: si un desarrollador o usuario ejecuta `DELETE FROM movimiento WHERE cuenta_id = 101;`, esa orden se transmite a la réplica en cuestión de milisegundos. **Ambos nodos quedan instantáneamente corruptos.**  
> Por ende, la **única protección real contra el error humano o corrupción de software es el Backup acompañado del Point-In-Time Recovery**.

### 5.3. Restricción de 2 Nodos y el Riesgo de Split-Brain
En arquitecturas acotadas a 2 nodos principales (como la impuesta al Grupo 11):
- **Problema:** Para determinar de forma matemática e indiscutible qué nodo debe asumir el rol de primario ante una caída de red, se requiere un sistema de quórum por mayoría simple ($N/2 + 1$). Con 2 nodos, la mayoría requerida es 2. Si se corta el enlace de red entre ambos nodos, ninguno tiene mayoría.
- **Riesgo (Split-Brain):** Si ambos nodos creen que el otro murió y ambos se promueven a servidores de lectura/escritura (primarios), los depósitos comenzarán a escribir datos divergentes en ambos equipos. La reconciliación posterior de esos datos es casi imposible sin pérdida de consistencia.
- **Solución Óptima:** 
  1. Uso de mecanismos de *fencing* (aislamiento mediante chequeo de un tercer punto neutro, como el router/gateway de red del depósito).
  2. Failover supervisado / asistido: automatizar el diagnóstico y la preparación, pero requerir validación del DBA o administrador de guardia para la promoción final.
