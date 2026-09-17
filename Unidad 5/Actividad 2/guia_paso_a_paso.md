# Guía Paso a Paso - Actividad 2 (Unidad 5)
**Coordinación de Sesiones**

Dado que trabajarán sobre el script unificado (`U5_A2_MySQL_3_experimentos_estudiantes.sql`), es **vital** que no aprieten el botón de "ejecutar todo" (el rayito normal en Workbench). Deberán pintar/seleccionar y ejecutar bloque por bloque según indica el archivo.

Para hacer esta práctica perfecta, elijan a dos integrantes:
- **Integrante A (Sesión A)**: Abrirá una conexión a la VM en su PC.
- **Integrante B (Sesión B)**: Abrirá otra conexión a la misma VM en su PC física.

Ambos deben tener abierto el archivo `U5_A2_MySQL_3_experimentos_estudiantes.sql` en su respectivo Workbench.

---

## Verificación Inicial (Antes de empezar)
1. Cualquiera de los dos (o ambos) ejecuten las primeras consultas (Líneas 31 a 36).
2. Tomen nota de los saldos actuales de las cuentas 1, 2 y 3.
3. Cierren esa pestaña y abran una nueva (o limpien los resultados) para no confundirse.

---

## Experimento 1: Espera por Lock

**Objetivo:** Ver cómo MySQL pone en "lista de espera" a una transacción si otra tiene agarrado el registro.

1. **[SESIÓN A]:** Selecciona y ejecuta el **Paso 1** (desde `START TRANSACTION` hasta el primer `UPDATE`). No ejecutes nada más. (Líneas 53-64).
2. **[SESIÓN B]:** Selecciona y ejecuta el **Paso 2** (`START TRANSACTION` y el `UPDATE` sobre la misma cuenta). (Líneas 73-79).
   > *Notarás que la barra de progreso de Workbench en la Sesión B se queda dando vueltas (ejecutando...). B está bloqueado.*
3. **[SESIÓN A]:** Mientras B está bloqueado, ejecuta las consultas de diagnóstico del **Paso 3** (`SHOW PROCESSLIST` y las de `performance_schema`). Saquen las capturas de pantalla para la bitácora aquí. (Líneas 92-98).
4. **[SESIÓN A]:** Libera a tu compañero ejecutando un `COMMIT` o `ROLLBACK` (Paso 4, línea 113).
5. **[SESIÓN B]:** Verán que el UPDATE que estaba colgado finalmente termina al instante. Ejecuten un `COMMIT` en B para cerrar. (Líneas 119-122).

---

## Experimento 2: Aislamiento (MVCC)

**Objetivo:** Demostrar que MySQL protege las lecturas en una transacción usando el aislamiento `REPEATABLE READ`.

1. **[SESIÓN A]:** Ejecuta el **Paso 1 y 2**. Miren el saldo de la cuenta 3. (Líneas 139 y 148-154).
2. **[SESIÓN B]:** Ejecuta el **Paso 3** completo (Update y Commit). El saldo en la base real ya cambió. (Líneas 163-174).
3. **[SESIÓN A]:** Ejecuta la segunda lectura (**Paso 4**). Sacar captura aquí demostrando que **A** sigue viendo el dato viejo (fantasma/snapshot) ignorando a **B**. (Líneas 181-184).
4. **[SESIÓN A]:** Finalmente ejecuta `COMMIT` para cerrar la transacción.

---

## Experimento 3: Deadlock Controlado

**Objetivo:** Generar un cruce mortal (A espera a B, B espera a A) para que el motor destruya una de las transacciones. Esto requiere ejecutar línea por línea con mucha precisión.

1. **[SESIÓN A]:** Ejecuta el **Paso 1A** (`START TRANSACTION` y el primer `UPDATE`). (Líneas 225-229).
2. **[SESIÓN B]:** Ejecuta el **Paso 1B** (`START TRANSACTION` y su primer `UPDATE`). (Líneas 238-242).
3. **[SESIÓN A]:** Ejecuta el **Paso 2** (el UPDATE a la cuenta 2). 
   > *A se quedará colgado esperando que B termine.* (Líneas 251-254).
4. **[SESIÓN B]:** Ejecuta el **Paso 3** (el UPDATE a la cuenta 1).
   > *B también se cuelga... ¡Pero al instante MySQL dispara un error rojo de Deadlock (Error 1213) y cancela a una de las sesiones!* (Líneas 263-266).
5. **[CUALQUIERA]:** El que sobrevivió, ejecute las consultas del **Paso 4** de Diagnóstico. Abran la salida de `SHOW ENGINE INNODB STATUS`, saquen captura de la sección "LATEST DETECTED DEADLOCK" y peguen el texto de evidencia en la bitácora. (Línea 278).
6. **[CUALQUIERA]:** El sobreviviente haga `ROLLBACK` para dejar todo limpio.

¡Listo! Exporten a PDF su bitácora.
