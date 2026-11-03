**U8 - Actividad 2 · Guardia DBA MongoDB**

*   **Modalidad:** Entrega grupal (12 grupos).
*   **Motor:** MongoDB Community.
*   **Herramientas:** `mongosh` y/o MongoDB Compass; en administración, Database Tools.

> **Importante:** Utilizar exclusivamente una instancia de laboratorio y datos ficticios. No publicar puertos ni credenciales; no realizar pruebas destructivas sobre bases compartidas.

**Situación y objetivo**
La solución de la Actividad 1 ya está en funcionamiento. Ahora el grupo asume la guardia DBA: debe diagnosticar la instancia, proteger accesos, revisar la exposición de red y demostrar que puede recuperar los datos.

---

**Secuencia de trabajo**

1.  **Diagnosticar:** Registrar versión de servidor, estado, bases y colecciones de laboratorio; identificar configuración de autenticación y escucha de red.
2.  **Autenticación:** Habilitar el control de acceso en una instancia aislada de laboratorio, con usuario administrador previamente creado; verificar conexión válida y rechazo de acceso sin credenciales.
3.  **RBAC:** Crear `u8_gXX_lector` con el rol `read` y `u8_gXX_operador` con el rol `readWrite` exclusivamente sobre `u8_gXX`. Demostrar lectura permitida, escritura denegada al lector, escritura permitida al operador y administración de usuarios denegada al operador.
4.  **Red y TLS:** Identificar `bindIp`, puerto y modo TLS; comprobar que no se expone innecesariamente la instancia. Implementar TLS en un entorno real (configuración y certificados); si el laboratorio no está preparado, documentar en detalle el procedimiento teórico de implementación.
5.  **Backup y restauración:** Realizar `mongodump` de la base del grupo y verificar artefactos. Eliminar controladamente una colección de prueba o restaurar en una base alternativa `u8_gXX_restore`, validando conteos y registros. **No borrar la base original compartida.**
6.  **Incidente:** Diagnosticar por qué un usuario puede leer pero no modificar un documento: distinguir niveles de conexión, autenticación y autorización mediante pruebas.

---

**Pruebas mínimas de autorización**

| Identidad | Acción | Resultado esperado |
| :--- | :--- | :--- |
| **Lector** | `find()` | Permitida |
| **Lector** | `insertOne()` | Denegada |
| **Operador** | `updateOne()` | Permitida |
| **Operador** | `createUser()` | Denegada |

---

**Evidencias y entrega**

*   `bitacora.pdf`: Pasos ejecutados, capturas o salidas de consola, fecha, entorno y conclusiones.
*   `admin.txt`: Contiene **únicamente** los comandos ejecutados en `mongosh` para la creación de usuarios, asignación de permisos y ejecución de las pruebas.
*   `restore.txt`: Comandos de consola/herramientas usados, conteos antes/después y verificación de datos (las salidas formateadas se colocan en la bitácora).

> **Formato de entrega:** Un único archivo `.zip` por grupo. No entregar archivos de backup ni archivos no solicitados.

---

**Criterios de logro**

| Criterio | Logrado | Parcial | No logrado |
| :--- | :--- | :--- | :--- |
| **Diagnóstico** | Identifica configuración global y estado del servicio de forma precisa. | Datos incompletos o parciales del diagnóstico. | Sin diagnóstico del entorno. |
| **Autenticación y RBAC** | Pruebas de acceso positivas y negativas completamente verificables. | Asignación de permisos sin la totalidad de las pruebas requeridas. | Sin control de acceso comprobado. |
| **Red y TLS** | Evalúa la superficie de exposición de red y documenta procedimiento TLS. | Análisis superficial de parámetros de red y seguridad. | No revisa puertos ni interfaces de red. |
| **Backup y recuperación** | Ejecución y validación completa del proceso de restauración (`restore`). | Proceso de respaldo generado sin validación de integridad. | No recupera los datos perdidos. |