# Guía Paso a Paso: U8 - Actividad 2 (Guardia DBA MongoDB)
**Grupo:** G11 · **Base bajo guardia:** `u8_g11` (resultado de la Actividad 1)  
**Motor:** MongoDB Community 8.0 · `mongosh` · Database Tools (`mongodump`, `mongorestore`, `bsondump`) · `openssl`  
**Archivos:** `solucion_u8_actividad2.sh` (laboratorio completo) · `solucion_u8_actividad2_mongosh.js` (comandos de `mongosh` por fases) · `admin.txt` y `restore.txt` (la entrega original; ver `bitacora_resuelta.md`, sección 7)

> **Reglas de la consigna:** instancia de laboratorio y datos ficticios; **no publicar puertos ni credenciales**; no hacer pruebas destructivas sobre bases compartidas; **no borrar la base original**.

Hay dos caminos. Conviene hacer primero el **A** para ver todo funcionando y después el **B** en la VM para sacar las capturas propias.

| Camino | Qué es | Cuándo |
| :--- | :--- | :--- |
| **A. Laboratorio aislado** | Un solo comando levanta su propio `mongod` (puerto 27019, solo `127.0.0.1`) y recorre las 6 etapas | Para comprobar que los scripts funcionan y ver las salidas esperadas; **no toca** el `mongod` del sistema |
| **B. VM del grupo** | Los mismos pasos, a mano, sobre la instancia real (`/etc/mongod.conf`) | Para las capturas y la entrega |

---

## A. Laboratorio aislado (un comando)

```bash
cd "Parcial 2/Unidad 8/Actividad 2"
./solucion_u8_actividad2.sh 2>&1 | tee salida_actividad2.txt
```
- Requiere `mongod`, `mongosh`, `mongodump`, `mongorestore`, `bsondump` y `openssl`.
- Crea todo en `~/u8_lab_g11` (cambiable con `LAB=/otra/ruta`) y **borra ese directorio al empezar**; el script rechaza rutas peligrosas (`/`, `$HOME`).
- Carga la Actividad 1 (`../Actividad 1/solucion_u8_actividad1.js`), activa el acceso, crea los usuarios, prueba TLS en una segunda instancia, hace backup y restore, y diagnostica el incidente.
- Las contraseñas de laboratorio son ficticias y se pueden cambiar con `PWD_ADMIN`, `PWD_LECTOR`, `PWD_OPERADOR`, `PWD_RESPALDO`, `PWD_RESTAURADOR`; no se muestran en pantalla (`********`).
- Dura alrededor de un minuto. Al final detiene sus instancias; la salida esperada termina con **34 líneas `[OK]` y ninguna `[FALLO]`**.

---

## B. En la VM del grupo (pasos manuales)

### B.0. Preparación
```bash
ssh vboxuser@192.168.1.42                       # si la IP cambió: ip -4 addr en la VM
sudo cp /etc/mongod.conf /etc/mongod.conf.bak   # copia de seguridad ANTES de tocar nada
sudo systemctl status mongod                    # active (running)
```
Copiar los scripts a la VM (desde la PC):
```bash
scp "Parcial 2/Unidad 8/Actividad 2/solucion_u8_actividad2_mongosh.js" vboxuser@192.168.1.42:~/u8_act2/
```
**Qué fase de `solucion_u8_actividad2_mongosh.js` se ejecuta:** se elige con la variable `FASE` (y `ROL` en las pruebas):
```bash
FASE=diagnostico mongosh "mongodb://127.0.0.1:27017" --file solucion_u8_actividad2_mongosh.js
```
Las contraseñas llegan por variables de entorno (`PWD_ADMIN`, `PWD_LECTOR`, `PWD_OPERADOR`); si no se definen, se usan valores ficticios de laboratorio.

