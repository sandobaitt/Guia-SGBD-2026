# Guía Paso a Paso - Actividad 1 (Unidad 5)

Esta guía condensa las instrucciones para que el grupo pueda completar satisfactoriamente la Actividad 1, basada en **MySQL** y **MySQL Workbench**.

## Etapa 1: Preparación del Servidor (La Máquina Virtual)

*Esta etapa se realiza únicamente en la PC de un solo integrante (quien alojará la Máquina Virtual).*

### 1. Aplicar el Script de Configuración Inicial
Antes de abrir la red, vamos a crear los usuarios y esquemas de la Unidad 5.
Dentro de la VM Ubuntu, abre una terminal y ejecuta el script proporcionado:
```bash
# Asumiendo que el archivo está en tu carpeta actual
sudo mysql < U5_Setup_MySQL.sql
```
*Esto creará los usuarios `alumno01` a `alumno06` con la clave `SgbdU5_2026!`, y la base `sgbd_u5`.*

### 2. Configurar la Red de la VM (Adaptador Puente)
Para que los demás puedan "ver" a la VM en la red Wi-Fi o LAN de la universidad/casa:
1. Apaga la VM.
2. En VirtualBox: Ve a `Configuración -> Red -> Adaptador 1`.
3. Cambia "Conectado a:" a **Adaptador puente (Bridged Adapter)**.
4. Selecciona tu placa Wi-Fi o de Red.
5. Inicia la VM.
6. En la terminal de la VM, escribe `ip addr` y anota la IP asignada (ej. `192.168.1.50`).

### 3. Exponer MySQL a la Red Externa
Por defecto, MySQL solo escucha en `127.0.0.1` (localhost). Debemos abrirlo a la red local.
1. Abre el archivo de configuración:
   ```bash
   sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
   # (La ruta puede variar levemente en tu instalación)
   ```
2. Busca la línea `bind-address` y modifícala:
   ```ini
   bind-address = 0.0.0.0
   ```
3. Guarda el archivo (Ctrl+O, Enter, Ctrl+X) y reinicia el servicio:
   ```bash
   sudo systemctl restart mysql
   ```
4. Comprueba que está escuchando:
   ```bash
   sudo ss -lntp
   # Deberías ver: 0.0.0.0:3306
   ```

---

## Etapa 2: Conexión de Todo el Grupo

*Esta etapa la hacen TODOS los integrantes desde sus propias computadoras físicas.*

1. Abre **MySQL Workbench**.
2. Haz clic en el ícono **+** junto a "MySQL Connections".
3. Completa:
   - **Connection Name:** Servidor Grupo (o el que prefieras).
   - **Hostname:** La IP de la VM obtenida en la Etapa 1 (ej. `192.168.1.50`).
   - **Port:** `3306`.
   - **Username:** `alumno01` (el integrante 2 usará `alumno02`, etc).
4. Haz clic en **Test Connection**, ingresa la clave `SgbdU5_2026!` y confirma el éxito.
5. **[EVIDENCIA]** ¡Saca captura de pantalla de la conexión exitosa para la bitácora!

---

## Etapa 3: Checklist DBA en Workbench

Una vez conectados a la base de datos `sgbd_u5`, busquen en Workbench las siguientes herramientas y completen el archivo `bitacora_resuelta.md`:

1. **Objetos:** Panel izquierdo `Navigator` -> pestaña `Schemas`.
2. **Seguridad:** Pestaña `Administration` (al lado de Schemas) -> `Users and Privileges`.
3. **Metadatos:** En `Schemas`, clic derecho en cualquier tabla (ej. *movimientos*) -> `Table Inspector`.
4. **Ingeniería Inversa:** Menú superior `Database` -> `Reverse Engineer`. (Sigue el asistente hasta que dibuje el diagrama ERD y sácale captura).

---

## Etapa 4: Primera Guardia DBA (Monitorización)

Con Workbench abierto, naveguen por la pestaña **Administration**:
1. Abran **Client Connections**: Cuéntenlas, vean qué IP corresponde a qué integrante y miren el estado (*Sleep* o *Query*). Saquen captura.
2. Abran **Dashboard**: Miren los gráficos de `Network Traffic`, `MySQL Server CPU`, y `InnoDB Buffer Pool`.
3. En la sección *Management*, busquen herramientas útiles como **Server Logs** (para diagnosticar errores fatales).
4. Con estos datos recopilados, completen las conclusiones de "Estado General" en la bitácora.

---

## Etapa 5: Plan de Ejecución (Visual Explain)

1. Abran una nueva pestaña SQL en Workbench.
2. Escriban una consulta simple pero que lea datos, por ejemplo:
   ```sql
   USE sgbd_u5;
   SELECT * FROM movimientos WHERE monto > 1000;
   ```
3. En vez de ejecutarla con el rayito normal, hagan clic en el ícono de la lupa con el rayito o presionen `Ctrl + Alt + X` (Execute Explain).
4. Cambien la vista en el panel de resultados de "Tabular Explain" a **"Visual Explain"**.
5. Saquen captura del diagrama de cajas generado (rojo/verde/azul) y péguenlo en la bitácora, analizando qué nodo fue el más costoso según la leyenda.
