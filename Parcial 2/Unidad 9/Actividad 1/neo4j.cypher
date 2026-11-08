// =====================================================================
// U9 - Actividad 1 · Parte C: Neo4j Community - Relaciones comerciales
// Escenario: tienda en línea (OmniMarket). Base: neo4j (la única de Community).
//
// Cómo ejecutarlo (sin credenciales en el archivo):
//   export NEO4J_PASSWORD='<la contraseña que definió el grupo>'
//   cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f neo4j.cypher
//
// Requisito previo: los CSV de la cátedra copiados al directorio de import
//   sudo cp U9-Datos-Usuarios.csv U9-Datos-Productos.csv /var/lib/neo4j/import/
//   (server.directories.import en /etc/neo4j/neo4j.conf; LOAD CSV solo lee de ahí)
//
// Convención: cada bloque lleva su identificador (C1.2, C2.2...) para
// poder pegar la evidencia correspondiente en el informe.
// =====================================================================


// ---------------------------------------------------------------------
// 0. VERIFICACIÓN DEL SERVICIO (versión y edición)
// ---------------------------------------------------------------------
CALL dbms.components() YIELD name, versions, edition RETURN name, versions, edition;


// ---------------------------------------------------------------------
// 1. MODELO: restricciones de unicidad (también crean el índice por id)
// ---------------------------------------------------------------------
CREATE CONSTRAINT cliente_id IF NOT EXISTS
  FOR (c:Cliente) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT producto_id IF NOT EXISTS
  FOR (p:Producto) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT categoria_nombre IF NOT EXISTS
  FOR (k:Categoria) REQUIRE k.nombre IS UNIQUE;


// ---------------------------------------------------------------------
// 2. CARGA de los datos provistos (MERGE: se puede re-ejecutar sin duplicar)
// ---------------------------------------------------------------------
// 5 Cliente (usuarios)
LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Usuarios.csv' AS f
MERGE (c:Cliente {id: f.usuario_id})
  SET c.nombre = f.nombre;

// 8 Producto + 3 Categoria + 8 relaciones PERTENECE_A
LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Productos.csv' AS f
MERGE (p:Producto {id: f.producto_id})
  SET p.nombre = f.nombre, p.precio = toInteger(f.precio_ars)
MERGE (k:Categoria {nombre: f.categoria})
MERGE (p)-[:PERTENECE_A]->(k);

// Compras (>= 12). Las tres primeras de cada usuario provisto salen de los
// eventos FINALIZAR_COMPRA del dataset (U01->P105, U02->P107, U03->P101);
// el resto son compras adicionales coherentes.
UNWIND [
  ['U01','P102'], ['U01','P105'],
  ['U02','P102'], ['U02','P103'], ['U02','P107'],
  ['U03','P101'], ['U03','P102'], ['U03','P108'],
  ['U04','P104'], ['U04','P106'],
  ['U05','P101'], ['U05','P108']
] AS par
MATCH (c:Cliente {id: par[0]}), (p:Producto {id: par[1]})
MERGE (c)-[:COMPRO]->(p);

// Seguimientos (>= 5)
UNWIND [
  ['U01','U02'], ['U01','U03'],
  ['U02','U03'],
  ['U04','U01'],
  ['U05','U04']
] AS par
MATCH (a:Cliente {id: par[0]}), (b:Cliente {id: par[1]})
MERGE (a)-[:SIGUE]->(b);


// ---------------------------------------------------------------------
// 3. VERIFICACIÓN DE LA CARGA (mínimos exigidos: 5/8/3, 8, >=12, >=5)
// ---------------------------------------------------------------------
MATCH (n) RETURN labels(n)[0] AS etiqueta, count(*) AS cantidad ORDER BY etiqueta;
MATCH ()-[r]->() RETURN type(r) AS relacion, count(*) AS cantidad ORDER BY relacion;


// =====================================================================
// C1. CRUD Y CONSULTAS CYPHER
// =====================================================================

// ---- C1.1 CRUD sobre el cliente de prueba U99 ----
// Crear
CREATE (c:Cliente {id: 'U99', nombre: 'Usuario Prueba'}) RETURN c.id AS id, c.nombre AS nombre;
// Consultar
MATCH (c:Cliente {id: 'U99'}) RETURN c.id AS id, c.nombre AS nombre;
// Modificar el nombre
MATCH (c:Cliente {id: 'U99'}) SET c.nombre = 'Usuario Modificado' RETURN c.id AS id, c.nombre AS nombre;
// Crear la relación COMPRO (U99 -> P101)
MATCH (c:Cliente {id: 'U99'}), (p:Producto {id: 'P101'})
CREATE (c)-[:COMPRO]->(p)
RETURN c.id AS cliente, p.id AS producto;
// Comprobar la relación
MATCH (c:Cliente {id: 'U99'})-[r:COMPRO]->(p) RETURN c.id AS cliente, type(r) AS rel, p.id AS producto;
// Borrar un nodo con relaciones falla (DELETE sin DETACH) -> primero se borra la relación
MATCH (c:Cliente {id: 'U99'})-[r:COMPRO]->() DELETE r;
// Borrar el nodo de prueba
MATCH (c:Cliente {id: 'U99'}) DELETE c;
// Verificar que ya no existe (debe devolver 0)
MATCH (c:Cliente {id: 'U99'}) RETURN count(c) AS u99_restantes;

