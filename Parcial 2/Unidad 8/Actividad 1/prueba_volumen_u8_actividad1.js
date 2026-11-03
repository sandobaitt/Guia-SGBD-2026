// =============================================================================
// U8 - ACTIVIDAD 1 · Prueba de volumen para el análisis de índices
// GRUPO 11 · Logística | Distribución interprovincial · MongoDB Community
//
// Con 15 documentos el tiempo de reloj no permite ver el efecto de un índice
// (todo cabe en la caché de WiredTiger). La pauta permite "cargar más datos":
// este script genera 200.000 envíos y 400.000 eventos FICTICIOS en una base
// APARTE (u8_g11_perf), para no alterar u8_g11, que se conserva para la Actividad 2.
//
// Uso:
//   mongosh "mongodb://127.0.0.1:27017" --file prueba_volumen_u8_actividad1.js
//
// Los datos se generan con un generador congruencial con semilla fija, de modo
// que cualquier integrante obtiene exactamente el mismo conjunto.
// Para limpiar al terminar:  db.getSiblingDB("u8_g11_perf").dropDatabase()
// =============================================================================

db = db.getSiblingDB("u8_g11_perf");

function seccion(t) { print("\n" + "=".repeat(78) + "\n" + t + "\n" + "=".repeat(78)); }
function sub(t) { print("\n--- " + t); }
function mostrar(x) { print(JSON.stringify(x, null, 2)); }
const mb = n => Math.round((n / 1048576) * 10) / 10;

// ---- generador reproducible ---------------------------------------------------
let semilla = 20261103;
function azar() { semilla = (semilla * 1664525 + 1013904223) % 4294967296; return semilla / 4294967296; }
function entre(a, b) { return a + Math.floor(azar() * (b - a + 1)); }
function elegir(v) { return v[Math.floor(azar() * v.length)]; }

const RUTAS = ["Resistencia - Rosario", "Resistencia - Salta", "Córdoba - Buenos Aires", "Corrientes - Posadas",
               "Rosario - Tucumán", "Buenos Aires - Concordia", "Mendoza - Córdoba", "Neuquén - Bahía Blanca",
               "Santa Fe - Paraná", "Salta - Jujuy", "Tucumán - Córdoba", "Posadas - Buenos Aires"];
const TRANSPORTISTAS = [
  { id: "TRANS-01", nombre: "Expreso Chaco" }, { id: "TRANS-02", nombre: "Logística del Litoral" },
  { id: "TRANS-03", nombre: "Transportes El Norteño" }, { id: "TRANS-04", nombre: "Vía Entre Ríos" },
  { id: "TRANS-05", nombre: "Cuyo Cargas" }, { id: "TRANS-06", nombre: "Patagonia Express" },
  { id: "TRANS-07", nombre: "Mesopotamia Log" }, { id: "TRANS-08", nombre: "Andes Transporte" } ];
const PROVINCIAS = ["Chaco", "Santa Fe", "Córdoba", "Buenos Aires", "Salta", "Tucumán", "Misiones", "Corrientes", "Entre Ríos", "Mendoza"];
const TIPOS_INTERMEDIOS = ["CONTROL_TRANSITO", "PASO_SUCURSAL", "INCIDENCIA_MECANICA", "CONGESTION_VIAL", "CORTE_CALZADA"];
const INICIO = Date.UTC(2026, 0, 1);

function estadoAleatorio() {
  const r = azar();
  return r < 0.55 ? "Entregado" : r < 0.70 ? "En tránsito" : r < 0.82 ? "Demorado" : r < 0.92 ? "En preparación" : "Cancelado";
}

function generarEnvio(i) {
  const despacho = INICIO + entre(0, 302 * 24) * 3600000;
  const estimada = despacho + entre(24, 72) * 3600000;
  const estado = estadoAleatorio();
  let demora = 0, real = null;
  if (estado === "Demorado") demora = entre(60, 900);
  if (estado === "Entregado") { demora = azar() < 0.3 ? entre(15, 600) : 0; real = new Date(estimada + demora * 60000 - (demora ? 0 : entre(0, 30) * 60000)); }
  const t = elegir(TRANSPORTISTAS);
  const n = entre(1, 4), paquetes = [];
  for (let k = 0; k < n; k++) paquetes.push({ tracking_paquete: "PAQ-" + i + "-" + k, peso_kg: entre(1, 800) / 10, fragil: azar() < 0.25, tipo: elegir(["Repuestos", "Electrónica", "Textil", "Alimentos", "Insumos médicos"]) });
  const id = "ENV-P-" + String(i).padStart(6, "0");
  return { _id: id, tracking_code: "TRK-P-" + i, ruta: elegir(RUTAS), transportista: t,
           origen: { provincia: elegir(PROVINCIAS), localidad: "Origen " + entre(1, 40) },
           destino: { provincia: elegir(PROVINCIAS), localidad: "Destino " + entre(1, 80) },
           fecha_despacho: new Date(despacho), fecha_estimada_entrega: new Date(estimada), fecha_entrega_real: real,
           estado_actual: estado, minutos_demora: demora, paquetes: paquetes };
}
function generarEventos(envio) {
  const t0 = envio.fecha_despacho.getTime();
  return [
    { _id: envio._id + "-E1", envio_id: envio._id, tipo_evento: "DESPACHO", timestamp: new Date(t0), operador: "op_" + entre(1, 30) },
    { _id: envio._id + "-E2", envio_id: envio._id, tipo_evento: elegir(TIPOS_INTERMEDIOS), timestamp: new Date(t0 + entre(2, 20) * 3600000), operador: "op_" + entre(1, 30) }
  ];
}

