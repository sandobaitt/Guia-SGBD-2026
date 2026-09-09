# Guía Paso a Paso - Ejecución Actividad 1

Esta guía documenta los pasos para instalar la base de datos de la Actividad 1 y ejecutar los scripts creados por el grupo.

## Paso 1: Inicialización del Laboratorio
Primero, necesitamos ejecutar el script provisto por la cátedra para crear las tablas e insertar los datos iniciales.
Abre tu terminal, ubícate en la carpeta del proyecto y ejecuta:

```bash
mysql -u root -p1234 < actividad1_mysql_setup.sql
```
*(Nota: asumiendo que la contraseña de MySQL es 1234. Cambiar si es diferente).*

## Paso 2: Creación del archivo de consultas
Crea un archivo llamado `resolucion_consultas.sql` en la misma carpeta e inserta el código SQL que redactamos en la bitácora (las 4 consultas).

Para ejecutarlo y probar que todo funciona, puedes entrar a MySQL:
```bash
mysql -u root -p1234 
```

Y luego dentro de la consola de MySQL:
```sql
USE sgbd_u3_act1; -- Asegúrate de usar la base de datos correcta creada por el setup
SOURCE resolucion_consultas.sql;
```

## Paso 3: Prueba de Carga (Opcional)
Como dice la consigna, el archivo `actividad1_mysql_setup.sql` tiene un bloque de código comentado al final para insertar miles de datos de forma masiva.
Si el grupo quiere probar las consultas con más volumen de datos:
1. Abre `actividad1_mysql_setup.sql`.
2. Ve al final del archivo y quítale los comentarios a la sección de "INSERCIÓN MASIVA".
3. Vuelve a ejecutar el script del Paso 1.
4. Vuelve a ejecutar tus consultas (Paso 2) y notarás que las funciones de ventana (`OVER`) siguen siendo extremadamente rápidas en comparación a usar múltiples subconsultas.

## Paso 4: Evidencias
Recuerda tomar capturas de pantalla de la terminal mostrando los resultados de las 4 consultas y armar un PDF con ellas. Este PDF se debe entregar junto con el archivo `.sql` de las consultas y la bitácora.
