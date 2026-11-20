#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 2 - Exportación a texto delimitado, esquema traducido y carga masiva
# Uso: ./ej02_carga_masiva.sh   (pide la clave de usr_g11)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino
# El servidor solo lee y escribe archivos en secure_file_priv (en Ubuntu:
# /var/lib/mysql-files/). LOAD DATA no acepta la ruta en una variable, por eso
# este script la obtiene del servidor y arma las sentencias.
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
read -rsp "Clave de usr_g11: " P; echo
export MYSQL_PWD="$P"
sql() { mysql $CON -u usr_g11 -t -vvv "$@"; }

DIR=$(mysql $CON -u usr_g11 -N -B -e "SELECT @@secure_file_priv")
echo "secure_file_priv = $DIR"
[ -n "$DIR" ] && [ "$DIR" != "NULL" ] || { echo "El servidor no permite archivos (secure_file_priv vacío o NULL)"; exit 1; }
# INTO OUTFILE falla si el archivo ya existe: se usa un sufijo con la fecha
SUF=$(date +%Y%m%d_%H%M%S)
F_EMP="${DIR}employees_${SUF}.csv"; F_SAL="${DIR}salaries_${SUF}.csv"; F_TIT="${DIR}titles_${SUF}.csv"
CSV="FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n'"

echo; echo "=== 2.1 Exportación a texto delimitado (CSV) con SELECT ... INTO OUTFILE"
sql <<SQL
SELECT * FROM employees.employees INTO OUTFILE '$F_EMP' $CSV;
SELECT * FROM employees.salaries  INTO OUTFILE '$F_SAL' $CSV;
SELECT * FROM employees.titles    INTO OUTFILE '$F_TIT' $CSV;
SQL

echo; echo "=== 2.2 Base empleados con nombres en castellano e integridad referencial"
sql <<'SQL'
DROP DATABASE IF EXISTS empleados;
CREATE DATABASE empleados CHARACTER SET utf8mb4;
USE empleados;
CREATE TABLE empleados (
  nro_empleado     INT          NOT NULL,
  fecha_nacimiento DATE         NOT NULL,
  nombre           VARCHAR(14)  NOT NULL,
  apellido         VARCHAR(16)  NOT NULL,
  genero           ENUM('M','F') NOT NULL,
  fecha_ingreso    DATE         NOT NULL,
  PRIMARY KEY (nro_empleado)
) ENGINE=InnoDB;
CREATE TABLE salarios (
  nro_empleado INT  NOT NULL,
  salario      INT  NOT NULL,
  desde        DATE NOT NULL,
  hasta        DATE NOT NULL,
  PRIMARY KEY (nro_empleado, desde),
  CONSTRAINT fk_salarios_empleados FOREIGN KEY (nro_empleado)
    REFERENCES empleados (nro_empleado) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE cargos (
  nro_empleado INT         NOT NULL,
  cargo        VARCHAR(50) NOT NULL,
  desde        DATE        NOT NULL,
  hasta        DATE,
  PRIMARY KEY (nro_empleado, cargo, desde),
  CONSTRAINT fk_cargos_empleados FOREIGN KEY (nro_empleado)
    REFERENCES empleados (nro_empleado) ON DELETE CASCADE
) ENGINE=InnoDB;
SHOW TABLES;
SQL

echo; echo "=== 2.3 Carga masiva con LOAD DATA INFILE (primero la tabla padre)"
sql <<SQL
USE empleados;
SET @t0 := NOW(6);
LOAD DATA INFILE '$F_EMP' INTO TABLE empleados $CSV
  (nro_empleado, fecha_nacimiento, nombre, apellido, genero, fecha_ingreso);
LOAD DATA INFILE '$F_SAL' INTO TABLE salarios  $CSV (nro_empleado, salario, desde, hasta);
LOAD DATA INFILE '$F_TIT' INTO TABLE cargos    $CSV (nro_empleado, cargo, desde, hasta);
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6)) / 1000000, 2) AS segundos_carga_total;
SQL

echo; echo "=== Verificación: filas en origen y destino, e integridad referencial"
sql <<'SQL'
SELECT 'empleados' AS tabla, (SELECT COUNT(*) FROM employees.employees) AS origen, (SELECT COUNT(*) FROM empleados.empleados) AS destino
UNION ALL SELECT 'salarios', (SELECT COUNT(*) FROM employees.salaries), (SELECT COUNT(*) FROM empleados.salarios)
UNION ALL SELECT 'cargos',   (SELECT COUNT(*) FROM employees.titles),   (SELECT COUNT(*) FROM empleados.cargos);
SELECT COUNT(*) AS salarios_sin_empleado FROM empleados.salarios s
  LEFT JOIN empleados.empleados e ON e.nro_empleado = s.nro_empleado WHERE e.nro_empleado IS NULL;
SELECT e.nro_empleado, e.nombre, e.apellido, c.cargo, s.salario
FROM empleados.empleados e
JOIN empleados.cargos c   ON c.nro_empleado = e.nro_empleado AND c.hasta = '9999-01-01'
JOIN empleados.salarios s ON s.nro_empleado = e.nro_empleado AND s.hasta = '9999-01-01'
ORDER BY e.nro_empleado LIMIT 3;
-- La integridad referencial rechaza un salario de un empleado inexistente
INSERT INTO empleados.salarios VALUES (999999, 1000, '2026-01-01', '9999-01-01');
SQL
