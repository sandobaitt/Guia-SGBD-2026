# Bitácora de Experimentación - Actividad 2

### 1. Problema a resolver
La aplicación del cliente estaba permitiendo inconsistencias graves en los datos porque las reglas de negocio dependían únicamente del código del frontend/backend. Se nos solicitó trasladar estas validaciones (saldos negativos, precios en cero, auditorías y clasificación de clientes anual) directamente al motor de la base de datos (MySQL) para garantizar la integridad a nivel físico, sin importar qué aplicación acceda a los datos.

### 2. Decisiones técnicas
Para cumplir con los requerimientos eligiendo la herramienta correcta en cada caso, definimos:
- **Regla de Saldos y Precios:** Usamos `CHECK Constraints` (Restricción Declarativa). ¿Por qué? Porque la consigna exigía que una regla simple no usara triggers. Validar matemáticamente que `saldo >= 0` o `precio > 0` es algo estático y simple, perfecto para un `CHECK`.
- **Auditoría de precios:** Usamos un `TRIGGER` (`AFTER UPDATE`). ¿Por qué? Porque no es una simple validación, sino que necesitamos reaccionar automáticamente ante un evento (UPDATE) para escribir datos en una tabla paralela de auditoría de forma transparente.
- **Clasificación de Clientes:** Usamos una `FUNCTION` almacenada. ¿Por qué? Porque el requerimiento (calcular el total de un año y devolver Oro, Plata o Bronce) retorna un único valor escalar. Las funciones están diseñadas precisamente para encapsular cálculos y luego poder llamarlas dentro de otras consultas (ej. `SELECT nombre, clasificar_cliente(...) FROM cliente`).
Además, siguiendo la indicación de la cátedra, la función **no recibe un monto precalculado**, sino que recibe el ID del cliente y el año, ejecutando ella misma internamente un `SUM(total)` sobre la tabla de ventas antes de categorizar.
- **Justificación de la tabla VENTA (Punto Aclaratorio):** Como detectamos tempranamente que el script base original no traía la tabla `VENTA`, decidimos crear una estructura mínima equivalente proactivamente para poder testear nuestra función. Nos aseguramos de que contenga los campos requeridos (`cliente_id`, `fecha` y `total`), cumpliendo con la directiva del profesor de que los grupos que ya hubieran avanzado creando su propia tabla no necesitaban reemplazarla, sino simplemente documentar su estructura y validar el requerimiento.

### 3. Comandos y evidencias (Definición en el SGBD)

**A. Definición de Restricciones (CHECKs):**
```sql
ALTER TABLE producto ADD CONSTRAINT chk_precio_positivo CHECK (precio > 0);
ALTER TABLE cuenta ADD CONSTRAINT chk_saldo_positivo CHECK (saldo >= 0);
```

**B. Definición del Trigger de Auditoría:**
```sql
DELIMITER //
CREATE TRIGGER trg_update_precio
AFTER UPDATE ON producto 
FOR EACH ROW 
BEGIN
  IF OLD.precio <> NEW.precio THEN
    INSERT INTO auditoria_precio (producto_id, precio_anterior, precio_nuevo) 
    VALUES (OLD.producto_id, OLD.precio, NEW.precio);
  END IF;
END //
DELIMITER ;
```

**C. Definición de la Función Almacenada:**
```sql
DELIMITER //
CREATE FUNCTION clasificar_cliente(p_cliente_id INT, p_anio INT) 
RETURNS VARCHAR(20)
DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2) DEFAULT 0;
  DECLARE v_categoria VARCHAR(20);
  
  SELECT COALESCE(SUM(total), 0) INTO v_total
  FROM venta
  WHERE cliente_id = p_cliente_id AND EXTRACT(YEAR FROM fecha) = p_anio;
  
  IF v_total > 50000000 THEN SET v_categoria = 'Oro';
  ELSEIF v_total >= 2000000 THEN SET v_categoria = 'Plata';
  ELSE SET v_categoria = 'Bronce';
  END IF;
  
  RETURN v_categoria;
END //
DELIMITER ;
```

