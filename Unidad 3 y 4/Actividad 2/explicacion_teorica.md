# Defensa y Explicación Teórica - Actividad 2

Este documento te da el sustento teórico para defender las decisiones tomadas en el script. Contiene respuestas clave a las preguntas que puede hacer el profesor.

---

## 1. Reglas en Base de Datos vs Aplicación (Pregunta Obligatoria)

La consigna pide explícitamente:
> **Pregunta para defensa:** ¿Esta regla debería estar en la base, en la aplicación o en ambas? Justifiquen según riesgo, mantenibilidad y evidencia.

**Tu Defensa:**
> "Para reglas críticas (como impedir saldos negativos o auditar precios), la lógica debe estar **en ambas partes**, pero el SGBD debe ser la última e infranqueable línea de defensa. 
> - **En la aplicación:** Se implementa para dar respuesta inmediata al usuario en la interfaz (UX) sin golpear la red ni gastar recursos del servidor (ej. un cartelito rojo si intentas comprar algo sin saldo).
> - **En la base de datos:** Se implementa por un tema de **Riesgo y Consistencia**. Si mañana se conecta a nuestra BD una API externa, una app móvil nueva, o alguien ejecuta una consulta manual en consola saltándose la validación del backend original, el motor de base de datos protegerá la integridad de los datos sí o sí gracias a nuestros `CHECKs` y `TRIGGERS`. A nivel **mantenibilidad**, si la regla de los umbrales de categorías de clientes cambia, actualizar la Función en la base de datos aplica el cambio instantáneamente para todas las apps que la consuman."

---

## 2. Trigger vs CHECK Constraint

**Pregunta del Profesor:** ¿Por qué para el saldo negativo usaron un `CHECK` y no un `TRIGGER` que lance un error (Signal SQLSTATE)?

**Tu Defensa:**
> "Porque un `CHECK constraint` es una regla declarativa pura y matemática (`CHECK saldo >= 0`). El motor la procesa de manera mucho más rápida y eficiente que un `TRIGGER` a nivel de fila, porque el trigger implica instanciar un bloque procedural `BEGIN...END` cada vez que insertas o actualizas un dato. Para algo estático, el `CHECK` es nativo, seguro y cumple la regla técnica de usar restricciones declarativas cuando la lógica lo permita."

---

## 3. Función vs Procedimiento Almacenado

**Pregunta del Profesor:** La consigna dejaba elegir función o procedimiento para categorizar al cliente. ¿Por qué eligieron una Función (`FUNCTION`)?

**Tu Defensa:**
> "El requerimiento principal era **reutilizar un cálculo**. Las funciones están diseñadas para devolver un único valor, lo que nos permite llamarlas directamente dentro de la proyección (SELECT) de otras consultas, como por ejemplo: `SELECT nombre, clasificar_cliente(id, 2026) FROM cliente`.
> Si hubiéramos usado un `PROCEDURE`, tendríamos que haberlo ejecutado con `CALL` obteniendo variables de salida (`OUT`), y no podríamos haberlo integrado tan limpiamente en un reporte tabular de múltiples clientes al mismo tiempo."

---

## 4. Agregación Interna (El "Centro" del Profesor)

**Pregunta del Profesor:** Vi que su función no recibe el monto (ej. `clasificar(2500000)`), sino que recibe el ID y el año. ¿Por qué lo hicieron así?

**Tu Defensa:**
> "Seguimos las buenas prácticas de encapsulamiento. Si la función solo fuera un 'traductor' o 'IF/ELSE' que recibe un número, la responsabilidad de sumar las ventas seguiría recayendo en la aplicación que hace la consulta. Al pasarle solo el ID y el año a nuestra función, le delegamos al SGBD todo el peso del cálculo transaccional (`SUM(total)`). La base de datos es inmensamente más rápida haciendo operaciones de agregación y leyendo el disco (porque tiene los datos en su memoria local) que obligando a una aplicación externa a traer miles de ventas por red para sumarlas del lado del cliente."
