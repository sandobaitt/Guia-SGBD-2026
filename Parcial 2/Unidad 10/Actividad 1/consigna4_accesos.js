// =============================================================================
// U10 - ACTIVIDAD 1 · Consigna 4: Accesos en MongoDB Atlas (plan Free M0)
// GRUPO 11 · base practicaU10
//
// Se ejecuta DOS veces, con cada identidad (mongosh pide la contraseña):
//   A) Lector (privilegio específico: read sobre practicaU10.productos):
//      mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 \
//              --username lector_g11 --file consigna4_accesos.js
//   B) Administrador (atlasAdmin):
//      mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 \
//              --username admin_grupo11 --file consigna4_accesos.js
// =============================================================================

const d = db.getSiblingDB("practicaU10");
const yo = db.runCommand({ connectionStatus: 1 }).authInfo;
print("\nUsuario autenticado: " + JSON.stringify(yo.authenticatedUsers));
print("Roles              : " + JSON.stringify(yo.authenticatedUserRoles));

function probar(descripcion, accion) {
  try { const r = accion(); print("[PERMITIDA] " + descripcion + " → " + JSON.stringify(r)); }
  catch (e) { print("[RECHAZADA] " + descripcion + " → " + (e.codeName ? e.codeName + ": " : "") + e.message); }
}

if (yo.authenticatedUsers[0].user === "lector_g11") {
  print("\n--- Identidad restringida: lector_g11");
  probar("find() sobre practicaU10.productos",
    () => d.productos.find({}, { _id: 0, codigo: 1, precio: 1 }).sort({ codigo: 1 }).toArray());
  probar("insertOne() sobre practicaU10.productos",
    () => d.productos.insertOne({ codigo: "PROD-99", nombre: "Notebook ASUS", precio: 100000 }));
  print("countDocuments() → " + d.productos.countDocuments() + " (sin cambios)");
} else {
  print("\n--- Permisos del motor frente a permisos de la plataforma");
  print("En la VM (U8) los usuarios se creaban con db.createUser(). En Atlas, aun siendo atlasAdmin:");
  probar("db.createUser() desde mongosh",
    () => db.getSiblingDB("admin").createUser({ user: "prueba_g11", pwd: "NoSeCrea#2026", roles: [{ role: "read", db: "practicaU10" }] }));
}
