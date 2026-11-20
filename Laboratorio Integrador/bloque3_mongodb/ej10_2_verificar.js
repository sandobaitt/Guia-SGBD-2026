// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 10.2 - Verificación de las colecciones auxiliares ciudades y paises
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u adminG11 --file ej10_2_verificar.js
// =============================================================================
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto

print("Colecciones: " + JSON.stringify(db.getCollectionNames().sort()));
print("ciudades: " + db.ciudades.countDocuments() + "   (esperado 4079)");
print("paises:   " + db.paises.countDocuments() + "   (esperado 239)");

print("\n--- Una ciudad y su país (referencia CodP -> Code) ---");
printjson(db.ciudades.findOne({ Ciudad: "Resistencia" }, { _id: 0 }));
printjson(db.paises.findOne({ Code: "ARG" }, { _id: 0, Code: 1, Name: 1, geography: 1 }));

print("\n--- Países de América del Sur (filtro del Ejercicio 11) ---");
db.paises.find({ "geography.Continent": "South America" }, { _id: 0, Code: 1, Name: 1 })
  .sort({ Name: 1 }).forEach(p => print("  " + p.Code + "  " + p.Name));

print("\n--- Clientes cuyo Country no tiene país en paises (esperado: solo Runion) ---");
printjson(db.clientes.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "p" } },
  { $match: { p: { $size: 0 } } },
  { $group: { _id: "$Country", clientes: { $sum: 1 } } }
]).toArray());

// Índices de apoyo para los $lookup del Ejercicio 11 (paises.Name) y para ciudades por país
print("\n--- Índices de apoyo ---");
print(db.paises.createIndex({ Name: 1 }) + " / " + db.ciudades.createIndex({ CodP: 1 }));
