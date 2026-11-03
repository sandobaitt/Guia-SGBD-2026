#!/usr/bin/env bash
# =============================================================================
# U8 - ACTIVIDAD 2 · Guardia DBA MongoDB · GRUPO 11
# Laboratorio completo, reproducible y AISLADO:
#   - levanta su propia instancia mongod (puerto 27019, solo 127.0.0.1) con datos
#     propios en $LAB: no toca el servicio mongod del sistema ni bases compartidas
#   - recorre las 6 etapas de la consigna y valida cada control con pruebas
#
# Requisitos: mongod, mongosh, mongodump, mongorestore, bsondump y openssl (Ubuntu 24.04).
# Uso:
#   ./solucion_u8_actividad2.sh 2>&1 | tee salida_actividad2.txt
# Variables opcionales: LAB (directorio de trabajo), PUERTO, PUERTO_TLS, CARGA_JS
#   (ruta de solucion_u8_actividad1.js) y las contraseñas PWD_ADMIN, PWD_LECTOR,
#   PWD_OPERADOR, PWD_RESPALDO (por defecto, valores ficticios de laboratorio).
# Las contraseñas ficticias no se muestran en pantalla (aparecen como ********).
# =============================================================================
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB="${LAB:-$HOME/u8_lab_g11}"
PUERTO="${PUERTO:-27019}"
PUERTO_TLS="${PUERTO_TLS:-27020}"
JS="$DIR/solucion_u8_actividad2_mongosh.js"
CARGA_JS="${CARGA_JS:-$DIR/../Actividad 1/solucion_u8_actividad1.js}"
export PWD_ADMIN="${PWD_ADMIN:-LabG11-Admin#2026}" PWD_LECTOR="${PWD_LECTOR:-LabG11-Lector#2026}"
export PWD_OPERADOR="${PWD_OPERADOR:-LabG11-Operador#2026}" PWD_RESPALDO="${PWD_RESPALDO:-LabG11-Respaldo#2026}"
export PWD_RESTAURADOR="${PWD_RESTAURADOR:-LabG11-Restaurador#2026}"
BACKUP="$LAB/backup_u8_g11"
case "$LAB" in ""|"/"|"$HOME"|"$HOME/"|"/home"|"/tmp") echo "LAB inválido ($LAB): el script borra ese directorio al empezar"; exit 1;; esac

paso()  { echo; echo "################################################################################"; echo "# $*"; echo "################################################################################"; }
nota()  { echo "-- $*"; }
mostrar_cmd() { echo "\$ $*"; }

# mongosh autenticado:  ms USUARIO CLAVE BASE_AUTH BASE_DATOS [opciones...]
ms() {
  local u="$1" p="$2" a="$3" b="$4"; shift 4
  mostrar_cmd "mongosh \"mongodb://127.0.0.1:$PUERTO/$b\" -u $u -p ******** --authenticationDatabase $a $*"
  mongosh --quiet "mongodb://127.0.0.1:$PUERTO/$b" -u "$u" -p "$p" --authenticationDatabase "$a" "$@"
}
# mongosh sin credenciales
ms_anonimo() { mostrar_cmd "mongosh \"mongodb://127.0.0.1:$PUERTO/u8_g11\" $*"; mongosh --quiet "mongodb://127.0.0.1:$PUERTO/u8_g11" "$@"; }
admin()   { ms adminG11 "$PWD_ADMIN" admin u8_g11 "$@"; }
# variante silenciosa (sin mostrar el comando) para capturar valores
admin_q() { mongosh --quiet "mongodb://127.0.0.1:$PUERTO/u8_g11" -u adminG11 -p "$PWD_ADMIN" --authenticationDatabase admin "$@"; }

escribir_conf() {  # escribir_conf AUTH(si|no)
  cat > "$LAB/mongod_a.conf" <<EOF
storage:
  dbPath: $LAB/datos_a
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.5
net:
  port: $PUERTO
  bindIp: 127.0.0.1
systemLog:
  destination: file
  path: $LAB/mongod_a.log
  logAppend: true
processManagement:
  fork: true
  pidFilePath: $LAB/mongod_a.pid
EOF
  if [ "$1" = "si" ]; then printf 'security:\n  authorization: enabled\n' >> "$LAB/mongod_a.conf"; fi
}
arrancar_a() { mostrar_cmd "mongod --config $LAB/mongod_a.conf"; mongod --config "$LAB/mongod_a.conf" | tail -1; sleep 3; }
detener_a()  { [ -f "$LAB/mongod_a.pid" ] && kill "$(cat "$LAB/mongod_a.pid")" 2>/dev/null; sleep 3; }

