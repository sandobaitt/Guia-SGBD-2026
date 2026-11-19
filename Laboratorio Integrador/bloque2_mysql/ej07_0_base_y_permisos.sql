-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 7 (preparación) - Base para los documentos JSON de Sakila
-- Ejecutar como administrador (root):  sudo mysql -t < ej07_0_base_y_permisos.sql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS zakila_json CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- usr_g11 (Ejercicio 1.1) administra las bases del laboratorio: se le suma la nueva
GRANT ALL PRIVILEGES ON zakila_json.* TO 'usr_g11'@'%' WITH GRANT OPTION;

SHOW GRANTS FOR 'usr_g11'@'%';
