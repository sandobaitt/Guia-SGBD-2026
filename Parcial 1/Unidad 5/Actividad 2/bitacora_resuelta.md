# Bitácora Técnica - Actividad 2 (Unidad 5)
**Concurrencia & Bloqueos**

**Grupo:** [Insertar Nombre/Número del Grupo]
**Motor Asignado:** MySQL
**Integrantes:**
- [Nombre Integrante A] (Actuará como Sesión A)
- [Nombre Integrante B] (Actuará como Sesión B)

---

## Experimento 1: ¿Quién bloquea a quién? (Espera por Lock)

**Línea temporal:**
1. **Sesión A** inició una transacción (`START TRANSACTION`) y ejecutó un `UPDATE` restando 100 al saldo de la cuenta 1, pero **no hizo COMMIT**.
2. **Sesión B** intentó hacer un `UPDATE` sobre la **misma fila** (cuenta 1). Al ejecutarlo, la consola de B se quedó "colgada" esperando.

**Auditoría (Mientras B esperaba):**
Mediante `SHOW PROCESSLIST` y revisando `performance_schema.data_locks`, pudimos evidenciar lo siguiente:
- **¿Qué sesión está esperando?** La Sesión B.
- **¿Qué sesión mantiene el lock (bloqueo)?** La Sesión A.
- **¿La consulta está "lenta" o está esperando un recurso?** No está lenta computacionalmente; está suspendida activamente (esperando un recurso).
- **Evidencia:** La tabla `data_locks` mostró que la Sesión A posee un **Exclusive Lock (X)** sobre la fila de la cuenta 1. La Sesión B solicitó también un Lock Exclusivo sobre la misma fila, pero su estado aparece como `WAITING`.

> **[ACCIÓN REQUERIDA]**
> Pegar aquí la captura de pantalla del resultado de `SHOW PROCESSLIST` o de `performance_schema.data_locks` donde se vea el bloqueo.

**Resolución:**
Al ejecutar `COMMIT` en la Sesión A, el motor liberó el lock exclusivo. Inmediatamente, la Sesión B obtuvo el candado que estaba esperando, aplicó su modificación y terminó de ejecutar su consulta exitosamente.

---

## Experimento 2: Aislamiento (¿Vemos lo mismo?)

**Línea temporal:**
1. Verificamos que el nivel de aislamiento por defecto del motor MySQL es: `REPEATABLE READ`.
2. **Sesión A** inició transacción y consultó el saldo de la cuenta 3. Vio un saldo de: `[ANOTAR SALDO INICIAL AQUÍ]`.
3. **Sesión B** inició transacción, modificó el saldo de la cuenta 3 (sumó 1000) y confirmó los cambios con `COMMIT`.
4. **Sesión A**, dentro de su misma transacción que seguía abierta, volvió a consultar el saldo de la cuenta 3.

**Análisis de Resultados:**
- **¿La segunda lectura de A muestra el mismo saldo que la primera?** Sí, muestra exactamente el mismo saldo inicial.
- **¿Ve el cambio confirmado por B?** No, la Sesión A ignoró por completo los 1000 que sumó la Sesión B, a pesar de que B ya había hecho el COMMIT definitivo.
- **Justificación técnica:** Esto ocurre porque el nivel de aislamiento en MySQL es **REPEATABLE READ** (Lectura Repetible). El motor utiliza un mecanismo llamado MVCC (Control de Concurrencia Multiversión), que toma una "foto" (snapshot) del estado de la base de datos en el instante en que la Sesión A hace su primera lectura. Mientras A no cierre su transacción, seguirá viendo esa foto antigua para garantizar la consistencia de su propia lectura, ignorando lo que suceda afuera.

> **[ACCIÓN REQUERIDA]**
> Pegar aquí la captura de pantalla de la Sesión A demostrando que la segunda consulta (Paso 4) arrojó el mismo resultado que la primera consulta (Paso 2).

---

## Experimento 3: Deadlock Controlado

**Línea temporal (Ejecución intercalada):**
1. **Sesión A** bloqueó la cuenta 1 (con un UPDATE).
2. **Sesión B** bloqueó la cuenta 2 (con un UPDATE).
3. **Sesión A** intentó modificar la cuenta 2 -> Quedó esperando a B.
4. **Sesión B** intentó modificar la cuenta 1 -> Quedó esperando a A.

**Registro del Deadlock:**
Apenas se ejecutó el paso 4, se formó una espera circular (Abraso Mortal). El motor InnoDB de MySQL detectó automáticamente este ciclo cerrado y cortó por lo sano, abortando una de las transacciones (arrojando el Error `1213: Deadlock found when trying to get lock; try restarting transaction`).

> **[ACCIÓN REQUERIDA]**
> Pegar aquí la captura de pantalla del mensaje de error (Deadlock) que arrojó Workbench en la consola, y la salida de `SHOW ENGINE INNODB STATUS` (buscando la sección LATEST DETECTED DEADLOCK).

**Análisis Diagnóstico:**
- **¿Qué transacción fue elegida como víctima?** Generalmente, InnoDB aborta la transacción que haya realizado menos modificaciones hasta el momento (en nuestro caso, como ambas hicieron un UPDATE idéntico, abortó a la última en generar el ciclo, es decir, la Sesión B). A esta sesión le hizo un `ROLLBACK` forzado.
- **¿Qué locks formaban el ciclo?** El Lock Exclusivo en el registro de la cuenta 1 y el Lock Exclusivo en la cuenta 2.
- **¿Por qué esto es un deadlock y no una simple espera?** Una espera simple ocurre cuando A espera a B (es lineal). Un deadlock ocurre cuando A espera a B, y al mismo tiempo B espera a A (es circular). Si el motor no interviniera, se quedarían esperando infinitamente.

---

## Desafío Final: Medidas Preventivas

Para reducir la contención, bloqueos y evitar deadlocks sin tener que mejorar el hardware del servidor, proponemos estas dos medidas arquitectónicas/de diseño en las aplicaciones que consumen la base de datos:

1. **Orden estandarizado de acceso a recursos (Evitar ciclos):**
   Si todos los módulos del software y todas las transacciones acceden a las tablas y filas siempre en el mismo orden lógico (por ejemplo, ordenar por `cuenta_id` de menor a mayor antes de actualizar), es matemáticamente imposible que se formen deadlocks. En nuestro Experimento 3, si ambas sesiones hubieran intentado bloquear primero la cuenta 1 y luego la 2, una habría esperado pacíficamente a la otra sin generar un ciclo cruzado.
2. **Mantener transacciones cortas y eficientes:**
   Los bloqueos duran el tiempo que tarde la transacción en hacer COMMIT o ROLLBACK. Si la aplicación abre una transacción, realiza consultas a la base, luego se pone a procesar datos pesados en código Java/PHP o espera que el usuario haga clic en una pantalla, el Lock se mantiene vivo mucho tiempo. La solución es recolectar todos los datos, y abrir la transacción SQL recién en el milisegundo exacto en que se va a enviar la modificación, haciendo el COMMIT de inmediato.