// ---- C1.2 Productos comprados por U01 ----
MATCH (c:Cliente {id: 'U01'})-[:COMPRO]->(p:Producto)
RETURN p.id AS id, p.nombre AS producto, p.precio AS precio
ORDER BY p.id;

// ---- C1.3 Clientes que compraron P102 ----
MATCH (c:Cliente)-[:COMPRO]->(p:Producto {id: 'P102'})
RETURN c.id AS id, c.nombre AS cliente
ORDER BY c.id;

// ---- C1.4 Productos de la categoría Tecnologia ----
MATCH (p:Producto)-[:PERTENECE_A]->(k:Categoria {nombre: 'Tecnologia'})
RETURN p.id AS id, p.nombre AS producto, p.precio AS precio
ORDER BY p.id;

// ---- C1.5 Productos comprados por quienes sigue U01 (dos relaciones) ----
MATCH (:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto)
RETURN s.nombre AS seguido, p.id AS id, p.nombre AS producto
ORDER BY s.nombre, p.id;

// ---- C1.6 Recomendación: lo que compran los seguidos y U01 aún no compró ----
// WHERE NOT (u)-[:COMPRO]->(p) excluye lo que U01 ya compró.
// DISTINCT evita repetir un producto cuando varios seguidos lo compraron:
// el patrón devuelve una fila por CAMINO (U01 -> seguido -> producto), no por producto.
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN DISTINCT p.id AS id, p.nombre AS recomendado, p.precio AS precio
ORDER BY p.id;

// ---- Demostración del duplicado (con datos reales, sin alterar el modelo base) ----
// Con los datos base ningún producto recomendable lo compraron dos seguidos, así que
// con y sin DISTINCT el resultado coincide. Para PROBAR el efecto se agrega un
// seguimiento temporal U01 -> U05 (U05 compró P101 y P108, igual que U03) y se quita al final.
MATCH (a:Cliente {id: 'U01'}), (b:Cliente {id: 'U05'})
CREATE (a)-[:SIGUE {temporal: true}]->(b);

// SIN DISTINCT: P101 y P108 aparecen dos veces (una por cada seguido que los compró)
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN p.id AS id, p.nombre AS recomendado
ORDER BY p.id;

// CON DISTINCT: una fila por producto
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN DISTINCT p.id AS id, p.nombre AS recomendado
ORDER BY p.id;

// Variante: agrupar y contar cuántos seguidos lo compraron (permite ordenar por relevancia)
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN p.id AS id, p.nombre AS recomendado, count(DISTINCT s) AS seguidos_que_lo_compraron
ORDER BY seguidos_que_lo_compraron DESC, id;

// Limpieza: se quita el seguimiento temporal y se comprueba que quedan 5 SIGUE
MATCH (:Cliente {id: 'U01'})-[r:SIGUE {temporal: true}]->(:Cliente {id: 'U05'}) DELETE r;
MATCH ()-[r:SIGUE]->() RETURN count(r) AS sigue_restantes;


// =====================================================================
// C2. SEGURIDAD Y RECUPERACIÓN
// =====================================================================

// ---- C2.1 Autenticación y cambio de la contraseña inicial ----
// Se hace UNA sola vez, en la primera conexión (la contraseña inicial
// neo4j/neo4j caduca). NO se deja la clave en este archivo; se ejecuta a mano:
//   cypher-shell -u neo4j -p neo4j -d system \
//     "ALTER CURRENT USER SET PASSWORD FROM 'neo4j' TO '<nueva_clave>'"
// Comprobaciones posteriores (con la nueva clave):
SHOW CURRENT USER;
//   Community tiene autenticación nativa pero NO roles ni privilegios:
//   SHOW ROLES / GRANT ROLE / DENY ... devuelven "not supported in community edition".

// ---- C2.2 Cantidades de nodos y relaciones ----
MATCH (n) RETURN count(n) AS cantidad_nodos;
MATCH ()-[r]->() RETURN count(r) AS cantidad_relaciones;

// ---- C2.3 Dump / carga offline ----
// Se hace por consola con el servicio detenido (ver solucion_u9_neo4j.sh):
//   sudo systemctl stop neo4j
//   sudo -u neo4j neo4j-admin database dump neo4j --to-path=/ruta/respaldo
//   (en el entorno aislado)  neo4j-admin database load neo4j --from-path=/ruta/respaldo
// Comprobación en el entorno aislado: repetir las dos consultas de C2.2
// y una consulta de negocio, por ejemplo la recomendación de C1.6.
