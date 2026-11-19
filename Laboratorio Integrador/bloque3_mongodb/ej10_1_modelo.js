// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 10.1 - Evidencia para el diseño del esquema (embedding vs referencing)
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej10_1_modelo.js
// Mide el tamaño de los documentos y de los arreglos embebidos, y verifica que
// las referencias entre colecciones apunten a documentos existentes.
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const medir = (coleccion, arreglo) => db.getCollection(coleccion).aggregate([
  { $project: { b: { $bsonSize: "$$ROOT" }, n: { $size: "$" + arreglo } } },
  { $group: { _id: null, docs: { $sum: 1 }, b_prom: { $avg: "$b" }, b_max: { $max: "$b" },
              n_prom: { $avg: "$n" }, n_max: { $max: "$n" } } }
]).toArray()[0];

print("1. EMBEBIDOS: tamaño de documentos y arreglos (límite de un documento BSON: 16 MB)\n");
print("Colección  Arreglo embebido  Docs  Elem.prom  Elem.max  KB prom  KB max");
[["customers", "Rentals"], ["films", "Actors"], ["stores", "Inventory"]].forEach(([c, a]) => {
  const m = medir(c, a);
  print(c.padEnd(10) + "  " + a.padEnd(16) + String(m.docs).padStart(6) +
        m.n_prom.toFixed(1).padStart(11) + String(m.n_max).padStart(10) +
        (m.b_prom / 1024).toFixed(1).padStart(9) + (m.b_max / 1024).toFixed(1).padStart(8));
});
const pagos = db.customers.aggregate([{ $unwind: "$Rentals" },
  { $group: { _id: null, max: { $max: { $size: "$Rentals.Payments" } } } }]).toArray()[0].max;
print("Pagos por alquiler (máximo): " + pagos);

print("\n2. REFERENCIAS: ¿apuntan a documentos existentes?\n");
const huerfanos = (desde, campo, unwind, hacia, clave) => db.getCollection(desde).aggregate([
  ...(unwind ? [{ $unwind: "$" + unwind }] : []),
  { $group: { _id: "$" + campo } },
  { $lookup: { from: hacia, localField: "_id", foreignField: clave, as: "x" } },
  { $group: { _id: null, distintos: { $sum: 1 }, sin_destino: { $sum: { $cond: [{ $eq: [{ $size: "$x" }, 0] }, 1, 0] } } } }
]).toArray()[0];
[
  ["customers.Rentals.filmId -> films._id", "customers", "Rentals.filmId", "Rentals", "films", "_id"],
  ["stores.Inventory.filmId  -> films._id", "stores", "Inventory.filmId", "Inventory", "films", "_id"],
  ["customers.Country        -> paises.Name", "customers", "Country", null, "paises", "Name"],
  ["ciudades.CodP            -> paises.Code", "ciudades", "CodP", null, "paises", "Code"]
].forEach(([t, ...r]) => { const h = huerfanos(...r); print(t + "   valores distintos: " + h.distintos + "   sin destino: " + h.sin_destino); });

print("\n3. Veces que se repite cada película en los alquileres (si se embebiera completa)");
printjson(db.customers.aggregate([{ $unwind: "$Rentals" }, { $group: { _id: "$Rentals.filmId", n: { $sum: 1 } } },
  { $group: { _id: null, alquileres: { $sum: "$n" }, peliculas: { $sum: 1 }, max_repeticiones: { $max: "$n" } } },
  { $project: { _id: 0 } }]).toArray()[0]);
