**U7 - Actividad 1 · Radar multimodelo**

* **Modalidad:** Grupal (entrega única por grupo).
* **Motor:** Asignado por la cátedra (MySQL / PostgreSQL).
* **Duración orientativa:** 50 - 60 min.

**Misión**
Investigar las capacidades no relacionales del motor asignado, verificando disponibilidad en el entorno actual frente a necesidades de plugins, extensiones, clientes, configuración o componentes adicionales.

**Reglas de trabajo**
* **Documentación oficial:** Usar como fuente primaria la documentación técnica del motor.
* **Problema y solución:** Asociar cada capacidad con una necesidad real que evite forzar el modelo tabular.
* **Validación empírica:** Probar y verificar sobre la instancia real del grupo (registrar versión y edición).
* **Modo lectura:** Solo observar, consultar y proponer; no modificar configuraciones sensibles.
* **Uso de IA:** Permitido solo para formular búsquedas o interpretar errores, validando todo resultado contra la documentación y el motor.

---

### Desafíos

**Desafío 1 - Identificar el entorno**
Registrar motor, versión, edición/distribución, sistema operativo y cliente administrativo activo. Incluir evidencia con comandos (`SELECT VERSION();`, `mysql -V`, `psql --version`) o capturas de consola.

**Desafío 2 - Construir el radar**
Investigar al menos 5 capacidades no tabulares (cobertura mínima: documento/JSON, estructura de indexación especializada y una capacidad no tabular adicional).

| Capacidad | Problema que resuelve | Estado en el entorno | Cómo se habilita/usa | Evidencia | Fuente oficial |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Documento / JSON** | Evita la dispersión en tablas secundarias para atributos altamente variables o esquemas dinámicos. | Disponible / Requiere habilitación / Requiere extensión | Tipo nativo `JSON` / funciones JSON / X DevAPI | Consulta SQL / comando de verificación | URL + Sección |
| **Índice Especializado** | Optimiza búsquedas en colecciones JSON o texto sin escaneo completo de filas. | Disponible / Requiere habilitación | Índices multivaluados / GIN / GiST / Full-Text | `EXPLAIN` / `SHOW INDEX` | URL + Sección |
| **Espacial / GeoJSON** | Resuelve consultas geométricas y geográficas (distancia, polígonos, intersección). | Disponible / Requiere extensión | Tipos `GEOMETRY`, `POINT` / PostGIS / Funciones `ST_*` | Consulta espacial con `ST_Contains` | URL + Sección |
| **Arrays / Clave-Valor** | Almacena conjuntos simples de valores o pares llave-valor sin crear tablas intermedias M:N. | Disponible / Requiere extensión | Arrays nativos / `hstore` / funciones de array | Consulta con operadores de array | URL + Sección |
| **Full-Text Search** | Búsqueda lingüística y por relevancia en bloques de texto no estructurado. | Disponible / Requiere habilitación | Índices `FULLTEXT` / dialectos de búsqueda `MATCH...AGAINST` | Query con `MATCH()` | URL + Sección |

**Pistas de búsqueda por motor:**
* **MySQL:** JSON nativo, Document Store / X Plugin / X Protocol / X DevAPI, índices multivaluados sobre arrays JSON, Full-Text Search, Spatial/GeoJSON.
* **PostgreSQL:** JSON/JSONB, índices GIN/GiST, arrays, `hstore`, Full-Text Search, extensiones/tipos adicionales (p. ej., PostGIS).

**Desafío 3 - Clasificar y elegir**
Clasificar cada capacidad según la categoría:
* **Core:** Disponible nativamente sin instalación previa.
* **Habilitable:** Incluida en el motor pero requiere activación o configuración previa.
* **Extensión / Plugin / Cliente:** Requiere componentes o librerías adicionales.
* **No disponible:** Explicar limitación o incompatibilidad del entorno.

> **Selección para Fase 2:** Elegir una capacidad candidata avanzada (no limitarse a guardar JSON en una columna; incluir características como Document Store/X Plugin, índices multivaluados, GIN, `hstore` o Full-Text).

---

### Entregables y Criterio

**Entregables**
1. **Radar multimodelo (PDF, máx. 3 pág.):** Matriz completa del Desafío 2 y clasificación del Desafío 3.
2. **Evidencias (3 a 5 capturas/salidas):** Integradas en el PDF, acompañadas de una frase descriptiva de validación.
3. **Selección Fase 2:** Definición explícita de la capacidad elegida + problema a resolver + requisitos de instalación/activación.

> **Criterio central:** Se evalúa la capacidad de distinguir la disponibilidad real en el entorno del grupo, su método de habilitación y la justificación técnica del problema que resuelve.