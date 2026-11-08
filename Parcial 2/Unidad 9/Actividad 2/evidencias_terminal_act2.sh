#!/usr/bin/env bash
# =====================================================================
# U9 - Actividad 2 · OmniMarket — SESIÓN GUIADA PARA CAPTURAS (Redis + Neo4j)
#
# Levanta un Redis y un Neo4j Community AISLADOS (otros puertos y carpetas, no
# tocan los servicios de la Actividad 1), ejecuta paso a paso los scripts
#   redis-omnimarket.txt   y   neo4j-omnimarket.cypher
# y luego la INTEGRACIÓN entre ambos motores y el experimento de CONCURRENCIA.
# Cada paso muestra el comando, lo ejecuta y espera un Enter: ahí se saca la captura.
#
#   cd <carpeta de la Actividad 2>
#   ./evidencias_terminal_act2.sh
#
# - No requiere sudo. La clave de Neo4j (mín. 8 caracteres) se pide con read -s.
# - PASO_DESDE=12 ./evidencias_terminal_act2.sh  retoma desde un paso (si las instancias siguen activas;
#   si se detuvieron, Redis pierde sus datos: usar REINICIAR=1).
# - SIN_PAUSA=1 desactiva las pausas.   REINICIAR=1 borra el laboratorio y empieza de cero.
# - Puertos: Redis 6381 · Neo4j Bolt 7690 / HTTP 7477.  Carpeta: ~/u9_act2
# =====================================================================
set -uo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="${LAB:-$HOME/u9_act2}"
RP=6381; BP=7690; HP=7477
ADDR="bolt://localhost:$BP"
FORMATO="${FORMATO:-}"                      # solo para pruebas sin terminal
PASO_DESDE="${PASO_DESDE:-1}"
case "$LAB" in ""|"/"|"/var/lib/neo4j"*|"/etc"*|"/usr"*|"$HOME") echo "LAB peligroso: $LAB"; exit 2;; esac

NUEVA_CLAVE="${NEO4J_PASSWORD:-}"; unset NEO4J_PASSWORD NEO4J_USERNAME NEO4J_ADDRESS NEO4J_CONF

N=0
paso()  { N=$((N+1)); printf '\n\033[1;36m=================== PASO %s · %s\033[0m\n' "$N" "$*"; }
va()    { [ "$N" -ge "$PASO_DESDE" ]; }
pausa() { va && [ "${SIN_PAUSA:-0}" != 1 ] && read -rp $'\n--- [Enter] para continuar (captura ahora) ---' _; return 0; }
cmd()   { va || return 0; printf '\n\033[1;32m$\033[0m %s\n' "$*"; eval "$*"; }
RC()    { va || return 0; printf '\n\033[1;32m127.0.0.1:%s>\033[0m %s\n' "$RP" "$1"; printf '%s\n' "$1" | redis-cli -p "$RP" --no-raw; }
QN()    { va || return 0; printf '\n\033[1;32m$\033[0m cypher-shell "%s"\n' "$1"; cypher-shell $FORMATO "$1"; }
esperar_puerto() { for _ in $(seq 1 40); do [ -n "$(ss -ltn | grep ":$1 ")" ] && return 0; sleep 2; done; return 1; }
clave_ok() { NEO4J_USERNAME=neo4j NEO4J_PASSWORD="$1" cypher-shell -a "$ADDR" --non-interactive "RETURN 1" >/dev/null 2>&1; }

