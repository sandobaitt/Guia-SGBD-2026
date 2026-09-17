# Conceptos Teóricos - Actividad 2 (Unidad 5)
**Transacciones, Aislamiento y Bloqueos en MySQL (InnoDB)**

Para defender exitosamente la Actividad 2, es vital comprender por qué el motor de base de datos interviene de diferentes maneras ante el acceso concurrente de múltiples usuarios a los mismos datos.

---

## 1. Locks (Bloqueos) y Esperas
Un **Lock** o candado es un mecanismo de protección. Cuando una sesión intenta modificar una fila (`UPDATE`, `DELETE`, `INSERT`), el motor (InnoDB en el caso de MySQL) solicita un **Exclusive Lock (X)** sobre ese registro.

- **Lock Wait (Espera por Lock):** Si la Sesión B intenta modificar la cuenta 1, pero la Sesión A ya la estaba modificando y todavía no hizo `COMMIT` o `ROLLBACK`, la Sesión B pasará al estado de `WAITING`. Esto **no es un error**, es el comportamiento normal y deseable de un sistema relacional para evitar la corrupción de datos (condición de carrera).
- Cuando A finaliza su transacción (suelta el candado), B lo agarra instantáneamente y prosigue.

## 2. Niveles de Aislamiento y MVCC
El aislamiento dicta "qué tan hermética" es una transacción respecto al ruido que generan otras transacciones concurrentes en el sistema.

MySQL (InnoDB) utiliza por defecto el nivel **REPEATABLE READ** (Lectura Repetible).
- Esto significa que si ejecutas un `SELECT`, el motor toma una especie de "foto temporal" (Snapshot) del estado de la base de datos en ese milisegundo.
- Si dentro de esa misma transacción vuelves a hacer el mismo `SELECT` 10 minutos después, seguirás viendo exactamente los mismos datos de la foto original, **incluso si** en el ínterin otro usuario modificó esos datos y los confirmó.

El mecanismo interno que permite mantener estas "versiones fantasma" de los datos sin frenar todo el sistema se llama **MVCC (Multi-Version Concurrency Control)**. Esto garantiza consistencia para tu lógica de negocios.

## 3. Deadlock (El Abrazo Mortal)
A diferencia de un *Lock Wait* (que es temporal y lineal), un **Deadlock** es una situación fatal y circular.
- La Sesión A tiene bloqueada la Cuenta 1 y necesita la Cuenta 2.
- La Sesión B tiene bloqueada la Cuenta 2 y necesita la Cuenta 1.
- **Resultado:** Ninguno puede avanzar, ambos se quedarían esperando al infinito.

El SGBD interviene de inmediato: un algoritmo en segundo plano detecta este ciclo, elige a la transacción que sea "más barata" o que haya hecho menos cambios, la clasifica como **Víctima** y la **aborta** forzando un `ROLLBACK` y arrojando el **Error 1213 (Deadlock)**. La otra transacción es perdonada y puede continuar.

## 4. Estrategias Preventivas
Como administradores y desarrolladores, no debemos escalar los servidores agregando RAM/CPU para "evitar" bloqueos lógicos, sino diseñar mejor nuestro código:

1. **Orden Determinístico:** Si el código fuente de nuestra aplicación siempre bloquea o actualiza las filas en un orden preestablecido (ej. siempre de menor a mayor ID), jamás ocurrirán ciclos de Deadlocks cruzados. Todos harán fila ordenada.
2. **Transacciones ultra-cortas:** El tiempo que dura el "candado" puesto es el tiempo que tarde en procesarse el código entre el `START TRANSACTION` y el `COMMIT`. Las transacciones deben hacer únicamente tareas de escritura masiva muy rápidas, y jamás esperar que el usuario "haga clic" en un botón de la pantalla mientras la transacción sigue abierta en la base de datos.
