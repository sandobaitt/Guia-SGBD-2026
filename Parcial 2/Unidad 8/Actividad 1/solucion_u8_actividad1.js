// =============================================================================
// U8 - ACTIVIDAD 1 · Del requerimiento al documento
// GRUPO 11 · Logística | Distribución interprovincial · MongoDB Community
// Script de solución reproducible (mongosh)
//
// Uso (instancia de laboratorio, sin autenticación):
//   mongosh "mongodb://127.0.0.1:27017" --file solucion_u8_actividad1.js
//
// Qué hace, en orden:
//   0. Entorno          1. Limpieza           2. Carga (2 colecciones)
//   3. Verificación de los requisitos de carga (30+ documentos, variedad, integridad)
//   4. CRUD sobre u8_g11 (alta, lectura, modificación, baja) + costo del estado duplicado
//   5. Cinco consultas (filtros sobre subdocumentos y arreglos) y dos pipelines
//   6. Optimización: explain("executionStats") antes y después de cada índice
//
// Nota: con "use" en un archivo, mongosh --file no ejecuta nada (sin error ni salida); se usa db.getSiblingDB().
// =============================================================================

db = db.getSiblingDB("u8_g11");

// ---- utilidades de salida ---------------------------------------------------
function seccion(titulo) {
  print("\n" + "=".repeat(78));
  print(titulo);
  print("=".repeat(78));
}
function sub(titulo) { print("\n--- " + titulo); }
function mostrar(x) { print(JSON.stringify(x, null, 2)); }
function chequeo(descripcion, ok, detalle) {
  print((ok ? "[CUMPLE]    " : "[NO CUMPLE] ") + descripcion + (detalle !== undefined ? "  -> " + detalle : ""));
}

// =============================================================================
// 0. ENTORNO
// =============================================================================
seccion("0. ENTORNO");
const info = db.hello();
print("Servidor MongoDB : " + db.version());
print("Base de trabajo  : " + db.getName());
print("Modo             : " + (info.setName ? "replica set " + info.setName : "standalone (sin transacciones multi-documento)"));
print("Fecha de ejecución: " + new Date().toISOString());

// =============================================================================
// 1. LIMPIEZA PREVIA (permite reejecutar el script desde cero)
// =============================================================================
seccion("1. LIMPIEZA PREVIA");
db.envios.drop();
db.eventos_seguimiento.drop();
print("Colecciones envios y eventos_seguimiento eliminadas (si existían).");

