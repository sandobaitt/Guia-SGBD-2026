# Unidad 5: Administración, Concurrencia y Diagnóstico

> [!IMPORTANT]
> **Idea Central de la Unidad:**
> No alcanza con que una conexión o un comando funcione. El grupo debe poder explicar qué está ocurriendo, dónde observarlo y qué evidencia respalda la conclusión.

En esta unidad, el motor de base de datos deja de ser un servicio aislado dentro de una máquina virtual (VM) y pasa a ser un servidor compartido, accedido por varios clientes y observado con herramientas de administración.

---

## Secuencia de Trabajo

A lo largo de esta unidad, se deberán completar los siguientes objetivos prácticos:

### 1. Configuración de Red y Acceso
- Convertir la máquina virtual (VM) del grupo en un servidor accesible desde los equipos de todos los integrantes.

### 2. Herramientas de Administración
- Instalar y utilizar herramientas gráficas de administración: **MySQL Workbench** o **pgAdmin** (según el motor de base de datos asignado al grupo).

### 3. Primera Guardia DBA (Database Administrator)
Realizar tareas de monitoreo y análisis del estado del motor, incluyendo:
- Inspección de **objetos** de la base de datos.
- Monitoreo de **sesiones** activas.
- Análisis de **rendimiento** y consumo de recursos.
- Control del **espacio** de almacenamiento.
- Lectura y comprensión del **plan de ejecución** de consultas.
- Tareas de **ingeniería inversa** (generación de diagramas a partir de esquemas existentes).

### 4. Transacciones y Concurrencia
- Ejecutar transacciones concurrentes simulando múltiples usuarios desde **sesiones independientes** al mismo tiempo.

### 5. Diagnóstico de Conflictos
Diagnosticar y documentar problemas de concurrencia usando evidencia directa del motor:
- Identificación de **esperas** (waits).
- Detección de **bloqueos** (locks).
- Análisis de niveles de **aislamiento** (isolation levels).
- Resolución de **deadlocks** (abrazos mortales).

---

> [!TIP]
> Recuerden que para cada punto de la secuencia de trabajo, el objetivo principal es **generar evidencia**. Tomen capturas de pantalla de las consolas de administración, guarden los logs del motor y documenten cada paso para respaldar sus conclusiones.
