// =============================================================================
// U8 - ACTIVIDAD 2 · Guardia DBA MongoDB
// GRUPO 11 · Comandos de mongosh, organizados por fases
//
// Cada fase se ejecuta con la identidad que corresponda y se elige con la variable
// de entorno FASE (las contraseñas de laboratorio llegan por variables de entorno):
//
//   FASE=diagnostico        mongosh <uri> --file solucion_u8_actividad2_mongosh.js
//   FASE=crear_admin        (instancia SIN autenticación aún; excepción de localhost)
//   FASE=rbac               (como adminG11) crea lector, operador y respaldo
//   FASE=pruebas ROL=...    (ROL = anonimo | lector | operador | respaldo)
//   FASE=incidente          (como lector) diagnóstico de las tres capas
//   FASE=incidente_corregido (como adminG11) corrige el permiso y verifica
//   FASE=preparar_borrado / borrar_prueba / comparar   (respaldo y recuperación)
//
// Nota: con "use" en un archivo, mongosh --file no ejecuta nada (sin error ni salida); se usa db.getSiblingDB().
// =============================================================================

const FASE = process.env.FASE || "ayuda";
const ROL = process.env.ROL || "";
const BASE = "u8_g11";
const PWD_ADMIN = process.env.PWD_ADMIN || "LabG11-Admin#2026";
const PWD_LECTOR = process.env.PWD_LECTOR || "LabG11-Lector#2026";
const PWD_OPERADOR = process.env.PWD_OPERADOR || "LabG11-Operador#2026";
const PWD_RESPALDO = process.env.PWD_RESPALDO || "LabG11-Respaldo#2026";
const PWD_RESTAURADOR = process.env.PWD_RESTAURADOR || "LabG11-Restaurador#2026";

function titulo(t) { print("\n" + "=".repeat(78) + "\n" + t + "\n" + "=".repeat(78)); }
function sub(t) { print("\n--- " + t); }
function mostrar(x) { print(JSON.stringify(x, null, 2)); }
function resumen(r) {
  if (r === null || r === undefined) return "";
  if (r.insertedId !== undefined && r.insertedId !== null) return "insertedId: " + r.insertedId;
  if (r.modifiedCount !== undefined) return "matchedCount: " + r.matchedCount + ", modifiedCount: " + r.modifiedCount;
  if (r.deletedCount !== undefined) return "deletedCount: " + r.deletedCount;
  if (Array.isArray(r)) return r.length + " documento(s)";
  if (typeof r === "object") { const s = JSON.stringify(r); return s.length > 140 ? s.slice(0, 140) + "..." : s; }
  return String(r);
}
// Ejecuta una acción y compara el resultado con el esperado (PERMITIDA / DENEGADA).
function probar(descripcion, esperado, accion) {
  let obtenido, detalle;
  try { detalle = resumen(accion()); obtenido = "PERMITIDA"; }
  catch (e) { obtenido = "DENEGADA"; detalle = "código " + e.code + " " + e.codeName + " — " + String(e.message).slice(0, 170); }
  print((obtenido === esperado ? "[OK]    " : "[FALLO] ") + descripcion);
  print("         esperado: " + esperado + " | obtenido: " + obtenido + " | " + detalle);
  return obtenido === esperado;
}

