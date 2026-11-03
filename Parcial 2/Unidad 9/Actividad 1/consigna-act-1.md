**U9 - Actividad 1 · Laboratorio multimotor: Redis, Cassandra y Neo4j**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.
*   **Modalidad:** Trabajo grupal.
*   **Entorno:** Ubuntu Server 24.04 LTS en VM (anterior o nueva); instalación nativa, sin Docker.
*   **Motores:** Redis, Apache Cassandra (un nodo) y Neo4j Community.
*   **Documentación:** Solo usar la documentación oficial de cada motor.

| Tecnología | Tipo de documentación | Enlace oficial |
| :--- | :--- | :--- |
| **Redis (Open Source)** | Documentación oficial de la última versión | [redis.io/docs/latest](https://redis.io/docs/latest/) |
| **Apache Cassandra (Community)** | Documentación oficial (v5.0 prerelease y GA) | [cassandra.apache.org/doc/latest](https://cassandra.apache.org/doc/latest/) |
| **Neo4j (Community Edition)** | Portal oficial de documentación | [neo4j.com/docs](https://neo4j.com/docs/) |

**Propósito y alcance**
Operar integralmente tres motores: instalar, modelar, cargar, ejecutar CRUD y consultas, aplicar seguridad básica y probar respaldo y recuperación. El escenario es una tienda en línea. No se pide desarrollar una aplicación ni integrar los motores.

**Datos comunes proporcionados por la cátedra**
Utilizar los archivos `U9-Datos-Usuarios.csv` (5 usuarios), `U9-Datos-Productos.csv` (8 productos, 3 categorías) y `U9-Datos-Eventos.csv` (15 eventos de 3 usuarios). Mantener los identificadores. Cada grupo puede agregar datos de prueba, pero no reemplazar los provistos.

**Verificación de servicios**
1. Registrar versión, nombre del servicio y estado de Redis; ejecutar `PING`.
2. Registrar versión, estado del nodo Cassandra con `nodetool status` y conexión `cqlsh`.
3. Registrar versión, estado de Neo4j y conexión con `cypher-shell` o Browser.
4. Mostrar al JTP los tres servicios operativos **antes** de modificar seguridad o realizar restauraciones.

---

### A. Redis - Sesiones, carritos y rankings

*   **Modelo mínimo:** 3 sesiones `STRING` (`U01`-`U03`), 3 carritos `HASH` (`U01`-`U03`, al menos 2 productos cada uno), 2 conjuntos `SET` de favoritos y un ranking `SORTED SET` de 5 productos. Utilizar los IDs del dataset.

#### A1. CRUD y consultas obligatorias
1.  **Crear sesión:** `sesion:U01`, leerla, actualizarla, eliminarla y comprobar que ya no existe.
2.  **Crear carrito:** `carrito:U01` con dos productos, consultar todos sus campos, modificar una cantidad y quitar un producto.
3.  **Favoritos:** Agregar y quitar un favorito de `favoritos:U01`; demostrar membresía con `SISMEMBER`.
4.  **Ranking:** Consultar los tres productos de mayor puntaje del ranking (orden descendente).
5.  **TTL:** Crear `sesion:temporal` con TTL de 30 segundos; registrar TTL inicial y verificar su expiración.

#### A2. Seguridad y recuperación
1.  **ACL:** Crear una ACL de aplicación restringida a claves del laboratorio; demostrar un comando autorizado y otro denegado. No incluir contraseñas en capturas.
2.  **Respaldo:** Generar un respaldo RDB, identificar su ubicación y copiarlo de forma consistente.
3.  **Restauración:** Restaurar en una **instancia de prueba aislada** y comparar al menos tres claves y sus valores. No sobrescribir el servicio compartido.

---

### B. Cassandra - Historial de actividad

*   **Modelo mínimo:** Keyspace `omnimarket` y tabla `eventos_por_usuario` con:
    *   `usuario_id text`
    *   `fecha_evento timestamp`
    *   `evento_id uuid`
    *   `tipo_evento text`
    *   `producto_id text`
    *   **Primary Key:** `usuario_id` como clave de partición, y (`fecha_evento`, `evento_id`) como claves de clustering.
    *   Cargar los 15 eventos provistos.

#### B1. CRUD y consultas obligatorias
1.  Insertar un evento adicional para `U01` y recuperarlo.
2.  Actualizar su `tipo_evento`; comprobar el cambio con `SELECT`.
3.  Eliminar ese evento adicional y verificar que desapareció.
4.  Listar todos los eventos de `U02`, en orden cronológico descendente.
5.  Recuperar los últimos tres eventos de `U01` con `LIMIT 3`.
6.  Consultar los eventos de `U03` en un intervalo de fechas usando la clave de partición.
7.  Intentar filtrar por `tipo_evento` sin clave de partición; documentar el resultado y proponer otra tabla orientada a esa consulta. **No usar `ALLOW FILTERING` como solución final.**

#### B2. Seguridad y recuperación
1.  Con supervisión del JTP, habilitar autenticación/autorización si no están activadas; crear un rol de solo lectura y demostrar `SELECT` permitido e `INSERT` denegado.
2.  Generar un snapshot con `nodetool` y localizar sus archivos.
3.  Realizar restauración **guiada en entorno de prueba** mediante procedimiento de SSTables compatible con la versión; comparar recuentos y una muestra de registros.

---

### C. Neo4j - Relaciones comerciales

*   **Modelo mínimo:** 5 nodos `Cliente`, 8 `Producto`, 3 `Categoria`; 8 relaciones `PERTENECE_A`; al menos 12 `COMPRO` y 5 `SIGUE`. Reutilizar IDs y nombres del dataset; crear compras y seguimientos adicionales coherentes.

#### C1. CRUD y consultas Cypher
1.  Crear Cliente de prueba `U99`, consultarlo, modificar su nombre, crear una relación `COMPRO`, eliminar la relación y finalmente el nodo de prueba.
2.  Listar productos comprados por `U01`.
3.  Listar clientes que compraron `P102`.
4.  Listar productos de la categoría `Tecnologia`.
5.  Listar productos comprados por clientes a los que sigue `U01` (recorrido de dos relaciones).
6.  Recomendar a `U01` productos comprados por usuarios que sigue y que `U01` aún no compró; explicar cómo se evitan duplicados.

#### C2. Seguridad y recuperación
1.  Verificar autenticación y cambiar contraseña inicial de administrador. Explicar por qué no se exige RBAC granular en Community.
2.  Registrar cantidades de nodos y relaciones.
3.  Realizar dump/copia offline compatible con Community, cargar en entorno aislado y comprobar cantidades y una consulta Cypher.

---

### Entrega y Evaluación

#### Archivos y evidencias a entregar
*   **Informe PDF:** Versión/servicio, modelo, capturas legibles de cada operación, consultas con resultados, prueba de seguridad y prueba de restauración por motor.
*   **Scripts:** `redis-comandos.txt`, `cassandra.cql` y `neo4j.cypher`; incluir datos de carga, CRUD y consultas, sin credenciales.
*   **Matriz final:** Comparar Redis, Cassandra y Neo4j en modelo, consultas, seguridad, recuperación y dificultad operativa.
*   **Validación:** Una evidencia antes y otra después de cada restauración. No se acepta solo el archivo de backup.

#### Criterios de evaluación

| Criterio | Peso |
| :--- | :---: |
| **Instalación y control previo** | 10 % |
| **Modelado y carga** | 15 % |
| **CRUD** | 20 % |
| **Consultas distintivas** | 20 % |
| **Seguridad básica** | 15 % |
| **Backup y restauración verificada** | 15 % |
| **Evidencias y análisis** | 5 % |

> **Condición:** Se debe demostrar el funcionamiento de los tres motores. Las pruebas destructivas se realizan únicamente sobre datos y entornos de laboratorio.