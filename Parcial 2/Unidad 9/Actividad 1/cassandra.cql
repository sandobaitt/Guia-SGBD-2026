-- =====================================================================
-- U9 - Actividad 1 · Parte B: Cassandra (un nodo) - Historial de actividad
-- Escenario: tienda en línea (OmniMarket)
--
-- Formato: comentarios con "--"; las sentencias CQL terminan en ";".
-- Las líneas que empiezan con "-- [Terminal]" son comandos de la terminal (no CQL).
-- Ejecutar POR SECCIONES: la sección B2 necesita reiniciar el nodo a mitad de camino.
--   cqlsh -f cassandra.cql            (secciones 0 a B1, antes de habilitar seguridad)
-- Sin credenciales: <clave_admin> y <clave_lector> se reemplazan al ejecutar.
-- Las fechas llevan "+0000" para que no dependan de la zona horaria del cliente.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. VERIFICACIÓN DE SERVICIOS
-- ---------------------------------------------------------------------
-- [Terminal] cassandra -v
-- [Terminal] nodetool status
-- [Terminal] cqlsh


-- ---------------------------------------------------------------------
-- MODELO MÍNIMO Y CARGA
-- ---------------------------------------------------------------------
CREATE KEYSPACE IF NOT EXISTS omnimarket
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE omnimarket;

CREATE TABLE IF NOT EXISTS eventos_por_usuario (
  usuario_id   text,
  fecha_evento timestamp,
  evento_id    uuid,
  tipo_evento  text,
  producto_id  text,
  PRIMARY KEY ((usuario_id), fecha_evento, evento_id)
) WITH CLUSTERING ORDER BY (fecha_evento DESC, evento_id ASC);

-- Carga de los 15 eventos provistos (U9-Datos-Eventos.csv)
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01', '2026-10-20 10:00:00+0000', 00000000-0000-4000-8000-000000000001, 'VER_PRODUCTO', 'P101');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01', '2026-10-20 11:00:00+0000', 00000000-0000-4000-8000-000000000002, 'AGREGAR_CARRITO', 'P102');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01', '2026-10-20 12:00:00+0000', 00000000-0000-4000-8000-000000000003, 'QUITAR_CARRITO', 'P103');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01', '2026-10-20 13:00:00+0000', 00000000-0000-4000-8000-000000000004, 'INICIAR_COMPRA', 'P104');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01', '2026-10-20 14:00:00+0000', 00000000-0000-4000-8000-000000000005, 'FINALIZAR_COMPRA', 'P105');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U02', '2026-10-21 10:00:00+0000', 00000000-0000-4000-8000-000000000011, 'VER_PRODUCTO', 'P103');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U02', '2026-10-21 11:00:00+0000', 00000000-0000-4000-8000-000000000012, 'AGREGAR_CARRITO', 'P104');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U02', '2026-10-21 12:00:00+0000', 00000000-0000-4000-8000-000000000013, 'QUITAR_CARRITO', 'P105');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U02', '2026-10-21 13:00:00+0000', 00000000-0000-4000-8000-000000000014, 'INICIAR_COMPRA', 'P106');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U02', '2026-10-21 14:00:00+0000', 00000000-0000-4000-8000-000000000015, 'FINALIZAR_COMPRA', 'P107');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U03', '2026-10-22 10:00:00+0000', 00000000-0000-4000-8000-000000000021, 'VER_PRODUCTO', 'P105');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U03', '2026-10-22 11:00:00+0000', 00000000-0000-4000-8000-000000000022, 'AGREGAR_CARRITO', 'P106');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U03', '2026-10-22 12:00:00+0000', 00000000-0000-4000-8000-000000000023, 'QUITAR_CARRITO', 'P107');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U03', '2026-10-22 13:00:00+0000', 00000000-0000-4000-8000-000000000024, 'INICIAR_COMPRA', 'P108');
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U03', '2026-10-22 14:00:00+0000', 00000000-0000-4000-8000-000000000025, 'FINALIZAR_COMPRA', 'P101');

-- Verificación de la carga: 5 eventos por usuario (15 en total)
SELECT usuario_id, COUNT(*) FROM eventos_por_usuario GROUP BY usuario_id;


-- =====================================================================
-- B1. CRUD Y CONSULTAS OBLIGATORIAS
-- =====================================================================

-- B1.1 Insertar un evento adicional para U01 y recuperarlo
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id)
VALUES ('U01', '2026-10-20 15:00:00+0000', 00000000-0000-4000-8000-000000000006, 'VER_PRODUCTO', 'P106');

