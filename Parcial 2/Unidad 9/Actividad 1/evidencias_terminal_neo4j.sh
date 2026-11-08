#!/usr/bin/env bash
# =====================================================================
# U9 - Actividad 1 · Parte C (Neo4j Community) — SESIÓN GUIADA PARA CAPTURAS
#
# Pensado para un equipo Ubuntu con Neo4j Community instalado de forma nativa.
# Cada paso muestra el comando (línea que empieza con "$"), lo ejecuta y espera
# un Enter: ese es el momento de sacar la captura de la terminal.
#
#   cd <carpeta con neo4j.cypher y los CSV>
#   ./evidencias_terminal_neo4j.sh
#
# - La contraseña NUEVA se pide con read -s (no se ve en pantalla ni queda en el historial).
#   Si ya la cambiaron antes, se pide la actual. También se puede dar por variable:
#   NEO4J_PASSWORD='...' ./evidencias_terminal_neo4j.sh  (solo para pruebas).
# - Ningún comando mostrado lleva credenciales (cypher-shell lee NEO4J_USERNAME/NEO4J_PASSWORD).
# - SIN_PAUSA=1 desactiva las pausas. Pasos: PASO_DESDE=5 ./evidencias_terminal_neo4j.sh
# Requiere sudo. Solo toca datos de laboratorio (base neo4j y una instancia aislada).
# =====================================================================
set -uo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO=/var/backups/neo4j-u9
LAB="${LAB:-$HOME/u9_neo4j_aislada}"
FORMATO="${FORMATO:-}"                       # solo para pruebas sin terminal
PASO_DESDE="${PASO_DESDE:-1}"
case "$LAB" in ""|"/"|"/var/lib/neo4j"*|"/etc"*|"/usr"*|"$HOME") echo "LAB peligroso: $LAB"; exit 2;; esac
sudo() { command sudo ${SUDO_ASKPASS:+-A} "$@"; }
esperar_puerto() { for _ in $(seq 1 40); do [ -n "$(ss -ltn | grep ":$1 ")" ] && return 0; sleep 2; done; return 1; }

# La clave se valida contra el servicio ANTES de usarla: una clave incorrecta rompe en silencio
# la comparación origen/copia (archivos vacíos) y la instancia aislada del paso 17.
clave_ok() { NEO4J_USERNAME=neo4j NEO4J_PASSWORD="$1" cypher-shell -a bolt://localhost:7687 --non-interactive "RETURN 1" >/dev/null 2>&1; }
asegurar_clave_actual() {   # pide/valida la contraseña actual de neo4j (hasta 3 intentos)
  if [ "$(systemctl is-active neo4j)" != active ]; then sudo systemctl start neo4j; esperar_puerto 7687; sleep 5; fi
  for intento in 1 2 3; do
    if [ -z "$NUEVA_CLAVE" ]; then read -rsp "Contraseña ACTUAL de neo4j: " NUEVA_CLAVE; echo; fi
    if clave_ok "$NUEVA_CLAVE"; then return 0; fi
    echo "Esa contraseña NO es válida para Neo4j (intento $intento de 3)."; NUEVA_CLAVE=""
  done
  echo "No se pudo validar la contraseña. Si no la recordás, ver la guía (sección 5)."; exit 1
}

NUEVA_CLAVE="${NEO4J_PASSWORD:-}"; unset NEO4J_PASSWORD NEO4J_USERNAME NEO4J_ADDRESS NEO4J_CONF

if [ "$PASO_DESDE" -gt 3 ]; then   # se saltea el cambio de clave: pedir la actual
  asegurar_clave_actual
  export NEO4J_USERNAME=neo4j NEO4J_PASSWORD="$NUEVA_CLAVE" NEO4J_ADDRESS=bolt://localhost:7687
fi

N=0
paso()  { N=$((N+1)); printf '\n\033[1;36m=================== PASO %s · %s\033[0m\n' "$N" "$*"; }
va()    { [ "$N" -ge "$PASO_DESDE" ]; }
pausa() { va && [ "${SIN_PAUSA:-0}" != 1 ] && read -rp $'\n--- [Enter] para continuar (captura ahora) ---' _; return 0; }
cmd()   { va || return 0; printf '\n\033[1;32m$\033[0m %s\n' "$*"; eval "$*"; }       # muestra y ejecuta
Q()     { va || return 0; printf '\n\033[1;32m$\033[0m cypher-shell "%s"\n' "$1"; cypher-shell $FORMATO "$1"; }
QI()    { va || return 0; printf '\n\033[1;32m$\033[0m cypher-shell -a bolt://localhost:7688 "%s"\n' "$1"; cypher-shell -a bolt://localhost:7688 $FORMATO "$1"; }

# ------------------------------------------------------------------ 1
paso "C0 · Verificación del servicio (ANTES de tocar seguridad)"
if va; then
  [ "$(systemctl is-active neo4j)" = active ] || { sudo systemctl start neo4j; esperar_puerto 7687; sleep 3; }
fi
cmd "systemctl status neo4j --no-pager | head -5"
cmd "neo4j --version && cypher-shell --version"
cmd "ss -ltn | grep -E ':(7474|7687) '"
pausa

# ------------------------------------------------------------------ 2
paso "C2.1 · Autenticación: sin credenciales y con la clave inicial"
cmd "cypher-shell -a bolt://localhost:7687 --non-interactive \"RETURN 1\""
cmd "cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive \"RETURN 1\""
pausa

# ------------------------------------------------------------------ 3
paso "C2.1 · Cambio de la contraseña inicial (la clave NO se muestra)"
if va; then
  RESP="$(cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive "RETURN 1" 2>&1 | head -1)"
  if [[ "$RESP" == *"credentials expired"* ]]; then
    while [ "${#NUEVA_CLAVE}" -lt 8 ]; do read -rsp "Elegí la NUEVA contraseña (mín. 8 caracteres): " NUEVA_CLAVE; echo; done
    printf '\n\033[1;32m$\033[0m cypher-shell -u neo4j -p neo4j --non-interactive -d system "ALTER CURRENT USER SET PASSWORD FROM '"'neo4j'"' TO '"'<nueva_clave>'"'"\n'
    cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive -d system "ALTER CURRENT USER SET PASSWORD FROM 'neo4j' TO '$NUEVA_CLAVE'" \
      && echo "(contraseña cambiada)"
  else
    echo "La clave inicial ya no está vigente: se cambió en una corrida anterior."
    asegurar_clave_actual
  fi
  export NEO4J_USERNAME=neo4j NEO4J_PASSWORD="$NUEVA_CLAVE" NEO4J_ADDRESS=bolt://localhost:7687
fi
cmd "cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive \"RETURN 1\""
pausa

# ------------------------------------------------------------------ 4
paso "C2.1 · Edición, usuario actual y límites de Community (¿por qué no hay RBAC granular?)"
Q "CALL dbms.components() YIELD name, versions, edition RETURN name, versions, edition"
Q "SHOW CURRENT USER"
cmd "cypher-shell -d system $FORMATO \"SHOW ROLES\""
cmd "cypher-shell -d system $FORMATO \"GRANT ROLE reader TO neo4j\""
pausa

# ------------------------------------------------------------------ 5
paso "Carga de los datos provistos por la cátedra"
cmd "sudo cp '$AQUI/U9-Datos-Usuarios.csv' '$AQUI/U9-Datos-Productos.csv' /var/lib/neo4j/import/ && ls -l /var/lib/neo4j/import/"
Q "CREATE CONSTRAINT cliente_id IF NOT EXISTS FOR (c:Cliente) REQUIRE c.id IS UNIQUE"
Q "CREATE CONSTRAINT producto_id IF NOT EXISTS FOR (p:Producto) REQUIRE p.id IS UNIQUE"
Q "CREATE CONSTRAINT categoria_nombre IF NOT EXISTS FOR (k:Categoria) REQUIRE k.nombre IS UNIQUE"
Q "LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Usuarios.csv' AS f MERGE (c:Cliente {id: f.usuario_id}) SET c.nombre = f.nombre"
Q "LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Productos.csv' AS f MERGE (p:Producto {id: f.producto_id}) SET p.nombre = f.nombre, p.precio = toInteger(f.precio_ars) MERGE (k:Categoria {nombre: f.categoria}) MERGE (p)-[:PERTENECE_A]->(k)"
Q "UNWIND [['U01','P102'],['U01','P105'],['U02','P102'],['U02','P103'],['U02','P107'],['U03','P101'],['U03','P102'],['U03','P108'],['U04','P104'],['U04','P106'],['U05','P101'],['U05','P108']] AS par MATCH (c:Cliente {id: par[0]}), (p:Producto {id: par[1]}) MERGE (c)-[:COMPRO]->(p)"
Q "UNWIND [['U01','U02'],['U01','U03'],['U02','U03'],['U04','U01'],['U05','U04']] AS par MATCH (a:Cliente {id: par[0]}), (b:Cliente {id: par[1]}) MERGE (a)-[:SIGUE]->(b)"
pausa
paso "Verificación de la carga (mínimos: 5/8/3 nodos, 8 PERTENECE_A, ≥12 COMPRO, ≥5 SIGUE)"
Q "MATCH (n) RETURN labels(n)[0] AS etiqueta, count(*) AS cantidad ORDER BY etiqueta"
Q "MATCH ()-[r]->() RETURN type(r) AS relacion, count(*) AS cantidad ORDER BY relacion"
pausa

# ------------------------------------------------------------------ C1.1
paso "C1.1 · CRUD sobre el cliente de prueba U99 (crear, consultar, modificar)"
Q "CREATE (c:Cliente {id: 'U99', nombre: 'Usuario Prueba'}) RETURN c.id AS id, c.nombre AS nombre"
Q "MATCH (c:Cliente {id: 'U99'}) RETURN c.id AS id, c.nombre AS nombre"
Q "MATCH (c:Cliente {id: 'U99'}) SET c.nombre = 'Usuario Modificado' RETURN c.id AS id, c.nombre AS nombre"
pausa
paso "C1.1 · Relación COMPRO (crear y comprobar)"
Q "MATCH (c:Cliente {id: 'U99'}), (p:Producto {id: 'P101'}) CREATE (c)-[:COMPRO]->(p) RETURN c.id AS cliente, p.id AS producto"
Q "MATCH (c:Cliente {id: 'U99'})-[r:COMPRO]->(p) RETURN c.id AS cliente, type(r) AS rel, p.id AS producto"
pausa
paso "C1.1 · Eliminar la relación y el nodo (y verificar)"
Q "MATCH (c:Cliente {id: 'U99'}) DELETE c"
Q "MATCH (c:Cliente {id: 'U99'})-[r:COMPRO]->() DELETE r"
Q "MATCH (c:Cliente {id: 'U99'}) DELETE c"
Q "MATCH (c:Cliente {id: 'U99'}) RETURN count(c) AS u99_restantes"
pausa

# ------------------------------------------------------------------ C1.2-1.6
paso "C1.2 y C1.3 · Productos de U01 · Clientes que compraron P102"
Q "MATCH (c:Cliente {id: 'U01'})-[:COMPRO]->(p:Producto) RETURN p.id AS id, p.nombre AS producto, p.precio AS precio ORDER BY p.id"
Q "MATCH (c:Cliente)-[:COMPRO]->(p:Producto {id: 'P102'}) RETURN c.id AS id, c.nombre AS cliente ORDER BY c.id"
pausa
paso "C1.4 y C1.5 · Categoría Tecnologia · Compras de los seguidos de U01 (dos relaciones)"
Q "MATCH (p:Producto)-[:PERTENECE_A]->(k:Categoria {nombre: 'Tecnologia'}) RETURN p.id AS id, p.nombre AS producto, p.precio AS precio ORDER BY p.id"
Q "MATCH (:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto) RETURN s.nombre AS seguido, p.id AS id, p.nombre AS producto ORDER BY s.nombre, p.id"
pausa
paso "C1.6 · Recomendación para U01"
Q "MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto) WHERE NOT (u)-[:COMPRO]->(p) RETURN DISTINCT p.id AS id, p.nombre AS recomendado, p.precio AS precio ORDER BY p.id"
pausa
paso "C1.6 · Cómo se evitan los duplicados (seguimiento temporal U01 -> U05, se borra al final)"
Q "MATCH (a:Cliente {id: 'U01'}), (b:Cliente {id: 'U05'}) CREATE (a)-[:SIGUE {temporal: true}]->(b)"
Q "MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto) WHERE NOT (u)-[:COMPRO]->(p) RETURN p.id AS id, p.nombre AS recomendado ORDER BY p.id"
Q "MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto) WHERE NOT (u)-[:COMPRO]->(p) RETURN DISTINCT p.id AS id, p.nombre AS recomendado ORDER BY p.id"
Q "MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto) WHERE NOT (u)-[:COMPRO]->(p) RETURN p.id AS id, p.nombre AS recomendado, count(DISTINCT s) AS seguidos_que_lo_compraron ORDER BY seguidos_que_lo_compraron DESC, id"
Q "MATCH (:Cliente {id: 'U01'})-[r:SIGUE {temporal: true}]->(:Cliente {id: 'U05'}) DELETE r"
Q "MATCH ()-[r:SIGUE]->() RETURN count(r) AS sigue_restantes"
pausa

# ------------------------------------------------------------------ C2.2
paso "C2.2 · Cantidades de nodos y relaciones (estado ANTES del respaldo)"
Q "MATCH (n) RETURN count(n) AS cantidad_nodos"
Q "MATCH ()-[r]->() RETURN count(r) AS cantidad_relaciones"
pausa

# ------------------------------------------------------------------ C2.3
COMPARABLE_NODOS="MATCH (n) RETURN labels(n)[0] AS etiqueta, coalesce(n.id, n.nombre) AS clave, n.nombre AS nombre, n.precio AS precio ORDER BY etiqueta, clave"
COMPARABLE_RELS="MATCH (a)-[r]->(b) RETURN type(r) AS rel, coalesce(a.id, a.nombre) AS desde, coalesce(b.id, b.nombre) AS hasta ORDER BY rel, desde, hasta"
paso "C2.3 · Dump OFFLINE: con el servicio activo se rechaza"
if va; then
  mkdir -p "$LAB"
  { cypher-shell --format plain "$COMPARABLE_NODOS"; cypher-shell --format plain "$COMPARABLE_RELS"; } > "$LAB/origen_antes.txt"
  sudo mkdir -p "$RESPALDO"; sudo chown neo4j:neo4j "$RESPALDO"; sudo rm -f "$RESPALDO/neo4j.dump"
fi
cmd "sudo -u neo4j neo4j-admin database dump neo4j --to-path=$RESPALDO 2>&1 | head -3"
pausa
paso "C2.3 · Dump con el servicio detenido"
cmd "sudo systemctl stop neo4j && systemctl is-active neo4j"
cmd "sudo -u neo4j neo4j-admin database dump neo4j --to-path=$RESPALDO 2>&1 | tail -3"
cmd "ls -l $RESPALDO && sha256sum $RESPALDO/neo4j.dump"
cmd "sudo systemctl start neo4j"
va && { esperar_puerto 7687; sleep 3; }
pausa

paso "C2.3 · Entorno aislado: configuración propia (otro directorio y puertos 7688/7475)"
if va; then
  [ -d "$LAB/conf" ] && NEO4J_CONF="$LAB/conf" neo4j stop >/dev/null 2>&1
  rm -rf "$LAB/iso" "$LAB/conf"; mkdir -p "$LAB/iso"/{data,logs,run,tx,import,plugins} "$LAB/conf"
  cat > "$LAB/conf/neo4j.conf" <<EOF
server.directories.data=$LAB/iso/data
server.directories.logs=$LAB/iso/logs
server.directories.run=$LAB/iso/run
server.directories.transaction.logs.root=$LAB/iso/tx
server.directories.import=$LAB/iso/import
server.directories.plugins=$LAB/iso/plugins
server.directories.lib=/usr/share/neo4j/lib
server.bolt.listen_address=127.0.0.1:7688
server.http.listen_address=127.0.0.1:7475
server.https.enabled=false
server.memory.heap.initial_size=256m
server.memory.heap.max_size=512m
server.memory.pagecache.size=128m
EOF
fi
cmd "cat $LAB/conf/neo4j.conf"
cmd "export NEO4J_CONF=$LAB/conf"
if va; then
  SALIDA="$(neo4j-admin dbms set-initial-password "$NUEVA_CLAVE" 2>&1)" || { echo "ERROR al fijar la clave de la instancia aislada: $SALIDA"; exit 1; }
fi
cmd "neo4j start"
va && { esperar_puerto 7688; sleep 4; }
cmd "ss -ltn | grep -E ':(7474|7475|7687|7688) '"
pausa

paso "C2.3 · ANTES de restaurar: la instancia aislada está vacía"
QI "MATCH (n) RETURN count(n) AS nodos"
QI "MATCH ()-[r]->() RETURN count(r) AS relaciones"
pausa

paso "C2.3 · Carga del dump en la instancia aislada"
cmd "neo4j stop"
va && sleep 4
cmd "neo4j-admin database load neo4j --from-path=$RESPALDO --overwrite-destination=true 2>&1 | tail -3"
cmd "neo4j start"
va && { esperar_puerto 7688; sleep 5; }
pausa

paso "C2.3 · DESPUÉS de restaurar: cantidades y una consulta Cypher en la copia"
QI "MATCH (n) RETURN count(n) AS nodos"
QI "MATCH ()-[r]->() RETURN count(r) AS relaciones"
QI "MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto) WHERE NOT (u)-[:COMPRO]->(p) RETURN DISTINCT p.id AS id, p.nombre AS recomendado ORDER BY id"
pausa

paso "C2.3 · Comparación completa origen vs. copia restaurada"
if va; then
  { cypher-shell -a bolt://localhost:7688 --format plain "$COMPARABLE_NODOS"; cypher-shell -a bolt://localhost:7688 --format plain "$COMPARABLE_RELS"; } > "$LAB/copia_despues.txt"
fi
cmd "wc -l $LAB/origen_antes.txt $LAB/copia_despues.txt"
cmd "diff $LAB/origen_antes.txt $LAB/copia_despues.txt && echo 'SIN DIFERENCIAS: la copia es idéntica al origen'"
cmd "cypher-shell -a bolt://localhost:7687 \"MATCH (n) RETURN count(n) AS nodos_servicio_compartido\""
pausa

# ------------------------------------------------------------------ cierre
if va; then
  neo4j stop >/dev/null 2>&1; unset NEO4J_CONF
  printf '\n\033[1;36m=== FIN. Instancia aislada detenida. El servicio neo4j sigue activo (detenerlo: sudo systemctl stop neo4j).\033[0m\n'
fi
