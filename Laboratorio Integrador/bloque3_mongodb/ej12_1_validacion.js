// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 12.1 - Regla de validación $jsonSchema sobre la colección de tiendas
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u admin_g11 --file ej12_1_validacion.js
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const esquema = {
  bsonType: "object",
  required: ["_id", "Address", "City", "Country", "Inventory"],
  properties: {
    _id:            { bsonType: "int", description: "número de tienda (entero)" },
    Address:        { bsonType: "string", minLength: 1 },
    City:           { bsonType: "string", minLength: 1 },
    Country:        { bsonType: "string", minLength: 1 },
    Phone:          { bsonType: "string" },
    // En stores.json viene como texto ("1"): se valida que sea texto numérico
    managerStaffId: { bsonType: "string", pattern: "^[0-9]+$" },
    Staff:          { bsonType: "array" },
    Inventory: {
      bsonType: "array",
      items: {
        bsonType: "object",
        required: ["filmId", "inventoryId", "Film Title"],
        properties: {
          filmId:       { bsonType: "int" },
          inventoryId:  { bsonType: "int" },
          "Film Title": { bsonType: "string" }
        }
      }
    }
  }
};

// 1. Antes de aplicar la regla: las tiendas existentes deben cumplirla (esperado 0).
//    Si no, mongorestore (12.2) crea la regla antes de cargar los datos y las rechaza.
print("Tiendas que NO cumplen el esquema: " + db.stores.countDocuments({ $nor: [{ $jsonSchema: esquema }] }));

// 2. Aplicar la regla a la colección existente
printjson(db.runCommand({ collMod: "stores", validator: { $jsonSchema: esquema },
                          validationLevel: "strict", validationAction: "error" }));
printjson(db.getCollectionInfos({ name: "stores" })[0].options.validationAction);

const probar = (titulo, doc) => {
  print("\n--- " + titulo + " ---");
  try {
    printjson(db.stores.insertOne(doc));
  } catch (e) {
    print(e.name + ": " + e.message);
    const det = e.errInfo && e.errInfo.details && e.errInfo.details.schemaRulesNotSatisfied;
    if (det) printjson(det);
  }
};

// 3. Inserciones VÁLIDAS
probar("VÁLIDA 1: tienda nueva con un ítem de inventario", {
  _id: 3, Address: "Av. 9 de Julio 1100", City: "Resistencia", Country: "Argentina",
  Phone: "3624000000", Staff: [],
  Inventory: [{ filmId: 1, inventoryId: 9001, "Film Title": "ACADEMY DINOSAUR" }] });
probar("VÁLIDA 2: tienda nueva con inventario vacío", {
  _id: 4, Address: "Junín 1500", City: "Corrientes", Country: "Argentina", Inventory: [] });

// 4. Inserciones INVÁLIDAS
probar("INVÁLIDA 1: falta el campo obligatorio City", {
  _id: 5, Address: "Calle sin ciudad 1", Country: "Argentina", Inventory: [] });
probar("INVÁLIDA 2: filmId del inventario como texto", {
  _id: 6, Address: "Calle 2", City: "Formosa", Country: "Argentina",
  Inventory: [{ filmId: "uno", inventoryId: 9002, "Film Title": "ACADEMY DINOSAUR" }] });

// 5. Resultado y limpieza (se borran las de prueba; la regla queda activa)
print("\nTiendas: " + JSON.stringify(db.stores.find({}, { _id: 1, City: 1 }).sort({ _id: 1 }).toArray()));
print("Borradas las de prueba: " + db.stores.deleteMany({ _id: { $in: [3, 4] } }).deletedCount +
      " | tiendas finales: " + db.stores.countDocuments());
