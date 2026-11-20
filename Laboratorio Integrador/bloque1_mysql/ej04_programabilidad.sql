-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 4 - Programabilidad: procedimientos y trigger sobre employees
--   mysql -h 127.0.0.1 -u usr_g11 -p --commands --skip-comments -t -vvv employees < ej04_programabilidad.sql
-- (--commands: en el cliente de MySQL 9.7 DELIMITER es un comando del cliente
--  y viene desactivado por defecto cuando se lee un archivo)
-- =============================================================================
USE employees;

DROP PROCEDURE IF EXISTS sp_verificar_gerente;
DROP PROCEDURE IF EXISTS sp_calcular_ayuda_escolar;
DROP TRIGGER   IF EXISTS trg_dept_manager_alta;
DROP TABLE     IF EXISTS asignaciones_familiares;
DROP TABLE     IF EXISTS ayuda_escolar_montos;

DELIMITER //

-- -----------------------------------------------------------------------------
-- 4.1 Verificación de gerentes
--   Si p_emp_no administra HOY un departamento (dept_manager.to_date = 9999-01-01)
--   devuelve: 1) un resumen y 2) los empleados asignados hoy a ese departamento
--   con su antigüedad en años (los p_limite de mayor antigüedad).
--   Si no es gerente vigente, lo informa (y si lo fue, dice hasta cuándo).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_verificar_gerente(IN p_emp_no INT, IN p_limite INT)
BEGIN
  DECLARE v_dept CHAR(4);
  DECLARE v_hasta DATE;

  SELECT dept_no INTO v_dept FROM dept_manager
  WHERE emp_no = p_emp_no AND to_date = '9999-01-01' LIMIT 1;

  IF v_dept IS NULL THEN
    SELECT MAX(to_date) INTO v_hasta FROM dept_manager WHERE emp_no = p_emp_no;
    SELECT p_emp_no AS emp_no,
           CASE WHEN v_hasta IS NULL THEN 'NO es ni fue gerente'
                ELSE CONCAT('NO es gerente vigente (lo fue hasta ', v_hasta, ')') END AS resultado;
  ELSE
    SELECT p_emp_no AS gerente, CONCAT(g.first_name, ' ', g.last_name) AS nombre,
           d.dept_no, d.dept_name AS departamento,
           COUNT(*) AS empleados_asignados,
           ROUND(AVG(TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())), 1) AS antiguedad_promedio
    FROM dept_emp de
    JOIN employees e   ON e.emp_no = de.emp_no
    JOIN departments d ON d.dept_no = de.dept_no
    JOIN employees g   ON g.emp_no = p_emp_no
    WHERE de.dept_no = v_dept AND de.to_date = '9999-01-01'
    GROUP BY d.dept_no, d.dept_name, g.first_name, g.last_name;

    SELECT e.emp_no, e.first_name, e.last_name, e.hire_date,
           TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) AS antiguedad_anios
    FROM dept_emp de
    JOIN employees e ON e.emp_no = de.emp_no
    WHERE de.dept_no = v_dept AND de.to_date = '9999-01-01'
    ORDER BY e.hire_date, e.emp_no
    LIMIT p_limite;
  END IF;
END //

-- -----------------------------------------------------------------------------
-- 4.2 Trigger de asignación de cargo
--   Al dar de alta un gerente vigente en dept_manager:
--   - titles: cierra el cargo vigente y abre 'Manager' desde la fecha del alta
--   - dept_emp: lo asigna al departamento que pasa a administrar (cierra la
--     asignación vigente en otro departamento). dept_emp no tiene columna de
--     cargo: el "cargo" del empleado vive en titles.
--   MySQL no permite que un trigger modifique su propia tabla (dept_manager),
--   por eso cerrar al gerente anterior queda fuera del trigger.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_dept_manager_alta
AFTER INSERT ON dept_manager
FOR EACH ROW
BEGIN
  IF NEW.to_date = '9999-01-01' THEN
    UPDATE titles SET to_date = NEW.from_date
    WHERE emp_no = NEW.emp_no AND to_date = '9999-01-01' AND title <> 'Manager';
    INSERT INTO titles (emp_no, title, from_date, to_date)
    VALUES (NEW.emp_no, 'Manager', NEW.from_date, '9999-01-01')
    ON DUPLICATE KEY UPDATE to_date = '9999-01-01';

    UPDATE dept_emp SET to_date = NEW.from_date
    WHERE emp_no = NEW.emp_no AND to_date = '9999-01-01' AND dept_no <> NEW.dept_no;
    INSERT INTO dept_emp (emp_no, dept_no, from_date, to_date)
    VALUES (NEW.emp_no, NEW.dept_no, NEW.from_date, '9999-01-01')
    ON DUPLICATE KEY UPDATE to_date = '9999-01-01';
  END IF;
END //

DELIMITER ;

-- -----------------------------------------------------------------------------
-- 4.3 Ayuda escolar: estructura y cálculo del beneficio
--   Reglas (supuestos del grupo, inspirados en la Ayuda Escolar Anual):
--   - un pago por hijo y ciclo lectivo, según el nivel educativo
--   - solo si se presentó el certificado de escolaridad
--   - solo si el sueldo vigente del empleado no supera el tope (parámetro)
-- -----------------------------------------------------------------------------
CREATE TABLE ayuda_escolar_montos (
  nivel ENUM('INICIAL','PRIMARIO','SECUNDARIO') NOT NULL PRIMARY KEY,
  monto DECIMAL(10,2) NOT NULL CHECK (monto > 0)
) ENGINE=InnoDB;

