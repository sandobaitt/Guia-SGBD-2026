#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 6 - Binary logs, evento de rotación, backup base y PITR
# Uso: ./ej06_pitr.sh     (pide las claves de usr_g11 y usr_backup)
#   MYSQL_CON="-h 127.0.0.1 -P 3306"   destino para usr_g11
#   MYSQL_CON_BACKUP=""                usr_backup es @localhost (socket)
#   ROOT="sudo mysql"                  administrador para restaurar
#   BINLOG="sudo mysqlbinlog"          lector de binlogs (los archivos son de mysql)
#
# Nota sobre GTID (comprobado en MySQL 9.7): con gtid_mode=ON, un dump con
# GTID_PURGED falla al restaurarse en el mismo servidor (ERROR 3546) y, si el
# binlog se reaplica sin --skip-gtids, el servidor descarta en silencio las
# transacciones que ya ejecutó (se pierden las operaciones válidas). Por eso:
# mysqldump --set-gtid-purged=OFF y mysqlbinlog --skip-gtids (sirve con GTID ON y OFF).
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
CON_BK=${MYSQL_CON_BACKUP:-}
ROOT=${ROOT:-sudo mysql}
BINLOG=${BINLOG:-sudo mysqlbinlog}
BACKUP=${BACKUP_FILE:-$HOME/backup_employees_pitr.sql}
read -rsp "Clave de usr_g11: " PG; echo
read -rsp "Clave de usr_backup: " PB; echo
g11()  { MYSQL_PWD="$PG" mysql $CON -u usr_g11 --skip-comments -t employees "$@" 2>&1; }
g11n() { MYSQL_PWD="$PG" mysql $CON -u usr_g11 -N -B employees "$@" 2>&1; }
estado() {   # huella de lo que tocan las operaciones válidas y el incidente
  g11 -e "SELECT (SELECT COUNT(*) FROM departments) AS departamentos,
                 (SELECT COUNT(*) FROM employees)   AS empleados,
                 (SELECT COUNT(*) FROM titles)      AS cargos,
                 (SELECT salary FROM salaries WHERE emp_no = 10001 AND to_date = '9999-01-01') AS sueldo_10001,
                 (SELECT COUNT(*) FROM titles WHERE emp_no = 500001) AS cargos_500001"
}

echo "=== 6.1 Binary logs activos"
g11 -e "SELECT @@log_bin AS log_bin, @@log_bin_basename AS ubicacion, @@binlog_format AS formato,
               @@gtid_mode AS gtid_mode, @@binlog_expire_logs_seconds / 86400 AS retencion_dias"
g11 -e "SHOW BINARY LOGS"

echo; echo "=== 6.2 Evento que rota el binlog cada 10 minutos"
g11 -e "SELECT @@event_scheduler AS event_scheduler"
g11 -e "CREATE EVENT IF NOT EXISTS ev_rotar_binlog
          ON SCHEDULE EVERY 10 MINUTE
          COMMENT 'Lab G11 Ej 6.2: cierra el binlog actual cada 10 minutos'
          DO FLUSH LOGS"
g11 -e "SELECT EVENT_NAME, DEFINER, INTERVAL_VALUE, INTERVAL_FIELD, STATUS, LAST_EXECUTED
        FROM information_schema.EVENTS WHERE EVENT_SCHEMA = 'employees'"

echo; echo "=== 6.3 Backup base con usr_backup"
echo "\$ mysqldump -u usr_backup -p --single-transaction --flush-logs --source-data=2 --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > $BACKUP"
MYSQL_PWD="$PB" mysqldump $CON_BK -u usr_backup --single-transaction --flush-logs --source-data=2 \
  --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > "$BACKUP"
echo "código de salida: $? · tamaño: $(du -h "$BACKUP" | cut -f1)"
COORD=$(grep -m1 "CHANGE REPLICATION SOURCE TO" "$BACKUP"); echo "$COORD"
INI_FILE=$(echo "$COORD" | grep -o "SOURCE_LOG_FILE='[^']*'" | cut -d"'" -f2)
INI_POS=$(echo "$COORD" | grep -o "SOURCE_LOG_POS=[0-9]*" | cut -d= -f2)
echo "Estado en el momento del backup:"; estado