**Salida explícita de consola al ejecutar las pruebas (`pruebas_actividad2.sql`):**
```text
Info
--- INICIANDO PRUEBAS DE PRECIO Y SALDO ---
ERROR 3819 (HY000) at line 13: Check constraint 'chk_saldo_positivo' is violated.
ERROR 3819 (HY000) at line 22: Check constraint 'chk_precio_positivo' is violated.

Info
--- RESULTADO DE AUDITORIA ---
auditoria_id    producto_id     precio_anterior precio_nuevo    fecha_cambio
1               1               1000.00         1200.00         2026-09-03 01:28:50

Info
--- PRUEBA DE CLASIFICACION (Bronce, Plata, Oro) ---
cliente_id      nombre          categoria_2026
1               Norte SA        Plata
2               Sur SRL         Oro
3               Cliente Uno     Bronce
```

### 4. Pruebas realizadas
- **Caso válido:** 
  - Se modificó un precio exitosamente de 1000 a 1200. Al consultar la tabla `auditoria_precio`, apareció el registro del cambio.
  - Se evaluó a los clientes 1, 2 y 3 en el año 2026, devolviendo Plata, Oro y Bronce respectivamente según las ventas insertadas en el script.
- **Caso inválido:** 
  - Se intentó ejecutar `UPDATE cuenta SET saldo = -500`. El motor rechazó la operación inmediatamente lanzando: `ERROR 3819 (HY000): Check constraint 'chk_saldo_positivo' is violated`.
  - Se intentó poner `precio = 0`, fallando también por su restricción `chk_precio_positivo`.
- **Caso límite:** 
  - Se intentó dejar el saldo exactamente en `0` (`UPDATE cuenta SET saldo = 0`). La base de datos lo permitió, ya que la regla de negocio establece que la cuenta no puede quedar "negativa", por ende el 0 es el límite válido permitido.

### 5. Errores y diagnóstico
**Falla:** Inicialmente, cuando la función sumaba las ventas usando `SUM(total)`, si el cliente no tenía ventas en ese año, el resultado arrojaba un valor `NULL`. Esto rompía la lógica de los `IF` y el cliente quedaba sin categoría.
**Detección:** Al probar la función con un cliente recién insertado sin ventas, la salida fue nula en lugar de 'Bronce'.
**Corrección:** Se modificó la consulta interna envolviendo el `SUM` en un `COALESCE`: `SELECT COALESCE(SUM(total), 0) INTO v_total`. Así, los clientes sin ventas en ese año suman 0 y automáticamente caen en la categoría 'Bronce'.

### 6. Uso de IA
Se utilizó la IA (Antigravity) como asistente para generar la estructura de los archivos `.sql` y asegurar la sintaxis correcta del `TRIGGER` y la `FUNCTION` de MySQL. 
- **Qué se validó:** Se validó corriendo el script localmente que el motor reconociera las restricciones `CHECK` (disponibles en MySQL > 8.0.16) y que la función procesara correctamente la agregación anual sugerida por el profesor.
- **Qué se descartó:** Se descartó el uso de un `PROCEDURE` (Procedimiento Almacenado) para la clasificación, ya que los procedimientos no devuelven valores directamente utilizables dentro de sentencias `SELECT`, perdiendo así el nivel de reutilización solicitado.

### 7. Aprendizajes
Comprobamos empíricamente la diferencia crucial entre las herramientas del motor: los `CHECK` protegen la estructura estática; los `TRIGGERS` automatizan procesos derivados (como auditorías); y las `FUNCTIONS` encapsulan lógicas numéricas reutilizables. Esto asegura que la base de datos sea la última línea de defensa contra datos corruptos generados por la aplicación.
