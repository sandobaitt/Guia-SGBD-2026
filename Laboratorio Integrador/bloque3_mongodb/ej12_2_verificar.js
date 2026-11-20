// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 12.2 - Comparación entre LabMongoDB y LabMongoDB_Restore
//   mongosh "mongodb://127.0.0.1:27017/admin" --authenticationDatabase admin -u adminG11 --file ej12_2_verificar.js
// =============================================================================
const orig = db.getSiblingDB("LabMongoDB"), rest = db.getSiblingDB("LabMongoDB_Restore");

print("Colección     LabMongoDB  LabMongoDB_Restore  Índices(orig/rest)  ¿Igual?");
orig.getCollectionNames().sort().forEach(c => {
  const a = orig.getCollection(c).countDocuments(), b = rest.getCollection(c).countDocuments();
  const ia = orig.getCollection(c).getIndexes().length, ib = rest.getCollection(c).getIndexes().length;
  print(c.padEnd(12) + String(a).padStart(11) + String(b).padStart(20) +
        (ia + "/" + ib).padStart(20) + "  " + (a === b && ia === ib ? "SÍ" : "NO"));
});

// La regla $jsonSchema del 12.1 viaja en el .metadata.json y queda activa en la copia
const v = rest.getCollectionInfos({ name: "tiendas" })[0].options;
print("\nValidador en LabMongoDB_Restore.tiendas: " + (v.validator ? "presente (" + v.validationAction + ")" : "NO"));

// El mismo pipeline del Ejercicio 11 sobre la copia da el mismo primer puesto
printjson(rest.clientes.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" }, { $match: { "pais.geography.Continent": "South America" } },
  { $unwind: "$Rentals" }, { $group: { _id: "$Rentals.Film Title", alquileres: { $sum: 1 } } },
  { $sort: { alquileres: -1, _id: 1 } }, { $limit: 1 }
]).toArray());
