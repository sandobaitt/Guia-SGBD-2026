#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 1 - Pruebas de las cuentas: qué puede y qué no puede hacer cada una
# Uso: ./ej01_pruebas.sh      (pide las claves de usr_g11 y usr_backup)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino de usr_g11
# =============================================================================
set -uo pipefail
CON_G11=${MYSQL_CON:--h 127.0.0.1}
CON_BK=${MYSQL_CON_BACKUP:-}            # usr_backup es @localhost: por socket
read -rsp "Clave de usr_g11: " PG; echo
read -rsp "Clave de usr_backup: " PB; echo
g11() { MYSQL_PWD="$PG" mysql $CON_G11 -u usr_g11 -t -e "$1" 2>&1; }
bk()  { MYSQL_PWD="$PB" mysql $CON_BK -u usr_backup -t -e "$1" 2>&1; }

echo "=== usr_g11: conectado desde un host remoto (@'%') ==="
g11 "SELECT CURRENT_USER() AS cuenta, USER() AS conectado_como"
echo "--- PERMITIDO: crear y borrar una tabla en una base del laboratorio"
g11 "CREATE TABLE employees.prueba_g11 (id INT PRIMARY KEY); DROP TABLE employees.prueba_g11; SELECT 'DDL en employees: OK' AS resultado"
echo "--- RECHAZADO: leer la base de sistema mysql (no es súper-usuario)"
g11 "SELECT user, host FROM mysql.user"
echo "--- RECHAZADO: crear usuarios"
g11 "CREATE USER 'intruso'@'%' IDENTIFIED BY 'x'"
echo "--- RECHAZADO: apagar el servidor"
g11 "SHUTDOWN"

echo; echo "=== usr_backup: solo lectura y respaldo de employees ==="
bk "SELECT CURRENT_USER() AS cuenta"
echo "--- PERMITIDO: leer employees"
bk "SELECT COUNT(*) AS empleados FROM employees.employees"
echo "--- RECHAZADO: modificar employees"
bk "UPDATE employees.salaries SET salary = 0 WHERE emp_no = 10001"
echo "--- RECHAZADO: leer otra base"
bk "SELECT COUNT(*) FROM world_x.city"
echo "--- PERMITIDO: respaldo completo de employees con mysqldump"
MYSQL_PWD="$PB" mysqldump $CON_BK -u usr_backup --single-transaction --flush-logs --source-data=2 \
  --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > /tmp/prueba_backup_employees.sql
echo "mysqldump terminó con código $? · tamaño: $(du -h /tmp/prueba_backup_employees.sql | cut -f1)"
grep -m1 "CHANGE REPLICATION SOURCE TO" /tmp/prueba_backup_employees.sql
rm -f /tmp/prueba_backup_employees.sql
