# Informe de Guardia DBA - Unidad 5 (Actividad 1)

**Grupo:** [Insertar Nombre/Número del Grupo]
**Motor Asignado:** MySQL + MySQL Workbench
**Integrantes:**
- [Nombre Integrante 1]
- [Nombre Integrante 2]
- [Nombre Integrante N...]

---

## 1. Arquitectura de Red y Topología

*Diagrama de arquitectura real: equipos del grupo → red → VM → SGBD.*

> **[ACCIÓN REQUERIDA]**  
> Insertar aquí el diagrama de red (puede ser una imagen hecha en draw.io o similar) donde se vea:
> - El router/Wi-Fi o switch (LAN).
> - La PC que oficia de "Host anfitrión" con su IP.
> - La Máquina Virtual (VirtualBox o Multipass) corriendo adentro con su IP puente.
> - Las PCs de los demás integrantes conectándose a esa IP.

---

## 2. Matriz de Conectividad (Etapa 2)

Cada integrante instaló **MySQL Workbench** y logró conectarse al mismo servidor remoto del grupo.

| Integrante | Sistema operativo | Cliente instalado | IP/Dirección del servidor | Puerto | Usuario utilizado | Prueba de puerto | Conexión al SGBD | Evidencia |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [Nombre 1] | [Ej. Windows 11] | MySQL Workbench 8.x | [Ej. 192.168.1.50] | 3306 | alumno01 | Sí | Sí | *Ver Captura 1* |
| [Nombre 2] | [Ej. Ubuntu 22.04] | MySQL Workbench 8.x | [Ej. 192.168.1.50] | 3306 | alumno02 | Sí | Sí | *Ver Captura 2* |
| [Nombre N] | [Completar...] | MySQL Workbench 8.x | [Completar...] | 3306 | alumno0N | Sí | Sí | *Ver Captura N* |

> **[ACCIÓN REQUERIDA]**  
> Pegar aquí las capturas de pantalla que demuestren la conexión exitosa (una por cada integrante). En Workbench, sirve una captura mostrando la pantalla de inicio con la conexión creada, o un "Server Status" donde se vea que se está conectado remotamente.

---

## 3. Checklist DBA (Etapa 3)

| Área | Investigación |
| :--- | :--- |
| **Objetos** | **Dónde está:** En el panel "Navigator" -> Pestaña "Schemas".<br>**Qué muestra:** El listado de bases de datos, y al desplegar una, se ven Tables, Views, Stored Procedures y Functions.<br>**Para qué sirve:** Permite al DBA ver la estructura lógica completa de la base, administrar permisos a nivel objeto y navegar por el esquema.<br>**Evidencia:** *[INSERTAR CAPTURA de la pestaña Schemas desplegada]* |
| **Seguridad** | **Dónde está:** En "Navigator" -> "Administration" -> "Users and Privileges".<br>**Qué muestra:** Cuentas de usuario del motor (ej. root, alumno01), contraseñas, tipos de autenticación y qué roles o privilegios tiene cada uno (Global, Schema, Object).<br>**Para qué sirve:** Vital para el DBA para restringir accesos, crear usuarios, rotar claves y auditar quién puede hacer qué.<br>**Evidencia:** *[INSERTAR CAPTURA de Users and Privileges]* |
| **Metadatos** | **Tabla analizada:** `[Elegir una tabla, ej: factura]`<br>**Dónde está:** Clic derecho sobre la tabla -> "Table Inspector".<br>**Qué muestra:** Columnas (Data types), Constraints (PK/FK), Índices, Tamaño en disco (Data length / Index length), Motor de almacenamiento (InnoDB).<br>**Para qué sirve:** Útil para revisar si una tabla está muy pesada, si faltan índices de rendimiento, o qué motor transaccional se está utilizando.<br>**Evidencia:** *[INSERTAR CAPTURA del Table Inspector]* |
| **Ingeniería inversa** | **Dónde está:** En el menú principal superior: "Database" -> "Reverse Engineer".<br>**Qué hace:** Conecta a la base, lee sus tablas y relaciones lógicas, y dibuja automáticamente el Diagrama Entidad-Relación (ERD).<br>**Evidencia:** *[INSERTAR CAPTURA del Diagrama ERD generado en Workbench]* |

---

## 4. Primera Guardia DBA (Etapa 4)

