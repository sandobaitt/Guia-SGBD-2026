**U5 - Actividad 1 - Guardia DBA**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.

**Desafío "Guardia DBA" - del servidor compartido a la administración gráfica**
*   **Modalidad:** Grupal. Una única entrega por grupo. Cada grupo trabaja con el motor asignado: **MySQL + MySQL Workbench** o **PostgreSQL + pgAdmin**.
*   **Condición de participación:** La VM puede residir en un solo equipo, pero todos los integrantes con equipo disponible deben instalar el cliente y demostrar conexión al mismo servidor del grupo.

**Escenario**
El equipo recibe una VM Ubuntu con el SGBD instalado. Debe convertirla en un servidor utilizable por el grupo desde la red del aula. La VM puede estar implementada con VirtualBox o Multipass. Se aceptan diferentes soluciones de red, siempre que sean explicables, reproducibles y seguras para el laboratorio.

**Etapa 1 - Habilitar el servidor para el equipo**
*   Identificar tecnología de virtualización, IP y topología utilizada.
*   Comprobar servicio del SGBD, puerto y dirección/interfaz de escucha.
*   Configurar acceso remoto y un usuario/rol de laboratorio sin publicar contraseñas.
*   Resolver la conectividad desde otros equipos. Si la VM no es alcanzable directamente, documentar el mecanismo alternativo utilizado (por ejemplo, bridge o redirección de puerto).

**Etapa 2 - Todos deben entrar**
Cada integrante instala el cliente gráfico correspondiente y se conecta al mismo servidor. Cada integrante debe aportar una evidencia propia de conexión.

| Integrante | Sistema operativo | Cliente instalado | IP/Dirección del servidor | Puerto | Usuario utilizado | Prueba de puerto | Conexión al SGBD | Evidencia |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Integrante 1 | Windows / Linux / macOS | Workbench o pgAdmin Versión x.x | xxx.xxx.xxx.xxx | xxxx | usuario | Sí / No | Sí / No | Captura de pantalla |
| Integrante x | ... | ... | ... | ... | ... | Sí / No | Sí / No | ... |

**Etapa 3 - Reconocer el territorio DBA**
Distribuyan el checklist entre los integrantes. Para cada punto responder: **dónde está**, **qué muestra**, **para qué le sirve a un DBA** y **qué evidencia obtuvieron**.

| Área | Investigación |
| :--- | :--- |
| **Objetos** | Bases/esquemas, tablas, vistas, índices, constraints, funciones/procedimientos y triggers disponibles. Describir brevemente cada uno. |
| **Seguridad** | Usuarios/roles y privilegios visibles desde la herramienta. |
| **Metadatos** | Columnas, tipos, PK, FK, índices y propiedades de una tabla elegida. Explicar qué información de utilidad brinda y para qué casos la usaría. |
| **Ingeniería inversa** | Generar un ERD/modelo a partir de una base o esquema existente. Pegar diagrama obtenido. |

**Etapa 4 - Primera guardia DBA**
Elaborar un informe breve por cada integrante desde su cliente (unificables en un solo PDF) que incluya:

| Aspecto | Qué deben informar |
| :--- | :--- |
| **Servidor** | Motor, versión, base analizada y usuario conectado. |
| **Sesiones** | Cantidad de conexiones y cuáles corresponden a integrantes del grupo. |
| **Actividad** | Identificar al menos una sesión activa y qué está ejecutando. |
| **Tabla** | Elegir cuenta o movimiento e informar filas, PK e índices. |
| **Rendimiento** | Seleccionar 3 indicadores disponibles en Workbench/pgAdmin. Indicar valor, qué representa y una breve interpretación. |
| **Espacio** | Informar tamaño de la base o de alguna de sus tablas, según lo disponible en la herramienta. |
| **Mantenimiento** | Identificar una función de mantenimiento, diagnóstico o logs disponible en la herramienta. |

> **Cierre (máximo 100 palabras):** ¿Cuál es el estado general del servidor? ¿Encontraron algo que merezca atención? Justifiquen utilizando al menos dos evidencias observadas.

**Etapa 5 - ¿Qué está haciendo esta consulta?**
*   Ejecutar una consulta sobre la base de laboratorio (sirven actividades anteriores).
*   Obtener el plan de ejecución mediante la herramienta gráfica.
*   Explicar: acceso principal, uso o no de índice, filas/estimaciones/costo disponibles y qué parte parece realizar mayor trabajo.
*   Comparar la salida en texto vs. la gráfica: ¿cuál se entiende más? *(No optimizar en esta actividad).*

**Entrega grupal**
Un archivo PDF titulado **Informe de Guardia DBA** con:
*   Diagrama de arquitectura real: equipos del grupo → red → VM → SGBD.
*   Matriz de conectividad con evidencia de todos los integrantes presentes.
*   Checklist DBA completo y distribuido entre integrantes.
*   ERD/modelo de ingeniería inversa.
*   Estado del servidor y tres indicadores interpretados.
*   Plan de ejecución y lectura breve.
*   **Conclusión grupal (máximo 200 palabras):** Si mañana este servidor presentara problemas, ¿qué cinco elementos revisaríamos primero desde la herramienta y por qué?

> **Importante:** La entrega es grupal. Durante la puesta en común el JTP puede solicitar a cualquier integrante que explique una parte del checklist o de la arquitectura.

**Archivos de apoyo**
*   `README.txt`
*   `U5_Actividad1_Etapa1_Conectividad_Guiada_2026.pdf`
*   `U5_Setup_MySQL.sql`
*   `U5_Setup_PostgreSQL.sql`