# UTN FRRe | Sistemas de Gestión de Bases de Datos | 2026
## UNIDAD 5 - ACTIVIDAD 1
### Etapa 1: Preparar el servidor para recibir conexiones

**Guía complementaria para estudiantes:** VirtualBox o Multipass | MySQL o PostgreSQL.  
**Objetivo:** Lograr que todos los integrantes del grupo puedan conectarse desde sus propias computadoras al mismo SGBD que se ejecuta dentro de la VM del grupo en la misma red local (Wi-Fi/LAN).

---

### 1. Antes de empezar: cuatro ideas mínimas

| Concepto | Qué significa en esta actividad |
| :--- | :--- |
| **Servidor** | La VM Ubuntu donde está instalado MySQL o PostgreSQL. |
| **Dirección IP** | La dirección que permite localizar esa VM desde otra computadora. |
| **Puerto** | La puerta TCP donde escucha el SGBD: normalmente `3306` en MySQL y `5432` en PostgreSQL. |
| **Cliente** | Workbench o pgAdmin instalado en la computadora de cada integrante. |

* **Regla clave:** `localhost` y `127.0.0.1` siempre significan "esta misma computadora". Desde la PC de otro integrante no deben usarse para conectarse a la VM del grupo.
* **Esquema objetivo:** `PC A / PC B / PC C → red local → VM del grupo (MySQL / PostgreSQL)`.

---

### 2. Paso 1 - Verificar el motor dentro de la VM

Validar localmente el funcionamiento del motor antes de modificar red o firewall.

**MySQL**
```bash
sudo systemctl status mysql
mysql -u USUARIO -p
SELECT VERSION();
SHOW VARIABLES LIKE 'port';
```

**PostgreSQL**
```bash
sudo systemctl status postgresql
psql -U USUARIO -d BASE
SELECT version();
SHOW port;
```

**Registro de verificación:**

| Parámetro | Resultado |
|---|---|
| **Motor y versión** | *(Completar)* |
| **Puerto observado** | *(Completar)* |
| **Servicio activo** | SÍ / NO |

---

### 3. Paso 2 - Configurar la red de la VM

#### A. Si usan VirtualBox

Configurar en modo **Adaptador puente (Bridged Adapter)** para que la VM opere como un nodo más en la red local.

1. Apagar la VM.
2. Acceder a: `VirtualBox → Configuración → Red`.
3. En **Adaptador 1**, marcar **Habilitar adaptador de red**.
4. En **Conectado a**, seleccionar **Adaptador puente**.
5. Seleccionar la interfaz física activa del host (Wi-Fi o Ethernet).
6. Guardar, iniciar Ubuntu y ejecutar `ip addr`.

> **Nota:** Identificar una IPv4 privada válida (`192.168.x.x`, `10.x.x.x` o `172.16.x.x` - `172.31.x.x`). No utilizar `127.0.0.1`.

#### B. Si usan Multipass

Configurar interfaz puente para exponer la VM fuera del host:

```bash
multipass version
multipass list
multipass info NOMBRE_VM
multipass networks
```

**Procedimiento para instancia existente (Multipass 1.14+):**

```bash
multipass set local.bridged-network NOMBRE_INTERFAZ
multipass stop NOMBRE_VM
multipass set local.NOMBRE_VM.bridged=true
multipass start NOMBRE_VM
multipass get local.NOMBRE_VM.bridged
multipass info NOMBRE_VM
```

**Comportamiento por plataforma anfitriona:**

| Host | Comportamiento esperado |
|---|---|
| **Windows** | Lista switches con Hyper-V o VirtualBox. Consultar al JTP si no lista opción puente. |
| **Linux** | Con QEMU lista Ethernet/bridges; Wi-Fi suele no admitir bridging directo. |
| **macOS** | Con QEMU/VirtualBox lista interfaces físicas y bridges (incluyendo Wi-Fi). |

---

### 4. Paso 3 - Configurar escucha para conexiones externas

#### A. PostgreSQL

1. Localizar archivos de configuración:
```sql
SHOW config_file;
SHOW hba_file;
```

2. Modificar `postgresql.conf`:
```ini
listen_addresses = '*'
```

3. Agregar regla en `pg_hba.conf` adaptada a la subred real de trabajo:
```text
host all all 192.168.1.0/24 scram-sha-256
```
*(No usar `0.0.0.0/0` de manera indiscriminada)*.

