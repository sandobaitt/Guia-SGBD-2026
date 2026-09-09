# Defensa y Explicación Teórica - Actividad 3

Este archivo es tu escudo para la defensa de las decisiones arquitectónicas tomadas durante la migración de v1 a v2.

---

## 1. Riesgos y Pérdida de Datos en el Rollback (Pregunta Obligatoria)

La consigna pide explícitamente:
> **Defensa esperada:** El grupo debe explicar cómo garantizó continuidad, qué riesgos detectó, cómo validó la migración y qué haría diferente para un despliegue real.

**Tu Defensa:**
> "Garantizamos la **continuidad** usando un `ALTER TABLE` con un valor `DEFAULT 'pendiente'`. Gracias a esto, los registros antiguos (v1) heredaron instantáneamente un estado lógico en v2 sin romperse y sin dejar campos nulos.
>
> **Sobre los riesgos detectados:** El mayor riesgo en las bases de datos no es avanzar (migrar), es retroceder (rollback). Si la v2 está viva durante 3 días procesando estados de envíos, y nosotros ejecutamos el script de rollback (`DROP COLUMN estado`), todo ese progreso se destruye para siempre sin chance de recuperarlo con código, porque el motor aniquila la columna físicamente. Por eso nuestro script de rollback tiene una advertencia gigante obligando a hacer un Backup previo.
>
> **¿Qué haríamos diferente en un despliegue real?** En la vida real (en bases gigantescas) hacer un `ALTER TABLE` bloquea la tabla entera por mucho tiempo y genera caídas de servicio. En lugar de eso, usaríamos estrategias como el patrón 'Expand and Contract' (crear una tabla de estados paralela temporal y sincronizarla en background antes de apuntar la app) o herramientas de migración líquida (como Liquibase/Flyway) que manejan los bloqueos inteligentemente."

---

## 2. ENUM vs Tabla de Referencia

**Pregunta del Profesor:** Para manejar los estados ('pendiente', 'pagado', etc.), ¿por qué crearon una columna `ENUM` en vez de crear una tabla nueva llamada `estado_pedido` y conectarla con una Foreign Key?

**Tu Defensa:**
> "Para un sistema gigante donde los usuarios pueden crear sus propios estados dinámicamente, sí, usar una tabla separada conectada con un JOIN es lo correcto. Sin embargo, en el contexto de un e-commerce estándar, los estados ('pendiente', 'pagado', 'enviado', 'cancelado') son un conjunto **cerrado y altamente estático**. 
> - Si usamos una tabla separada, obligaríamos a la aplicación a hacer un `JOIN` extra en absolutamente TODAS las lecturas de pedidos, ralentizando el sistema y fragmentando los datos.
> - Al usar `ENUM`, el motor MySQL valida internamente que no entren otros valores (nos ahorramos una restricción), ocupa solo 1 byte en disco, y la lectura del pedido es instantánea sin JOINs."

---

## 3. Función vs Consulta Directa

**Pregunta del Profesor:** ¿Por qué crear una función `calcular_total_cliente()` en la base de datos (v2) si la aplicación backend en Node/Python podría sumar esos pedidos?

**Tu Defensa:**
> "Al igual que vimos en la Actividad 2, mover este cálculo al backend obligaría a transferir por red absolutamente todos los detalles de facturación de un cliente desde la BD hacia la API de Backend para sumarlos en RAM. A medida que un cliente acumula 10 años de historial de compras, eso saturaría la memoria de la aplicación. 
> Creando una **Función Almacenada** en el motor, forzamos a que MySQL haga todo el trabajo pesado leyendo directo de los bloques del disco, y solo transfiera por la red 1 mísero número (el resultado final). Además, esa misma función luego se puede re-utilizar en decenas de reportes (CTEs) sin tener que duplicar la lógica de `SUM()` en cada archivo SQL."
