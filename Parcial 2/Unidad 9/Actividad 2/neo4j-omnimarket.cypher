// =====================================================================
// U9 - Actividad 2 · OmniMarket · Componente Neo4j Community
// Dominio que resuelve: recomendaciones (relaciones entre clientes,
// productos, categorías y afinidades). Neo4j NO es fuente de verdad: es una
// proyección de las compras y vistas que viven en el sistema transaccional.
//
// Formato: sentencias Cypher que terminan en ";" (una por bloque); los
// comentarios empiezan con "//". Las líneas "//@ ..." separan pasos (para la
// sesión guiada de capturas). Sin credenciales en este archivo.
//   cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f neo4j-omnimarket.cypher
// Datos coherentes con el escenario: IDs U01-U05 y P101-P108 de la cátedra.
// =====================================================================


//@ Verificación del servicio y de la edición
CALL dbms.components() YIELD name, versions, edition RETURN name, versions, edition;


//@ Modelo: restricciones (identidad única y compras sin duplicar)
CREATE CONSTRAINT cliente_id IF NOT EXISTS FOR (c:Cliente) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT producto_id IF NOT EXISTS FOR (p:Producto) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT categoria_nombre IF NOT EXISTS FOR (k:Categoria) REQUIRE k.nombre IS UNIQUE;
CREATE CONSTRAINT compro_linea IF NOT EXISTS FOR ()-[r:COMPRO]-() REQUIRE r.linea_id IS UNIQUE;


//@ Carga: clientes y catálogo (IDs del dataset); version permite descartar eventos viejos
UNWIND [{id:'U01',nombre:'Ana'},{id:'U02',nombre:'Bruno'},{id:'U03',nombre:'Carla'},{id:'U04',nombre:'Diego'},{id:'U05',nombre:'Elena'}] AS f
MERGE (c:Cliente {id: f.id}) SET c.nombre = f.nombre;

UNWIND [{id:'P101',nombre:'Notebook',precio:1200000,cat:'Tecnologia'},{id:'P102',nombre:'Mouse',precio:18000,cat:'Tecnologia'},
        {id:'P103',nombre:'Teclado',precio:35000,cat:'Tecnologia'},{id:'P104',nombre:'Monitor',precio:320000,cat:'Tecnologia'},
        {id:'P105',nombre:'Campera',precio:95000,cat:'Indumentaria'},{id:'P106',nombre:'Zapatillas',precio:110000,cat:'Indumentaria'},
        {id:'P107',nombre:'Libro SQL',precio:28000,cat:'Libros'},{id:'P108',nombre:'Libro NoSQL',precio:31000,cat:'Libros'}] AS f
MERGE (p:Producto {id: f.id}) SET p.nombre = f.nombre, p.precio = f.precio, p.version = 1
MERGE (k:Categoria {nombre: f.cat})
MERGE (p)-[:PERTENECE_A]->(k);


//@ Carga: compras históricas, seguimientos y productos vistos
UNWIND [['U01','P102'],['U01','P105'],['U02','P102'],['U02','P103'],['U02','P107'],['U03','P101'],['U03','P102'],['U03','P103'],['U03','P108'],
        ['U04','P104'],['U04','P106'],['U05','P101'],['U05','P108']] AS par
MATCH (c:Cliente {id: par[0]}), (p:Producto {id: par[1]})
MERGE (c)-[r:COMPRO {linea_id: 'HIST-' + par[0] + '-' + par[1]}]->(p)
  ON CREATE SET r.cantidad = 1;

UNWIND [['U01','U02'],['U01','U03'],['U02','U03'],['U04','U01'],['U05','U04']] AS par
MATCH (a:Cliente {id: par[0]}), (b:Cliente {id: par[1]})
MERGE (a)-[:SIGUE]->(b);

UNWIND [['U01','P101'],['U02','P103'],['U03','P105'],['U01','P102'],['U02','P104'],['U03','P106'],['U01','P103'],['U01','P107']] AS par
MATCH (c:Cliente {id: par[0]}), (p:Producto {id: par[1]})
MERGE (c)-[:VIO]->(p);


//@ Verificación de la carga
MATCH (n) RETURN labels(n)[0] AS etiqueta, count(*) AS cantidad ORDER BY etiqueta;
MATCH ()-[r]->() RETURN type(r) AS relacion, count(*) AS cantidad ORDER BY relacion;


//@ CRUD · Alta de un cliente nuevo y de una relación
CREATE (c:Cliente {id: 'U06', nombre: 'Fiorella'}) RETURN c.id AS id, c.nombre AS nombre;
MATCH (a:Cliente {id: 'U06'}), (b:Cliente {id: 'U01'}) CREATE (a)-[:SIGUE]->(b);
MATCH (c:Cliente {id: 'U06'}), (p:Producto {id: 'P102'})
CREATE (c)-[:COMPRO {linea_id: 'ALTA-U06-P102', cantidad: 1}]->(p);


