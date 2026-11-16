# Guía Paso a Paso: U10 - Actividad 1 (De la VM a la nube)
**Grupo:** G11 · **Motor:** MongoDB 8.0.37 · **Servicio:** MongoDB Atlas `M0`, AWS São Paulo · **Cluster:** `SGBD-U10-Grupo11`
**Archivos:** `bitacora_resuelta.md` (informe corregido) · `consigna3.js` · `consigna4_accesos.js` · `consigna5_backup.txt`

> El grupo ya hizo la conexión, el CRUD, el usuario lector y la matriz. Esta guía dice **qué falta y cómo hacerlo**, con todo ejecutado desde la VM Ubuntu (`mv-sgbd`) desde la que se conectaron.

---

## 0. Estado de la entrega (segunda versión del PDF)

| Consigna | Estado | Qué falta |
| :---: | :---: | :--- |
| 1. Entorno | Completa | "Mongo DB" → "MongoDB" |
| 2. Provisionar y conectar | Completa | En el texto el comando dice `admin_g11`; la captura usa `admin_grupo11` |
| 3. CRUD | Casi completa | La captura del `deleteOne` sigue cortada: falta `deletedCount: 1` y `countDocuments()` → 4 |
| 4. Accesos | **Corregida** | Lector con `read@practicaU10.productos`. Falta: cambiar el texto ("exclusivo de la base") por "de la colección `practicaU10.productos`", quitar el párrafo de Custom Roles y (recomendado) la prueba de `createUser` rechazado |
| 5. Backup | **Falta lo principal** | `mongodump` y restauración verificada. Se puede hacer **todo en el cloud** (sección 3) |
| 6. Matriz | Sin cambios | Corregir la fila Backup y "tiempo real" en Monitoreo |
| 7. Conclusiones | Sin cambios | Corregir "no se puede realizar backups" y quitar lo de Custom Roles |

---

## 1. Por qué el backup no se puede omitir

La consigna 5 pide tres cosas: **identificar** la protección administrada (ya está: la captura de la pestaña Backup), **generar un respaldo lógico/exportación** y **verificar una recuperación** "si el servicio lo permite". El servicio lo permite: la documentación oficial de Atlas indica que en clusters Free se usa `mongodump` para respaldar y `mongorestore` para restaurar. El respaldo *administrado* es lo único que no está incluido (es pago: *Purchase Daily Backups*). Sin esta parte, el criterio Respaldo / recuperación (20 %) queda casi sin evidencia.

## 2. Repetir las pruebas de acceso (opcional pero recomendado)

```bash
mongosh "mongodb+srv://sgbd-u10-grupo11.ryeyzsk.mongodb.net/" --apiVersion 1 --username admin_grupo11 --file consigna4_accesos.js
```
Tiene que mostrar `[RECHAZADA] db.createUser()`. Esa captura respalda lo que el PDF ya afirma ("Atlas bloquea db.createUser()"). Copiá el mensaje en el informe.

## 3. Respaldo y recuperación, todo en el cloud (consigna 5)

Comandos completos en `consigna5_backup.txt`. Se ejecutan desde la VM; las herramientas piden la contraseña. Sacá una captura de cada paso:

1. **Estado de la base original** (punto 1): 4 productos con sus `_id`.
2. **`mongodump` desde Atlas** (punto 2): `done dumping practicaU10.productos (4 documents)`.
3. **Verificación del respaldo** (punto 3): `ls -lh` con `productos.bson`, `productos.metadata.json`, `prelude.json`; `bsondump ... | wc -l` → `4`.
4. **`mongorestore` hacia Atlas, en otra base** (punto 4): `--nsFrom 'practicaU10.*' --nsTo 'practicaU10_restore.*'` → `4 document(s) restored successfully`.
5. **Comparación** (punto 5): `practicaU10_restore` tiene los **mismos 4 `_id`**, precios y stock que `practicaU10`. Opcional: captura de Data Explorer con las dos bases.

| Problema | Solución |
| :--- | :--- |
| `mongodump: command not found` | `sudo apt install mongodb-database-tools` |
| Se queda esperando | La IP de la VM cambió: agregala de nuevo en Network Access |
| `mongorestore` da error de permisos | Usá `admin_grupo11` (tiene `atlasAdmin`, que es lo que pide Atlas para restaurar) |

Texto para el PDF: copiar la sección 5 de `bitacora_resuelta.md` y completar los `[completar]` con lo que muestren las capturas.

