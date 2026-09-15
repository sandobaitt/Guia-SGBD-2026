**SGBD 2026 - Unidad 5 · Setup unificado**

**Archivos**
*   `U5_Setup_MySQL.sql`
*   `U5_Setup_PostgreSQL.sql`

**Alcance de los scripts**
1. Creación del ambiente de laboratorio.
2. Tablas y datos usados en U5.
3. Creación de `alumno01`..`alumno06`.
4. Permisos de trabajo.
5. Permisos mínimos de observación para Guardia DBA y concurrencia.

**Credencial de laboratorio por defecto**
*   **Usuario:** `alumno01` .. `alumno06`
*   **Password:** `SgbdU5_2026!`

**Ejecución por motor**
*   **MySQL:** Ejecutar con una cuenta administrativa del motor.
*   **PostgreSQL:** Ejecutar preferentemente con `psql`:
    ```bash
    sudo -u postgres psql -f U5_Setup_PostgreSQL.sql
    ```

> **IMPORTANTE:** El script SQL **NO** reemplaza la configuración de acceso remoto.

**Verificaciones previas a la Fase 2**
*   Red de VirtualBox/Multipass.
*   IP alcanzable de la VM.
*   **MySQL:** `bind-address`.
*   **PostgreSQL:** `listen_addresses` y `pg_hba.conf`.
*   Firewall.
*   Puerto `3306` / `5432` accesible desde otra PC.