// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.1 - Gestión de accesos: usuario administrador en la base admin
// Motor: MongoDB (mongosh). Ejecutar con la autorización TODAVÍA desactivada:
//   mongosh --quiet --file ej09_1_crear_admin.js
// La clave se pide por teclado (passwordPrompt) o se toma de la variable de
// entorno MONGO_ADMIN_PWD: nunca queda escrita en el script ni en el historial.
// =============================================================================

const admin = db.getSiblingDB("admin");
const clave = process.env.MONGO_ADMIN_PWD || passwordPrompt();

if (admin.getUser("adminG11")) {
  print("El usuario adminG11 ya existe: no se vuelve a crear.");
} else {
  admin.createUser({
    user: "adminG11",
    pwd: clave,
    roles: [
      // Crear y administrar usuarios y roles en cualquier base
      { role: "userAdminAnyDatabase", db: "admin" },
      // Leer y escribir datos en todas las bases (LabMongoDB, LabMongoDB_Restore)
      { role: "readWriteAnyDatabase", db: "admin" },
      // collMod / validadores $jsonSchema e índices (Ejercicio 12.1)
      { role: "dbAdminAnyDatabase", db: "admin" },
      // Ver estado del servidor: serverStatus, currentOp, getCmdLineOpts
      { role: "clusterMonitor", db: "admin" },
      // mongodump y mongorestore (Ejercicio 12.2)
      { role: "backup", db: "admin" },
      { role: "restore", db: "admin" }
    ]
  });
  print("Usuario adminG11 creado en la base admin.");
}

printjson(admin.getUser("adminG11", { showPrivileges: false }));