// ---- utilidades de explain (las mismas que en solucion_u8_actividad1.js) --------
function buscarEtapa(p, n) { while (p) { if (p.stage === n) return p; p = p.inputStage || (p.inputStages ? p.inputStages[0] : null); } return null; }
function ramaPlan(p) { const a = []; while (p) { a.push(p.stage + (p.indexName ? "(" + p.indexName + ")" : "")); p = p.inputStage || (p.inputStages ? p.inputStages[0] : null); } return a.join(" > "); }
function medir(titulo, fabrica, repeticiones) {
  repeticiones = repeticiones || 5;
  const tiempos = []; let ex, primera;
  for (let i = 0; i < repeticiones; i++) {
    ex = fabrica().explain("executionStats");
    tiempos.push(ex.executionStats.executionTimeMillis);
    if (i === 0) primera = ex.executionStats.executionTimeMillis;
  }
  const o = tiempos.slice().sort((a, b) => a - b);
  const wp = ex.queryPlanner.winningPlan.queryPlan || ex.queryPlanner.winningPlan;
  const r = { consulta: titulo, plan_ganador: ramaPlan(wp), ordena_en_memoria: !!buscarEtapa(wp, "SORT"),
              nReturned: ex.executionStats.nReturned, totalKeysExamined: ex.executionStats.totalKeysExamined,
              totalDocsExamined: ex.executionStats.totalDocsExamined, primera_ejecucion_ms: primera,
              ms_min_mediana_max: o[0] + " / " + o[Math.floor(o.length / 2)] + " / " + o[o.length - 1] };
  mostrar(r); return r;
}

// =============================================================================
// 1. GENERACIÓN DE LOS DATOS
// =============================================================================
seccion("1. GENERACIÓN DE 200.000 ENVÍOS Y 400.000 EVENTOS (base u8_g11_perf)");
print("Servidor MongoDB: " + db.version() + " | Fecha: " + new Date().toISOString());
db.dropDatabase();
db = db.getSiblingDB("u8_g11_perf");

const T0 = Date.now();
const N = 200000, LOTE = 5000;
for (let desde = 1; desde <= N; desde += LOTE) {
  const envios = [], eventos = [];
  for (let i = desde; i < desde + LOTE && i <= N; i++) { const e = generarEnvio(i); envios.push(e); generarEventos(e).forEach(x => eventos.push(x)); }
  db.envios.insertMany(envios, { ordered: false });
  db.eventos_seguimiento.insertMany(eventos, { ordered: false });
}
print("Carga terminada en " + Math.round((Date.now() - T0) / 1000) + " s");
print("envios = " + db.envios.countDocuments({}) + " | eventos_seguimiento = " + db.eventos_seguimiento.countDocuments({}));
sub("Distribución por estado");
mostrar(db.envios.aggregate([{ $group: { _id: "$estado_actual", n: { $sum: 1 } } }, { $sort: { n: -1 } }]).toArray());

// =============================================================================
// 2. CONSULTAS ANTES Y DESPUÉS DE LOS ÍNDICES
// =============================================================================
seccion("2. explain(\"executionStats\") A ESCALA");
const filtroQ1 = { ruta: "Resistencia - Rosario",
                   fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lte: ISODate("2026-10-15T23:59:59Z") } };
const filtroQ2 = { estado_actual: "Demorado",
                   fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lt: ISODate("2026-11-01T00:00:00Z") } };
const idBuscado = "ENV-P-100000";

sub("2.1 SIN índices secundarios");
const a1 = medir("Q1 ruta + rango de fechas", () => db.envios.find(filtroQ1));
const a2 = medir("Q2 estado + fecha, orden descendente", () => db.envios.find(filtroQ2).sort({ fecha_despacho: -1 }));
const a3 = medir("Historial de un envío (eventos por envio_id)", () => db.eventos_seguimiento.find({ envio_id: idBuscado }).sort({ timestamp: 1 }));

