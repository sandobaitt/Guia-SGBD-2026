**U10 - Actividad 1 · De la VM a la nube: operar un SGBD como servicio**

*   **Requisitos de finalización:** Por hacer: Hacer un envío.
*   **Modalidad:** Grupal.
*   **Duración orientativa:** Una clase práctica (60 minutos, con cuentas preparadas).
*   **Entrega:** Un PDF breve y archivos de comandos.

**Desafío**
Seleccionar **un solo motor** entre los modelos estudiados y utilizarlo en una plataforma cloud con modalidad gratuita, sin contratar servicios pagos ni registrar tarjetas de crédito.

**Opciones orientativas (verificar disponibilidad y límites)**
*   **Relacional:** PostgreSQL en Neon o Supabase / MySQL en MariaDB Cloud.
*   **Documental:** MongoDB en MongoDB Atlas.
*   **Clave-valor:** Redis en Redis Cloud.
*   **Columnas anchas:** Cassandra en Astra DB (si existe una modalidad gratuita apta).
*   **Grafos:** Neo4j en AuraDB (si existe una modalidad gratuita apta).

> **Nota:** La plataforma y las funciones del plan gratuito deben ser validadas por el JTP antes de comenzar. Si una opción no permite demostrar los mínimos, se deberá seleccionar otra.

---

### Consignas

**1. Identificar el entorno**
*   **Motor seleccionado:**
*   **Versión del motor:**
*   **Proveedor cloud:**
*   **Servicio DBaaS / Plan utilizado:**
*   **Región del servicio:**

**2. Provisionar y conectar**
Crear el servicio, identificar región, motor/versión, *endpoint* y límites. Probar una conexión autenticada (sin publicar credenciales).

**3. CRUD**
Crear una estructura y al menos cinco registros; demostrar una lectura, una actualización y una eliminación. Entregar comandos y salidas reproducibles.

**4. Accesos**
Crear o configurar una identidad de acceso restringido y demostrar una operación autorizada y otra rechazada. Distinguir permisos del motor de permisos de la plataforma. Si el plan no admite RBAC granular, documentar la restricción y ejecutar el control de acceso más cercano disponible, aprobado por el JTP.

**5. Backup**
Identificar la protección administrada disponible. Generar un respaldo lógico/exportación y verificar una recuperación en un entorno de prueba, si el servicio lo permite.
> *No presentar una captura de "backup activado" como prueba de restauración.*

**6. Comparar**
Completar la matriz **VM vs. DBaaS** explicando qué administra el proveedor y qué sigue administrando el equipo:

| Aspecto | VM — Administración tradicional | DBaaS — Servicio Cloud | ¿Quién administra en DBaaS? | Evidencia / Observaciones |
| :--- | :--- | :--- | :--- | :--- |
| **Instalación y SO** | ¿Cómo se instala el motor? ¿Quién administra el sistema operativo y las actualizaciones? | ¿Cómo se provisiona el servicio? ¿Existe acceso al SO? | | |
| **Conectividad** | ¿Cómo se configura el acceso mediante IP, puerto y credenciales? | ¿Cómo se obtiene el *endpoint* y se configura la conexión? | | |
| **CRUD** | ¿Cómo se ejecutan las operaciones sobre los datos? | ¿Se utilizan los mismos comandos? ¿Existen diferencias? | | |
| **Permisos / RBAC** | ¿Cómo se crean usuarios, roles y privilegios? | ¿Qué mecanismos de autenticación y autorización ofrece el servicio? | | |
| **Backup / Restore** | ¿Cómo se genera un respaldo y se ejecuta una restauración? | ¿Qué mecanismos ofrece el proveedor? ¿Qué permite el plan gratuito? | | |
| **Monitoreo** | ¿Cómo se consultan logs, métricas y estado del motor? | ¿Qué indicadores y herramientas proporciona la plataforma? | | |
| **Costos** | ¿Qué recursos requiere mantener la VM? | ¿Qué recursos se facturan? ¿Cuáles son los límites del plan gratuito? | | |

> En la columna **¿Quién administra en DBaaS?**, indicar **Proveedor**, **Equipo** o **Compartida**, explicando brevemente la distribución de responsabilidades.

**7. Conclusiones**
Responder brevemente, utilizando evidencia de la implementación:
*   **Responsabilidades delegadas:** ¿Qué tareas que realizaban sobre la VM ahora ejecuta el proveedor?
*   **Responsabilidades que permanecen:** ¿Qué tareas continúan siendo responsabilidad del equipo de administración?
*   **Limitaciones:** ¿Qué operaciones no pudieron realizar debido a restricciones del servicio o del plan gratuito?
*   **Diferencias operativas:** ¿Qué cambió realmente al ejecutar CRUD, administrar permisos y realizar respaldos?
*   **Reflexión final:** ¿DBaaS elimina la necesidad de administrar bases de datos o transforma el rol del DBA? Justificar.

---

### Entrega y Evaluación

*   **Entrega:** Un **informe PDF** con identificación del motor y servicio, evidencias de las cuatro operaciones, matriz comparativa y conclusión; incluir scripts o archivo de comandos.

> **Pregunta para debate final:** ¿DBaaS elimina la necesidad de administrar bases de datos o transforma el rol del DBA?

**Criterios de evaluación** *(Escala: Logrado / Parcial / No logrado)*

| Criterio | Peso |
| :--- | :---: |
| **Provisionamiento** | 20 % |
| **CRUD** | 20 % |
| **Seguridad / permisos** | 20 % |
| **Respaldo / recuperación** | 20 % |
| **Comparación VM–DBaaS** | 20 % |