### B.1. Diagnóstico
```bash
sudo grep -A6 -E "^net:|^security:" /etc/mongod.conf       # configuración escrita
ss -ltnp | grep mongod                                      # en qué dirección escucha realmente
ps -o pid,user,args -C mongod
```
```javascript
db.version()
db.adminCommand({ getCmdLineOpts: 1 }).parsed        // configuración EFECTIVA: net, security, storage
db.serverStatus().connections
show dbs
db.getSiblingDB("u8_g11").getCollectionNames()
db.getSiblingDB("u8_g11").getUsers()                  // {users: []} si todavía no hay usuarios
```
**Qué buscar y anotar:** versión; `net.bindIp` (¿`0.0.0.0`?); `security.authorization` (¿ausente?); `net.tls.mode`. Si hay `bindIp: 0.0.0.0` y no hay autenticación, **la instancia está abierta a la red**: es el primer hallazgo.

*(Capturar: **Evidencia 1 — diagnóstico**.)*

### B.2. Autenticación
**1) Crear el administrador antes de activar el acceso** (en `mongosh`, sin credenciales; todavía funciona porque la autenticación está desactivada):
```javascript
db.getSiblingDB("admin").createUser({
  user: "adminG11", pwd: passwordPrompt(),            // pide la clave sin mostrarla ni guardarla
  roles: [ { role: "userAdminAnyDatabase", db: "admin" },
           { role: "readWriteAnyDatabase", db: "admin" },
           { role: "clusterMonitor",       db: "admin" } ] })
```
**2) Activar el control de acceso** y reiniciar:
```bash
sudoedit /etc/mongod.conf        # agregar al final:    security:
                                 #                        authorization: enabled
sudo systemctl restart mongod
sudo systemctl status mongod
```
**3) Probar el rechazo sin credenciales y el acceso con credenciales:**
```javascript
// mongosh "mongodb://127.0.0.1:27017/u8_g11"   (sin credenciales)
db.envios.find()                  // MongoServerError[Unauthorized]: Command find requires authentication
db.adminCommand({ ping: 1 })      // { ok: 1 }: la conexión no exige autenticarse
```
```bash
mongosh "mongodb://127.0.0.1:27017/u8_g11" -u adminG11 --authenticationDatabase admin -p       # -p sin valor: pide la clave
mongosh "mongodb://127.0.0.1:27017/u8_g11" -u adminG11 --authenticationDatabase admin -p mala   # Authentication failed
```
```javascript
db.adminCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers
```
> **Si te quedás afuera** (clave perdida): comentar el bloque `security:` en `/etc/mongod.conf`, reiniciar, crear de nuevo el usuario con la excepción de localhost y volver a activar `security:`.

*(Capturar: **Evidencia 2 — rechazo sin credenciales**, **Evidencia 3 — conexión válida con `connectionStatus`**.)*

### B.3. RBAC
Como `adminG11`:
```javascript
const lab = db.getSiblingDB("u8_g11")
lab.createUser({ user: "u8_g11_lector",   pwd: passwordPrompt(), roles: [{ role: "read",      db: "u8_g11" }] })
lab.createUser({ user: "u8_g11_operador", pwd: passwordPrompt(), roles: [{ role: "readWrite", db: "u8_g11" }] })
lab.getUsers().users.map(u => ({ usuario: u.user, roles: u.roles }))
```
Conectar con cada usuario (están definidos en `u8_g11`, por eso `--authenticationDatabase u8_g11`):
```bash
mongosh "mongodb://127.0.0.1:27017/u8_g11" -u u8_g11_lector   --authenticationDatabase u8_g11 -p
mongosh "mongodb://127.0.0.1:27017/u8_g11" -u u8_g11_operador --authenticationDatabase u8_g11 -p
```

**Matriz mínima (obligatoria) y ampliada.** Una captura por fila, con el mensaje de error completo:

| Identidad | Comando | Resultado esperado |
| :--- | :--- | :--- |
| Lector | `db.envios.find({}, {tracking_code:1}).limit(2)` | Permitida |
| Lector | `db.envios.insertOne({ _id: "ENV-TEST-DENIED" })` | **Denegada** `not authorized on u8_g11 to execute command { insert ...` |
| Lector | `db.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { x: 1 } })` | **Denegada** |
| Lector | `db.envios.drop()` | **Denegada** |
| Lector | `db.getSiblingDB("admin").system.users.find()` | **Denegada** (otra base) |
| Operador | `db.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones_operador: "RBAC" } })` | Permitida |
| Operador | `db.envios.updateOne({ _id: "ENV-2026-001" }, { $unset: { observaciones_operador: "" } })` | Permitida (**revierte el cambio**) |
| Operador | `db.createUser({ user: "x", pwd: "x", roles: ["read"] })` | **Denegada** |
| Operador | `db.grantRolesToUser("u8_g11_operador", [{ role: "dbOwner", db: "u8_g11" }])` | **Denegada** (escalada) |