// =============================================================================
if (FASE === "diagnostico") {
  titulo("1. DIAGNÓSTICO DE LA INSTANCIA");
  const admin = db.getSiblingDB("admin");
  const opts = admin.adminCommand({ getCmdLineOpts: 1 });
  const hello = admin.hello();
  const ss = admin.serverStatus();
  sub("1.1 Servidor y estado");
  mostrar({ version: db.version(), host: ss.host, pid: Number(ss.pid), uptime_segundos: Number(ss.uptime), motor_almacenamiento: ss.storageEngine.name,
            modo: hello.setName ? "replica set " + hello.setName : "standalone",
            conexiones: { actuales: ss.connections.current, disponibles: ss.connections.available }, fecha: new Date().toISOString() });
  sub("1.2 Configuración efectiva (getCmdLineOpts)");
  mostrar(opts.parsed);
  sub("1.3 Autenticación y escucha de red");
  const sec = opts.parsed.security || {};
  const net = opts.parsed.net || {};
  print("security.authorization : " + (sec.authorization || "(no configurado => disabled: cualquier cliente puede operar)"));
  print("net.port               : " + (net.port || 27017));
  print("net.bindIp             : " + (net.bindIp || "127.0.0.1 (por defecto)"));
  print("net.tls.mode           : " + ((net.tls && net.tls.mode) || "(no configurado => disabled: tráfico en texto plano)"));
  sub("1.4 Bases de datos y colecciones");
  mostrar(admin.adminCommand({ listDatabases: 1 }).databases.map(d => ({ base: d.name, tamano_KiB: Math.round(d.sizeOnDisk / 1024) })));
  const lab = db.getSiblingDB(BASE);
  mostrar(lab.getCollectionNames().map(c => ({ coleccion: c, documentos: lab.getCollection(c).countDocuments({}), indices: lab.getCollection(c).getIndexes().map(i => i.name) })));
  sub("1.5 Usuarios definidos");
  print("admin.system.users: " + admin.getUsers().users.length + " usuario(s) | " + BASE + ": " + lab.getUsers().users.length + " usuario(s)");
}

// =============================================================================
if (FASE === "crear_admin") {
  titulo("2. AUTENTICACIÓN: creación del usuario administrador (antes de activar el control de acceso)");
  const admin = db.getSiblingDB("admin");
  mostrar(admin.createUser({
    user: "adminG11",
    pwd: PWD_ADMIN,
    roles: [{ role: "userAdminAnyDatabase", db: "admin" }, { role: "readWriteAnyDatabase", db: "admin" }, { role: "clusterMonitor", db: "admin" }]
  }));
  mostrar(admin.getUsers().users.map(u => ({ usuario: u.user, base: u.db, roles: u.roles })));
}

// =============================================================================
if (FASE === "rbac") {
  titulo("3. RBAC: creación de usuarios con mínimo privilegio (como adminG11)");
  const lab = db.getSiblingDB(BASE);
  mostrar(lab.createUser({ user: "u8_g11_lector", pwd: PWD_LECTOR, roles: [{ role: "read", db: BASE }] }));
  mostrar(lab.createUser({ user: "u8_g11_operador", pwd: PWD_OPERADOR, roles: [{ role: "readWrite", db: BASE }] }));
  sub("Usuarios de respaldo y de restauración SEPARADOS (roles integrados backup y restore, definidos en admin)");
  mostrar(db.getSiblingDB("admin").createUser({ user: "u8_g11_respaldo", pwd: PWD_RESPALDO, roles: [{ role: "backup", db: "admin" }] }));
  mostrar(db.getSiblingDB("admin").createUser({ user: "u8_g11_restaurador", pwd: PWD_RESTAURADOR, roles: [{ role: "restore", db: "admin" }] }));
  sub("Usuarios y roles resultantes");
  mostrar(lab.getUsers().users.map(u => ({ usuario: u.user, base: u.db, roles: u.roles })));
  mostrar(db.getSiblingDB("admin").getUsers().users.map(u => ({ usuario: u.user, base: u.db, roles: u.roles })));
}

