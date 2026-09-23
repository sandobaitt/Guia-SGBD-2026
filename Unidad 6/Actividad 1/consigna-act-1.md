**U6 - Actividad 1 - Operación Rescate**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.
*   **Modalidad:** Grupal. Cada grupo trabaja con el motor asignado por la cátedra.
*   **Entorno:** Motor relacional instalado y operativo. Utilizar los scripts de apoyo publicados para el motor correspondiente.
*   **Objetivo:** Proteger una base, generar una copia de resguardo, resolver un incidente de borrado accidental y defender una estrategia de continuidad.

**Situación inicial**
La organización utiliza una base operativa con clientes, cuentas y movimientos. Durante una revisión se detecta que existen permisos excesivos. Luego, durante la operatoria normal, ocurre un incidente: un usuario ejecuta un borrado incorrecto sobre movimientos de una cuenta.
El grupo deberá actuar como equipo DBA: primero reducir la superficie de riesgo, luego recuperar los datos al punto correcto y finalmente proponer cómo evitar o reducir el impacto de incidentes similares.

**Fase 1 - El usuario infiltrado**
*   Ejecutar el script base del motor asignado.
*   Identificar los roles o permisos peligrosos existentes.
*   Demostrar al menos tres accesos indebidos antes de corregirlos.
*   Rediseñar los permisos aplicando el principio de mínimo privilegio.
*   Volver a ejecutar las pruebas y registrar qué operaciones quedan permitidas y cuáles son rechazadas.
*   **Producto de la fase:** Matriz de permisos final y evidencia de pruebas por rol.

**Fase 2 - El DBA borró producción**
*   Registrar el estado inicial: cantidad de clientes, cuentas, movimientos y suma de importes.
*   Generar una copia de resguardo y documentar el comando utilizado.
*   Ejecutar las operaciones válidas posteriores al backup indicadas por la cátedra o por el script de apoyo.
*   Simular el incidente de borrado accidental.
*   Determinar el punto objetivo de recuperación (PITR).
*   Restaurar y validar el estado final.
> **Importante:** Restaurar solamente al backup inicial puede perder operaciones válidas. Recuperar hasta el último estado observado puede conservar el error. El grupo debe justificar el punto elegido.
*   **Producto de la fase:** Comandos de backup/restore/recovery, evidencia antes/después y validación del estado final.

**Fase 3 - Diseñar para sobrevivir**
Cada grupo deberá proponer una arquitectura de protección, recuperación y continuidad para el escenario asignado. La solución debe indicar: estrategia de backup, frecuencia, retención, uso de logs, posibilidad de PITR, réplica si corresponde, modalidad síncrona/asíncrona, procedimiento ante caída del primario, tratamiento de un borrado accidental y evidencia de cumplimiento de RPO y RTO solicitados. También deberán indicar al menos un costo, riesgo o limitación de la solución elegida.

| Grupo | Escenario asignado | Contexto | Requerimientos operativos | Restricción principal |
| :--- | :--- | :--- | :--- | :--- |
| **G01 / G03** | E-commerce 24x7 | Tienda online con ventas continuas, pagos y actualización permanente de stock. Una caída afecta ventas y experiencia de clientes. | RPO: 5 min. RTO: 20 min. Debe contemplar backup, recuperación puntual y una alternativa de continuidad ante caída del servidor principal. | Presupuesto medio. No se admite una arquitectura excesivamente costosa. |
| **G02 / G07** | Sistema académico universitario | Gestión de alumnos, inscripciones, regularidades y actas. Alta actividad en períodos de inscripción y cierre de cursadas, pero menor criticidad fuera de esas ventanas. | RPO: 4 h. RTO: 6 h. Debe priorizar recuperación confiable y bajo costo operativo. | Presupuesto bajo. |
| **G04 / G08** | Core financiero crítico | Sistema que registra movimientos de cuentas. Una interrupción afecta operaciones financieras y una pérdida de transacciones tiene alto impacto. | RPO: cercano a 0. RTO: 5 min. Debe contemplar redundancia, replicación, recuperación y separación entre HA y backup. | Presupuesto alto, pero toda complejidad debe justificarse. |
| **G05 / G09** | Sistema interno de RR.HH. | Gestión de empleados, licencias y novedades. Se utiliza principalmente durante horario laboral y sus datos cambian moderadamente. | RPO: 8 h. RTO: 12 h. No requiere operación 24x7. | Se debe evitar sobrearquitectura. |
| **G06 / G11** | Logística y depósitos | Sistema central de stock, preparación de pedidos y despacho para varios depósitos. La indisponibilidad detiene la operación física. | RPO: 15 min. RTO: 30 min. Debe contemplar continuidad operativa y recuperación ante error humano. | Presupuesto medio; infraestructura limitada a dos nodos principales. |
| **G10 / G12** | Data mart de reportes | Base analítica alimentada desde otros sistemas. Los datos pueden regenerarse parcialmente y no atiende transacciones operativas. | RPO: 24 h. RTO: 24 h. Se debe justificar qué respaldar y qué podría reconstruirse. | Prioridad absoluta al costo. No se justifica HA compleja salvo evidencia. |

*   **Puntos a incluir en la propuesta:** Usuarios/roles, backup, logs, pruebas de restore, réplica o alta disponibilidad si corresponde, monitoreo y costos/límites.
*   **Emparejamiento de debate:** G01 ↔ G03, G02 ↔ G07, G04 ↔ G08, G05 ↔ G09, G06 ↔ G11 y G10 ↔ G12.
*   **Producto de la fase:** Propuesta técnica breve y defensa oral de 2 minutos.

**Entrega grupal**
*   **Bitácora PDF:** Decisiones, comandos, evidencias, errores y conclusiones.
*   **Script o archivo TXT:** Comandos SQL y comandos de consola utilizados.
*   **Matriz de permisos:** Puede incluirse dentro de la bitácora.

**Uso responsable de IA**
Se permite utilizar IA para comprender errores, comparar alternativas y mejorar la redacción de la bitácora. No se permite inventar evidencias, reemplazar la práctica real ni entregar comandos que el grupo no pueda explicar.