> **Cuidado con los residuos.** Cualquier prueba que **inserte** debe ejecutarse con el usuario correcto y **borrar lo que crea**. Una `insertOne` de prueba que quede en `envios` altera el recuento (15 → 16) y se arrastra al respaldo.

Ver el privilegio concreto del usuario afectado:
```javascript
db.adminCommand({ connectionStatus: 1, showPrivileges: true }).authInfo.authenticatedUserPrivileges
```

### B.4. Red y TLS
**Evaluar la exposición:**
```bash
ss -ltn | grep 27017               # ¿127.0.0.1:27017 o 0.0.0.0:27017?
sudo ufw status verbose            # ¿qué reglas hay para el puerto?
```
Desde **otra PC** de la red: `mongosh "mongodb://192.168.1.42:27017/?serverSelectionTimeoutMS=3000" --eval 'db.runCommand({ping:1})'`. Si responde, el puerto está expuesto.

**Reducir la exposición:**
```yaml
# /etc/mongod.conf
net:
  port: 27017
  bindIp: 127.0.0.1,192.168.1.42       # solo las interfaces necesarias (no 0.0.0.0)
```
```bash
sudo ufw allow from 192.168.1.0/24 to any port 27017 proto tcp     # solo la subred del aula
sudo systemctl restart mongod
```

**Implementar TLS** (la VM tiene `openssl`):
```bash
mkdir -p ~/tls && cd ~/tls
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -subj "/O=UTN FRRe SGBD/CN=CA Laboratorio G11" -out ca.crt
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/O=UTN FRRe SGBD/CN=192.168.1.42" -out server.csr
printf 'subjectAltName=IP:192.168.1.42,IP:127.0.0.1,DNS:localhost\nextendedKeyUsage=serverAuth\n' > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile server.ext
sudo sh -c 'cat server.key server.crt > /etc/ssl/mongodb.pem'
sudo cp ca.crt /etc/ssl/ca.crt
sudo chown mongodb:mongodb /etc/ssl/mongodb.pem && sudo chmod 600 /etc/ssl/mongodb.pem
```
```yaml
# /etc/mongod.conf  (bloque net)
net:
  port: 27017
  bindIp: 127.0.0.1,192.168.1.42
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb.pem
    CAFile: /etc/ssl/ca.crt
    allowConnectionsWithoutCertificates: true     # sin esta línea el servidor exige certificado de CLIENTE (TLS mutuo)
```
```bash
sudo systemctl restart mongod ; sudo tail -20 /var/log/mongodb/mongod.log     # si no arranca, el motivo está en el log
mongosh --host 192.168.1.42 --port 27017 --eval 'db.runCommand({ping:1})'                   # SIN TLS: debe fallar
mongosh --host 192.168.1.42 --port 27017 --tls --eval 'db.runCommand({ping:1})'             # TLS sin CA: self-signed certificate in certificate chain
mongosh --host 192.168.1.42 --port 27017 --tls --tlsCAFile ca.crt -u adminG11 --authenticationDatabase admin -p
```
En la sesión con TLS: `db.serverStatus().transportSecurity` y `db.adminCommand({getCmdLineOpts:1}).parsed.net.tls`.
> Distribuir a los clientes **solo `ca.crt`**. Las claves (`*.key`, `*.pem`) no se envían ni se versionan.

*(Capturar: **Evidencia 4 — exposición**, **Evidencia 5 — cliente sin TLS rechazado**, **Evidencia 6 — conexión TLS exitosa**.)*