# -----------------------------------------------------------------------------
paso "0. PREPARACIÓN DEL LABORATORIO AISLADO"
# -----------------------------------------------------------------------------
detener_a
rm -rf "$LAB"; mkdir -p "$LAB/datos_a"
echo "Directorio de laboratorio: $LAB"
echo "Fecha                    : $(date -Is)"
echo "Sistema                  : $(. /etc/os-release; echo "$PRETTY_NAME") · $(uname -m)"
echo "Versiones                : $(mongod --version | head -1) · mongosh $(mongosh --version) · $(mongodump --version | head -1)"
escribir_conf no
arrancar_a
nota "Se carga la solución de la Actividad 1 (base u8_g11: 15 envíos + 20 eventos) — instancia sin autenticación todavía"
mongosh --quiet "mongodb://127.0.0.1:$PUERTO" --file "$CARGA_JS" | grep -E "insertedCount|TOTAL|CUMPLE|NO CUMPLE|FIN\."

# -----------------------------------------------------------------------------
paso "1. DIAGNÓSTICO (estado, bases, colecciones, autenticación y escucha de red)"
# -----------------------------------------------------------------------------
FASE=diagnostico mongosh --quiet "mongodb://127.0.0.1:$PUERTO" --file "$JS"
nota "Proceso y socket a nivel del sistema operativo"
mostrar_cmd "ps -o pid,user,args -C mongod"; ps -o pid,user,args -C mongod | sed "s#$HOME#~#g"
mostrar_cmd "ss -ltnp | grep :$PUERTO"; ss -ltnp 2>/dev/null | grep ":$PUERTO " | sed 's/users:.*//'

# -----------------------------------------------------------------------------
paso "2. AUTENTICACIÓN: usuario administrador, control de acceso y rechazo sin credenciales"
# -----------------------------------------------------------------------------
nota "2.1 Se crea el administrador ANTES de activar el control de acceso"
FASE=crear_admin mongosh --quiet "mongodb://127.0.0.1:$PUERTO" --file "$JS"
nota "2.2 Se activa security.authorization: enabled y se reinicia la instancia"
detener_a; escribir_conf si; echo "$(grep -A1 '^security' "$LAB/mongod_a.conf")"; arrancar_a
nota "2.3 Sin credenciales: la conexión se establece pero cualquier operación sobre datos se rechaza"
FASE=pruebas ROL=anonimo ms_anonimo --file "$JS"
nota "2.4 Credenciales incorrectas"
ms adminG11 "clave-incorrecta" admin u8_g11 --eval 'db.runCommand({ ping: 1 })' 2>&1 | sed 's/^/   /' | head -3
nota "2.5 Credenciales correctas del administrador (connectionStatus)"
admin --eval 'printjson(db.adminCommand({ connectionStatus: 1 }).authInfo)'
nota "2.6 Con el acceso activo, el diagnóstico confirma security.authorization"
FASE=diagnostico admin --file "$JS" | sed -n '/1.3 Autenticación/,/1.4 Bases/p'

# -----------------------------------------------------------------------------
paso "3. RBAC: lector (read) y operador (readWrite) solo sobre u8_g11 + usuario de respaldo"
# -----------------------------------------------------------------------------
FASE=rbac admin --file "$JS"
nota "3.1 Pruebas del LECTOR"
FASE=pruebas ROL=lector ms u8_g11_lector "$PWD_LECTOR" u8_g11 u8_g11 --file "$JS"
nota "3.2 Pruebas del OPERADOR"
FASE=pruebas ROL=operador ms u8_g11_operador "$PWD_OPERADOR" u8_g11 u8_g11 --file "$JS"
nota "3.3 Pruebas del usuario de RESPALDO (rol backup)"
FASE=pruebas ROL=respaldo ms u8_g11_respaldo "$PWD_RESPALDO" admin u8_g11 --file "$JS"
nota "3.4 Observación sobre el usuario de RESTAURACIÓN (rol restore)"
FASE=pruebas ROL=restaurador ms u8_g11_restaurador "$PWD_RESTAURADOR" admin u8_g11 --file "$JS"