## 4. Completar la captura que falta del CRUD (consigna 3)

La captura del DELETE se cortó y no muestra el resultado. Ejecutá en `mongosh` (como `admin_grupo11`):

```javascript
use practicaU10
db.productos.countDocuments()                        // 4
db.productos.findOne({ codigo: "PROD-05" })          // null: el producto eliminado ya no existe
```

**No vuelvas a correr `consigna3.js` contra Atlas:** borra la colección y la recrea con `_id` nuevos, y las capturas que ya tienen dejarían de coincidir. Se entrega como archivo de comandos reproducible.

---

## 5. Correcciones de texto en el PDF

| Dónde | Dice | Cambiar por |
| :--- | :--- | :--- |
| §1 | "Mongo DB" | "MongoDB" |
| §2 | "Creamos el proyecto 0" | "Dentro del proyecto `Project 0`" |
| §2 | Comando con `admin_g11` | `admin_grupo11` (como en la captura) |
| §3 | El archivo de comandos dice `use u10_practica` | `practicaU10`: usar `consigna3.js`, que ya está corregido |
| §4 | "read restringido de forma exclusiva a la base de datos practicaU10" | "read sobre la colección `practicaU10.productos`" (es lo que muestra la captura) |
| §4 | "Ausencia de Custom Roles en M0..." | Quitarlo: la documentación de Atlas no lo dice, y no lo probaron. Lo correcto es que en Atlas los roles y usuarios **solo** se crean desde la plataforma |
| §4 | "SCRAM-SHA-256" | "SCRAM" (es lo que muestra la consola) |
| §5 | "no permite realizar un backup para la versión FREE" | El respaldo **administrado** no está incluido (solo como adicional pago: *Purchase Daily Backups*); el respaldo **lógico** sí se puede hacer |
| §6, Backup | "Equipo: En el tier gratuito M0 no se permiten realizar backups" | "Equipo: respaldo lógico con `mongodump` y recuperación verificada" |
| §6, Backup | "Los planes pagos (M10+) incluyen ... Point-in-Time Recovery" | "Los planes pagos **ofrecen** snapshots y restauración a un momento exacto" |
| §6, Monitoreo | "gráficos en tiempo real" | "gráficos de conexiones, operaciones, red y tamaño" (el panel en tiempo real no está en el plan Free) |
| §6, CRUD | "script consigna3.js" | Correcto: entregar `consigna3.js` |
| §7 | "imposibilidad de crear Custom Roles granulares" | Quitarlo |
| §7 | "no se puede realizar backups en el plan gratuito" | "no hay snapshots incluidos; el respaldo es lógico y la restauración la verificamos nosotros" |

La versión corregida completa está en `bitacora_resuelta.md`: pueden copiar desde ahí.

---

## 6. Qué se entrega

- El **informe PDF** corregido, con las capturas nuevas.
- Los **archivos de comandos**: `consigna3.js`, `consigna4_accesos.js` y `consigna5_backup.txt`. Ninguno tiene contraseñas.

---

## 7. Tablero de Miro

Cada nota lleva una idea y se firma con el equipo.

**1. Responsabilidades delegadas**
- "Instalar MongoDB 8.0.37 y el SO: lo hizo Atlas; nunca tuvimos acceso al servidor. — G11"
- "Replica set de 3 nodos, TLS y DNS listos sin configurar nada. — G11"

**2. Responsabilidades que permanecen**
- "Mínimo privilegio: lector_g11 solo lee practicaU10.productos; el insert fue rechazado. — G11"
- "Decidir qué IP se conectan (Network Access). — G11"
- "Respaldar Y probar la restauración: en M0 lo hicimos nosotros con mongodump. — G11"

**3. Limitaciones**
- "Sin backup incluido en M0: solo pagando (Purchase Daily Backups). — G11"
- "db.createUser() bloqueado: los usuarios solo se crean en la consola. — G11"
- "512 MB y recursos compartidos; sin descarga de logs. — G11"

**4. Diferencias operativas**
- "CRUD: los mismos comandos que en la VM, solo cambió la conexión. — G11"
- "Permisos: de db.createUser() en el motor a la consola web de Atlas. — G11"
- "Backup: mismo mongodump, pero contra un endpoint en internet. — G11"

**5. Reflexión final:** voten hacia **"Transforma el rol del DBA"** y peguen:
- "Transforma: delegamos la infraestructura, pero seguimos decidiendo accesos, red y continuidad. — G11"