// =============================================================================
// 2. CARGA DE DATOS
//    envios: 15 documentos con transportista, origen, destino y paquetes EMBEBIDOS.
//    eventos_seguimiento: 20 documentos REFERENCIADOS por envio_id.
// =============================================================================
const enviosData = [
  {
    _id: "ENV-2026-001",
    tracking_code: "TRK-RN11-001",
    ruta: "Resistencia - Rosario",
    transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Santa Fe", localidad: "Rosario", direccion: "Bv. Oroño 4520" },
    fecha_despacho: ISODate("2026-10-01T08:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-02T16:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-02T15:30:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-101", peso_kg: 12.5, fragil: false, tipo: "Repuestos mecánicos" },
      { tracking_paquete: "PAQ-102", peso_kg: 3.2, fragil: true, tipo: "Componentes electrónicos" }
    ]
  },
  {
    _id: "ENV-2026-002",
    tracking_code: "TRK-RN11-002",
    ruta: "Resistencia - Rosario",
    transportista: { id: "TRANS-02", nombre: "Logística del Litoral", cuit: "30-68991234-5" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Santa Fe", localidad: "Santa Fe Capital", direccion: "San Jerónimo 1890" },
    fecha_despacho: ISODate("2026-10-03T09:30:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-04T12:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-04T18:30:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 390,
    paquetes: [
      { tracking_paquete: "PAQ-103", peso_kg: 45.0, fragil: false, tipo: "Bobinas de cable" }
    ]
  },
  {
    _id: "ENV-2026-003",
    tracking_code: "TRK-RN16-003",
    ruta: "Resistencia - Salta",
    transportista: { id: "TRANS-03", nombre: "Transportes El Norteño", cuit: "30-55443322-1" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Salta", localidad: "Salta Capital", direccion: "Av. Paraguay 1200" },
    fecha_despacho: ISODate("2026-10-05T07:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-06T14:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "Demorado",
    minutos_demora: 720,
    paquetes: [
      { tracking_paquete: "PAQ-104", peso_kg: 8.0, fragil: true, tipo: "Insumos médicos" },
      { tracking_paquete: "PAQ-105", peso_kg: 15.0, fragil: false, tipo: "Textil" }
    ]
  },
  {
    _id: "ENV-2026-004",
    tracking_code: "TRK-RN9-004",
    ruta: "Córdoba - Buenos Aires",
    transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
    origen: { provincia: "Córdoba", localidad: "Córdoba Capital", centro_distribucion: "Hub Centro" },
    destino: { provincia: "Buenos Aires", localidad: "Tortuguitas", direccion: "Parque Industrial Calle 3" },
    fecha_despacho: ISODate("2026-10-08T11:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-09T09:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-09T08:45:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-106", peso_kg: 120.0, fragil: false, tipo: "Maquinaria liviana" }
    ]
  },
  {
    _id: "ENV-2026-005",
    tracking_code: "TRK-RN9-005",
    ruta: "Córdoba - Buenos Aires",
    transportista: { id: "TRANS-02", nombre: "Logística del Litoral", cuit: "30-68991234-5" },
    origen: { provincia: "Córdoba", localidad: "Córdoba Capital", centro_distribucion: "Hub Centro" },
    destino: { provincia: "Buenos Aires", localidad: "Avellaneda", direccion: "Av. Mitre 2300" },
    fecha_despacho: ISODate("2026-10-10T14:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-11T12:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-11T16:00:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 240,
    paquetes: [
      { tracking_paquete: "PAQ-107", peso_kg: 5.5, fragil: true, tipo: "Vidrios ópticos" }
    ]
  },
  {
    _id: "ENV-2026-006",
    tracking_code: "TRK-RN12-006",
    ruta: "Corrientes - Posadas",
    transportista: { id: "TRANS-03", nombre: "Transportes El Norteño", cuit: "30-55443322-1" },
    origen: { provincia: "Corrientes", localidad: "Corrientes Capital", centro_distribucion: "Hub Corrientes" },
    destino: { provincia: "Misiones", localidad: "Posadas", direccion: "Ruta 12 Km 5" },
    fecha_despacho: ISODate("2026-10-12T06:30:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-12T16:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-12T15:40:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-108", peso_kg: 30.0, fragil: false, tipo: "Material de ferretería" }
    ]
  },
  {
    _id: "ENV-2026-007",
    tracking_code: "TRK-RN11-007",
    ruta: "Resistencia - Rosario",
    transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Santa Fe", localidad: "Reconquista", direccion: "Patricio Diez 840" },
    fecha_despacho: ISODate("2026-10-15T08:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-15T15:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "En tránsito",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-109", peso_kg: 10.0, fragil: false, tipo: "Papelería" },
      { tracking_paquete: "PAQ-110", peso_kg: 2.0, fragil: true, tipo: "Dispositivos IoT" }
    ]
  },
  {
    _id: "ENV-2026-008",
    tracking_code: "TRK-RN34-008",
    ruta: "Rosario - Tucumán",
    transportista: { id: "TRANS-02", nombre: "Logística del Litoral", cuit: "30-68991234-5" },
    origen: { provincia: "Santa Fe", localidad: "Rosario", centro_distribucion: "Hub Litoral" },
    destino: { provincia: "Tucumán", localidad: "San Miguel de Tucumán", direccion: "Crisóstomo Álvarez 600" },
    fecha_despacho: ISODate("2026-10-16T18:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-18T10:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "Demorado",
    minutos_demora: 480,
    paquetes: [
      { tracking_paquete: "PAQ-111", peso_kg: 78.0, fragil: false, tipo: "Repuestos agropecuarios" }
    ]
  },
  {
    _id: "ENV-2026-009",
    tracking_code: "TRK-RN14-009",
    ruta: "Buenos Aires - Concordia",
    transportista: { id: "TRANS-04", nombre: "Vía Entre Ríos", cuit: "30-44119988-7" },
    origen: { provincia: "Buenos Aires", localidad: "San Martín", centro_distribucion: "Hub Central" },
    destino: { provincia: "Entre Ríos", localidad: "Concordia", direccion: "Monseñor Rösch 310" },
    fecha_despacho: ISODate("2026-10-18T10:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-19T08:00:00Z"),
    fecha_entrega_real: ISODate("2026-10-19T07:50:00Z"),
    estado_actual: "Entregado",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-112", peso_kg: 18.0, fragil: false, tipo: "Alimentos no perecederos" }
    ]
  },
  {
    _id: "ENV-2026-010",
    tracking_code: "TRK-RN16-010",
    ruta: "Resistencia - Salta",
    transportista: { id: "TRANS-03", nombre: "Transportes El Norteño", cuit: "30-55443322-1" },
    origen: { provincia: "Chaco", localidad: "Sáenz Peña", centro_distribucion: "Hub Interior" },
    destino: { provincia: "Santiago del Estero", localidad: "Monte Quemado", direccion: "Av. San Martín 200" },
    fecha_despacho: ISODate("2026-10-20T07:30:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-20T14:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "En tránsito",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-113", peso_kg: 5.0, fragil: false, tipo: "Documentación bancaria" }
    ]
  },
  {
    _id: "ENV-2026-011",
    tracking_code: "TRK-RN9-011",
    ruta: "Córdoba - Buenos Aires",
    transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
    origen: { provincia: "Córdoba", localidad: "Villa María", centro_distribucion: "Hub Centro" },
    destino: { provincia: "Buenos Aires", localidad: "La Plata", direccion: "Calle 7 N° 450" },
    fecha_despacho: ISODate("2026-10-21T13:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-22T11:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "En preparación",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-114", peso_kg: 60.0, fragil: false, tipo: "Insumos lácteos" }
    ]
  },
  {
    _id: "ENV-2026-012",
    tracking_code: "TRK-RN11-012",
    ruta: "Resistencia - Rosario",
    transportista: { id: "TRANS-02", nombre: "Logística del Litoral", cuit: "30-68991234-5" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Santa Fe", localidad: "San Lorenzo", direccion: "Av. San Martín 150" },
    fecha_despacho: ISODate("2026-10-22T08:30:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-23T14:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "Demorado",
    minutos_demora: 300,
    paquetes: [
      { tracking_paquete: "PAQ-115", peso_kg: 22.0, fragil: true, tipo: "Material de laboratorio" }
    ]
  },
  {
    _id: "ENV-2026-013",
    tracking_code: "TRK-RN14-013",
    ruta: "Buenos Aires - Concordia",
    transportista: { id: "TRANS-04", nombre: "Vía Entre Ríos", cuit: "30-44119988-7" },
    origen: { provincia: "Buenos Aires", localidad: "San Martín", centro_distribucion: "Hub Central" },
    destino: { provincia: "Entre Ríos", localidad: "Gualeguaychú", direccion: "Urquiza 520" },
    fecha_despacho: ISODate("2026-10-24T15:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-25T10:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "En tránsito",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-116", peso_kg: 9.0, fragil: false, tipo: "Indumentaria deportiva" }
    ]
  },
  {
    _id: "ENV-2026-014",
    tracking_code: "TRK-RN16-014",
    ruta: "Resistencia - Salta",
    transportista: { id: "TRANS-03", nombre: "Transportes El Norteño", cuit: "30-55443322-1" },
    origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
    destino: { provincia: "Jujuy", localidad: "San Salvador de Jujuy", direccion: "Necochea 340" },
    fecha_despacho: ISODate("2026-10-25T06:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-26T18:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "Cancelado",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-117", peso_kg: 14.0, fragil: true, tipo: "Instrumental quirúrgico" }
    ]
  },
  {
    _id: "ENV-2026-015",
    tracking_code: "TRK-RN34-015",
    ruta: "Rosario - Tucumán",
    transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
    origen: { provincia: "Santa Fe", localidad: "Rosario", centro_distribucion: "Hub Litoral" },
    destino: { provincia: "Santiago del Estero", localidad: "La Banda", direccion: "Av. Belgrano 780" },
    fecha_despacho: ISODate("2026-10-26T10:00:00Z"),
    fecha_estimada_entrega: ISODate("2026-10-27T17:00:00Z"),
    fecha_entrega_real: null,
    estado_actual: "En preparación",
    minutos_demora: 0,
    paquetes: [
      { tracking_paquete: "PAQ-118", peso_kg: 33.0, fragil: false, tipo: "Herramientas de mano" },
      { tracking_paquete: "PAQ-119", peso_kg: 4.5, fragil: true, tipo: "Sensores electrónicos" }
    ]
  }
];

