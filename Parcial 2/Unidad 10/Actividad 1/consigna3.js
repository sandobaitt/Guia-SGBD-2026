// =============================================================================
// U10 - ACTIVIDAD 1 · Consigna 3: CRUD en MongoDB Atlas (plan Free M0)
// GRUPO 11 · base practicaU10 · colección productos
//
// Uso (sin claves en el archivo; mongosh pide la contraseña):
//   mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 \
//           --username admin_grupo11 --file consigna3.js
//
// Nota: dentro de un archivo, "use practicaU10" no cambia de base; se usa db.getSiblingDB().
// =============================================================================

db = db.getSiblingDB("practicaU10");
db.productos.drop();   // permite repetir el script desde cero

// 1. CREATE: insertar 5 productos (la colección se crea con la primera inserción)
print("\n--- 1. CREATE: insertMany de 5 productos");
printjson(db.productos.insertMany([
  { codigo: "PROD-01", nombre: "Notebook Dell Inspiron", categoria: "Computación", precio: 850000, stock: 10, disponible: true },
  { codigo: "PROD-02", nombre: "Mouse Inalámbrico Logitech", categoria: "Periféricos", precio: 25000, stock: 45, disponible: true },
  { codigo: "PROD-03", nombre: "Monitor Samsung 24 pulgadas", categoria: "Monitores", precio: 210000, stock: 8, disponible: true },
  { codigo: "PROD-04", nombre: "Teclado Mecánico Redragon", categoria: "Periféricos", precio: 65000, stock: 0, disponible: false },
  { codigo: "PROD-05", nombre: "Auriculares Bluetooth", categoria: "Audio", precio: 42000, stock: 15, disponible: true }
]));
print("countDocuments() → " + db.productos.countDocuments());

// 2. READ: productos disponibles con precio >= 50000
print("\n--- 2. READ: disponibles con precio >= 50000");
printjson(db.productos.find({ disponible: true, precio: { $gte: 50000 } }).toArray());

// 3. UPDATE: stock, disponibilidad y precio del teclado mecánico
print("\n--- 3. UPDATE: PROD-04");
printjson(db.productos.updateOne(
  { codigo: "PROD-04" },
  { $set: { stock: 12, disponible: true, precio: 68000 } }
));
printjson(db.productos.findOne({ codigo: "PROD-04" }));

// 4. DELETE: eliminar un producto discontinuado
print("\n--- 4. DELETE: PROD-05");
printjson(db.productos.deleteOne({ codigo: "PROD-05" }));
print("countDocuments() → " + db.productos.countDocuments());
print("findOne({ codigo: 'PROD-05' }) → " + JSON.stringify(db.productos.findOne({ codigo: "PROD-05" })));
