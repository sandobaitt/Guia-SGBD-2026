# Guía Paso a Paso - Actividad 2 (MySQL)

Esta guía documenta los comandos exactos utilizados para completar la Actividad 2 de Diseño Físico, ideal para que cualquier miembro del grupo pueda replicar el trabajo desde cero.

> [!NOTE]
> Todos los comandos asumen que estás ubicado en la carpeta `Kit_Estudiantes_MySQL` y que la contraseña del usuario root es `1234`.

## Paso 1: Instalación del Laboratorio (Minutos 0-5)
Para crear la base de datos `sgbd_a2_lab` y poblarla con 300,000 registros, utilizamos el operador `<` para inyectar el script SQL directamente en MySQL.

```bash
mysql -u root -p1234 < 00_instalar_lab_mysql.sql
```

## Paso 2: Medición de la Línea Base (Lectura) (Minutos 5-15)
Para ver el comportamiento inicial de las consultas sin índices (el motor utilizará "Table Scan" y "Filesort"), ejecutamos:

```bash
mysql -u root -p1234 sgbd_a2_lab < 01_linea_base_mysql.sql
```
*Toma nota de los tiempos (en milisegundos) y del costo (generalmente 30222) que muestra el comando EXPLAIN.*

## Paso 3: Medición de la Línea Base (Escritura) (Minutos 5-15)
Medimos cuánto tiempo tarda MySQL en insertar 10,000 registros sin los índices que vamos a crear:

```bash
mysql -u root -p1234 sgbd_a2_lab < 03_prueba_escritura_mysql.sql
```
*Anota los milisegundos.*

## Paso 4: Planteo de Hipótesis (Minutos 15-23)
*(Debe documentarse en la bitácora antes de continuar)*
Decidimos crear dos índices compuestos para evitar los Table Scans y Filesorts de las consultas A y B.

## Paso 5: Intervención (Creación de Índices) (Minutos 23-35)
Para crear los índices, editamos el archivo `02_experimento_estudiantes_mysql.sql` y agregamos nuestro código DDL:

```sql
CREATE INDEX idx_a2_gXX_cliente_fecha ON pedido (cliente_id, fecha);
CREATE INDEX idx_a2_gXX_sucursal_estado_fecha ON pedido (sucursal_id, estado, fecha);
```

Luego, lo ejecutamos:
```bash
mysql -u root -p1234 sgbd_a2_lab < 02_experimento_estudiantes_mysql.sql
```

## Paso 6: Segunda Medición (Lectura) (Minutos 35-45)
El script del paso 5 (`02_experimento_estudiantes_mysql.sql`) automáticamente corre los `EXPLAIN` de nuevo. 
*Aquí debemos comprobar que los tiempos cayeron a fracciones de milisegundo y que desaparecieron los `Sort` y `Table scan`.*

## Paso 7: Segunda Medición (Escritura) (Minutos 45-55)
Volvemos a medir el costo de insertar 10,000 filas (ahora el motor tiene que actualizar los nuevos índices).

```bash
mysql -u root -p1234 sgbd_a2_lab < 03_prueba_escritura_mysql.sql
```
*Notarás que el tiempo es mayor que en el Paso 3.*

## Paso 8: Batalla y Veredicto (Minutos 55-70)
Con estos datos, completamos el veredicto en la bitácora (Justificando que el inmenso beneficio en lectura compensa la penalidad en escritura).