// =============================================================================
if (FASE === "pruebas") {
  titulo("PRUEBAS DE ACCESO · identidad: " + ROL);
  const lab = db.getSiblingDB(BASE);
  const estado = db.adminCommand({ connectionStatus: 1 }).authInfo;
  print("Usuarios autenticados en esta conexión: " + (estado.authenticatedUsers.length ? estado.authenticatedUsers.map(u => u.user + "@" + u.db).join(", ") : "(ninguno)"));
  print("Roles efectivos: " + (estado.authenticatedUserRoles.length ? estado.authenticatedUserRoles.map(r => r.role + "@" + r.db).join(", ") : "(ninguno)"));
  let ok = [];
  if (ROL === "anonimo") {
    ok.push(probar("Conexión sin credenciales: ping", "PERMITIDA", () => db.adminCommand({ ping: 1 })));
    ok.push(probar("Sin credenciales: find() sobre envios", "DENEGADA", () => lab.envios.find({}).limit(1).toArray()));
    ok.push(probar("Sin credenciales: listDatabases", "DENEGADA", () => db.adminCommand({ listDatabases: 1 })));
    ok.push(probar("Sin credenciales: insertOne", "DENEGADA", () => lab.envios.insertOne({ _id: "ENV-ANONIMO" })));
    ok.push(probar("Sin credenciales: createUser", "DENEGADA", () => lab.createUser({ user: "intruso", pwd: "x", roles: ["read"] })));
  }
  if (ROL === "lector") {
    ok.push(probar("LECTOR · find()", "PERMITIDA", () => lab.envios.find({}, { _id: 1, tracking_code: 1, estado_actual: 1 }).limit(2).toArray()));
    ok.push(probar("LECTOR · insertOne()", "DENEGADA", () => lab.envios.insertOne({ _id: "ENV-TEST-DENIED", tracking_code: "TRK-X" })));
    ok.push(probar("LECTOR · updateOne()", "DENEGADA", () => lab.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones: "x" } })));
    ok.push(probar("LECTOR · deleteOne()", "DENEGADA", () => lab.envios.deleteOne({ _id: "ENV-2026-001" })));
    ok.push(probar("LECTOR · drop() de la colección", "DENEGADA", () => lab.envios.drop()));
    ok.push(probar("LECTOR · createIndex()", "DENEGADA", () => lab.envios.createIndex({ tracking_code: 1 })));
    ok.push(probar("LECTOR · createUser()", "DENEGADA", () => lab.createUser({ user: "otro", pwd: "x", roles: ["read"] })));
    ok.push(probar("LECTOR · leer otra base (admin.system.users)", "DENEGADA", () => db.getSiblingDB("admin").system.users.find().limit(1).toArray()));
    sub("Bases visibles para el lector (listDatabases con nameOnly)");
    print(JSON.stringify(db.adminCommand({ listDatabases: 1, nameOnly: true }).databases.map(d => d.name)));
  }
  if (ROL === "operador") {
    ok.push(probar("OPERADOR · find()", "PERMITIDA", () => lab.envios.find({}, { _id: 1, estado_actual: 1 }).limit(2).toArray()));
    ok.push(probar("OPERADOR · updateOne() (agrega observaciones_operador)", "PERMITIDA", () => lab.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones_operador: "Verificación de control RBAC" } })));
    ok.push(probar("OPERADOR · updateOne() (revierte el cambio con $unset)", "PERMITIDA", () => lab.envios.updateOne({ _id: "ENV-2026-001" }, { $unset: { observaciones_operador: "" } })));
    ok.push(probar("OPERADOR · insertOne() en envios", "PERMITIDA", () => lab.envios.insertOne({ _id: "ENV-TEST-OPERADOR", tracking_code: "TRK-OP" })));
    ok.push(probar("OPERADOR · deleteOne() del documento de prueba", "PERMITIDA", () => lab.envios.deleteOne({ _id: "ENV-TEST-OPERADOR" })));
    ok.push(probar("OPERADOR · createUser()", "DENEGADA", () => lab.createUser({ user: "usuario_no_autorizado", pwd: "x", roles: [{ role: "read", db: BASE }] })));
    ok.push(probar("OPERADOR · grantRolesToUser() (escalar sus propios privilegios a dbOwner)", "DENEGADA", () => lab.grantRolesToUser("u8_g11_operador", [{ role: "dbOwner", db: BASE }])));
    ok.push(probar("OPERADOR · getUsers()", "DENEGADA", () => lab.getUsers()));
    ok.push(probar("OPERADOR · leer otra base (admin.system.users)", "DENEGADA", () => db.getSiblingDB("admin").system.users.find().limit(1).toArray()));
    ok.push(probar("OPERADOR · serverStatus()", "DENEGADA", () => db.adminCommand({ serverStatus: 1 })));
    sub("Recuento final de envios (debe seguir siendo el original)");
    print("envios: " + lab.envios.countDocuments({}));
  }
  if (ROL === "respaldo") {
    ok.push(probar("RESPALDO · find() (necesario para mongodump)", "PERMITIDA", () => lab.envios.find({}).limit(1).toArray()));
    ok.push(probar("RESPALDO · insertOne() en u8_g11", "DENEGADA", () => lab.envios.insertOne({ _id: "ENV-TEST-RESPALDO" })));
    ok.push(probar("RESPALDO · createUser()", "DENEGADA", () => lab.createUser({ user: "x", pwd: "x", roles: ["read"] })));
    ok.push(probar("RESPALDO · deleteOne()", "DENEGADA", () => lab.envios.deleteOne({ _id: "ENV-2026-001" })));
  }
  if (ROL === "restaurador") {
    print("OBSERVACIÓN: el rol integrado 'restore' es AMPLIO (necesita escribir en cualquier colección para restaurar).");
    ok.push(probar("RESTAURADOR · insertOne() en una colección de prueba", "PERMITIDA", () => lab.prueba_restaurador.insertOne({ _id: 1 })));
    ok.push(probar("RESTAURADOR · createUser() (consecuencia de un rol amplio)", "PERMITIDA", () => lab.createUser({ user: "temporal_restaurador", pwd: "x", roles: ["read"] })));
    lab.prueba_restaurador.drop(); try { lab.dropUser("temporal_restaurador"); } catch (e) {}
    print("(limpieza: colección y usuario de prueba eliminados) => usarlo SOLO durante una recuperación y no dejarlo habilitado.");
  }
  const aciertos = ok.filter(x => x).length;
  print("\nRESULTADO: " + aciertos + " de " + ok.length + " pruebas coinciden con lo esperado");
}