4. Aplicar cambios:
```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

#### B. MySQL

1. Modificar directiva en el archivo de configuración (`my.cnf` o subdirectorios):
```ini
bind-address = 0.0.0.0
```

2. Reiniciar servicio:
```bash
sudo systemctl restart mysql
sudo systemctl status mysql
```

3. Crear credenciales de acceso remoto dedicadas:
```sql
CREATE USER 'sgbd_u5'@'%' IDENTIFIED BY 'CLAVE_DEL_GRUPO';
GRANT ALL PRIVILEGES ON sgbd_u5.* TO 'sgbd_u5'@'%';
```

---

### 5. Paso 4 - Verificar puertos de escucha en red

Ejecutar en la VM:

```bash
sudo ss -lntp
```

| Salida observada | Diagnóstico |
|---|---|
| `127.0.0.1:3306` / `5432` | El servicio acepta únicamente tráfico local. Revisar configuración del motor. |
| `0.0.0.0:3306` / `5432` | El servicio escucha correctamente por todas las interfaces de red de la VM. |

---

### 6. Paso 5 - Prueba de conectividad TCP

Probar alcance de puerto desde el host y desde equipos externos antes de abrir clientes gráficos:

* **Desde Windows (PowerShell):**
```powershell
Test-NetConnection IP_VM -Port 3306   # MySQL
Test-NetConnection IP_VM -Port 5432   # PostgreSQL
```

* **Desde Linux / macOS:**
```bash
nc -vz IP_VM 3306   # MySQL
nc -vz IP_VM 5432   # PostgreSQL
```

**Matriz de verificación TCP:**

| Integrante | SO del host | IP del servidor | Puerto | Resultado |
|---|---|---|---|---|
| *(Nombre)* | *(SO)* | *(IP)* | *(Puerto)* | OK / Fallo |

---

### 7. Paso 6 - Gestión de Firewall (UFW)

Revisar solo si la prueba de puerto falló y el servicio está confirmado en `0.0.0.0`:

```bash
sudo ufw status
```

Habilitar el puerto correspondiente si el firewall se encuentra activo:

```bash
sudo ufw allow 3306/tcp   # MySQL
sudo ufw allow 5432/tcp   # PostgreSQL
```

---

### 8. Paso 7 - Conexión desde el cliente gráfico

| Parámetro | MySQL Workbench | pgAdmin |
|---|---|---|
| **Hostname / Address** | IP de la VM | IP de la VM |
| **Port** | `3306` | `5432` |
| **Username** | Usuario de laboratorio | Usuario de laboratorio |
| **Database** | *(Opcional / Por defecto)* | `sgbd_u5` |

> **Criterio de éxito:** Todos los integrantes deben validar conexión simultánea desde sus puestos al servidor del grupo.

---

### 9. Contingencia: Redes no compartidas

Si los puestos no comparten la misma subred física, utilizar una VPN privada (p. ej., LogMeIn Hamachi) autorizada por la cátedra:

`PC A / PC B / PC C → VPN privada (Hamachi) → Host anfitrión → VM → SGBD`

---

### 10. Árbol de diagnóstico rápido

| Pregunta de control | Si la respuesta es NO | Si la respuesta es SÍ |
|---|---|---|
| **¿El SGBD funciona dentro de la VM?** | Resolver servicio o configuración local. | Continuar. |
| **¿Escucha en una interfaz externa?** | Corregir `listen_addresses` o `bind-address`. | Continuar. |
| **¿El host alcanza `IP_VM:puerto`?** | Revisar modo de red de la VM, IP y firewall. | Continuar. |
| **¿Otra PC alcanza `IP_VM:puerto`?** | Revisar bridge, switch físico, LAN o aplicar VPN. | Continuar. |
| **¿Workbench / pgAdmin conecta?** | Auditar credenciales, permisos de usuario y base. | **Etapa 1 completada**. |

---

### 11. Checklist final de la Etapa 1

| # | Punto de control | Estado |
|---|---|---|
| 1 | El SGBD funciona dentro de la VM | [ ] |
| 2 | Identificamos versión y puerto | [ ] |
| 3 | Configuramos VirtualBox o Multipass según la guía | [ ] |
| 4 | Identificamos una IP de la VM alcanzable | [ ] |
| 5 | Configuramos escucha remota del SGBD | [ ] |
| 6 | Configuramos autenticación/usuario de laboratorio | [ ] |
| 7 | Verificamos el puerto con `ss` | [ ] |
| 8 | El host alcanza el puerto | [ ] |
| 9 | Otra PC del grupo alcanza el puerto | [ ] |
| 10 | Todos los integrantes conectan con Workbench/pgAdmin | [ ] |