// --- eventos_seguimiento (20 documentos referenciados por envio_id) ---
const eventosData = [
  // Eventos para ENV-2026-001 (Ciclo completo entregado)
  {
    _id: "EVT-001",
    envio_id: "ENV-2026-001",
    tipo_evento: "DESPACHO",
    descripcion: "Camión partió de Hub Resistencia",
    ubicacion: { localidad: "Resistencia", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-01T08:00:00Z"),
    operador: "op_resistencia_01"
  },
  {
    _id: "EVT-002",
    envio_id: "ENV-2026-001",
    tipo_evento: "CONTROL_TRANSITO",
    descripcion: "Control de pesaje en balanza vial",
    ubicacion: { localidad: "Vera", provincia: "Santa Fe", km_ruta: 430 },
    timestamp: ISODate("2026-10-01T15:30:00Z"),
    operador: "op_gendarmeria_04"
  },
  {
    _id: "EVT-003",
    envio_id: "ENV-2026-001",
    tipo_evento: "ENTREGA",
    descripcion: "Entregado en destino conforme receptor",
    ubicacion: { localidad: "Rosario", provincia: "Santa Fe", km_ruta: 800 },
    timestamp: ISODate("2026-10-02T15:30:00Z"),
    operador: "chofer_gonzalez"
  },


  // Eventos para ENV-2026-002 (Entregado con demora por desperfecto)
  {
    _id: "EVT-004",
    envio_id: "ENV-2026-002",
    tipo_evento: "DESPACHO",
    descripcion: "Salida de unidad desde Hub Norte",
    ubicacion: { localidad: "Resistencia", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-03T09:30:00Z"),
    operador: "op_resistencia_02"
  },
  {
    _id: "EVT-005",
    envio_id: "ENV-2026-002",
    tipo_evento: "INCIDENCIA_MECANICA",
    descripcion: "Rotura de neumático trasero en RN 11",
    ubicacion: { localidad: "San Justo", provincia: "Santa Fe", km_ruta: 560 },
    timestamp: ISODate("2026-10-04T08:15:00Z"),
    operador: "chofer_ramirez"
  },
  {
    _id: "EVT-006",
    envio_id: "ENV-2026-002",
    tipo_evento: "ENTREGA",
    descripcion: "Entrega con demora justificada",
    ubicacion: { localidad: "Santa Fe Capital", provincia: "Santa Fe", km_ruta: 660 },
    timestamp: ISODate("2026-10-04T18:30:00Z"),
    operador: "chofer_ramirez"
  },


  // Eventos para ENV-2026-003 (Demorado por piquete / corte de ruta)
  {
    _id: "EVT-007",
    envio_id: "ENV-2026-003",
    tipo_evento: "DESPACHO",
    descripcion: "Salida hacia Salta",
    ubicacion: { localidad: "Resistencia", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-05T07:00:00Z"),
    operador: "op_resistencia_01"
  },
  {
    _id: "EVT-008",
    envio_id: "ENV-2026-003",
    tipo_evento: "CORTE_CALZADA",
    descripcion: "Corte de calzada por temporal en RN 16",
    ubicacion: { localidad: "Joaquín V. González", provincia: "Salta", km_ruta: 580 },
    timestamp: ISODate("2026-10-05T19:40:00Z"),
    operador: "chofer_castillo"
  },


  // Eventos para ENV-2026-004 (Ruta 9 a tiempo)
  {
    _id: "EVT-009",
    envio_id: "ENV-2026-004",
    tipo_evento: "DESPACHO",
    descripcion: "Salida desde Hub Córdoba",
    ubicacion: { localidad: "Córdoba Capital", provincia: "Córdoba", km_ruta: 0 },
    timestamp: ISODate("2026-10-08T11:00:00Z"),
    operador: "op_cordoba_01"
  },
  {
    _id: "EVT-010",
    envio_id: "ENV-2026-004",
    tipo_evento: "ENTREGA",
    descripcion: "Descarga completa en nave logística Tortuguitas",
    ubicacion: { localidad: "Tortuguitas", provincia: "Buenos Aires", km_ruta: 690 },
    timestamp: ISODate("2026-10-09T08:45:00Z"),
    operador: "chofer_benitez"
  },


  // Eventos para ENV-2026-005 (Tránsito pesado en accesos)
  {
    _id: "EVT-011",
    envio_id: "ENV-2026-005",
    tipo_evento: "DESPACHO",
    descripcion: "Partida desde Córdoba",
    ubicacion: { localidad: "Córdoba Capital", provincia: "Córdoba", km_ruta: 0 },
    timestamp: ISODate("2026-10-10T14:00:00Z"),
    operador: "op_cordoba_02"
  },
  {
    _id: "EVT-012",
    envio_id: "ENV-2026-005",
    tipo_evento: "CONGESTION_VIAL",
    descripcion: "Demora en ingreso a Panamericana y Acceso Sudeste",
    ubicacion: { localidad: "Campana", provincia: "Buenos Aires", km_ruta: 620 },
    timestamp: ISODate("2026-10-11T10:30:00Z"),
    operador: "chofer_alvarez"
  },
  {
    _id: "EVT-013",
    envio_id: "ENV-2026-005",
    tipo_evento: "ENTREGA",
    descripcion: "Entrega concretada en dock",
    ubicacion: { localidad: "Avellaneda", provincia: "Buenos Aires", km_ruta: 710 },
    timestamp: ISODate("2026-10-11T16:00:00Z"),
    operador: "chofer_alvarez"
  },


  // Eventos para ENV-2026-007 (En tránsito activo)
  {
    _id: "EVT-014",
    envio_id: "ENV-2026-007",
    tipo_evento: "DESPACHO",
    descripcion: "Salida desde Chaco hacia Reconquista",
    ubicacion: { localidad: "Resistencia", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-15T08:00:00Z"),
    operador: "op_resistencia_01"
  },
  {
    _id: "EVT-015",
    envio_id: "ENV-2026-007",
    tipo_evento: "PASO_SUCURSAL",
    descripcion: "Tránsito por puente interprovincial General Belgrano",
    ubicacion: { localidad: "Barranqueras", provincia: "Chaco", km_ruta: 15 },
    timestamp: ISODate("2026-10-15T09:10:00Z"),
    operador: "chofer_gonzalez"
  },


  // Eventos para ENV-2026-008 (Demorado)
  {
    _id: "EVT-016",
    envio_id: "ENV-2026-008",
    tipo_evento: "DESPACHO",
    descripcion: "Salida nocturna desde Rosario",
    ubicacion: { localidad: "Rosario", provincia: "Santa Fe", km_ruta: 0 },
    timestamp: ISODate("2026-10-16T18:00:00Z"),
    operador: "op_rosario_01"
  },
  {
    _id: "EVT-017",
    envio_id: "ENV-2026-008",
    tipo_evento: "FALLA_ELECTRICA",
    descripcion: "Detención en estación de servicio por corte de alternador",
    ubicacion: { localidad: "Rafaela", provincia: "Santa Fe", km_ruta: 110 },
    timestamp: ISODate("2026-10-17T03:45:00Z"),
    operador: "chofer_fernandez"
  },


  // Evento para ENV-2026-010 (En tránsito)
  {
    _id: "EVT-018",
    envio_id: "ENV-2026-010",
    tipo_evento: "DESPACHO",
    descripcion: "Salida desde Sáenz Peña",
    ubicacion: { localidad: "Presidencia Roque Sáenz Peña", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-20T07:30:00Z"),
    operador: "op_interior_03"
  },


  // Eventos para ENV-2026-014 (Cancelado por siniestro)
  {
    _id: "EVT-019",
    envio_id: "ENV-2026-014",
    tipo_evento: "DESPACHO",
    descripcion: "Partida hacia Jujuy",
    ubicacion: { localidad: "Resistencia", provincia: "Chaco", km_ruta: 0 },
    timestamp: ISODate("2026-10-25T06:00:00Z"),
    operador: "op_resistencia_02"
  },
  {
    _id: "EVT-020",
    envio_id: "ENV-2026-014",
    tipo_evento: "CANCELACION",
    descripcion: "Envío cancelado y retornado por daños en precinto",
    ubicacion: { localidad: "Pampa del Infierno", provincia: "Chaco", km_ruta: 220 },
    timestamp: ISODate("2026-10-25T11:20:00Z"),
    operador: "chofer_castillo"
  }
];

const resEnvios = db.envios.insertMany(enviosData);
const resEventos = db.eventos_seguimiento.insertMany(eventosData);
print("envios              -> acknowledged: " + resEnvios.acknowledged + ", insertedCount: " + Object.keys(resEnvios.insertedIds).length);
print("eventos_seguimiento -> acknowledged: " + resEventos.acknowledged + ", insertedCount: " + Object.keys(resEventos.insertedIds).length);

// =============================================================================
// 3. VERIFICACIÓN DE LOS REQUISITOS DE CARGA
//    (pauta: base u8_gXX, 30+ documentos ficticios, variedad de estados, fechas
//     y valores, recuentos verificados, colecciones justificadas)
// =============================================================================
seccion("3. VERIFICACIÓN DE LOS REQUISITOS DE CARGA");

const totalEnvios = db.envios.countDocuments({});
const totalEventos = db.eventos_seguimiento.countDocuments({});
const total = totalEnvios + totalEventos;

sub("3.1 Recuentos");
print("db.envios.countDocuments()              = " + totalEnvios);
print("db.eventos_seguimiento.countDocuments() = " + totalEventos);
print("TOTAL en u8_g11                         = " + total);

sub("3.2 Variedad de estados (estado_actual)");
const porEstado = db.envios.aggregate([
  { $group: { _id: "$estado_actual", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1, _id: 1 } }
]).toArray();
mostrar(porEstado);

sub("3.3 Variedad de fechas, transportistas, rutas y valores");
const rangoFechas = db.envios.aggregate([
  { $group: { _id: null, primera: { $min: "$fecha_despacho" }, ultima: { $max: "$fecha_despacho" },
              peso_min: { $min: { $min: "$paquetes.peso_kg" } }, peso_max: { $max: { $max: "$paquetes.peso_kg" } },
              demora_max: { $max: "$minutos_demora" } } },
  { $project: { _id: 0, primera: 1, ultima: 1, dias_de_rango: { $round: [{ $divide: [{ $subtract: ["$ultima", "$primera"] }, 86400000] }, 1] },
                peso_min: 1, peso_max: 1, demora_max: 1 } }
]).toArray()[0];
mostrar(rangoFechas);
const transportistas = db.envios.distinct("transportista.nombre");
const rutas = db.envios.distinct("ruta");
const tiposEvento = db.eventos_seguimiento.distinct("tipo_evento");
print("Transportistas distintos (" + transportistas.length + "): " + transportistas.join(" | "));
print("Rutas distintas (" + rutas.length + "): " + rutas.join(" | "));
print("Tipos de evento distintos (" + tiposEvento.length + "): " + tiposEvento.join(" | "));

sub("3.4 Integridad referencial (eventos cuyo envio_id no existe en envios)");
const huerfanos = db.eventos_seguimiento.aggregate([
  { $lookup: { from: "envios", localField: "envio_id", foreignField: "_id", as: "envio" } },
  { $match: { envio: { $size: 0 } } },
  { $project: { _id: 1, envio_id: 1 } }
]).toArray();
print("Eventos huérfanos: " + huerfanos.length);

sub("3.5 Coherencia de datos: minutos_demora de los envíos entregados");
const incoherentes = db.envios.aggregate([
  { $match: { estado_actual: "Entregado" } },
  { $addFields: { demora_calculada: { $max: [0, { $round: [{ $divide: [{ $subtract: ["$fecha_entrega_real", "$fecha_estimada_entrega"] }, 60000] }, 0] }] } } },
  { $match: { $expr: { $ne: ["$demora_calculada", "$minutos_demora"] } } },
  { $project: { _id: 1, minutos_demora: 1, demora_calculada: 1 } }
]).toArray();
print("Entregados con minutos_demora distinto de (entrega real - entrega estimada): " + incoherentes.length);

sub("3.6 Envíos con y sin eventos de seguimiento");
const conEventos = db.eventos_seguimiento.distinct("envio_id").length;
print("Envíos con al menos un evento: " + conEventos + " de " + totalEnvios + " (el resto aún no registró hitos)");

sub("3.7 Resultado de la verificación contra la pauta");
chequeo("Base nombrada u8_gXX", /^u8_g\d{2}$/.test(db.getName()), db.getName());
chequeo("Al menos 2 colecciones justificadas por el dominio (envios + eventos_seguimiento)", db.getCollectionNames().length >= 2, db.getCollectionNames().join(", "));
chequeo("Al menos 30 documentos en total", total >= 30, total + " documentos");
chequeo("Variedad de estados (4 o más)", porEstado.length >= 4, porEstado.length + " estados");
chequeo("Variedad de fechas (rango de al menos 14 días)", rangoFechas.dias_de_rango >= 14, rangoFechas.dias_de_rango + " días");
chequeo("Variedad de valores (3+ transportistas, 4+ rutas, pesos y demoras distintos)",
        transportistas.length >= 3 && rutas.length >= 4 && rangoFechas.peso_max > rangoFechas.peso_min && rangoFechas.demora_max > 0,
        transportistas.length + " transportistas, " + rutas.length + " rutas");
chequeo("Sin eventos huérfanos", huerfanos.length === 0, huerfanos.length + " huérfanos");
chequeo("Coherencia de minutos_demora en entregados", incoherentes.length === 0, incoherentes.length + " incoherentes");
chequeo("Todo envío tiene al menos un paquete embebido", db.envios.countDocuments({ "paquetes.0": { $exists: true } }) === totalEnvios);

// =============================================================================
// 4. OPERACIONES CRUD (sobre u8_g11, con un registro de prueba)
// =============================================================================
seccion("4. CRUD SOBRE u8_g11 (registro de prueba ENV-TEST-999)");

sub("4.1 ALTA (insertOne)");
mostrar(db.envios.insertOne({
  _id: "ENV-TEST-999",
  tracking_code: "TRK-TEST-999",
  ruta: "Resistencia - Formosa",
  transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
  origen: { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
  destino: { provincia: "Formosa", localidad: "Formosa Capital", direccion: "Av. 25 de Mayo 100" },
  fecha_despacho: ISODate("2026-10-28T09:00:00Z"),
  fecha_estimada_entrega: ISODate("2026-10-28T18:00:00Z"),
  fecha_entrega_real: null,
  estado_actual: "En preparación",
  minutos_demora: 0,
  paquetes: [{ tracking_paquete: "PAQ-999", peso_kg: 5.0, fragil: false, tipo: "Muestra de prueba" }]
}));

sub("4.2 LECTURA (findOne)");
mostrar(db.envios.findOne({ _id: "ENV-TEST-999" }));

sub("4.3 MODIFICACIÓN (updateOne con $set y $push)");
mostrar(db.envios.updateOne(
  { _id: "ENV-TEST-999" },
  { $set: { estado_actual: "Demorado", minutos_demora: 60 },
    $push: { paquetes: { tracking_paquete: "PAQ-998", peso_kg: 1.5, fragil: true, tipo: "Documentación adicional" } } }
));
mostrar(db.envios.findOne({ _id: "ENV-TEST-999" }, { estado_actual: 1, minutos_demora: 1, paquetes: 1 }));

sub("4.4 MODIFICACIÓN DE UN ELEMENTO DEL ARREGLO (operador posicional $)");
mostrar(db.envios.updateOne(
  { _id: "ENV-TEST-999", "paquetes.tracking_paquete": "PAQ-998" },
  { $set: { "paquetes.$.fragil": false } }
));
mostrar(db.envios.findOne({ _id: "ENV-TEST-999" }, { paquetes: 1 }));

sub("4.5 COSTO DEL ESTADO DUPLICADO: registrar un evento implica DOS escrituras");
print("(estado_actual vive en envios y el historial en eventos_seguimiento; en un standalone no hay transacción que las agrupe)");
mostrar(db.eventos_seguimiento.insertOne({
  _id: "EVT-TEST-1", envio_id: "ENV-TEST-999", tipo_evento: "INCIDENCIA_MECANICA",
  descripcion: "Evento de prueba", ubicacion: { localidad: "Clorinda", provincia: "Formosa", km_ruta: 120 },
  timestamp: ISODate("2026-10-28T12:00:00Z"), operador: "op_prueba"
}));
mostrar(db.envios.updateOne({ _id: "ENV-TEST-999" }, { $set: { estado_actual: "Demorado" } }));

sub("4.6 BAJA (deleteOne / deleteMany) y verificación de recuentos");
mostrar(db.envios.deleteOne({ _id: "ENV-TEST-999" }));
mostrar(db.eventos_seguimiento.deleteMany({ envio_id: "ENV-TEST-999" }));
print("findOne tras la baja: " + JSON.stringify(db.envios.findOne({ _id: "ENV-TEST-999" })));
print("Recuentos finales -> envios: " + db.envios.countDocuments({}) + " | eventos_seguimiento: " + db.eventos_seguimiento.countDocuments({}));
chequeo("La base quedó con los mismos documentos que antes del CRUD", db.envios.countDocuments({}) === 15 && db.eventos_seguimiento.countDocuments({}) === 20);

// =============================================================================
// 5. CONSULTAS DEL ESCENARIO
// =============================================================================
seccion("5. CONSULTAS DEL ESCENARIO");

sub("Q1. Envíos por ruta y fecha (requerimiento prioritario)");
mostrar(db.envios.find(
  { ruta: "Resistencia - Rosario",
    fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lte: ISODate("2026-10-15T23:59:59Z") } },
  { tracking_code: 1, ruta: 1, fecha_despacho: 1, "transportista.nombre": 1, estado_actual: 1 }
).sort({ fecha_despacho: 1 }).toArray());

sub("Q2. Envíos por estado y fecha (consulta complementaria)");
mostrar(db.envios.find(
  { estado_actual: "Demorado",
    fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lt: ISODate("2026-11-01T00:00:00Z") } },
  { tracking_code: 1, ruta: 1, fecha_despacho: 1, minutos_demora: 1, estado_actual: 1 }
).sort({ fecha_despacho: -1 }).toArray());

sub("Q3. Filtro sobre subdocumento y arreglo: destino en Santa Fe con algún paquete frágil");
mostrar(db.envios.find(
  { "destino.provincia": "Santa Fe", paquetes: { $elemMatch: { fragil: true } } },
  { tracking_code: 1, "destino.localidad": 1, estado_actual: 1, paquetes: 1 }
).toArray());

sub("Q3b. $elemMatch frente a notación con punto: ¿algún paquete frágil Y de más de 10 kg?");
const conPunto = db.envios.find({ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }, { _id: 1 }).toArray().map(d => d._id);
const conElemMatch = db.envios.find({ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }, { _id: 1 }).toArray().map(d => d._id);
print("Notación con punto  (condiciones sobre paquetes distintos) -> " + conPunto.length + " envíos: " + conPunto.join(", "));
print("$elemMatch          (misma pieza cumple ambas)             -> " + conElemMatch.length + " envíos: " + conElemMatch.join(", "));
print("Los que figuran solo con la notación con punto tienen un paquete frágil y OTRO de más de 10 kg: no es lo que se pregunta.");

sub("Q4. Recuperar un envío completo por identificador, con su historial (referencia)");
mostrar(db.envios.aggregate([
  { $match: { _id: "ENV-2026-001" } },
  { $lookup: { from: "eventos_seguimiento", localField: "_id", foreignField: "envio_id", as: "historial_eventos" } },
  { $addFields: { cantidad_eventos: { $size: "$historial_eventos" } } }
]).toArray());

sub("Q4b. Lo mismo con historial ordenado por fecha (lookup con sub-pipeline)");
mostrar(db.envios.aggregate([
  { $match: { _id: "ENV-2026-002" } },
  { $lookup: { from: "eventos_seguimiento",
               let: { id: "$_id" },
               pipeline: [{ $match: { $expr: { $eq: ["$envio_id", "$$id"] } } },
                          { $sort: { timestamp: 1 } },
                          { $project: { _id: 0, timestamp: 1, tipo_evento: 1, "ubicacion.localidad": 1 } }],
               as: "historial" } },
  { $project: { _id: 1, estado_actual: 1, historial: 1 } }
]).toArray());

sub("P1. Pipeline (4 etapas): demoras por transportista");
mostrar(db.envios.aggregate([
  { $match: { minutos_demora: { $gt: 0 } } },
  { $group: { _id: "$transportista.nombre",
              cantidad_envios_demorados: { $sum: 1 },
              total_minutos_demora: { $sum: "$minutos_demora" },
              promedio_minutos_demora: { $avg: "$minutos_demora" } } },
  { $sort: { promedio_minutos_demora: -1 } },
  { $project: { _id: 0, transportista: "$_id", cantidad_envios_demorados: 1,
                total_horas_demora: { $round: [{ $divide: ["$total_minutos_demora", 60] }, 1] },
                promedio_minutos_demora: { $round: ["$promedio_minutos_demora", 1] } } }
]).toArray());

sub("P1b. Pipeline (4 etapas): porcentaje de envíos demorados sobre el total de cada transportista");
mostrar(db.envios.aggregate([
  { $group: { _id: "$transportista.nombre",
              envios: { $sum: 1 },
              demorados: { $sum: { $cond: [{ $gt: ["$minutos_demora", 0] }, 1, 0] } } } },
  { $addFields: { porcentaje_demorados: { $round: [{ $multiply: [{ $divide: ["$demorados", "$envios"] }, 100] }, 1] } } },
  { $sort: { porcentaje_demorados: -1, _id: 1 } },
  { $project: { _id: 0, transportista: "$_id", envios: 1, demorados: 1, porcentaje_demorados: 1 } }
]).toArray());

sub("P2. Pipeline (4 etapas): paquetes y peso por provincia de destino");
mostrar(db.envios.aggregate([
  { $unwind: "$paquetes" },
  { $group: { _id: "$destino.provincia", paquetes: { $sum: 1 }, peso_total_kg: { $sum: "$paquetes.peso_kg" },
              fragiles: { $sum: { $cond: ["$paquetes.fragil", 1, 0] } } } },
  { $sort: { peso_total_kg: -1 } },
  { $project: { _id: 0, provincia: "$_id", paquetes: 1, fragiles: 1, peso_total_kg: { $round: ["$peso_total_kg", 1] } } }
]).toArray());

// =============================================================================
// 6. OPTIMIZACIÓN: explain("executionStats") ANTES Y DESPUÉS DE CADA ÍNDICE
// =============================================================================
seccion("6. OPTIMIZACIÓN CON ÍNDICES");

function buscarEtapa(p, nombre) {
  while (p) {
    if (p.stage === nombre) return p;
    p = p.inputStage || (p.inputStages ? p.inputStages[0] : null);
  }
  return null;
}
function ramaPlan(p) {
  const partes = [];
  while (p) {
    partes.push(p.stage + (p.indexName ? "(" + p.indexName + ")" : ""));
    p = p.inputStage || (p.inputStages ? p.inputStages[0] : null);
  }
  return partes.join(" > ");
}
// Ejecuta el explain varias veces y resume. La PRIMERA ejecución incluye la planificación
// (la caché de planes está fría); las siguientes reutilizan el plan.
function medir(titulo, fabrica, repeticiones) {
  repeticiones = repeticiones || 5;
  const tiempos = [];
  let ex;
  for (let i = 0; i < repeticiones; i++) {
    ex = fabrica().explain("executionStats");
    tiempos.push(ex.executionStats.executionTimeMillis);
    if (i === 0) { var primera = ex.executionStats.executionTimeMillis; var planif = ex.queryPlanner.optimizationTimeMillis; }
  }
  const orden = tiempos.slice().sort((a, b) => a - b);
  const wp = ex.queryPlanner.winningPlan.queryPlan || ex.queryPlanner.winningPlan;
  const ixscan = buscarEtapa(wp, "IXSCAN");
  const r = {
    consulta: titulo,
    plan_ganador: ramaPlan(wp),
    ordena_en_memoria: !!buscarEtapa(wp, "SORT"),
    nReturned: ex.executionStats.nReturned,
    totalKeysExamined: ex.executionStats.totalKeysExamined,
    totalDocsExamined: ex.executionStats.totalDocsExamined,
    primera_ejecucion_ms: primera,
    optimizationTimeMillis_primera: planif,
    ms_min_mediana_max: orden[0] + " / " + orden[Math.floor(orden.length / 2)] + " / " + orden[orden.length - 1]
  };
  if (ixscan) r.indexBounds = ixscan.indexBounds;
  mostrar(r);
  return r;
}

const filtroQ1 = { ruta: "Resistencia - Rosario",
                   fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lte: ISODate("2026-10-15T23:59:59Z") } };
const filtroQ2 = { estado_actual: "Demorado",
                   fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lt: ISODate("2026-11-01T00:00:00Z") } };

sub("6.1 Q1 (ruta + rango de fechas) SIN índice");
const q1Antes = medir("Q1 sin índice", () => db.envios.find(filtroQ1));

sub("6.2 Creación del índice compuesto { ruta: 1, fecha_despacho: 1 } (igualdad primero, rango después)");
print("createIndex -> " + db.envios.createIndex({ ruta: 1, fecha_despacho: 1 }));

sub("6.3 Q1 CON índice");
const q1Despues = medir("Q1 con índice ruta_1_fecha_despacho_1", () => db.envios.find(filtroQ1));

sub("6.4 Q2 (estado + fecha, orden descendente) SIN índice propio");
const q2Antes = medir("Q2 sin índice por estado (ordena en memoria)", () => db.envios.find(filtroQ2).sort({ fecha_despacho: -1 }));
print("createIndex -> " + db.envios.createIndex({ estado_actual: 1, fecha_despacho: -1 }));
const q2Despues = medir("Q2 con índice estado_actual_1_fecha_despacho_-1", () => db.envios.find(filtroQ2).sort({ fecha_despacho: -1 }));

sub("6.5 Historial de un envío (lo que resuelve el $lookup): eventos por envio_id, ordenados por fecha");
const evAntes = medir("Eventos de un envío sin índice", () => db.eventos_seguimiento.find({ envio_id: "ENV-2026-001" }).sort({ timestamp: 1 }));
print("createIndex -> " + db.eventos_seguimiento.createIndex({ envio_id: 1, timestamp: 1 }));
const evDespues = medir("Eventos de un envío con índice envio_id_1_timestamp_1", () => db.eventos_seguimiento.find({ envio_id: "ENV-2026-001" }).sort({ timestamp: 1 }));

sub("6.6 Resumen comparativo (documentos examinados)");
mostrar([
  { consulta: "Q1 ruta + fecha", sin_indice: q1Antes.totalDocsExamined, con_indice: q1Despues.totalDocsExamined, claves_con_indice: q1Despues.totalKeysExamined, devueltos: q1Despues.nReturned },
  { consulta: "Q2 estado + fecha", sin_indice: q2Antes.totalDocsExamined, con_indice: q2Despues.totalDocsExamined, claves_con_indice: q2Despues.totalKeysExamined, devueltos: q2Despues.nReturned },
  { consulta: "Eventos de un envío", sin_indice: evAntes.totalDocsExamined, con_indice: evDespues.totalDocsExamined, claves_con_indice: evDespues.totalKeysExamined, devueltos: evDespues.nReturned }
]);

sub("6.7 Índices existentes y uso real ($indexStats)");
print("envios: " + db.envios.getIndexes().map(i => i.name).join(", "));
print("eventos_seguimiento: " + db.eventos_seguimiento.getIndexes().map(i => i.name).join(", "));
print("(explain no cuenta como uso: se ejecutan las consultas reales una vez y se lee $indexStats)");
db.envios.find(filtroQ1).toArray();
db.envios.find(filtroQ2).sort({ fecha_despacho: -1 }).toArray();
db.eventos_seguimiento.find({ envio_id: "ENV-2026-001" }).sort({ timestamp: 1 }).toArray();
mostrar(db.envios.aggregate([{ $indexStats: {} }, { $project: { _id: 0, indice: "$name", usos: { $toInt: "$accesses.ops" } } }, { $sort: { indice: 1 } }]).toArray());
mostrar(db.eventos_seguimiento.aggregate([{ $indexStats: {} }, { $project: { _id: 0, indice: "$name", usos: { $toInt: "$accesses.ops" } } }, { $sort: { indice: 1 } }]).toArray());

seccion("FIN. Estado final: envios = " + db.envios.countDocuments({}) + ", eventos_seguimiento = " + db.eventos_seguimiento.countDocuments({}));
