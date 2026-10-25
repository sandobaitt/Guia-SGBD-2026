**U7 - Actividad 2 · Laboratorio bisagra**

* **Modalidad:** Grupal (entrega única por grupo).
* **Motor:** Asignado por la cátedra (MySQL / PostgreSQL).
* **Duración orientativa:** 80 - 100 min.

**Misión**
Instalar, habilitar o configurar una capacidad no relacional identificada en el Radar; usarla sobre un caso práctico concreto, producir evidencia de rendimiento o comportamiento, y decidir con criterio técnico si alcanza con extender el motor relacional o si tiene sentido incorporar un SGBD NoSQL especializado.

**Condición de entrada**
Partir de la matriz del Radar multimodelo con una capacidad seleccionada. La implementación elegida no puede reducirse únicamente a crear una columna tipo `JSON` y ejecutar consultas `SELECT` simples.

---

### Caso de estudio: Catálogo técnico multirubro

Una organización comercializa productos heterogéneos pertenecientes a categorías muy diversas. 
* **Atributos estables (relacionales):** `id`, `nombre`, `precio`, `stock`.
* **Atributos dinámicos/variables (no relacionales):** Dependen de cada categoría (RAM/GPU, litros/no_frost, talle/material, potencia/voltaje, etc.), acompañados de etiquetas y propiedades opcionales.
* **Dataset:** Se utiliza el archivo de datos provisto `U7_catalogo_multimodelo.jsonl` o un conjunto de datos equivalente compuesto por al menos 20 registros heterogéneos.

---

### Fases de ejecución

#### Fase A - Preparar y habilitar
1. **Registrar baseline:** Identificar versión exacta del motor, estado inicial de la instancia y la capacidad seleccionada.
2. **Procedimiento oficial:** Documentar los pasos basados en la documentación técnica oficial del motor.
3. **Instalación / Activación:** Configurar, instalar o activar la capacidad elegida cuando aplique.
4. **Verificación:** Confirmar la operatividad de la función con evidencia directa.

**Capacidades válidas como foco principal:**

| Motor | Capacidades seleccionables |
| :--- | :--- |
| **MySQL** | Document Store / X Plugin + colección; índice multivaluado sobre array JSON; Full-Text Search; Spatial/GeoJSON u otra capacidad adicional justificada. |
| **PostgreSQL** | `JSONB` + índice GIN; `hstore`; Full-Text Search; arrays + índice especializado; u otra extensión/tipo avanzado disponible. |

#### Fase B - Resolver el caso
Implementar el catálogo en un esquema híbrido que evidencie la transición entre el modelo relacional y el no relacional:

1. **Poblado de datos:** Cargar un mínimo de 20 productos heterogéneos.
2. **Consultas de validación:**
   * Consulta 1: Filtrado por atributo escalar relacional.
   * Consulta 2: Búsqueda sobre atributo anidado, colección o etiqueta.
   * Consulta 3: Consulta avanzada explotando la capacidad no relacional seleccionada.
3. **Intervención física:** Crear una estructura de indexación especializada (índice GIN, índice multivaluado, índice Full-Text, espacial, etc.).
4. **Medición y comparación:** Evaluar el comportamiento antes y después de la optimización usando planes de ejecución (`EXPLAIN`), tiempos de respuesta o métricas del motor.

> **Nota:** El objetivo no es obligatoriamente obtener mayor velocidad, sino fundamentar el comportamiento del optimizador, la variación del costo de E/S y las implicaciones técnicas del cambio.

#### Fase C - Veredicto
Completar la matriz de decisión técnica comparando la extensión relacional frente a una solución NoSQL nativa:

| Dimensión | ¿Extender el relacional alcanza? | ¿Cuándo tendría sentido un NoSQL especializado? |
| :--- | :--- | :--- |
| **Variabilidad del esquema** | | |
| **Patrón de consulta** | | |
| **Transacciones / Joins** | | |
| **Escala / Distribución** | | |
| **Complejidad operativa** | | |

* **Conclusión (150 - 200 palabras):** Formular un veredicto justificado sobre la estrategia de arquitectura recomendada: mantener relacional extendido, implementar una arquitectura híbrida o migrar a un motor NoSQL dedicado.

---

### Entregables

1. **Bitácora técnica (PDF, máx. 5 páginas):** Conteniendo baseline, fuente oficial, proceso de habilitación, pruebas, mediciones antes/después, análisis de costos/límites y veredicto final.
2. **Script de código:** Archivo ejecutable (`.sql`, `.js`, `.py` o `.txt`) con la DDL, DML, índices y consultas del experimento.
3. **Evidencia mínima (4 capturas/salidas interpretadas):**
   * Verificación de disponibilidad del entorno.
   * Confirmación de habilitación de la capacidad.
   * Ejecución de consultas sobre el catálogo.
   * Comparación de planes de ejecución o métricas de rendimiento.