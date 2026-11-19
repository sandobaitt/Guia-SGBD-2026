// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 7 - Importación de documentos JSON con util.importJson (MySQL Shell)
// util.importJson requiere una sesión X Protocol (puerto 33060):
//   mysqlsh --mysqlx -u usr_g11 -h 127.0.0.1 -P 33060 --file ej07_2_importar.js
// Los archivos son JSON Lines (un documento por línea), formato que importJson
// acepta directamente. Cada documento se guarda en la columna JSON "doc".
// =============================================================================

const carpeta = os.getenv("DATOS") || os.getenv("HOME") + "/lab_integrador_g11/datos";

for (const tabla of ["customers", "films", "stores"]) {
  print(`\n=== ${tabla}.json -> zakila_json.${tabla}(doc)\n`);
  util.importJson(`${carpeta}/${tabla}.json`, {
    schema: "zakila_json",
    table: tabla,
    tableColumn: "doc"
  });
}