# -----------------------------------------------------------------------------
paso "4. RED Y TLS"
# -----------------------------------------------------------------------------
nota "4.1 Parámetros de la instancia de laboratorio (puerto, bindIp, TLS)"
grep -E "^net:|port:|bindIp:" "$LAB/mongod_a.conf"
mostrar_cmd "ss -ltn | grep :$PUERTO"; ss -ltn | grep ":$PUERTO "
echo "Sockets de escucha en 0.0.0.0:$PUERTO (todas las interfaces): $(ss -ltn | grep -c "0.0.0.0:$PUERTO ")"
LAN_IP="$(hostname -I | awk '{print $1}')"
nota "4.2 ¿Se expone en la red? Intento de conexión desde la IP de la LAN ($LAN_IP) al mismo puerto"
mostrar_cmd "mongosh --host $LAN_IP --port $PUERTO --eval 'db.runCommand({ping:1})'"
mongosh --quiet "mongodb://$LAN_IP:$PUERTO/?serverSelectionTimeoutMS=3000" --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
nota "4.3 TLS real: CA propia + certificado de servidor (SAN localhost y 127.0.0.1)"
TLS="$LAB/tls"; mkdir -p "$TLS" "$LAB/datos_tls"
openssl genrsa -out "$TLS/ca.key" 4096 2>/dev/null
openssl req -x509 -new -nodes -key "$TLS/ca.key" -sha256 -days 365 -subj "/O=UTN FRRe SGBD/CN=CA Laboratorio G11" -out "$TLS/ca.crt"
openssl genrsa -out "$TLS/server.key" 2048 2>/dev/null
openssl req -new -key "$TLS/server.key" -subj "/O=UTN FRRe SGBD/CN=localhost" -out "$TLS/server.csr"
printf 'subjectAltName=DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth\n' > "$TLS/server.ext"
openssl x509 -req -in "$TLS/server.csr" -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial -out "$TLS/server.crt" -days 365 -sha256 -extfile "$TLS/server.ext" 2>&1 | sed 's/^/   /'
cat "$TLS/server.key" "$TLS/server.crt" > "$TLS/server.pem"; chmod 600 "$TLS"/*.key "$TLS/server.pem"
mostrar_cmd "openssl x509 -in server.crt -noout -subject -issuer -dates -ext subjectAltName"
openssl x509 -in "$TLS/server.crt" -noout -subject -issuer -dates -ext subjectAltName | sed 's/^/   /'
cat > "$LAB/mongod_tls.conf" <<EOF
storage:
  dbPath: $LAB/datos_tls
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.25
net:
  port: $PUERTO_TLS
  bindIp: 127.0.0.1
  tls:
    mode: requireTLS
    certificateKeyFile: $TLS/server.pem
    CAFile: $TLS/ca.crt
    allowConnectionsWithoutCertificates: true
security:
  authorization: enabled
systemLog:
  destination: file
  path: $LAB/mongod_tls.log
  logAppend: true
processManagement:
  fork: true
  pidFilePath: $LAB/mongod_tls.pid
EOF
nota "4.4 Configuración TLS aplicada (mongod_tls.conf, bloque net)"; sed -n '/^net:/,/^security:/p' "$LAB/mongod_tls.conf" | sed "s#$LAB#\$LAB#g" | head -12
mostrar_cmd "mongod --config mongod_tls.conf"; mongod --config "$LAB/mongod_tls.conf" | tail -1; sleep 3
TLSOPT=(--tls --tlsCAFile "$TLS/ca.crt")
nota "4.5 Primer usuario por la excepción de localhost (el cliente ya usa TLS)"
mongosh --quiet --host localhost --port "$PUERTO_TLS" "${TLSOPT[@]}" --eval 'db.getSiblingDB("admin").createUser({user:"adminTLS",pwd:"'"$PWD_ADMIN"'",roles:["root"]})'
nota "4.6 Cliente SIN TLS contra el puerto TLS (debe ser rechazado)"
mongosh --quiet "mongodb://127.0.0.1:$PUERTO_TLS/?serverSelectionTimeoutMS=3000" --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
nota "4.7 Cliente con TLS pero SIN confiar en la CA (debe ser rechazado: cadena no verificable)"
mongosh --quiet "mongodb://localhost:$PUERTO_TLS/?serverSelectionTimeoutMS=3000" --tls --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
nota "4.8 Cliente con TLS y la CA del laboratorio + credenciales (debe funcionar)"
mostrar_cmd "mongosh --host localhost --port $PUERTO_TLS --tls --tlsCAFile ca.crt -u adminTLS -p ******** --authenticationDatabase admin"
mongosh --quiet --host localhost --port "$PUERTO_TLS" "${TLSOPT[@]}" -u adminTLS -p "$PWD_ADMIN" --authenticationDatabase admin --eval '
  const o = db.adminCommand({ getCmdLineOpts: 1 }).parsed.net;
  printjson({ ping: db.adminCommand({ ping: 1 }).ok, tls_mode: o.tls.mode, bindIp: o.bindIp, port: o.port });
  printjson(db.serverStatus().transportSecurity);'
nota "4.9 Handshake observado con openssl s_client (protocolo, cifrado y verificación de la cadena)"
echo | openssl s_client -connect "localhost:$PUERTO_TLS" -CAfile "$TLS/ca.crt" -verify_return_error 2>/dev/null | grep -E "Protocol|Cipher is|Verify return code|subject=|issuer=" | sed 's/^/   /'
kill "$(cat "$LAB/mongod_tls.pid")" 2>/dev/null; sleep 2
nota "4.10 Variante con TLS MUTUO: es lo que ocurre con CAFile y SIN allowConnectionsWithoutCertificates (la configuración que propone la bitácora original)"
PUERTO_M=$((PUERTO_TLS + 1)); mkdir -p "$LAB/datos_mtls"
sed -e "s#datos_tls#datos_mtls#; s#port: $PUERTO_TLS#port: $PUERTO_M#; /allowConnectionsWithoutCertificates/d; /^security:/d; /authorization:/d; s#mongod_tls#mongod_mtls#" "$LAB/mongod_tls.conf" > "$LAB/mongod_mtls.conf"
mongod --config "$LAB/mongod_mtls.conf" | tail -1; sleep 3
nota "Cliente con TLS y CA, pero SIN certificado de cliente (rechazado):"
mongosh --quiet "mongodb://localhost:$PUERTO_M/?serverSelectionTimeoutMS=3000" --tls --tlsCAFile "$TLS/ca.crt" --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
openssl genrsa -out "$TLS/cliente.key" 2048 2>/dev/null
openssl req -new -key "$TLS/cliente.key" -subj "/O=UTN FRRe SGBD/CN=cliente-g11" -out "$TLS/cliente.csr"
openssl x509 -req -in "$TLS/cliente.csr" -CA "$TLS/ca.crt" -CAkey "$TLS/ca.key" -CAcreateserial -out "$TLS/cliente.crt" -days 30 -sha256 2>/dev/null
cat "$TLS/cliente.key" "$TLS/cliente.crt" > "$TLS/cliente.pem"; chmod 600 "$TLS/cliente.key" "$TLS/cliente.pem"
nota "Cliente con TLS, CA y certificado de cliente firmado por la misma CA (aceptado):"
mongosh --quiet "mongodb://localhost:$PUERTO_M/?serverSelectionTimeoutMS=3000" --tls --tlsCAFile "$TLS/ca.crt" --tlsCertificateKeyFile "$TLS/cliente.pem" --eval 'printjson(db.runCommand({ping:1}))' 2>&1 | sed 's/^/   /'
kill "$(cat "$LAB/mongod_mtls.pid")" 2>/dev/null; sleep 2
nota "Instancias TLS detenidas. La instancia principal (sin TLS, solo localhost) continúa para backup y restore."

# -----------------------------------------------------------------------------
paso "5. BACKUP Y RESTAURACIÓN (mongodump / mongorestore) con validación"
# -----------------------------------------------------------------------------
nota "5.1 Estado ANTES del respaldo (recuentos de la base original, registrados justo antes del dump)"
admin --eval 'const d=db.getSiblingDB("u8_g11"); d.getCollectionNames().forEach(c=>print(c.padEnd(24)+d[c].countDocuments({})+" documentos"))'
nota "5.2 Colección de prueba para el borrado controlado (copia de envíos entregados y demorados)"
FASE=preparar_borrado admin --file "$JS"
HASH_ANTES="$(admin_q --eval 'print(db.getSiblingDB("u8_g11").runCommand({dbHash:1,collections:["prueba_borrado"]}).collections.prueba_borrado)')"
NANTES="$(admin_q --eval 'print(db.getSiblingDB("u8_g11").prueba_borrado.countDocuments({}))')"
nota "prueba_borrado antes del incidente: $NANTES documentos, md5 $HASH_ANTES"
nota "5.3 mongodump con el usuario de respaldo (rol backup; sin usar el administrador)"
mostrar_cmd "mongodump --host 127.0.0.1:$PUERTO -u u8_g11_respaldo -p ******** --authenticationDatabase admin --db u8_g11 --out \$LAB/backup_u8_g11"
mongodump --host "127.0.0.1:$PUERTO" -u u8_g11_respaldo -p "$PWD_RESPALDO" --authenticationDatabase admin --db u8_g11 --out "$BACKUP" 2>&1 | sed 's/^[0-9T:.+-]*\t//'
nota "5.4 Verificación de los artefactos generados"
mostrar_cmd "ls -lh \$LAB/backup_u8_g11/u8_g11/"; ls -lh "$BACKUP/u8_g11/" | sed 's/vboxuser//'
mostrar_cmd "sha256sum \$LAB/backup_u8_g11/u8_g11/*"; (cd "$BACKUP/u8_g11" && sha256sum *)
nota "Metadatos de índices guardados en envios.metadata.json:"
python3 -c "import json,sys; m=json.load(open('$BACKUP/u8_g11/envios.metadata.json')); print('   índices:', [i['name'] for i in m['indexes']])"
nota "Lectura de un documento del .bson con bsondump (el respaldo es legible):"
bsondump --quiet "$BACKUP/u8_g11/envios.bson" 2>/dev/null | head -1 | cut -c1-150 | sed 's/^/   /'
nota "bsondump cuenta los documentos del archivo (control cruzado con el recuento de la base): $(bsondump --quiet "$BACKUP/u8_g11/envios.bson" 2>/dev/null | wc -l) en envios.bson"

nota "5.5 Restauración en una base ALTERNATIVA u8_g11_restore con el usuario restaurador (rol restore). Primero un ensayo (--dryRun)"
mostrar_cmd "mongorestore -u u8_g11_restaurador -p ******** --dryRun --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' \$LAB/backup_u8_g11"
mongorestore --host "127.0.0.1:$PUERTO" -u u8_g11_restaurador -p "$PWD_RESTAURADOR" --authenticationDatabase admin --dryRun --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' "$BACKUP" 2>&1 | sed 's/^[0-9T:.+-]*\t//' | tail -4
nota "Restauración real"
mostrar_cmd "mongorestore -u u8_g11_restaurador -p ******** --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' \$LAB/backup_u8_g11"
mongorestore --host "127.0.0.1:$PUERTO" -u u8_g11_restaurador -p "$PWD_RESTAURADOR" --authenticationDatabase admin --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' "$BACKUP" 2>&1 | sed 's/^[0-9T:.+-]*\t//'
nota "5.6 Validación de la recuperación: conteos, contenido documento a documento, hash e índices"
FASE=comparar ORIGEN=u8_g11 DESTINO=u8_g11_restore admin --file "$JS"
nota "5.7 Restaurar sobre un destino que ya tiene datos NO sobrescribe (claves duplicadas); para reemplazar se usa --drop"
mongorestore --host "127.0.0.1:$PUERTO" -u u8_g11_restaurador -p "$PWD_RESTAURADOR" --authenticationDatabase admin --nsInclude 'u8_g11.envios' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' "$BACKUP" 2>&1 | sed 's/^[0-9T:.+-]*\t//' | grep -E "restoring|duplicate|finished|restored|failed" | sed 's/{ .* }//' | tail -4

nota "5.8 INCIDENTE CONTROLADO: se elimina la colección de prueba (la base original NO se borra)"
FASE=borrar_prueba admin --file "$JS"
nota "5.9 Recuperación de SOLO esa colección desde el respaldo"
mostrar_cmd "mongorestore -u u8_g11_restaurador -p ******** --nsInclude 'u8_g11.prueba_borrado' \$LAB/backup_u8_g11"
mongorestore --host "127.0.0.1:$PUERTO" -u u8_g11_restaurador -p "$PWD_RESTAURADOR" --authenticationDatabase admin --nsInclude 'u8_g11.prueba_borrado' "$BACKUP" 2>&1 | sed 's/^[0-9T:.+-]*\t//'
HASH_DESPUES="$(admin_q --eval 'print(db.getSiblingDB("u8_g11").runCommand({dbHash:1,collections:["prueba_borrado"]}).collections.prueba_borrado)')"
NDESPUES="$(admin_q --eval 'print(db.getSiblingDB("u8_g11").prueba_borrado.countDocuments({}))')"
IDX_DESPUES="$(admin_q --eval 'print(db.getSiblingDB("u8_g11").prueba_borrado.getIndexes().map(i=>i.name).join(", "))')"
echo "Antes del incidente : $NANTES documentos | md5 $HASH_ANTES"
echo "Después de recuperar: $NDESPUES documentos | md5 $HASH_DESPUES | índices: $IDX_DESPUES"
[ "$HASH_ANTES" = "$HASH_DESPUES" ] && [ "$NANTES" = "$NDESPUES" ] && echo "[OK]    Colección recuperada con el mismo contenido (conteo y md5 idénticos)" || echo "[FALLO] La colección recuperada difiere"
nota "5.10 Control final: la base original conserva todas sus colecciones de datos"
admin --eval 'const d=db.getSiblingDB("u8_g11"); d.getCollectionNames().sort().forEach(c=>print(c.padEnd(24)+d[c].countDocuments({})+" documentos"))'

# -----------------------------------------------------------------------------
paso "6. INCIDENTE: el usuario puede leer pero no modificar un documento"
# -----------------------------------------------------------------------------
nota "6.1 Diagnóstico por capas con el usuario afectado (u8_g11_lector)"
FASE=incidente ms u8_g11_lector "$PWD_LECTOR" u8_g11 u8_g11 --file "$JS"
nota "6.2 Contraste: un fallo de AUTENTICACIÓN se ve distinto (contraseña errónea y base de autenticación equivocada)"
ms u8_g11_lector "clave-incorrecta" u8_g11 u8_g11 --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
ms u8_g11_lector "$PWD_LECTOR" admin u8_g11 --eval 'db.runCommand({ping:1})' 2>&1 | head -2 | sed 's/^/   /'
nota "6.3 Corrección: se otorga readWrite sobre u8_g11 (como adminG11) y el usuario reconecta"
FASE=incidente_corregido admin --file "$JS"
ms u8_g11_lector "$PWD_LECTOR" u8_g11 u8_g11 --eval '
  const l = db.getSiblingDB("u8_g11");
  printjson(l.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones: "prueba tras la corrección" } }));
  printjson(l.envios.updateOne({ _id: "ENV-2026-001" }, { $unset: { observaciones: "" } }));'
nota "6.4 Reversión al mínimo privilegio y verificación de que el update vuelve a ser denegado"
FASE=incidente_revertir admin --file "$JS"
ms u8_g11_lector "$PWD_LECTOR" u8_g11 u8_g11 --eval 'try { db.getSiblingDB("u8_g11").envios.updateOne({ _id: "ENV-2026-001" }, { $set: { x: 1 } }) } catch (e) { print("DENEGADA -> " + e.codeName + " (código " + e.code + ")") }'

# -----------------------------------------------------------------------------
paso "FIN · se detiene la instancia de laboratorio"
# -----------------------------------------------------------------------------
detener_a
echo "Instancia detenida. Los datos y certificados quedan en $LAB (no se versionan: contienen claves privadas de laboratorio)."
