# Bitácora de Experimentación - Actividad 3 (Release v2.0)

### 1. Problema a resolver
Se requiere evolucionar una base de datos que ya se encuentra en producción (v1) a una nueva versión (v2) sin borrarla desde cero, manteniendo los datos actuales. Se deben agregar estados de pedido, auditorías, reglas de negocio (sin negativos) y una función para calcular el total histórico por cliente. Además, se debe proveer un plan de contingencia (Rollback).

### 2. Decisiones técnicas
- **Migración particionada:** Se dividieron los scripts en 6 archivos separados (`01` a `06`) para simular un proceso de CI/CD profesional. Nunca se usa un `DROP DATABASE` en los scripts de migración (del 03 al 05).
- **Control de Estados:** Se agregó la columna `estado` directamente en la tabla `pedido` utilizando el tipo de dato nativo `ENUM('pendiente', 'pagado', 'enviado', 'cancelado')` con un valor por defecto (`DEFAULT 'pendiente'`). Se eligió esto sobre crear una tabla anexa porque los estados son pocos, estáticos, y el `ENUM` garantiza integridad referencial a nivel de motor sin costo adicional de `JOINs`. Al poner un `DEFAULT`, nos aseguramos de que todos los pedidos viejos de la v1 asuman automáticamente este estado y no rompan la aplicación.
- **Auditoría y Lógica:** Igual que en la Actividad 2, se implementó un `TRIGGER AFTER UPDATE` para poblar la tabla `auditoria_estado_pedido` automáticamente si el estado cambia. Para el cálculo del total, se usó una `FUNCTION` con un `SUM` envolviendo en `COALESCE` para que los clientes sin pedidos (como el Cliente 3) devuelvan 0 en vez de `NULL`.
- **Rollback:** El script `06_rollback_v2.sql` destruye limpiamente todos los objetos creados por la v2 (`DROP TRIGGER`, `DROP FUNCTION`, `ALTER TABLE DROP COLUMN`, `DROP TABLE`).

### 3. Comandos y evidencias (Definición en el SGBD)

**A. Migración Estructural v2 (Cambio de estado, auditoría y CHECK):**
```sql
ALTER TABLE pedido ADD COLUMN estado ENUM('pendiente', 'pagado', 'enviado', 'cancelado') NOT NULL DEFAULT 'pendiente';

CREATE TABLE auditoria_estado_pedido (
  auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  estado_anterior VARCHAR(20),
  estado_nuevo VARCHAR(20) NOT NULL,
  fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id)
);

ALTER TABLE pedido ADD CONSTRAINT chk_total_positivo CHECK (total >= 0);
```

**B. Programabilidad v2 (Trigger de Auditoría):**
```sql
DELIMITER //
CREATE TRIGGER trg_auditoria_estado
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
  IF OLD.estado <> NEW.estado THEN
    INSERT INTO auditoria_estado_pedido (pedido_id, estado_anterior, estado_nuevo)
    VALUES (NEW.pedido_id, OLD.estado, NEW.estado);
  END IF;
END //
DELIMITER ;
```

**C. Programabilidad v2 (Función Sumadora Histórica):**
```sql
DELIMITER //
CREATE FUNCTION calcular_total_cliente(p_cliente_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2) DEFAULT 0;
  SELECT COALESCE(SUM(total), 0) INTO v_total
  FROM pedido
  WHERE cliente_id = p_cliente_id;
  RETURN v_total;
END //
DELIMITER ;
```

**Salida explícita de consola al ejecutar las pruebas (`05_pruebas_v2.sql`):**
```text
Info
--- VERIFICACION DE DATOS HEREDADOS (v1 a v2) ---
pedido_id       cliente_id      fecha           total           estado
1001            1               2026-09-01      15000.00        pendiente
1002            1               2026-09-12      22000.00        pendiente
1003            2               2026-09-15      9000.00         pendiente

Info
--- PRUEBA VÁLIDA: CAMBIO DE ESTADO Y FUNCION ---
cliente_id      nombre          total_historico
1               Norte SA        37000.00
2               Sur SRL         9000.00
3               Cliente Uno     0.00

Info
--- PRUEBA INVÁLIDA: RESTRICCIONES ---
ERROR 1265 (01000) at line 22: Data truncated for column 'estado' at row 1
ERROR 3819 (HY000) at line 26: Check constraint 'chk_total_positivo' is violated.

Info
--- VERIFICACION DE AUDITORIA ---
auditoria_id    pedido_id       estado_anterior estado_nuevo    fecha_cambio
1               1001            pendiente       pagado          2026-09-06 03:53:57
2               1001            pagado          enviado         2026-09-06 03:53:57
```

### 4. Pruebas realizadas
- **Caso válido:** 
  - Al migrar a v2, se verificó mediante un `SELECT` que los 3 pedidos antiguos (1001, 1002, 1003) se conservaron intactos y adquirieron mágicamente el estado `pendiente`.
  - Se probó actualizar un estado `UPDATE pedido SET estado = 'pagado'` y la tabla de auditoría capturó el cambio inmediatamente.
  - La función `calcular_total_cliente` sumó correctamente el histórico.
- **Caso inválido:** 
  - Se intentó insertar un estado inventado: `UPDATE pedido SET estado = 'entregado_ayer'`. El `ENUM` frenó la ejecución inmediatamente lanzando el error: `ERROR 1265 (01000): Data truncated for column 'estado'`.
- **Caso límite:** 
  - Se calculó el total para el "Cliente Uno" (ID 3), el cual no tenía ningún pedido. La función retornó `0.00` de forma segura gracias a prever los nulos con `COALESCE(SUM(total), 0)`.

### 5. Errores y diagnóstico
**Riesgo de Rollback:** Durante el diseño del Rollback (volver de v2 a v1) nos dimos cuenta de que si borramos la columna `estado` usando `ALTER TABLE pedido DROP COLUMN estado;`, todos los pedidos que hayan transcurrido durante la vigencia de la v2 y sus cambios de estado se borrarán permanentemente.
**Diagnóstico/Solución:** Dado que un rollback estructural siempre implica pérdida de datos introducidos en la versión superior, la única forma técnica de mitigarlo fue agregar una **Alerta de Peligro comentada** gigante en el encabezado del archivo `06_rollback_v2.sql`, exigiendo explícitamente a los DBAs realizar un backup (`mysqldump`) antes de apretar el gatillo del rollback, para luego poder reconciliar los datos perdidos a mano si fuese necesario.

### 6. Uso de IA
La IA (Antigravity) se usó para orquestar la secuenciación de los 6 archivos `.sql`, garantizando que las dependencias lógicas no fallen al ejecutarse en cadena.
- **Qué se validó:** Se validó ejecutando un pipeline manual en consola: `mysql < 01... && mysql < 02... && mysql < 03...` demostrando que el despliegue es 100% automatizable sin intervención humana. 
- **Qué se descartó:** Se descartó el uso de tipos de datos `VARCHAR` para la columna de estado; en su lugar, la IA sugirió el uso de `ENUM` porque actúa como una restricción de datos incorporada a nivel binario.

### 7. Aprendizajes
Aprendimos la extrema delicadeza de trabajar con bases de datos en producción ("live"). Modificar estructuras (ALTER TABLE) requiere planificar los valores por defecto (`DEFAULT`) para no corromper la data heredada de años anteriores. Además, interiorizamos que el código SQL no solo sirve para guardar datos, sino para versionar arquitecturas de manera ordenada (v1 -> v2) y poder retroceder en el tiempo si el despliegue sale mal.
