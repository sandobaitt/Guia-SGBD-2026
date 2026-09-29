# Guía Paso a Paso - Ejecución Actividad 3

Este instructivo muestra cómo simular el ciclo de vida completo de un despliegue de Base de Datos (CI/CD simulado en local).

## 1. El Pasado (Desplegar versión 1)
Simularemos que es el año pasado y subimos la base de datos a producción insertándole clientes y pedidos reales.
Abre tu consola y ejecuta:
```bash
mysql -u root -p1234 < 01_schema_v1.sql
mysql -u root -p1234 < 02_datos_v1.sql
```

## 2. El Presente (Desplegar versión 2.0)
El equipo de desarrollo avisa que van a subir la nueva versión del código que maneja estados de pedidos. Necesitamos actualizar la estructura de la base de datos y agregar nuestra programabilidad **sin perder la info de los clientes del punto 1**.
```bash
mysql -u root -p1234 < 03_migracion_v2.sql
mysql -u root -p1234 < 04_programabilidad_v2.sql
```

## 3. Certificación (Pruebas Automatizadas)
Para asegurar que nuestra migración v2 no rompió nada y que los `ENUM`, `CHECK` y `TRIGGERS` funcionan como un escudo protector, corremos las pruebas invalidantes usando `-f` (force). Verás salir un par de `ERROR`s en rojo; eso significa que nuestro sistema de seguridad funcionó a la perfección.
```bash
mysql -u root -p1234 -f < 05_pruebas_v2.sql
```
*(Saca capturas a la terminal de esta ejecución para armar el PDF de entrega).*

## 4. El Pánico (Rollback a la v1)
Simularemos que la aplicación v2 tuvo un error crítico en producción y el Tech Lead nos ordena volver todo a la v1. 
Ejecutaremos el script destructor (lee las alertas de peligro del código fuente).
```bash
mysql -u root -p1234 < 06_rollback_v2.sql
```
Si luego de hacer esto corres el script de pruebas de nuevo, verás que todo falla porque la base de datos volvió a ser la misma estructura rústica de la versión inicial.
