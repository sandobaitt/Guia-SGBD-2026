# Guía SGBD 2026

Material de estudio y trabajos prácticos de **Sistemas de Gestión de Bases de Datos 2026** (UTN FRRe): bitácoras resueltas, guías paso a paso, apuntes teóricos, scripts reproducibles y dos pregunteros tipo simulacro, uno por parcial.

Todo está en español. Las salidas que aparecen en las bitácoras salen de ejecuciones reales; cuando una prueba no se pudo hacer, está marcada como pendiente en lugar de inventarse.

## Dónde está cada cosa

| Carpeta | Contenido | Motores |
| :--- | :--- | :--- |
| [Parcial 1](Parcial%201/) | Unidades 1 a 6: administración de bases de datos relacionales | MySQL (con algunas resoluciones en PostgreSQL) |
| [Parcial 2](Parcial%202/) | Unidades 7 a 10: bases de datos NoSQL y en la nube | MySQL 9.x, MongoDB 8.0, Redis, Cassandra, Neo4j, MongoDB Atlas |
| [Laboratorio Integrador](Laboratorio%20Integrador/) | Práctica final que junta los dos bloques | MySQL 9.7 y MongoDB 8.0 sobre Ubuntu Server 24.04, más un clúster en Atlas |

### Para estudiar

| Archivo | Qué es |
| :--- | :--- |
| [apunte_parcial_1.md](Parcial%201/apunte_parcial_1.md) | Apunte de las Unidades 1 a 6, con la comparación MySQL y PostgreSQL por unidad |
| [preguntas_simulacro_parcial_1.md](Parcial%201/preguntas_simulacro_parcial_1.md) | 80 preguntas de opción múltiple sobre las Unidades 1 a 6, con la respuesta explicada |
| [preguntas_simulacro_parcial_2.md](Parcial%202/preguntas_simulacro_parcial_2.md) | 80 preguntas de opción múltiple sobre las Unidades 7 a 10, con la respuesta explicada |
| [referencia_laboratorio.md](Laboratorio%20Integrador/referencia_laboratorio.md) | Recetas por tarea (usuarios, carga masiva, índices, respaldo, MongoDB, Atlas) para consultar durante el laboratorio |

En los dos pregunteros cada pregunta es una situación concreta con cuatro opciones y una sola correcta. La respuesta está dentro de un bloque desplegable, y al final hay una clave para corregir rápido.

## Temas por unidad

**Parcial 1**

| Unidad | Tema |
| :--- | :--- |
| 1 | Arquitectura de motores de bases de datos |
| 2 | Diseño físico y rendimiento |
| 3 y 4 | SQL avanzado, programabilidad y migraciones |
| 5 | Conectividad, transacciones y concurrencia |
| 6 | Seguridad, respaldo, réplica y alta disponibilidad |

**Parcial 2**

| Unidad | Tema |
| :--- | :--- |
| 7 | El relacional multimodelo: JSON, índices multivaluados y Full-Text Search en MySQL |
| 8 | MongoDB: modelado, consultas, índices, seguridad y respaldo |
| 9 | Redis, Cassandra y Neo4j, y la actividad de persistencia políglota |
| 10 | Bases de datos como servicio con MongoDB Atlas |

## Cómo está armada cada actividad

Las actividades del Parcial 2 siguen la misma estructura:

| Archivo | Para qué sirve |
| :--- | :--- |
| `consigna-act-N.md` | Consigna transcripta de la cátedra |
| `bitacora_resuelta.md` | Entregable: problema, decisiones, comandos y evidencias, pruebas válidas, inválidas y límite, errores, uso de IA y aprendizajes |
| `guia_paso_a_paso.md` | Orden de ejecución y de capturas para reproducir la actividad |
| `explicacion_teorica.md` | Teoría necesaria para defender la actividad, con preguntas probables |
| scripts (`.sql`, `.js`, `.sh`, `.cql`, `.cypher`) | Los comandos de la bitácora, listos para ejecutar |

En el Parcial 1, las actividades traen sus propios formatos de entrega.

## Para reproducir los laboratorios

- **MySQL 9.x:** corré el cliente con `--commands` si el script usa `source`, `DELIMITER` o `\G`. Con GTID activado (el valor por defecto), la recuperación a un punto en el tiempo necesita `mysqldump --set-gtid-purged=OFF` y `mysqlbinlog --skip-gtids`.
- **MongoDB 8.0:** las actividades de seguridad y respaldo se prueban en una instancia aparte, nunca sobre el servicio del sistema.
- **Redis, Cassandra y Neo4j Community:** corren sin arranque automático por consumo de memoria. Se levantan a mano con `systemctl start`.
- **Atlas:** plan gratuito M0, sin tarjeta. Los límites de ese plan condicionan el respaldo y el monitoreo, y están explicados en [la teoría de la Unidad 10](Parcial%202/Unidad%2010/Actividad%201/explicacion_teorica.md).

Las contraseñas no están en ningún archivo: aparecen como `<clave>` o se piden por consola (`-p` sin valor, `passwordPrompt()`).

## Material de la cátedra

[Parcial 1/Powers](Parcial%201/Powers/) tiene las diapositivas de las clases 0 a 6. La carpeta *Resoluciones por unidad PostgreSQL* del Parcial 1 reúne resoluciones de otro grupo, como referencia.
