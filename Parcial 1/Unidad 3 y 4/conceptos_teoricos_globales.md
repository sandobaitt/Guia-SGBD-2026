# Conceptos Teóricos y Usos Prácticos (SGBD)
**Resumen Global - Actividades 1, 2 y 3 (Unidades 3 y 4)**

Este documento consolida todos los conceptos teóricos avanzados de bases de datos que aplicamos a lo largo de las tres actividades. Sirve como material de estudio integral para defender cualquiera de los ejercicios.

---

## ACTIVIDAD 1: Consultas Avanzadas y Analítica

### 1. Funciones de Ventana (Window Functions)
**Concepto:** Son funciones que realizan cálculos a través de un conjunto de filas que están relacionadas con la fila actual, pero *sin agrupar* (colapsar) el resultado en una sola fila como lo hace el `GROUP BY`.
**Usos Prácticos:**
- Obtener la **última venta** de cada cliente usando `ROW_NUMBER() OVER(PARTITION BY cliente_id ORDER BY fecha DESC)`. 
- Calcular totales acumulados mes a mes (running totals).
- **Ventaja:** Evita hacer subconsultas complejas o `JOINs` consigo misma, lo que mejora drásticamente la legibilidad y el rendimiento (`EXPLAIN ANALYZE`).

### 2. CTEs (Common Table Expressions - Cláusula `WITH`)
**Concepto:** Son tablas temporales con nombre que solo existen durante la ejecución de una consulta. 
**Usos Prácticos:**
- Fragmentar una consulta inmensa y difícil de leer en pequeños bloques lógicos fáciles de entender.
- Crear primero una "tabla virtual" de ventas acumuladas, y en el renglón siguiente consultar sobre esa misma tabla virtual para sacar promedios.

### 3. Consultas Jerárquicas (`WITH RECURSIVE`)
**Concepto:** Una CTE especial que se llama a sí misma iterativamente hasta que no queden más datos por procesar.
**Usos Prácticos:**
- Navegar estructuras de árbol, como un organigrama de empleados (quién es jefe de quién) o categorías de productos anidadas, algo que el SQL tradicional no puede hacer fácilmente.

---

## ACTIVIDAD 2: Programabilidad e Integridad de Datos

### 4. ¿Dónde poner las reglas de negocio? (BD vs App)
**Concepto:** Existe un debate sobre si las validaciones (ej. saldo > 0) deben estar en el código (Node/Python) o en el motor (MySQL/PostgreSQL).
**Usos Prácticos:**
- **En la Aplicación:** Para darle respuesta rápida al usuario (UI).
- **En la Base de Datos:** Como **última línea de defensa**. El motor de BD garantiza que, si alguien se salta la aplicación y entra directo por consola, los datos no puedan ser corrompidos nunca.

### 5. Restricciones Declarativas (`CHECK Constraints`)
**Concepto:** Es una regla matemática estática que se declara en la estructura de la tabla. El motor la procesa de forma nativa a nivel binario.
**Usos Prácticos:**
- Impedir saldos negativos (`CHECK saldo >= 0`).
- **Ventaja:** Es extremadamente rápido y no requiere programar lógica manual. Siempre debe preferirse por sobre un `TRIGGER` si la regla es una simple ecuación.

### 6. Disparadores (`TRIGGERS`)
**Concepto:** Es un bloque de código SQL que se ejecuta *automáticamente* como reacción a un evento (INSERT, UPDATE o DELETE) en una tabla específica.
**Usos Prácticos:**
- **Auditorías (Cámaras de seguridad):** Registrar en una tabla paralela cuándo cambia el precio de un producto, guardando el valor viejo (`OLD`) y el nuevo (`NEW`). No sirve para devolver valores.

### 7. Funciones Almacenadas (`FUNCTIONS`)
**Concepto:** Un bloque de código SQL programado para recibir parámetros, realizar cálculos internos pesados y devolver un único valor escalar resultante.
**Usos Prácticos:**
- Clasificar clientes (Oro/Plata/Bronce) sumando internamente su historial de recibos (`SUM(total)`).
- **Ventaja:** Al recibir solo el ID del cliente, obligamos al motor (que tiene acceso directo al disco) a sumar millones de registros en milisegundos, en lugar de transferir esos millones de registros por internet hacia la aplicación para sumarlos allá. Además, las funciones se pueden reusar adentro de un `SELECT`.

---

## ACTIVIDAD 3: Evolución de Esquemas (Migraciones)

### 8. Migración por Fases y Versionado de BD
**Concepto:** En sistemas reales (producción), la base de datos no se puede borrar y crear de cero (`DROP DATABASE`). Se debe migrar de una versión (v1) a la siguiente (v2) modificando la estructura en vivo (`ALTER TABLE`).
**Usos Prácticos:**
- Separar el código en archivos enumerados (`01_schema`, `03_migracion`, etc.) para automatizar el despliegue mediante pipelines (CI/CD).
- Al agregar columnas nuevas a tablas llenas de datos viejos, es mandatorio usar la cláusula `DEFAULT` (ej. `DEFAULT 'pendiente'`) para que los registros históricos no queden corruptos con valores `NULL`.

### 9. El Tipo de Dato `ENUM`
**Concepto:** Un tipo de dato de cadena de texto que solo puede adoptar un valor elegido de una lista permitida (enumeración) predefinida en la estructura.
**Usos Prácticos:**
- Definir estados de un pedido (`'pendiente'`, `'pagado'`, `'cancelado'`).
- **Ventaja:** Ocupa muy poco espacio en disco (1 byte) y evita tener que crear una "tabla de estados" separada. Esto nos ahorra tener que hacer operaciones `JOIN` costosas cada vez que leemos un pedido, agilizando el sistema.

### 10. Riesgo de Pérdida de Datos (El Rollback)
**Concepto:** El script de Rollback revierte la base de datos a su versión estructural anterior (v2 a v1).
**Riesgo Teórico:** Mientras que *avanzar* de versión suele ser seguro, *retroceder* es destructivo. Hacer un `ALTER TABLE DROP COLUMN` aniquila la columna físicamente. Si el sistema operó 5 días en la v2, al hacer el Rollback se perderán absolutamente todos los datos de los estados generados en esos 5 días. 
**Mitigación:** Siempre hacer un volcado de seguridad (Backup / `mysqldump`) previo a ejecutar un script de Rollback.