echo; echo "=== 6.4 Cinco modificaciones identificables posteriores al backup"
g11 -vvv -e "INSERT INTO departments VALUES ('d010', 'PITR Ciberseguridad')"
g11 -vvv -e "INSERT INTO employees VALUES (500001, '1995-05-05', 'Lautaro', 'Pitr', 'M', '2026-11-17')"
g11 -vvv -e "INSERT INTO titles VALUES (500001, 'Engineer', '2026-11-17', '9999-01-01')"
g11 -vvv -e "INSERT INTO salaries VALUES (500001, 70000, '2026-11-17', '9999-01-01')"
g11 -vvv -e "UPDATE salaries SET salary = salary + 1111 WHERE emp_no = 10001 AND to_date = '9999-01-01'"
echo "Estado OBJETIVO de la recuperación:"; estado | tee /tmp/ej06_objetivo.txt

echo; echo "=== 6.5 Incidente: borrado accidental de la tabla crítica titles"
g11 -vvv -e "DROP TABLE titles"
g11 -e "SELECT COUNT(*) FROM titles"

echo; echo "=== 6.6 PITR"
echo "--- Coordenadas de inicio (del backup): $INI_FILE posición $INI_POS"
echo "--- Búsqueda del DROP en los binlogs posteriores al backup (como administrador:"
echo "    SHOW BINLOG EVENTS exige REPLICATION SLAVE, que usr_g11 no tiene a propósito)"
FIN_FILE=""; FIN_POS=""; ARCHIVOS=()
for f in $(g11n -e "SHOW BINARY LOGS" | awk '{print $1}'); do
  [[ "$f" < "$INI_FILE" ]] && continue
  ARCHIVOS+=("$f")
  POS=$($ROOT -N -B -e "SHOW BINLOG EVENTS IN '$f'" | awk -F'\t' '
        $3 ~ /Gtid$/ {inicio = $2}                       # Gtid o Anonymous_Gtid: empieza una transacción
        $3 == "Query" && $6 ~ /DROP TABLE `titles`/ {print inicio; exit}')
  if [ -n "$POS" ]; then FIN_FILE="$f"; FIN_POS="$POS"; break; fi
done
echo "Archivos a reaplicar: ${ARCHIVOS[*]}"
if [ -z "$FIN_POS" ]; then
  echo "No se encontró el DROP en los binlogs: NO se restaura nada (revisar a mano con SHOW BINLOG EVENTS)."; exit 1
fi
echo "El DROP empieza en $FIN_FILE posición $FIN_POS (se corta justo antes)"
$ROOT -t -e "SHOW BINLOG EVENTS IN '$FIN_FILE'" | grep -E "Pos|Gtid|Query|Write_rows|Update_rows|Xid" | tail -12
DIR=$(dirname "$(g11n -e "SELECT @@log_bin_basename")")
RUTAS=(); for f in "${ARCHIVOS[@]}"; do RUTAS+=("$DIR/$f"); done

echo; echo "--- Paso 1: restaurar el backup base"
echo "\$ $ROOT < $BACKUP"
$ROOT < "$BACKUP" && echo "restaurado"
echo "--- Paso 2: reaplicar el binlog desde el backup hasta justo antes del DROP"
echo "\$ $BINLOG --skip-gtids --start-position=$INI_POS --stop-position=$FIN_POS ${ARCHIVOS[*]} | $ROOT"
$BINLOG --skip-gtids --start-position="$INI_POS" --stop-position="$FIN_POS" "${RUTAS[@]}" | $ROOT && echo "binlog reaplicado"

echo; echo "--- Validación: estado recuperado frente al objetivo"
estado | tee /tmp/ej06_recuperado.txt
if diff -q /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt >/dev/null; then
  echo "RECUPERACIÓN EXACTA: coincide con el estado previo al incidente (las 5 modificaciones están y titles existe)"
else
  echo "DIFERENCIAS con el estado objetivo:"; diff /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt
fi
g11 -e "SELECT e.emp_no, e.first_name, e.last_name, t.title, s.salary
        FROM employees e JOIN titles t USING (emp_no) JOIN salaries s USING (emp_no) WHERE e.emp_no = 500001"
rm -f /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt
