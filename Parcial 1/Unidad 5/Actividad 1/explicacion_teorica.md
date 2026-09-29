# Conceptos Teóricos - Unidad 5 (Administración y Concurrencia)

Este documento condensa los conocimientos teóricos necesarios para respaldar las prácticas realizadas en la Actividad 1 de la Unidad 5.

---

## 1. El Rol del DBA y las Herramientas GUI

Hasta ahora, la interacción con la base de datos se realizaba de manera local y mayormente mediante la línea de comandos (CLI) o scripts. En un entorno de producción real, una base de datos es un **servidor compartido** administrado por un **Database Administrator (DBA)**.

El DBA no solo ejecuta consultas (DML) o crea esquemas (DDL), sino que es el responsable de:
- **Seguridad:** Proveer acceso mediante la creación de roles y usuarios con privilegios limitados.
- **Rendimiento (Performance):** Monitorear cuellos de botella en CPU, Memoria o E/S de disco.
- **Auditoría:** Revisar logs y conexiones activas para identificar anomalías.

Para realizar esto de forma ágil, el DBA emplea herramientas gráficas de administración o IDEs de bases de datos como **MySQL Workbench** o **pgAdmin**. Estas herramientas abstraen consultas complejas de las tablas del sistema (Information Schema) y las muestran en dashboards visuales.

---

## 2. Conectividad en Red: Bind-Address y Puertos TCP

Un Sistema de Gestión de Bases de Datos (SGBD) es un software que expone un servicio de red. Por defecto, por motivos de seguridad, los motores vienen configurados para escuchar conexiones únicamente en `127.0.0.1` (localhost).

Para que un servidor sea accesible desde el exterior (la LAN o Internet), el DBA debe configurar la **interfaz de escucha**:
- En MySQL, esto se logra cambiando la directiva `bind-address = 0.0.0.0` (o comentándola) en el archivo `mysqld.cnf`.
- `0.0.0.0` significa *"escuchar en todas las interfaces de red disponibles en esta máquina"*.

A nivel de capa de transporte, la conexión se rige por un **Puerto TCP**. En el caso de MySQL, el estándar asignado por IANA es el **3306**. Para que la conexión fluya, los firewalls (como UFW en Linux o Windows Defender) deben tener una regla de entrada (Inbound) permitiendo el tráfico TCP hacia ese puerto.

---

## 3. Metadatos y el "Information Schema"

Los **Metadatos** son "datos sobre los datos". Un SGBD relacional no solo almacena la información del negocio (ej. clientes, ventas), sino que también mantiene un catálogo exhaustivo sobre sí mismo: qué tablas existen, cuántas columnas tienen, de qué tipo de dato son, quién es su dueño, qué índices existen, etc.

En MySQL, esta información se guarda en bases de datos internas como `information_schema` y `performance_schema`. Cuando en Workbench usamos la herramienta **Table Inspector**, el programa está haciendo por detrás consultas automáticas (ej. `SHOW TABLE STATUS` o `SELECT * FROM information_schema.tables`) y dibujando los resultados de manera amigable para que el DBA tome decisiones (como notar que una tabla creció a Gigabytes de tamaño).

---

## 4. Planes de Ejecución (Execution Plans)

El motor de base de datos posee un componente interno vital llamado **Optimizador de Consultas**. Cuando enviamos una instrucción SQL (`SELECT * FROM...`), el optimizador evalúa diferentes caminos algorítmicos para traer los datos (ej. escanear toda la tabla fila por fila vs. ir directo al dato usando un índice). 

El camino elegido se denomina **Plan de Ejecución**.
- **Visualización en texto:** Se obtiene prefijando la consulta con la palabra `EXPLAIN`. Muestra una tabla con filas indicando el método de acceso, uso de índices, etc.
- **Visual Explain (Gráfico):** Herramientas como Workbench leen la salida del EXPLAIN y generan un grafo tipo árbol (de abajo hacia arriba). Es muy útil para un DBA porque colorea de **rojo o naranja** los nodos "costosos" (por ejemplo, un `Full Table Scan` o un ordenamiento en memoria `Filesort`), permitiendo optimizar rápidamente la consulta agregando índices.

---

## 5. Monitoreo Básico: CPU, Memoria (Buffer Pool) y Sesiones

Cuando un servidor de bases de datos se ralentiza, el DBA monitorea tres pilares mediante los "Dashboards":

1. **Sesiones Concurrentes:** Cada cliente (Workbench, una App Web, etc.) que se conecta abre una "Sesión" o hilo en el motor. Si hay cientos de sesiones simultáneas y una ejecuta una actualización masiva, puede "bloquear" a las demás generando encolamientos (*Locks* o *Waits*).
2. **CPU (Procesador):** Si la CPU está al 100%, puede indicar que se están ejecutando cálculos matemáticos complejos, agregaciones masivas sin índices, o que la cantidad de consultas concurrentes superó la capacidad del procesador.
3. **Memoria y Buffer Pool:** Las bases de datos intentan leer todo desde la Memoria RAM porque es miles de veces más rápida que el disco duro. En MySQL (InnoDB), la porción de RAM dedicada a caché se llama **Buffer Pool**. Si el *Buffer Pool Usage* está lleno, significa que la base está aprovechando bien la RAM. Sin embargo, si la tasa de aciertos de caché (Hit Rate) es baja, significa que la RAM se quedó corta y el motor está leyendo del disco físico, lo que ralentiza todo brutalmente.