SELECT * FROM eventos_por_usuario WHERE usuario_id = 'U01';

-- B1.2 Actualizar su tipo_evento (el WHERE lleva toda la clave primaria) y comprobar
UPDATE omnimarket.eventos_por_usuario SET tipo_evento = 'AGREGAR_CARRITO'
WHERE usuario_id = 'U01'
  AND fecha_evento = '2026-10-20 15:00:00+0000'
  AND evento_id = 00000000-0000-4000-8000-000000000006;

SELECT usuario_id, fecha_evento, evento_id, tipo_evento, producto_id
FROM omnimarket.eventos_por_usuario
WHERE usuario_id = 'U01'
  AND fecha_evento = '2026-10-20 15:00:00+0000'
  AND evento_id = 00000000-0000-4000-8000-000000000006;

-- B1.3 Eliminar ese evento y verificar que desapareció
DELETE FROM omnimarket.eventos_por_usuario
WHERE usuario_id = 'U01'
  AND fecha_evento = '2026-10-20 15:00:00+0000'
  AND evento_id = 00000000-0000-4000-8000-000000000006;

SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01';

-- B1.4 Eventos de U02 en orden cronológico descendente
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U02' ORDER BY fecha_evento DESC;

-- B1.5 Los últimos tres eventos de U01 (la tabla ordena de más reciente a más antiguo)
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01' LIMIT 3;

-- B1.6 Eventos de U03 en un intervalo de fechas (usa la clave de partición)
SELECT * FROM omnimarket.eventos_por_usuario
WHERE usuario_id = 'U03'
  AND fecha_evento >= '2026-10-22 10:00:00+0000'
  AND fecha_evento <= '2026-10-22 13:00:00+0000';

-- B1.7 Filtrar por tipo_evento SIN clave de partición: Cassandra la rechaza
-- (InvalidRequest code=2200 ... use ALLOW FILTERING). No se usa ALLOW FILTERING.
SELECT * FROM omnimarket.eventos_por_usuario WHERE tipo_evento = 'VER_PRODUCTO';

-- Tabla alternativa orientada a esa consulta (clave de partición: tipo_evento)
CREATE TABLE IF NOT EXISTS omnimarket.eventos_por_tipo (
  tipo_evento  text,
  fecha_evento timestamp,
  evento_id    uuid,
  usuario_id   text,
  producto_id  text,
  PRIMARY KEY ((tipo_evento), fecha_evento, evento_id)
) WITH CLUSTERING ORDER BY (fecha_evento DESC);

-- [PENDIENTE DE EJECUTAR Y CAPTURAR] Carga de la tabla alternativa con los mismos 15 eventos.
-- Cassandra no copia datos entre tablas: se escribe en ambas.
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('VER_PRODUCTO', '2026-10-20 10:00:00+0000', 00000000-0000-4000-8000-000000000001, 'U01', 'P101');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('AGREGAR_CARRITO', '2026-10-20 11:00:00+0000', 00000000-0000-4000-8000-000000000002, 'U01', 'P102');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('QUITAR_CARRITO', '2026-10-20 12:00:00+0000', 00000000-0000-4000-8000-000000000003, 'U01', 'P103');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('INICIAR_COMPRA', '2026-10-20 13:00:00+0000', 00000000-0000-4000-8000-000000000004, 'U01', 'P104');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('FINALIZAR_COMPRA', '2026-10-20 14:00:00+0000', 00000000-0000-4000-8000-000000000005, 'U01', 'P105');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('VER_PRODUCTO', '2026-10-21 10:00:00+0000', 00000000-0000-4000-8000-000000000011, 'U02', 'P103');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('AGREGAR_CARRITO', '2026-10-21 11:00:00+0000', 00000000-0000-4000-8000-000000000012, 'U02', 'P104');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('QUITAR_CARRITO', '2026-10-21 12:00:00+0000', 00000000-0000-4000-8000-000000000013, 'U02', 'P105');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('INICIAR_COMPRA', '2026-10-21 13:00:00+0000', 00000000-0000-4000-8000-000000000014, 'U02', 'P106');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('FINALIZAR_COMPRA', '2026-10-21 14:00:00+0000', 00000000-0000-4000-8000-000000000015, 'U02', 'P107');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('VER_PRODUCTO', '2026-10-22 10:00:00+0000', 00000000-0000-4000-8000-000000000021, 'U03', 'P105');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('AGREGAR_CARRITO', '2026-10-22 11:00:00+0000', 00000000-0000-4000-8000-000000000022, 'U03', 'P106');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('QUITAR_CARRITO', '2026-10-22 12:00:00+0000', 00000000-0000-4000-8000-000000000023, 'U03', 'P107');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('INICIAR_COMPRA', '2026-10-22 13:00:00+0000', 00000000-0000-4000-8000-000000000024, 'U03', 'P108');
INSERT INTO eventos_por_tipo (tipo_evento, fecha_evento, evento_id, usuario_id, producto_id) VALUES ('FINALIZAR_COMPRA', '2026-10-22 14:00:00+0000', 00000000-0000-4000-8000-000000000025, 'U03', 'P101');