# ------------------------------------------------------------------ ejecutores de los scripts entregables
ejecutar_redis_txt() {   # un paso por cada línea "#@ ..."; "#! sleep N" espera
  local linea abierto=0
  while IFS= read -r linea || [ -n "$linea" ]; do
    case "$linea" in
      "#@ "*)  [ $abierto = 1 ] && pausa; paso "Redis · ${linea#\#@ }"; abierto=1 ;;
      "#! sleep "*) va && { printf '\n(esperando %s segundos...)\n' "${linea#\#! sleep }"; sleep "${linea#\#! sleep }"; } ;;
      "#"*|"") ;;
      *) RC "$linea" ;;
    esac
  done < "$AQUI/redis-omnimarket.txt"
  [ $abierto = 1 ] && pausa
}
ejecutar_cypher() {      # un paso por cada línea "//@ ..."; las sentencias terminan en ";"
  local linea stmt="" abierto=0 t
  while IFS= read -r linea || [ -n "$linea" ]; do
    t="${linea%"${linea##*[![:space:]]}"}"
    case "$t" in
      "//@ "*) [ $abierto = 1 ] && pausa; paso "Neo4j · ${t#//@ }"; abierto=1 ;;
      "//"*|"") [ -z "$stmt" ] || true ;;
      *) stmt="${stmt:+$stmt$'\n'}$t"
         if [[ "$t" == *";" ]]; then QN "$stmt"; stmt=""; fi ;;
    esac
  done < "$AQUI/neo4j-omnimarket.cypher"
  [ $abierto = 1 ] && pausa
}

# ------------------------------------------------------------------ PASO 1 · entorno aislado
paso "Entorno aislado de la Actividad 2 (Redis y Neo4j, otros puertos y carpetas)"
REDIS_NUEVO=0
if true; then                          # siempre se asegura el entorno, aunque se retome desde un paso intermedio
  [ "${REINICIAR:-0}" = 1 ] && { redis-cli -p $RP shutdown nosave >/dev/null 2>&1; NEO4J_CONF="$LAB/neo4j/conf" neo4j stop >/dev/null 2>&1; sleep 3; rm -rf "$LAB"; }
  mkdir -p "$LAB/redis" "$LAB/neo4j"/{data,logs,run,tx,import,plugins,conf}
  # --- Redis
  redis-cli -p $RP ping >/dev/null 2>&1 || REDIS_NUEVO=1
  [ $REDIS_NUEVO = 1 ] && redis-server --port $RP --bind 127.0.0.1 --dir "$LAB/redis" --save "" --daemonize yes \
      --logfile "$LAB/redis/redis.log" --pidfile "$LAB/redis/redis.pid" >/dev/null
  # --- Neo4j (instancia propia: carpeta de datos y puertos distintos a los del servicio)
  cat > "$LAB/neo4j/conf/neo4j.conf" <<EOF
server.directories.data=$LAB/neo4j/data
server.directories.logs=$LAB/neo4j/logs
server.directories.run=$LAB/neo4j/run
server.directories.transaction.logs.root=$LAB/neo4j/tx
server.directories.import=$LAB/neo4j/import
server.directories.plugins=$LAB/neo4j/plugins
server.directories.lib=/usr/share/neo4j/lib
server.bolt.listen_address=127.0.0.1:$BP
server.http.listen_address=127.0.0.1:$HP
server.https.enabled=false
server.memory.heap.initial_size=256m
server.memory.heap.max_size=512m
server.memory.pagecache.size=128m
EOF
  export NEO4J_CONF="$LAB/neo4j/conf"
  if [ ! -d "$LAB/neo4j/data/databases" ]; then            # primera vez: fijar la clave inicial
    while [ "${#NUEVA_CLAVE}" -lt 8 ]; do read -rsp "Elegí la clave de Neo4j para este laboratorio (mín. 8 caracteres): " NUEVA_CLAVE; echo; done
    SALIDA="$(neo4j-admin dbms set-initial-password "$NUEVA_CLAVE" 2>&1)" || { echo "ERROR al fijar la clave: $SALIDA"; exit 1; }
  fi
  neo4j start >/dev/null 2>&1; esperar_puerto $BP || { echo "Neo4j no arrancó"; exit 1; }; sleep 4
  for i in 1 2 3; do                                         # validar la clave (corridas posteriores)
    [ -n "$NUEVA_CLAVE" ] && clave_ok "$NUEVA_CLAVE" && break
    NUEVA_CLAVE=""; read -rsp "Clave de Neo4j del laboratorio: " NUEVA_CLAVE; echo
    [ "$i" = 3 ] && { echo "Clave incorrecta. Para empezar de cero: REINICIAR=1 ./evidencias_terminal_act2.sh"; exit 1; }
  done
  export NEO4J_USERNAME=neo4j NEO4J_PASSWORD="$NUEVA_CLAVE" NEO4J_ADDRESS="$ADDR"