// =============================================================================
if (FASE === "incidente") {
  titulo("6. INCIDENTE: «puedo leer con find() pero no puedo modificar un documento»");
  const lab = db.getSiblingDB(BASE);
  sub("Capa 1 · CONEXIÓN (¿llega al servidor?): ping y hello no exigen autenticación");
  mostrar({ ping: db.adminCommand({ ping: 1 }).ok, hello_ok: db.hello().isWritablePrimary, maxBsonObjectSize: db.hello().maxBsonObjectSize });
  sub("Capa 2 · AUTENTICACIÓN (¿quién es?): connectionStatus");
  const info = db.adminCommand({ connectionStatus: 1, showPrivileges: true }).authInfo;
  mostrar({ usuario_autenticado: info.authenticatedUsers, roles: info.authenticatedUserRoles });
  sub("Capa 3 · AUTORIZACIÓN (¿qué puede hacer?): acciones concedidas sobre " + BASE);
  const privBase = info.authenticatedUserPrivileges.filter(p => p.resource.db === BASE && !p.resource.collection);
  mostrar(privBase.map(p => ({ recurso: p.resource, acciones: p.actions })));
  sub("Prueba funcional: lectura y escritura con la misma conexión");
  probar("find() sobre envios", "PERMITIDA", () => lab.envios.find({}).limit(1).toArray());
  probar("updateOne() sobre envios", "DENEGADA", () => lab.envios.updateOne({ _id: "ENV-2026-001" }, { $set: { observaciones: "x" } }));
  print("\nDiagnóstico: la conexión y la autenticación son correctas; falla la AUTORIZACIÓN: el rol 'read' no incluye las acciones insert, update ni remove.");
}

if (FASE === "incidente_corregido") {
  titulo("6b. CORRECCIÓN DEL INCIDENTE (como adminG11) y verificación");
  const lab = db.getSiblingDB(BASE);
  sub("Roles de u8_g11_lector ANTES");
  mostrar(lab.getUser("u8_g11_lector").roles);
  mostrar(lab.grantRolesToUser("u8_g11_lector", [{ role: "readWrite", db: BASE }]));
  sub("Roles de u8_g11_lector DESPUÉS");
  mostrar(lab.getUser("u8_g11_lector").roles);
  print("(Los privilegios se aplican a las conexiones NUEVAS: el usuario debe reconectar.)");
}
if (FASE === "incidente_revertir") {
  titulo("6c. REVERSIÓN: se restablece el rol 'read' (principio de mínimo privilegio)");
  const lab = db.getSiblingDB(BASE);
  mostrar(lab.revokeRolesFromUser("u8_g11_lector", [{ role: "readWrite", db: BASE }]));
  mostrar(lab.getUser("u8_g11_lector").roles);
}