| Aspecto | Informe |
| :--- | :--- |
| **Servidor** | **Motor y versión:** MySQL [Ej. 8.0.35-0ubuntu0.22.04.1]<br>**Base analizada:** [Nombre de la base]<br>**Usuario conectado:** [ej. alumno01] |
| **Sesiones** | **Dónde se vio:** "Administration" -> "Client Connections".<br>**Resultado:** Hay X conexiones en total. De esas, Y corresponden a integrantes del grupo usando sus respectivos usuarios.<br>*[INSERTAR CAPTURA DE CLIENT CONNECTIONS]* |
| **Actividad** | En "Client Connections" pudimos identificar que la sesión del usuario `[ej. alumno02]` estaba en estado `Sleep` (o `Query` ejecutando `[escribir consulta]`). |
| **Tabla** | **Tabla elegida:** `[Ej: movimientos]`<br>Tiene X filas, su Clave Primaria es `id_movimiento`, y tiene índices adicionales en `[ej. id_cuenta]`. |
| **Rendimiento** | **Indicadores vistos en el *Dashboard*:**<br>1. **Network Traffic:** Indica los KB de entrada/salida. Sirve para ver cuán demandada está la red del SGBD.<br>2. **MySQL Server CPU:** Porcentaje de uso de procesador del SGBD. Sirve para detectar cuellos de botella computacionales.<br>3. **InnoDB Buffer Pool Usage:** Memoria RAM ocupada por caché de datos. Un número alto es normal y bueno, indica que no está leyendo lento desde el disco duro.<br>*[INSERTAR CAPTURA DEL DASHBOARD]* |
| **Espacio** | Desde el "Table Inspector" -> "Table Info", vimos que la tabla `[Nombre]` ocupa [Ej. 16 KB] de datos (Data Length) y [Ej. 0 KB] de índices. |
| **Mantenimiento** | **Función identificada:** Export/Import (Backup lógicos) o visualización de Server Logs en el Dashboard ("Server Logs"). Permite al DBA revisar errores fatales del SGBD o restaurar datos si hay problemas. |

**Estado General del Servidor (Cierre 100 palabras):**
> **[ACCIÓN REQUERIDA]** Escribir una breve conclusión grupal.  
> *Ejemplo base:* "El servidor se encuentra estable, escuchando correctamente en todas sus interfaces (`0.0.0.0`). Los indicadores de CPU y RAM están en niveles mínimos ya que no hay gran volumen de transacciones concurrentes. Pudimos evidenciar en el monitor de sesiones que todas las conexiones provenían de las IP de los integrantes y ninguna requirió tiempos prolongados. La única atención futura sería el control del crecimiento del log si se activaran consultas pesadas."

---

## 5. ¿Qué está haciendo esta consulta? (Etapa 5)

**Consulta analizada:**
```sql
EXPLAIN
SELECT titular, saldo
FROM cuenta
WHERE saldo > 50000.00 AND estado = 'activa0'
ORDER BY titular ASC;
```

**Lectura del Plan de Ejecución (Formato Árbol/Gráfico):**
- **Acceso principal:** Escaneo completo de tabla (`Table scan on cuenta`).
- **Uso de índice:** No usó índices. El motor realizó una lectura secuencial completa de la tabla para luego aplicar el filtro `WHERE`.
- **Costo/Estimaciones:** El costo total estimado de la consulta (`cost`) es muy bajo: **0.65**, y el optimizador estima procesar y retornar **4 filas** (`rows=4`).
- **Parte más pesada:** La operación de lectura a disco base (`Table scan on cuenta`) que luego debe ser filtrada (`Filter: ((cuenta.estado = 'activa') ...`) y finalmente ordenada en memoria (`Sort: cuenta.titular`). Aunque los costos son bajos, al no haber índice, el motor tiene que leer todos los registros y ordenarlos "al vuelo".

> **[ACCIÓN REQUERIDA]**  
> Insertar CAPTURA del Plan de Ejecución (Visual Explain o el formato árbol como se ve en la captura) desde MySQL Workbench para respaldar la lectura.

**Texto vs Gráfica (o formato Árbol):**
Al comparar la salida tradicional de consola contra la vista en forma de árbol (`FORMAT=TREE` o Visual Explain), resulta mucho más intuitivo entender el flujo de los datos desde adentro hacia afuera (o de abajo hacia arriba). Queda clarísimo en un solo vistazo que primero se lee toda la tabla, el paso intermedio es filtrar por estado y saldo, y el paso final (y más externo) es ordenar los resultados por titular.

---

## 6. Conclusión Grupal

**Si mañana este servidor presentara problemas, ¿qué cinco elementos revisaríamos primero desde la herramienta y por qué?**

1. **Dashboard - Server Status:** Para ver de un plumazo si el motor está online (Running), el uso global de CPU y memoria RAM para descartar un colapso generalizado de recursos físicos del equipo.
2. **Client Connections (Sesiones):** Para revisar si hay un pico anormal de sesiones conectadas ("cientos de usuarios de golpe") o si alguna conexión se quedó "colgada" ejecutando una query pesada bloqueando a otras.
3. **Server Logs:** Ubicado en la administración, permite leer los archivos de log de MySQL para buscar mensajes de error críticos (`[ERROR]`), caídas por falta de memoria u otros avisos del sistema.
4. **Performance Reports / Statement Analysis:** Si el servidor está lento, este reporte permite identificar cuáles son las consultas SQL (Queries) más lentas o que mayor carga de E/S están generando.
5. **Dashboard - InnoDB Buffer Pool:** Si vemos que la caché (memoria) está al 100% y la métrica de escrituras/lecturas a disco físico se dispara, significa que la VM se quedó corta de memoria RAM y el motor está forzando lecturas lentas, degradando el rendimiento general.
