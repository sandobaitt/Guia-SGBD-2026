// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 11 - Aggregation Pipeline: Top 10 de películas más alquiladas en
// América del Sur, vinculando customers (clientes), films (películas) y paises
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej11_pipeline.js
// Resultado esperado = Ejercicio 8.3 (MySQL): mismo orden y desempate por título.
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const pipeline = [
  // 1. Cliente -> país (referencia por nombre: customers.Country = paises.Name)
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" },
  // 2. Solo clientes de América del Sur
  { $match: { "pais.geography.Continent": "South America" } },
  // 3. Un documento por alquiler (el arreglo Rentals está embebido en el cliente)
  { $unwind: "$Rentals" },
  // 4. Alquileres por película y países distintos donde se alquiló
  { $group: { _id: "$Rentals.filmId", alquileres: { $sum: 1 }, paises: { $addToSet: "$pais.Name" } } },
  // 5. Película (referencia filmId -> films._id) para el título y la categoría
  { $lookup: { from: "films", localField: "_id", foreignField: "_id", as: "pelicula" } },
  { $unwind: "$pelicula" },
  { $project: { _id: 0, filmId: "$_id", pelicula: "$pelicula.Title", categoria: "$pelicula.Category",
                alquileres: 1, paises: { $size: "$paises" } } },
  // 6. Mayor cantidad primero; desempate alfabético (13 películas empatan con 6)
  { $sort: { alquileres: -1, pelicula: 1 } },
  { $limit: 10 }
];

const top = db.customers.aggregate(pipeline).toArray();
print("Top 10 de películas más alquiladas en América del Sur\n");
print("Pos  Película                  Categoría     Alq  Países");
top.forEach((p, i) => print(
  String(i + 1).padStart(3) + "  " + p.pelicula.padEnd(24) + "  " + p.categoria.padEnd(12) +
  "  " + String(p.alquileres).padStart(3) + "  " + String(p.paises).padStart(5)));

// Control del empate en el corte: películas con la misma cantidad que el puesto 10
const corte = top[top.length - 1].alquileres;
const empatadas = db.customers.aggregate(pipeline.slice(0, 5).concat([
  { $match: { alquileres: corte } }, { $count: "n" }
])).toArray()[0].n;
print("\nPelículas con " + corte + " alquileres (empate en el corte): " + empatadas);