CREATE TABLE asignaciones_familiares (
  asignacion_id   INT AUTO_INCREMENT PRIMARY KEY,
  emp_no          INT NOT NULL,
  hijo_nombre     VARCHAR(40) NOT NULL,
  hijo_nacimiento DATE NOT NULL,
  nivel           ENUM('INICIAL','PRIMARIO','SECUNDARIO') NOT NULL,
  ciclo_lectivo   YEAR NOT NULL,
  certificado     BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_asignaciones_employees FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE,
  CONSTRAINT fk_asignaciones_nivel     FOREIGN KEY (nivel)  REFERENCES ayuda_escolar_montos (nivel),
  CONSTRAINT uq_hijo_ciclo UNIQUE (emp_no, hijo_nombre, ciclo_lectivo)
) ENGINE=InnoDB;

DELIMITER //
CREATE PROCEDURE sp_calcular_ayuda_escolar(IN p_ciclo YEAR, IN p_tope INT)
BEGIN
  SELECT a.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS empleado, s.salary AS sueldo_vigente,
         COUNT(*) AS hijos_beneficiarios, SUM(m.monto) AS beneficio_total
  FROM asignaciones_familiares a
  JOIN employees e            ON e.emp_no = a.emp_no
  JOIN salaries s             ON s.emp_no = a.emp_no AND s.to_date = '9999-01-01'
  JOIN ayuda_escolar_montos m ON m.nivel = a.nivel
  WHERE a.ciclo_lectivo = p_ciclo AND a.certificado AND s.salary <= p_tope
  GROUP BY a.emp_no, e.first_name, e.last_name, s.salary
  ORDER BY a.emp_no;

  SELECT COUNT(DISTINCT a.emp_no) AS empleados_beneficiarios, COUNT(*) AS hijos,
         COALESCE(SUM(m.monto), 0) AS total_a_pagar
  FROM asignaciones_familiares a
  JOIN salaries s             ON s.emp_no = a.emp_no AND s.to_date = '9999-01-01'
  JOIN ayuda_escolar_montos m ON m.nivel = a.nivel
  WHERE a.ciclo_lectivo = p_ciclo AND a.certificado AND s.salary <= p_tope;
END //
DELIMITER ;

-- =============================================================================
-- PRUEBAS
-- =============================================================================
-- 4.1 Caso válido: gerente vigente de Marketing (d001)
CALL sp_verificar_gerente(110039, 5);
-- 4.1 Caso inválido: fue gerente de d001 pero ya no lo es
CALL sp_verificar_gerente(110022, 5);
-- 4.1 Caso inválido: nunca fue gerente
CALL sp_verificar_gerente(10001, 5);

-- 4.2 Antes del alta: 10002 es 'Staff' en Sales (d007)
SELECT emp_no, title, from_date, to_date FROM titles   WHERE emp_no = 10002 ORDER BY from_date;
SELECT emp_no, dept_no, from_date, to_date FROM dept_emp WHERE emp_no = 10002 ORDER BY from_date;
-- Alta de 10002 como gerente de Human Resources (d003) -> se dispara el trigger
INSERT INTO dept_manager (emp_no, dept_no, from_date, to_date) VALUES (10002, 'd003', '2026-11-17', '9999-01-01');
-- Después: cargo 'Manager' vigente y asignado a d003
SELECT emp_no, title, from_date, to_date FROM titles   WHERE emp_no = 10002 ORDER BY from_date;
SELECT emp_no, dept_no, from_date, to_date FROM dept_emp WHERE emp_no = 10002 ORDER BY from_date;
-- El procedimiento 4.1 ya lo reconoce como gerente vigente
CALL sp_verificar_gerente(10002, 3);

-- 4.3 Datos de prueba (ciclo 2026) y cálculo con tope de $60.000
INSERT INTO ayuda_escolar_montos VALUES ('INICIAL', 15000), ('PRIMARIO', 20000), ('SECUNDARIO', 25000);
INSERT INTO asignaciones_familiares (emp_no, hijo_nombre, hijo_nacimiento, nivel, ciclo_lectivo, certificado) VALUES
  (10003, 'Lucía Bamford',     '2015-03-10', 'PRIMARIO',   2026, TRUE),   -- sueldo 43.311: cobra
  (10003, 'Tomás Bamford',     '2011-07-22', 'SECUNDARIO', 2026, TRUE),   -- sueldo 43.311: cobra
  (10006, 'Sofía Preusig',     '2021-01-05', 'INICIAL',    2026, TRUE),   -- sueldo 59.755: cobra (cerca del tope)
  (10012, 'Mateo Bridgland',   '2016-09-30', 'PRIMARIO',   2026, FALSE),  -- sin certificado: no cobra
  (10001, 'Valentina Facello', '2014-05-18', 'PRIMARIO',   2026, TRUE);   -- sueldo 88.958 > tope: no cobra
CALL sp_calcular_ayuda_escolar(2026, 60000);
-- Caso límite: tope igual al sueldo de 10006 (59.755) -> sigue cobrando (<=)
CALL sp_calcular_ayuda_escolar(2026, 59755);
-- Caso límite: tope un peso menor -> 10006 queda afuera
CALL sp_calcular_ayuda_escolar(2026, 59754);
-- Caso inválido: un hijo de un empleado inexistente (integridad referencial)
INSERT INTO asignaciones_familiares (emp_no, hijo_nombre, hijo_nacimiento, nivel, ciclo_lectivo, certificado)
VALUES (999999, 'Sin Empleado', '2015-01-01', 'PRIMARIO', 2026, TRUE);
