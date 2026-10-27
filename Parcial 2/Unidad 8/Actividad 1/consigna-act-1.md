**U8 - Actividad 1 · Del requerimiento al documento**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.
*   **Desafío:** MongoDB | Diseño e implementación.
*   **Modalidad:** Entrega grupal (12 grupos).
*   **Motor:** MongoDB Community.
*   **Herramientas:** `mongosh` y/o MongoDB Compass; en administración, Database Tools.

> **Importante:** Utilizar exclusivamente una instancia de laboratorio y datos ficticios. No publicar puertos ni credenciales; no realizar pruebas destructivas sobre bases compartidas.

**Situación y objetivo**
Construir una solución documental nativa basada en los patrones de acceso y consultas que debe resolver la aplicación (evitar la traducción directa de un modelo relacional a JSON).

**Escenarios asignados**

| Grupo | Escenario | Variante |
| :--- | :--- | :--- |
| **G01** | Comercio electrónico | Venta minorista |
| **G02** | Reservas | Hotel urbano |
| **G03** | Plataforma educativa | Cursos autogestionados |
| **G04** | Gestión de incidentes | Mesa de ayuda TI |
| **G05** | Logística | Paquetería urbana |
| **G06** | Plataforma de contenidos | Portal de noticias |
| **G07** | Comercio electrónico | Compras corporativas |
| **G08** | Reservas | Complejo de cabañas |
| **G09** | Plataforma educativa | Capacitaciones empresariales |
| **G10** | Gestión de incidentes | Incidentes de servicios |
| **G11** | Logística | Distribución interprovincial |
| **G12** | Plataforma de contenidos | Comunidad técnica |

*Consultar el archivo del propio grupo para conocer los requerimientos específicos de la variante.*

---

**Etapas de trabajo**

1.  **Diseñar:** Identificar patrones de acceso; proponer colecciones, documentos, arreglos, subdocumentos y referencias. Justificar al menos dos decisiones de diseño considerando límites de crecimiento.
2.  **Cargar:** Crear una base de datos nombrada `u8_gXX` (según el número de grupo), insertar al menos 30 documentos representativos con datos ficticios y verificar recuentos.
3.  **Consultar:**
    *   Ejecutar operaciones CRUD (alta, lectura, modificación y eliminación) sobre registros de prueba.
    *   Resolver cuatro consultas del escenario asignado, incluyendo filtros sobre arreglos o subdocumentos.
    *   Construir un pipeline de agregación con al menos tres etapas.
4.  **Optimizar:** Crear un índice relevante y registrar la salida de `explain("executionStats")` antes y después de su aplicación.
5.  **Defender:** Describir una alternativa de modelado descartada y justificar el costo de mantener datos duplicados/desnormalizados.

---

**Evidencias y entrega**

*   `bitacora.pdf`: Colecciones, estructura/ejemplo de documentos y justificaciones de diseño.
*   `actividad1.txt`: Script reproducible con sentencias de carga de datos, operaciones CRUD, consultas, pipeline de agregación e índices.
*   `evidencias.txt` o `.pdf`: Resultados de ejecución, análisis del plan de consulta antes/después, métricas y conclusiones.

> **Formato de entrega:** Un único archivo `.zip` por grupo que contenga únicamente los tres archivos solicitados.

---

**Criterios de logro**

| Criterio | Logrado | Parcial | No logrado |
| :--- | :--- | :--- | :--- |
| **Modelo y acceso** | Diseño coherente y justificado según patrones de acceso. | Diseño funcional pero con justificación incompleta. | El modelo no resuelve los patrones de acceso requeridos. |
| **Implementación** | Carga de datos y operaciones CRUD completamente reproducibles. | Ejecución parcial o script incompleto. | No hay evidencia de ejecución verificable. |
| **Consultas y pipeline** | 4 consultas correctas y pipeline de agregación con 3+ etapas funcional. | Consultas con errores o pipeline incompleto. | No resuelve las consultas del escenario. |
| **Índice y evidencia** | Explicación detallada de planes de ejecución (`explain`) y sus limitaciones. | Creación de índice sin análisis suficiente de métricas. | Sin evidencia de optimización ni comparación. |