fi
[ "$PASO_DESDE" -gt 6 ] && [ "$REDIS_NUEVO" = 1 ] && printf '\n\033[1;33mAVISO: Redis arrancó vacío (las instancias estaban detenidas). Los pasos desde %s pueden mostrar datos vacíos: usá REINICIAR=1 para repetir desde el paso 1.\033[0m\n' "$PASO_DESDE"
cmd "redis-server --version | cut -c1-40 && redis-cli -p $RP ping"
cmd "neo4j --version && cypher-shell --version"
cmd "ss -ltn | grep -E ':($RP|$BP|$HP) '"
pausa

# ------------------------------------------------------------------ Redis y Neo4j: scripts entregables
ejecutar_redis_txt
ejecutar_cypher

# ------------------------------------------------------------------ INTEGRACIÓN Redis <-> Neo4j
paso "Integración 1 · El carrito de U01 en Redis, antes de confirmar el pedido"
RC "HGETALL carrito:U01"
RC "HLEN carrito:U01"
pausa

paso "Integración 2 · Pedido confirmado: se genera el evento (mensaje de la 'outbox')"
if va; then
  EVENTO_ID="$(cat /proc/sys/kernel/random/uuid)"; PEDIDO="PED-0002"; CLIENTE="U01"
  mapfile -t KV < <(redis-cli -p $RP HGETALL carrito:$CLIENTE | sed '/^$/d')
  if [ "${#KV[@]}" -eq 0 ]; then
    echo "El carrito de $CLIENTE está vacío: faltan los datos de los pasos anteriores. Repetí la sesión con REINICIAR=1 (o sin PASO_DESDE)."
    exit 1
  fi
  ITEMS_JSON=""; ITEMS_CYPHER=""
  for ((i=0;i<${#KV[@]};i+=2)); do
    ITEMS_JSON="${ITEMS_JSON:+$ITEMS_JSON,}{\"sku\":\"${KV[i]}\",\"cant\":${KV[i+1]}}"
    ITEMS_CYPHER="${ITEMS_CYPHER:+$ITEMS_CYPHER,}{sku:'${KV[i]}',cant:${KV[i+1]}}"
  done
  EVENTO="{\"evento_id\":\"$EVENTO_ID\",\"tipo\":\"PEDIDO_CONFIRMADO\",\"pedido_id\":\"$PEDIDO\",\"cliente\":\"$CLIENTE\",\"items\":[$ITEMS_JSON]}"
  printf '\n\033[1;32m$\033[0m echo "$EVENTO"\n%s\n' "$EVENTO"
  echo "(en la arquitectura real este mensaje se inserta en la tabla 'outbox' del sistema transaccional, dentro de la misma transacción del pedido)"
fi
pausa

aplicar_pedido() {   # consumidor idempotente: construye y ejecuta la sentencia con los datos del evento
  cypher-shell $FORMATO "UNWIND [$ITEMS_CYPHER] AS l MATCH (c:Cliente {id: '$CLIENTE'}), (p:Producto {id: l.sku}) MERGE (c)-[r:COMPRO {linea_id: '$PEDIDO-' + l.sku}]->(p) ON CREATE SET r.pedido_id = '$PEDIDO', r.cantidad = l.cant, r.fecha = datetime()"
}
paso "Integración 3 · El consumidor aplica el evento en Neo4j (compras de U01 antes y después)"
QN "MATCH (:Cliente {id: 'U01'})-[r:COMPRO]->() RETURN count(r) AS compras_u01_antes"
if va; then
  printf '\n\033[1;32m$\033[0m cypher-shell "UNWIND [<items del evento>] AS l MATCH (c:Cliente {id: <cliente>}), (p:Producto {id: l.sku}) MERGE (c)-[r:COMPRO {linea_id: <pedido> + l.sku}]->(p) ON CREATE SET ..."\n'
  aplicar_pedido
fi
QN "MATCH (:Cliente {id: 'U01'})-[r:COMPRO]->(p) RETURN r.linea_id AS linea, p.nombre AS producto, r.cantidad AS cantidad ORDER BY linea"
pausa

paso "Integración 4 · Reentrega del mismo evento (at-least-once): no se duplican las compras"
if va; then
  printf '\n\033[1;32m$\033[0m (el consumidor recibe otra vez el evento %s)\n' "$EVENTO_ID"
  aplicar_pedido
fi
QN "MATCH (:Cliente {id: 'U01'})-[r:COMPRO]->() RETURN count(r) AS compras_u01_despues_de_reentrega"
pausa

paso "Integración 5 · Neo4j recalcula las recomendaciones de U01 y Redis las sirve (caché con TTL)"
if va; then
  printf '\n\033[1;32m$\033[0m cypher-shell --format plain "<recomendaciones de U01>" | (por cada fila) redis-cli ZADD reco:U01 <afinidad> <producto>\n'
  redis-cli -p $RP DEL reco:U01 >/dev/null
  while IFS= read -r fila; do
    id="$(echo "$fila" | cut -d, -f1 | tr -d '" ')"; af="$(echo "$fila" | cut -d, -f2 | tr -d ' ')"
    [ -n "$id" ] && redis-cli -p $RP ZADD reco:U01 "$af" "$id" >/dev/null
  done < <(cypher-shell --format plain "MATCH (u:Cliente {id:'U01'})-[:COMPRO]->(:Producto)<-[:COMPRO]-(otro:Cliente)-[:COMPRO]->(rec:Producto) WHERE otro <> u AND NOT (u)-[:COMPRO]->(rec) RETURN rec.id AS id, count(DISTINCT otro) AS afinidad ORDER BY afinidad DESC, id" | tail -n +2)
  redis-cli -p $RP EXPIRE reco:U01 3600 >/dev/null
fi
RC "ZREVRANGE reco:U01 0 -1 WITHSCORES"
RC "TTL reco:U01"
pausa

paso "Integración 6 · Cierre del flujo: el carrito se vacía solo después de aplicar el pedido"
RC "DEL carrito:U01"
RC "EXISTS carrito:U01"
pausa

# ------------------------------------------------------------------ CONCURRENCIA en Redis
paso "Concurrencia 1 · 200 clientes suman 1 al mismo contador a la vez: HINCRBY es atómico"
if va; then
  redis-cli -p $RP DEL carrito:prueba >/dev/null
  printf '\n\033[1;32m$\033[0m for i in $(seq 200); do redis-cli HINCRBY carrito:prueba P101 1 & done; wait\n'
  for i in $(seq 200); do redis-cli -p $RP HINCRBY carrito:prueba P101 1 >/dev/null & done; wait
fi
RC "HGET carrito:prueba P101"
pausa

paso "Concurrencia 2 · El mismo experimento leyendo y escribiendo (HGET + HSET): se pierden actualizaciones"
if va; then
  printf '\n\033[1;32m$\033[0m for i in $(seq 200); do ( v=$(redis-cli HGET carrito:prueba P102 || echo 0); redis-cli HSET carrito:prueba P102 $((v+1)) ) & done; wait\n'
  redis-cli -p $RP HSET carrito:prueba P102 0 >/dev/null
  for i in $(seq 200); do ( v=$(redis-cli -p $RP HGET carrito:prueba P102); redis-cli -p $RP HSET carrito:prueba P102 $((v+1)) >/dev/null ) & done; wait
fi
RC "HGET carrito:prueba P102"
printf '\n(esperado: 200. Todo valor menor son actualizaciones perdidas por la condición de carrera)\n'
RC "DEL carrito:prueba"
pausa

# ------------------------------------------------------------------ cierre
if va; then
  printf '\n\033[1;36m=== FIN. Instancias de la Actividad 2 todavía activas (Redis %s, Neo4j %s).\033[0m\n' "$RP" "$BP"
  if [ "${SIN_PAUSA:-0}" != 1 ]; then
    read -rp "¿Detenerlas ahora? [S/n] " r
    [[ "$r" =~ ^[nN]$ ]] || { redis-cli -p $RP shutdown nosave >/dev/null 2>&1; neo4j stop >/dev/null 2>&1; echo "Instancias detenidas."; }
  else redis-cli -p $RP shutdown nosave >/dev/null 2>&1; neo4j stop >/dev/null 2>&1; echo "Instancias detenidas."; fi
  unset NEO4J_CONF
fi