### B.5. Backup y restauración
**1) Registrar el estado ANTES** (y, si el recuento no es el esperado, investigar antes de respaldar):
```javascript
const d = db.getSiblingDB("u8_g11")
d.getCollectionNames().forEach(c => print(c, d[c].countDocuments({})))      // envios 15 · eventos_seguimiento 20
d.envios.find({ _id: { $not: /^ENV-2026-0(0[1-9]|1[0-5])$/ } })              // ¿algún documento de prueba?
```
**2) Respaldar** (usuario con el rol `backup`; si se usa el administrador, también sirve):
```javascript
db.getSiblingDB("admin").createUser({ user: "u8_g11_respaldo", pwd: passwordPrompt(), roles: [{ role: "backup", db: "admin" }] })
```
```bash
mongodump --host 127.0.0.1:27017 -u u8_g11_respaldo --authenticationDatabase admin -p --db u8_g11 --out ~/backup_u8_g11
ls -lh ~/backup_u8_g11/u8_g11/              # .bson (datos) y .metadata.json (índices) por colección + prelude.json
(cd ~/backup_u8_g11/u8_g11 && sha256sum *)
bsondump --quiet ~/backup_u8_g11/u8_g11/envios.bson | wc -l     # 15
```
**3) Restaurar en una base alternativa** (usuario con rol `restore`, que es **amplio** y se habilita solo durante la recuperación):
```javascript
db.getSiblingDB("admin").createUser({ user: "u8_g11_restaurador", pwd: passwordPrompt(), roles: [{ role: "restore", db: "admin" }] })
```
```bash
mongorestore --host 127.0.0.1:27017 -u u8_g11_restaurador --authenticationDatabase admin -p --dryRun \
  --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' ~/backup_u8_g11     # ensayo
mongorestore --host 127.0.0.1:27017 -u u8_g11_restaurador --authenticationDatabase admin -p \
  --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' ~/backup_u8_g11
```
**4) Validar** (no alcanza con comparar recuentos):
```javascript
const o = db.getSiblingDB("u8_g11"), r = db.getSiblingDB("u8_g11_restore")
;["envios", "eventos_seguimiento"].forEach(c => {
  print(c, "documentos:", o[c].countDocuments({}), "/", r[c].countDocuments({}))
  print("  dbHash:", o.runCommand({dbHash:1, collections:[c]}).collections[c], "/", r.runCommand({dbHash:1, collections:[c]}).collections[c])
  print("  índices:", o[c].getIndexes().map(i=>i.name).join(","), "/", r[c].getIndexes().map(i=>i.name).join(","))
})
```
(La fase `comparar` del script hace además la comparación documento a documento: `FASE=comparar ORIGEN=u8_g11 DESTINO=u8_g11_restore mongosh ... --file solucion_u8_actividad2_mongosh.js`.)

**5) Borrado controlado de una colección de prueba y recuperación:**
```javascript
// crear la colección de prueba ANTES del dump (FASE=preparar_borrado) y volver a respaldar
db.getSiblingDB("u8_g11").prueba_borrado.drop()                // incidente controlado: NO se borra la base
```
```bash
mongorestore --host 127.0.0.1:27017 -u u8_g11_restaurador --authenticationDatabase admin -p \
  --nsInclude 'u8_g11.prueba_borrado' ~/backup_u8_g11
```
Verificar conteo, `dbHash` e índices de `prueba_borrado` contra los valores registrados antes del `drop`.

*(Capturar: **Evidencia 7 — dump y artefactos**, **Evidencia 8 — restauración**, **Evidencia 9 — validación de conteos, hash e índices**, **Evidencia 10 — borrado y recuperación**.)*

### B.6. Incidente: leer sí, modificar no
Con el usuario afectado (`u8_g11_lector`):
```javascript
db.runCommand({ ping: 1 })                                              // 1) conexión
db.adminCommand({ connectionStatus: 1 }).authInfo                       // 2) autenticación: quién es
db.adminCommand({ connectionStatus: 1, showPrivileges: true }).authInfo.authenticatedUserPrivileges   // 3) autorización: qué puede
db.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones: "x" } })   // Unauthorized, código 13
```
Corrección y reversión (como `adminG11`):
```javascript
db.getSiblingDB("u8_g11").grantRolesToUser("u8_g11_lector", [{ role: "readWrite", db: "u8_g11" }])   // el usuario debe reconectar
db.getSiblingDB("u8_g11").revokeRolesFromUser("u8_g11_lector", [{ role: "readWrite", db: "u8_g11" }])
```

