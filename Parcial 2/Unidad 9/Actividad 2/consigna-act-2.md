**U9 - Actividad 2 · Batalla de arquitecturas multimodelo**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.

> **Pregunta guía:** ¿Cómo justificar una arquitectura de datos cuando distintas áreas del negocio exigen propiedades diferentes?

**Escenario único: OmniMarket**
OmniMarket es una plataforma omnicanal con web, app móvil, tiendas físicas, depósitos y campañas de fidelización. Debe integrar ventas, catálogo, clientes, inventario, sesiones, navegación, recomendaciones, logística y marketing. Todos los grupos reciben el mismo escenario; no existe una asignación previa de motor por área.

**Requerimientos del negocio**

| Dominio | Operaciones y condiciones |
| :--- | :--- |
| **Clientes** | Alta y actualización de perfiles; búsquedas por identidad; protección de datos personales. |
| **Catálogo** | Productos con atributos heterogéneos por categoría; filtros y cambios frecuentes de atributos. |
| **Inventario** | Stock por sucursal; reservas; evitar ventas por encima del disponible. |
| **Ventas y pagos** | Pedidos, comprobantes y cambios de estado; integridad y trazabilidad. |
| **Sesiones y carritos** | Acceso frecuente, baja latencia y expiración de sesiones inactivas. |
| **Navegación** | Eventos masivos por usuario y fecha; consulta de historial reciente. |
| **Recomendaciones** | Relaciones entre clientes, productos, categorías y afinidades. |
| **Marketing** | Campañas, segmentos y promociones temporales. |
| **Logística** | Estados de envío y consulta de seguimiento por pedido. |
| **Fidelización** | Puntos, beneficios y movimientos auditables. |

**Modelos a considerar**
*   **Evaluación obligatoria de 5 modelos:** Relacional (MySQL/PostgreSQL), documental (MongoDB), clave-valor (Redis), columnas anchas (Cassandra) y grafos (Neo4j).
*   **Condición de implementación:** Evaluar los cinco es obligatorio; utilizar los cinco no lo es. Deben implementarse al menos **dos modelos NoSQL diferentes** elegidos por el grupo. El componente relacional se modela y justifica, pero no se implementa.

---

### Fases de trabajo

*   **Fase 1. Diagnóstico**
    *   Identificar datos, operaciones y consultas prioritarias de cada dominio.
    *   Explicitar supuestos de volumen, frecuencia, crecimiento, integridad, latencia y disponibilidad.
    *   Separar requisitos obligatorios de preferencias.

*   **Fase 2. Selección y arquitectura**
    *   Asignar modelo y motor a cada dominio, pudiendo reutilizar un mismo motor en varias áreas.
    *   Para cada selección, justificar la alternativa elegida y al menos una descartada.
    *   Entregar un diagrama de componentes, flujos y dependencias; indicar fuente de verdad de datos compartidos y estrategia de sincronización.
    *   Justificar explícitamente el costo de sumar motores (no gana quien usa más tecnologías).

*   **Fase 3. Modelado e implementación NoSQL**
    *   Modelar los componentes elegidos de los modelos NoSQL; presentar el diseño conceptual/lógico de los componentes relacionales sin implementarlos.
    *   Implementar en Ubuntu Server 24.04 al menos dos modelos NoSQL distintos, con datos de prueba consistentes con el escenario.
    *   Para cada componente NoSQL implementado: altas, modificaciones, bajas y lecturas; al menos dos consultas de negocio con resultados.
    *   Demostrar una interacción o intercambio de información entre componentes mediante flujo documentado o carga de datos coherente (no se exige aplicación web ni integración automática completa).
    *   Explicar qué se haría ante duplicación de datos y actualizaciones concurrentes.

*   **Fase 4. Batalla entre grupos**
    *   Dos grupos se enfrentan sobre el mismo caso.
    *   **Dinámica del debate:** Presentación de arquitectura (8 min) → Cuestionamiento a la propuesta rival (5 min) → Respuesta a objeciones (4 min).
    *   **Evaluación:** El JTP modera y evalúa la calidad de evidencias y argumentación, no la cantidad de motores.

---

### Entregables

*   **Informe PDF:** Matriz de requisitos, matriz de decisión de los cinco modelos y alternativas descartadas.
*   **Diagrama de arquitectura:** Componentes, flujos, fuente de verdad y estrategia de sincronización de datos.
*   **Modelos NoSQL:** Diseños de datos y scripts de los al menos dos modelos NoSQL implementados, con capturas y resultados de CRUD/consultas.
*   **Diseño relacional:** Especificación de los componentes relacionales sin implementación.
*   **Presentación para defensa:** Diapositivas/apoyo para la exposición y registro escrito de objeciones recibidas con sus respuestas.
*   **Estrategia de integración:** Explicación detallada sobre cómo se integrarían los datos de los distintos motores entre sí.

---

### Criterios de evaluación

| Criterio | Peso |
| :--- | :---: |
| **Análisis de requerimientos** | 15 % |
| **Selección y justificación de modelos** | 25 % |
| **Modelado** | 20 % |
| **Implementación NoSQL y consultas** | 20 % |
| **Defensa y contraargumentación** | 20 % |