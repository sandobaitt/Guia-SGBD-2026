# Guía Paso a Paso - Ejecución Actividad 2

Esta guía documenta los pasos para levantar la base de datos de la Actividad 2 y ejecutar tanto el script de solución como el de pruebas.

## Paso 1: Inicialización del Laboratorio Base
Primero, necesitamos instalar el esquema original provisto por la cátedra (las tablas de clientes, cuentas y productos).
Abre tu terminal, ubícate en la carpeta del proyecto de la Actividad 2 y ejecuta:

```bash
mysql -u root -p1234 < actividad2_mysql_base.sql
```

## Paso 2: Ejecución del Script de Resolución
Hemos agrupado las soluciones (Constraints, Trigger, Tabla temporal de ventas y Función Almacenada) en el archivo `resolucion_actividad2.sql`. Para aplicarlas a la base de datos, corre el siguiente comando indicando el nombre de la base de datos (`sgbd_u4_act2`):

```bash
mysql -u root -p1234 sgbd_u4_act2 < resolucion_actividad2.sql
```

## Paso 3: Ejecución de la Batería de Pruebas
Para demostrarle al profesor (y documentar en el PDF) que nuestras reglas de negocio son infranqueables, creamos el archivo `pruebas_actividad2.sql`. Este archivo contiene intentos deliberados de vulnerar el sistema, por lo que usaremos la bandera `-f` (force) para que MySQL imprima los errores en pantalla pero continúe ejecutando el resto de las pruebas exitosas.

```bash
mysql -u root -p1234 sgbd_u4_act2 -f < pruebas_actividad2.sql
```

**Lo que verás en la salida:**
1. Los errores `Check constraint is violated` (demostrando que bloqueamos precios y saldos negativos).
2. La tabla de auditoría con el registro de aumento de precio.
3. El listado de 3 clientes categorizados como Oro, Plata y Bronce por la función de agregación anual.

## Paso 4: Evidencias para la Entrega
Toma capturas de pantalla de la salida en terminal del Paso 3. Arma un documento PDF con esas capturas y entrégalo junto con los archivos `.sql` y tu bitácora.
