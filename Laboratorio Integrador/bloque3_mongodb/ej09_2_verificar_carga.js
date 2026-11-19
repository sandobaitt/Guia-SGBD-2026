// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.2 - Verificación de la carga en LabMongoDB
//   mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u admin_g11 --quiet --file ej09_2_verificar_carga.js
// =============================================================================

if (!db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers.length) {
  db.getSiblingDB("admin").auth("admin_g11", process.env.MONGO_ADMIN_PWD || passwordPrompt());
}
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto

print("Base: " + db.getName());
print("Colecciones: " + JSON.stringify(db.getCollectionNames().sort()));

print("\n--- Documentos por colección (esperado: 599 / 1000 / 2) ---");
["clientes", "peliculas", "tiendas"].forEach(c =>
  print(c.padEnd(10) + db.getCollection(c).countDocuments()));

print("\n--- Arreglos anidados (alquileres por cliente, inventario por tienda) ---");
printjson(db.clientes.aggregate([
  { $project: { n: { $size: "$Rentals" } } },
  { $group: { _id: null, clientes: { $sum: 1 }, alquileres: { $sum: "$n" },
              min: { $min: "$n" }, max: { $max: "$n" } } },
  { $project: { _id: 0 } }
]).toArray()[0]);
printjson(db.tiendas.find({}, { _id: 1, City: 1, Country: 1,
  items_inventario: { $size: "$Inventory" }, empleados: { $size: "$Staff" } }).toArray());

print("\n--- Muestra: un cliente (primer alquiler) y una película ---");
printjson(db.clientes.findOne({ _id: 1 },
  { "First Name": 1, "Last Name": 1, City: 1, Country: 1, Rentals: { $slice: 1 } }));
printjson(db.peliculas.findOne({ _id: 1 }, { Actors: 0 }));