sub("2.2 Creación de los índices");
let t = Date.now(); print("createIndex envios {ruta:1, fecha_despacho:1}          -> " + db.envios.createIndex({ ruta: 1, fecha_despacho: 1 }) + "  (" + (Date.now() - t) + " ms)");
t = Date.now(); print("createIndex envios {estado_actual:1, fecha_despacho:-1}  -> " + db.envios.createIndex({ estado_actual: 1, fecha_despacho: -1 }) + "  (" + (Date.now() - t) + " ms)");
t = Date.now(); print("createIndex eventos {envio_id:1, timestamp:1}            -> " + db.eventos_seguimiento.createIndex({ envio_id: 1, timestamp: 1 }) + "  (" + (Date.now() - t) + " ms)");

sub("2.3 CON índices");
const d1 = medir("Q1 ruta + rango de fechas", () => db.envios.find(filtroQ1));
const d2 = medir("Q2 estado + fecha, orden descendente", () => db.envios.find(filtroQ2).sort({ fecha_despacho: -1 }));
const d3 = medir("Historial de un envío (eventos por envio_id)", () => db.eventos_seguimiento.find({ envio_id: idBuscado }).sort({ timestamp: 1 }));

sub("2.4 Índice mal ordenado: { fecha_despacho: 1, ruta: 1 } para Q1 (rango primero, igualdad después)");
db.envios.dropIndex("ruta_1_fecha_despacho_1");
db.envios.createIndex({ fecha_despacho: 1, ruta: 1 });
const m1 = medir("Q1 con índice (fecha, ruta) — orden invertido", () => db.envios.find(filtroQ1).hint({ fecha_despacho: 1, ruta: 1 }));
db.envios.dropIndex("fecha_despacho_1_ruta_1");
db.envios.createIndex({ ruta: 1, fecha_despacho: 1 });
print("Se restituyó { ruta: 1, fecha_despacho: 1 }.");

sub("2.5 Resumen (a escala)");
mostrar([
  { consulta: "Q1 ruta + fecha", docs_sin: a1.totalDocsExamined, docs_con: d1.totalDocsExamined, claves_con: d1.totalKeysExamined, devueltos: d1.nReturned, ms_med_sin: a1.ms_min_mediana_max.split(" / ")[1], ms_med_con: d1.ms_min_mediana_max.split(" / ")[1], con_indice_invertido_docs: m1.totalDocsExamined, con_indice_invertido_keys: m1.totalKeysExamined },
  { consulta: "Q2 estado + fecha", docs_sin: a2.totalDocsExamined, docs_con: d2.totalDocsExamined, claves_con: d2.totalKeysExamined, devueltos: d2.nReturned, ms_med_sin: a2.ms_min_mediana_max.split(" / ")[1], ms_med_con: d2.ms_min_mediana_max.split(" / ")[1] },
  { consulta: "Historial de un envío", docs_sin: a3.totalDocsExamined, docs_con: d3.totalDocsExamined, claves_con: d3.totalKeysExamined, devueltos: d3.nReturned, ms_med_sin: a3.ms_min_mediana_max.split(" / ")[1], ms_med_con: d3.ms_min_mediana_max.split(" / ")[1] }
]);

// =============================================================================
// 3. COSTO DE MANTENER LOS ÍNDICES: ESCRITURAS Y ESPACIO
// =============================================================================
seccion("3. COSTO DE LOS ÍNDICES");
sub("3.1 Espacio (colección envios)");
const st = db.runCommand({ collStats: "envios" });
mostrar({ documentos: st.count, tamano_datos_MB: mb(st.size), almacenado_datos_MB: mb(st.storageSize), indices_total_MB: mb(st.totalIndexSize),
          indices_MB: Object.fromEntries(Object.entries(st.indexSizes).map(([k, v]) => [k, mb(v)])) });

sub("3.2 Escritura: insertar 50.000 envíos en una colección SIN índices secundarios y en otra CON 2 índices (3 repeticiones)");
const muestra = []; for (let i = 1000001; i <= 1050000; i++) muestra.push(generarEnvio(i));
function insertar(nombre, conIndices) {
  db[nombre].drop();
  if (conIndices) { db[nombre].createIndex({ ruta: 1, fecha_despacho: 1 }); db[nombre].createIndex({ estado_actual: 1, fecha_despacho: -1 }); }
  const ini = Date.now();
  for (let i = 0; i < muestra.length; i += 5000) db[nombre].insertMany(muestra.slice(i, i + 5000), { ordered: false });
  const ms = Date.now() - ini; db[nombre].drop(); return ms;
}
const sin = [], con = [];
for (let r = 0; r < 3; r++) { sin.push(insertar("costo_sin_indices", false)); con.push(insertar("costo_con_indices", true)); }
const mediana = v => v.slice().sort((a, b) => a - b)[1];
mostrar({ sin_indices_ms: sin, con_2_indices_ms: con, mediana_sin_ms: mediana(sin), mediana_con_ms: mediana(con),
          sobrecosto_de_escritura: Math.round((mediana(con) / mediana(sin) - 1) * 100) + " %" });

print("\nFIN. Para limpiar: db.getSiblingDB(\"u8_g11_perf\").dropDatabase()");