---

## C. Armar la entrega
La consigna pide **un único `.zip`** y **no entregar archivos de backup ni archivos no solicitados**:

| Archivo | Contenido |
| :--- | :--- |
| `bitacora.pdf` | Pasos, capturas o salidas, fecha, entorno y conclusiones (`bitacora_resuelta.md` como base) |
| `admin.txt` | **Solo** los comandos ejecutados en `mongosh`: creación de usuarios, asignación de permisos y pruebas |
| `restore.txt` | Comandos de consola/herramientas, conteos antes y después y verificación |

Lista de control:
- [ ] El zip **no** incluye `backup_u8_g11/`, ni `*.bson`, ni certificados ni claves.
- [ ] `admin.txt` incluye la **creación** de `u8_g11_lector` y `u8_g11_operador` y las 4 pruebas de la tabla mínima, cada una indicando con qué usuario se ejecuta.
- [ ] Ninguna contraseña real en los archivos (usar `passwordPrompt()` o un marcador).
- [ ] Los recuentos "antes" y "después" del respaldo coinciden (y se explica cualquier diferencia).
- [ ] La bitácora indica **MongoDB** como motor y el `bindIp` coincide con la captura.

## D. Limpieza
```javascript
db.getSiblingDB("u8_g11_restore").dropDatabase()      // la base alternativa; NUNCA dropDatabase sobre u8_g11
db.getSiblingDB("u8_g11").prueba_borrado.drop()       // si se dejó la colección de prueba
```
```bash
rm -rf ~/backup_u8_g11                                 # el respaldo contiene datos: no se deja suelto
sudo cp /etc/mongod.conf.bak /etc/mongod.conf          # solo si se quiere volver a la configuración inicial
```

## E. Problemas frecuentes
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `Authentication failed` con el usuario correcto | Base de autenticación equivocada (el usuario está en `u8_g11` y se pasó `admin`) o clave incorrecta | `--authenticationDatabase u8_g11` para lector y operador; `admin` para el administrador |
| `Unauthorized` recién creado el rol | El usuario sigue con la sesión anterior | Cerrar y reconectar: los privilegios se aplican a conexiones nuevas |
| `mongod` no arranca después de editar el `.conf` | YAML mal indentado, ruta de certificado errónea, permisos | `sudo tail -30 /var/log/mongodb/mongod.log`; restaurar `mongod.conf.bak` |
| `self-signed certificate in certificate chain` | El cliente no tiene la CA | `--tlsCAFile ca.crt` |
| `Hostname/IP does not match certificate's altnames` | El SAN no incluye la IP o el nombre usados | Regenerar el certificado con el SAN correcto |
| `connection <monitor> to ...:27017 closed` contra un servidor con TLS | El cliente no usa TLS (o falta su certificado en TLS mutuo) | Agregar `--tls --tlsCAFile ...`; revisar `allowConnectionsWithoutCertificates` |
| `E11000 duplicate key` al restaurar | El destino ya tiene datos | Restaurar en una base vacía o usar `--drop` con cuidado |
| `The --db and --collection flags are deprecated` | Uso de la forma antigua | `--nsInclude`, `--nsFrom`, `--nsTo` |
| `mongodump` falla con `not authorized` | El usuario no tiene el rol `backup` o se autenticó en otra base | Rol `backup` en `admin` y `--authenticationDatabase admin` |
| El recuento antes y después del respaldo no coincide | Se insertó un documento de prueba (o alguien escribió) | Registrar el recuento **justo antes** del dump y buscar documentos de prueba |
| `bind` en `0.0.0.0` y el puerto sigue accesible tras cambiar `bindIp` | No se reinició o hay otra instancia | `sudo systemctl restart mongod`; `ss -ltnp \| grep 27017` |