// =============================================================================
if (FASE === "preparar_borrado") {
  titulo("5a. PREPARACIÓN DEL BORRADO CONTROLADO: colección de prueba prueba_borrado");
  const lab = db.getSiblingDB(BASE);
  lab.prueba_borrado.drop();
  lab.envios.aggregate([{ $match: { estado_actual: { $in: ["Entregado", "Demorado"] } } }, { $out: "prueba_borrado" }]);
  lab.prueba_borrado.createIndex({ estado_actual: 1 });
  print("prueba_borrado: " + lab.prueba_borrado.countDocuments({}) + " documentos, índices: " + lab.prueba_borrado.getIndexes().map(i => i.name).join(", "));
}
if (FASE === "borrar_prueba") {
  titulo("5c. INCIDENTE CONTROLADO: se elimina la colección de prueba (NO la base)");
  const lab = db.getSiblingDB(BASE);
  print("Antes : colecciones = " + lab.getCollectionNames().join(", "));
  print("drop(prueba_borrado) -> " + lab.prueba_borrado.drop());
  print("Después: colecciones = " + lab.getCollectionNames().join(", "));
  print("prueba_borrado existe: " + lab.getCollectionNames().includes("prueba_borrado"));
}

// =============================================================================
if (FASE === "comparar") {
  const ORIGEN = process.env.ORIGEN || BASE;
  const DESTINO = process.env.DESTINO || "u8_g11_restore";
  const COLECCIONES = (process.env.COLECCIONES || "envios,eventos_seguimiento").split(",");
  titulo("VALIDACIÓN: " + ORIGEN + " frente a " + DESTINO);
  const o = db.getSiblingDB(ORIGEN), d = db.getSiblingDB(DESTINO);
  const hashO = o.runCommand({ dbHash: 1, collections: COLECCIONES }).collections;
  const hashD = d.runCommand({ dbHash: 1, collections: COLECCIONES }).collections;
  let todo = true;
  for (const c of COLECCIONES) {
    const nO = o[c].countDocuments({}), nD = d[c].countDocuments({});
    const A = {}; o[c].find().forEach(x => A[x._id] = EJSON.stringify(x));
    let distintos = 0, faltan = 0;
    d[c].find().forEach(x => { if (!(x._id in A)) distintos++; else if (A[x._id] !== EJSON.stringify(x)) distintos++; });
    faltan = Object.keys(A).length - d[c].countDocuments({ _id: { $in: Object.keys(A) } });
    const idxO = o[c].getIndexes().map(i => i.name + JSON.stringify(i.key)).sort().join(" "), idxD = d[c].getIndexes().map(i => i.name + JSON.stringify(i.key)).sort().join(" ");
    const iguales = nO === nD && distintos === 0 && faltan === 0 && hashO[c] === hashD[c] && idxO === idxD;
    todo = todo && iguales;
    sub("Colección " + c);
    print("Documentos           : origen " + nO + " | destino " + nD);
    print("Documentos distintos : " + distintos + " | faltantes en destino: " + faltan + "  (comparación documento a documento, EJSON)");
    print("dbHash (md5)         : origen " + hashO[c] + " | destino " + hashD[c]);
    print("Índices              : " + (idxO === idxD ? "idénticos -> " + idxD : "DIFERENTES\n   origen : " + idxO + "\n   destino: " + idxD));
    print((iguales ? "[OK]    " : "[FALLO] ") + "Recuperación " + (iguales ? "íntegra" : "con diferencias"));
  }
  print("\nRESULTADO GLOBAL: " + (todo ? "RECUPERACIÓN VERIFICADA (conteos, contenido, hash e índices)" : "HAY DIFERENCIAS"));
}

if (FASE === "ayuda") {
  print("Definir FASE=diagnostico|crear_admin|rbac|pruebas|incidente|incidente_corregido|incidente_revertir|preparar_borrado|borrar_prueba|comparar");
}