SELECT * FROM omnimarket.eventos_por_tipo WHERE tipo_evento = 'VER_PRODUCTO';


-- =====================================================================
-- B2. SEGURIDAD Y RECUPERACIÓN
-- =====================================================================

-- ---- B2.1 Autenticación/autorización y rol de solo lectura (con supervisión del JTP) ----
-- Comprobar la configuración actual:
-- [Terminal] grep -E "^authenticator:|^authorizer:" /etc/cassandra/cassandra.yaml
--
-- Habilitar autenticación y autorización:
-- [Terminal] sudo sed -i 's/^authenticator: AllowAllAuthenticator/authenticator: PasswordAuthenticator/' /etc/cassandra/cassandra.yaml
-- [Terminal] sudo sed -i 's/^authorizer: AllowAllAuthorizer/authorizer: CassandraAuthorizer/' /etc/cassandra/cassandra.yaml
-- [Terminal] grep -E "^authenticator:|^authorizer:" /etc/cassandra/cassandra.yaml
--
-- Reiniciar el nodo para que tome la nueva política:
-- [Terminal] sudo systemctl restart cassandra
--
-- Sin credenciales ya no se puede entrar (AuthenticationFailed):
-- [Terminal] cqlsh
-- Conectar con el usuario predeterminado:
-- [Terminal] cqlsh -u cassandra -p <clave_admin>

-- Rol de solo lectura (ejecutar como cassandra):
CREATE ROLE IF NOT EXISTS lector WITH PASSWORD = '<clave_lector>' AND LOGIN = true;
GRANT SELECT ON KEYSPACE omnimarket TO lector;

-- Ingresar con el rol creado:
-- [Terminal] cqlsh -u lector -p <clave_lector>
-- Comprobación de permisos (ejecutar como lector): SELECT permitido, INSERT denegado
SELECT usuario_id, tipo_evento FROM omnimarket.eventos_por_usuario LIMIT 3;
INSERT INTO omnimarket.eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id)
VALUES ('U01', toTimestamp(now()), uuid(), 'VER_PRODUCTO', 'P101');
-- Resultado esperado del INSERT: Unauthorized ... User lector has no MODIFY permission ...

-- ---- B2.2 Snapshot con nodetool y ubicación de sus archivos ----
-- [Terminal] nodetool snapshot -t backup_b2 omnimarket
-- [Terminal] sudo find /var/lib/cassandra/data/omnimarket/ -type d -name "backup_b2"
-- [Terminal] nodetool listsnapshots
-- [Terminal] sudo sh -c 'ls -lh /var/lib/cassandra/data/omnimarket/eventos_por_usuario-*/snapshots/backup_b2/'

-- ---- B2.3 Restauración guiada con SSTables (evidencia antes y después) ----
-- Ingresar como cassandra: cqlsh -u cassandra -p <clave_admin>
-- ANTES de perder los datos (evidencia de referencia):
SELECT COUNT(*) FROM omnimarket.eventos_por_usuario;
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01' LIMIT 3;

-- Simular la pérdida de datos:
TRUNCATE omnimarket.eventos_por_usuario;
SELECT COUNT(*) FROM omnimarket.eventos_por_usuario;

-- Copiar las SSTables del snapshot al directorio activo de la tabla (y ajustar el dueño):
-- [Terminal] sudo sh -c 'cp /var/lib/cassandra/data/omnimarket/eventos_por_usuario-*/snapshots/backup_b2/*-*.db /var/lib/cassandra/data/omnimarket/eventos_por_usuario-*/'
-- [Terminal] sudo chown -R cassandra:cassandra /var/lib/cassandra/data/omnimarket/
-- Que Cassandra reconozca los archivos sin reiniciar (en Cassandra 5.0 "refresh" está deprecado: nodetool import):
-- [Terminal] nodetool refresh omnimarket eventos_por_usuario

-- DESPUÉS de restaurar: mismos recuentos y la misma muestra
SELECT COUNT(*) FROM omnimarket.eventos_por_usuario;
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01' LIMIT 3;
