#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 5 - Concurrencia y bloqueos sobre employees.salaries
# Reproduce las dos sesiones en paralelo (en el laboratorio se hacen en dos
# terminales: el SQL de cada sesión es el que figura abajo).
# Uso: ./ej05_bloqueos.sh       (pide la clave de usr_g11)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
read -rsp "Clave de usr_g11: " P; echo
export MYSQL_PWD="$P"
m() { mysql $CON -u usr_g11 --skip-comments -t employees "$@"; }
TMP=$(mktemp -d)

S1="SELECT CONNECTION_ID() AS hilo_sesion1;
START TRANSACTION;
UPDATE salaries SET salary = ROUND(salary * 1.10)
WHERE emp_no BETWEEN 10001 AND 10010 AND to_date = '9999-01-01';
SELECT ROW_COUNT() AS sueldos_incrementados_sin_confirmar;
SELECT SLEEP(15) AS transaccion_abierta_15s;
ROLLBACK;
SELECT emp_no, salary FROM salaries WHERE emp_no = 10005 AND to_date = '9999-01-01';"

S2="SELECT CONNECTION_ID() AS hilo_sesion2;
UPDATE salaries SET salary = salary + 500
WHERE emp_no = 10005 AND to_date = '9999-01-01';"

echo "=== 5.1 SESIÓN 1 (transacción abierta, sin COMMIT):"; echo "$S1"; echo
m -e "$S1" > "$TMP/s1.txt" 2>&1 &
sleep 2
echo "=== 5.2 SESIÓN 2 (modifica un registro ya bloqueado por la Sesión 1):"; echo "$S2"; echo
m -e "$S2" > "$TMP/s2.txt" 2>&1 &
sleep 3

echo "=== 5.3 DIAGNÓSTICO (tercera conexión, mientras la Sesión 2 espera)"
m -e "SELECT trx_id, trx_mysql_thread_id AS hilo, trx_state AS estado, trx_started AS inicio,
              trx_wait_started AS espera_desde, trx_rows_locked AS filas_bloqueadas,
              LEFT(trx_query, 70) AS sentencia
       FROM information_schema.innodb_trx ORDER BY trx_started"
m -e "SELECT ENGINE_TRANSACTION_ID AS trx, THREAD_ID, OBJECT_NAME AS tabla, INDEX_NAME AS indice,
              LOCK_TYPE, LOCK_MODE, LOCK_STATUS, LOCK_DATA
       FROM performance_schema.data_locks
       WHERE OBJECT_NAME = 'salaries' AND (LOCK_STATUS = 'WAITING' OR LOCK_DATA LIKE '10005,%' OR LOCK_TYPE = 'TABLE')
       ORDER BY ENGINE_TRANSACTION_ID, LOCK_TYPE DESC"
m -e "SELECT REQUESTING_ENGINE_TRANSACTION_ID AS trx_que_espera, BLOCKING_ENGINE_TRANSACTION_ID AS trx_que_bloquea
       FROM performance_schema.data_lock_waits"

BLOQUEADA=$(mysql $CON -u usr_g11 -N -B -e "SELECT trx_mysql_thread_id FROM information_schema.innodb_trx WHERE trx_state = 'LOCK WAIT' LIMIT 1")
echo "=== 5.4 RESOLUCIÓN: se interrumpe la sesión bloqueada (hilo $BLOQUEADA)"
echo "KILL $BLOQUEADA;"
m -e "KILL $BLOQUEADA"
sleep 1
m -e "SELECT COUNT(*) AS transacciones_esperando FROM information_schema.innodb_trx WHERE trx_state = 'LOCK WAIT'"

wait
echo; echo "=== Salida de la SESIÓN 2 (interrumpida)"; cat "$TMP/s2.txt"
echo; echo "=== Salida de la SESIÓN 1 (termina con ROLLBACK: los sueldos no cambian)"; cat "$TMP/s1.txt"
rm -rf "$TMP"