//@ CRUD · Lectura
MATCH (c:Cliente {id: 'U06'}) OPTIONAL MATCH (c)-[r]->(x) RETURN c.nombre AS cliente, type(r) AS relacion, coalesce(x.id, x.nombre) AS destino ORDER BY relacion;


//@ CRUD · Modificación
MATCH (c:Cliente {id: 'U06'}) SET c.nombre = 'Fiorella Gómez' RETURN c.id AS id, c.nombre AS nombre;
MATCH (:Cliente {id: 'U06'})-[r:COMPRO]->(:Producto {id: 'P102'}) SET r.cantidad = 2 RETURN r.linea_id AS linea, r.cantidad AS cantidad;


//@ CRUD · Baja: primero la relación y luego el nodo con todo lo que le queda
MATCH (:Cliente {id: 'U06'})-[r:COMPRO]->() DELETE r;
MATCH (c:Cliente {id: 'U06'}) DETACH DELETE c;
MATCH (c:Cliente {id: 'U06'}) RETURN count(c) AS u06_restantes;


//@ Consulta de negocio 1 · Recomendar a U01 lo que compraron quienes compraron lo mismo (afinidad)
MATCH (u:Cliente {id: 'U01'})-[:COMPRO]->(:Producto)<-[:COMPRO]-(otro:Cliente)-[:COMPRO]->(rec:Producto)
WHERE otro <> u AND NOT (u)-[:COMPRO]->(rec)
RETURN rec.id AS id, rec.nombre AS recomendado, count(DISTINCT otro) AS afinidad
ORDER BY afinidad DESC, id;


//@ Consulta de negocio 2 · Productos que se compran junto con P102 (Mouse)
MATCH (:Producto {id: 'P102'})<-[:COMPRO]-(c:Cliente)-[:COMPRO]->(o:Producto)
WHERE o.id <> 'P102'
RETURN o.id AS id, o.nombre AS producto, count(DISTINCT c) AS clientes_en_comun
ORDER BY clientes_en_comun DESC, id;


//@ Consulta de negocio 3 · Segmento de remarketing: clientes que vieron un producto y no lo compraron
MATCH (c:Cliente)-[:VIO]->(p:Producto)
WHERE NOT (c)-[:COMPRO]->(p)
RETURN c.id AS cliente, collect(p.nombre) AS vio_y_no_compro
ORDER BY cliente;


//@ Actualizaciones concurrentes · el evento con versión nueva se aplica y el viejo se descarta
MATCH (p:Producto {id: 'P102'}) WHERE p.version < 2 SET p.precio = 19500, p.version = 2 RETURN p.id AS id, p.precio AS precio, p.version AS version;
MATCH (p:Producto {id: 'P102'}) WHERE p.version < 1 SET p.precio = 18000, p.version = 1 RETURN p.id AS id, p.precio AS precio, p.version AS version;
MATCH (p:Producto {id: 'P102'}) RETURN p.id AS id, p.precio AS precio, p.version AS version;


//@ Duplicación · aplicar dos veces el mismo pedido confirmado no duplica las compras
UNWIND [{sku:'P101',cant:1},{sku:'P102',cant:1}] AS l
MATCH (c:Cliente {id: 'U04'}), (p:Producto {id: l.sku})
MERGE (c)-[r:COMPRO {linea_id: 'PED-0001-' + l.sku}]->(p)
  ON CREATE SET r.pedido_id = 'PED-0001', r.cantidad = l.cant, r.fecha = datetime();
MATCH (:Cliente {id: 'U04'})-[r:COMPRO]->() RETURN count(r) AS compras_u04;
UNWIND [{sku:'P101',cant:1},{sku:'P102',cant:1}] AS l
MATCH (c:Cliente {id: 'U04'}), (p:Producto {id: l.sku})
MERGE (c)-[r:COMPRO {linea_id: 'PED-0001-' + l.sku}]->(p)
  ON CREATE SET r.pedido_id = 'PED-0001', r.cantidad = l.cant, r.fecha = datetime();
MATCH (:Cliente {id: 'U04'})-[r:COMPRO]->() RETURN count(r) AS compras_u04;


//@ Violación de la restricción: una línea de compra duplicada se rechaza
MATCH (c:Cliente {id: 'U02'}), (p:Producto {id: 'P104'}) CREATE (c)-[:COMPRO {linea_id: 'PED-0001-P101'}]->(p);
