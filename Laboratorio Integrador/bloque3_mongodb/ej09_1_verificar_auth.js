// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.1 - Verificación de la autenticación (con authorization: enabled)
//   mongosh --quiet --file ej09_1_verificar_auth.js
// Forma interactiva equivalente (pide la clave):
//   mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u admin_g11
// =============================================================================

// 1. Sin credenciales: el servidor rechaza los comandos que requieren autorización
print("--- 1. Conexión SIN autenticar ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);
try {
  db.adminCommand({ listDatabases: 1 });
} catch (e) {
  print("listDatabases sin autenticar -> " + e.codeName + ": " + e.message);
}

// 2. Autenticación contra la base admin
print("\n--- 2. Autenticación como admin_g11 ---");
const ok = db.getSiblingDB("admin").auth("admin_g11", process.env.MONGO_ADMIN_PWD || passwordPrompt());
print("db.auth() -> " + JSON.stringify(ok));

// 3. Identidad y roles de la sesión autenticada
print("\n--- 3. connectionStatus autenticado ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);

print("\n--- 4. Comando administrativo permitido ---");
printjson(db.adminCommand({ listDatabases: 1, nameOnly: true }).databases.map(d => d.name));
