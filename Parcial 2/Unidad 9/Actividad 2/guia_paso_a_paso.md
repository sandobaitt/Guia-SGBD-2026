# Guía Paso a Paso: U9 - Actividad 2 (Batalla de arquitecturas multimodelo)
**Grupo:** G11 (Escenario: OmniMarket)
**Motores implementados:** Redis (`redis-cli`) y Neo4j Community (`cypher-shell`) · **Diseñados:** PostgreSQL (relacional) y Cassandra
**Archivos:** `bitacora_resuelta.md` (informe) · `redis-omnimarket.txt` y `neo4j-omnimarket.cypher` (scripts de los modelos NoSQL) · `evidencias_terminal_act2.sh` (sesión guiada para las capturas) · `diagrama_arquitectura.png/.svg` y `diagrama_relacional.png/.svg` (diagramas)

> Esta guía sirve para tres cosas: **reproducir** la parte NoSQL y sacar las capturas, **armar el informe** con todos los entregables de la consigna y **preparar la defensa** (batalla entre grupos).

---

## 0. Qué pide la consigna, en palabras simples

| Fase | Qué hay que hacer | Dónde está resuelto |
| :--- | :--- | :--- |
| **1. Diagnóstico** | Listar qué datos y operaciones tiene cada área del negocio, y **explicar los supuestos** de volumen. Separar lo obligatorio de lo que es solo preferencia | Informe, sección 1 |
| **2. Selección y arquitectura** | Elegir un motor por área, **justificar la elegida y al menos una descartada**, dibujar la arquitectura, decir cuál es la fuente de verdad y justificar el **costo de sumar motores** | Informe, sección 2 y diagrama |
| **3. Modelado e implementación** | Modelar. Implementar **al menos dos** motores NoSQL distintos con datos de prueba: altas, modificaciones, bajas, lecturas y **dos consultas de negocio** cada uno. Mostrar un **intercambio de datos** entre componentes y explicar qué se hace ante duplicación y concurrencia | Informe, sección 3 y 4; scripts y sesión guiada |
| **4. Batalla** | Presentar (8 min), cuestionar al rival (5 min), responder objeciones (4 min) | Informe, sección 5; esta guía, sección 6 |

La idea central de la actividad: **no gana quien usa más tecnologías**, sino quien justifica mejor con evidencia. Por eso la decisión se tomó con un método (criterios con peso y una regla para sumar motores) y no por gusto.

---

## 1. Preparación

### 1.1. Qué tiene que estar instalado
```bash
redis-server --version      # Redis (cualquier versión reciente)
neo4j --version             # Neo4j Community
cypher-shell --version
```
No hace falta que los servicios de la Actividad 1 estén detenidos ni activos: la sesión de esta actividad levanta **instancias aparte**, con otros puertos y otras carpetas, y no los toca.

| Instancia | Puerto | Carpeta |
| :--- | :---: | :--- |
| Redis de la Actividad 2 | 6381 | `~/u9_act2/redis` |
| Neo4j de la Actividad 2 (Bolt / HTTP) | 7690 / 7477 | `~/u9_act2/neo4j` |

### 1.2. Recursos y terminal
- Libres unos 1,5 GB de memoria (Neo4j usa hasta 512 MB de heap; Redis casi nada).
- Terminal ancha (140 columnas o más) para que las tablas no se corten. Si algo no entra, achicá la letra con `Ctrl` + `-`.
- **No hace falta `sudo`.** Solo se pide una contraseña: la de Neo4j (la elegís vos, mínimo 8 caracteres, con entrada oculta). **Anotala.**

---

## 2. Ejecutar la sesión guiada

```bash
cd "Parcial 2/Unidad 9/Actividad 2"
./evidencias_terminal_act2.sh
```

En cada paso se muestra el comando, se ejecuta y se detiene con `[Enter] para continuar`: **ahí sacás la captura**. Los comandos de Redis y de Neo4j que ves son **exactamente los de `redis-omnimarket.txt` y `neo4j-omnimarket.cypher`**, así que esos archivos son tu script entregable y la sesión es su demostración.

| Opción | Para qué |
| :--- | :--- |
| `PASO_DESDE=12 ./evidencias_terminal_act2.sh` | Retomar desde un paso. **Solo sirve si las instancias siguen activas** (respondiste `n` al final): si se detuvieron, Redis arranca vacío y el script te avisa. Te pide la clave de Neo4j |
| `REINICIAR=1 ./evidencias_terminal_act2.sh` | Borrar el laboratorio y empezar de cero (para que las capturas queden con los mismos números que el informe) |
| `SIN_PAUSA=1 ./evidencias_terminal_act2.sh` | Correr todo sin pausas, solo para verificar que funciona |

> **Para sacar las capturas definitivas conviene `REINICIAR=1`.** Si repetís la sesión sin reiniciar, Neo4j conserva los datos de la corrida anterior (el pedido `PED-0002` ya existe) y los conteos de la integración no coincidirán con los del informe.

### 2.1. Tabla de pasos

El número de **captura** del informe es el número del paso. Obligatorio = lo pide la consigna; recomendado = respalda una explicación del informe.

| Paso | Qué muestra | Qué escribís | Obligatorio |
| :---: | :--- | :--- | :---: |
| 1 | Se crean Redis y Neo4j aislados; versiones y puertos | **La clave de Neo4j** (oculta) y Enter | Sí |
| 2 | Redis responde (`PING`) | Solo Enter | Opcional |
| 3 a 5 | Carga del modelo: sesiones, carritos, ranking y promociones | Solo Enter | Opcional |
| 6 | Tipo de cada estructura (`TYPE`) y total de claves | Solo Enter | **Sí** |
| 7 | Redis · **Altas** | Solo Enter | **Sí** |
| 8 | Redis · **Lecturas** | Solo Enter | **Sí** |
| 9 | Redis · **Modificaciones** | Solo Enter | **Sí** |
| 10 | Redis · **Bajas** | Solo Enter | **Sí** |
| 11 | Expiración: la sesión inactiva desaparece sola (espera 4 s) | Solo Enter | Recomendado |
| 12 | Consulta de negocio 1: top 3 de productos más vistos | Solo Enter | **Sí** |
| 13 | Consulta de negocio 2: unidades en el carrito (script Lua) | Solo Enter | **Sí** |
| 14 y 15 | Consultas 3 y 4: sesión vigente y promociones activas | Solo Enter | Opcional |
| 16 | Neo4j: versión y edición `community` | Solo Enter | Recomendado |
| 17 | Restricciones de unicidad (incluye la de la relación `COMPRO`) | Solo Enter | Recomendado |
| 18 y 19 | Carga de clientes, catálogo, compras, seguimientos y vistas | Solo Enter | Opcional |
| 20 | Conteos: 16 nodos y 34 relaciones | Solo Enter | **Sí** |
| 21 | Neo4j · **Alta** | Solo Enter | **Sí** |
| 22 | Neo4j · **Lectura** | Solo Enter | **Sí** |
| 23 | Neo4j · **Modificación** | Solo Enter | **Sí** |
| 24 | Neo4j · **Baja** (relación y nodo) | Solo Enter | **Sí** |
| 25 | Consulta de negocio 1: recomendaciones para U01 | Solo Enter | **Sí** |
| 26 | Consulta de negocio 2: productos que se compran juntos | Solo Enter | **Sí** |
| 27 | Consulta de negocio 3: segmento de remarketing | Solo Enter | Recomendado |
| 28 | Versión: el evento viejo se descarta | Solo Enter | Recomendado |
| 29 | Idempotencia: aplicar dos veces el mismo pedido (4 y 4) | Solo Enter | Recomendado |
| 30 | La restricción rechaza una línea duplicada | Solo Enter | Recomendado |
| 31 | Integración 1: carrito de U01 en Redis | Solo Enter | **Sí** |
| 32 | Integración 2: el evento (mensaje del outbox) | Solo Enter | **Sí** |
| 33 | Integración 3: el consumidor lo aplica en Neo4j (2 → 4 compras) | Solo Enter | **Sí** |
| 34 | Integración 4: reentrega del mismo evento (siguen 4) | Solo Enter | **Sí** |
| 35 | Integración 5: Neo4j calcula y Redis sirve las recomendaciones (TTL 3600) | Solo Enter | **Sí** |
| 36 | Integración 6: se vacía el carrito | Solo Enter | Recomendado |
| 37 y 38 | Concurrencia: 200 con la operación atómica y un valor muy inferior sin ella | Solo Enter | Recomendado |

Al final te pregunta si querés detener las instancias: respondé `S` (o Enter) para liberar memoria, o `n` si querés seguir probando a mano (sección 3).

> **Los pasos 37 y 38 dan un número distinto en cada corrida** (el segundo, muy por debajo de 200). Ese valor es el que va en el informe (sección 3.6, tabla del experimento): reemplazá el texto `[completar: valor muy inferior a 200]` por lo que viste.

---

## 3. Si querés probar a mano

Al terminar la sesión, respondé `n` a "¿Detenerlas ahora?". Las instancias quedan activas:
```bash
redis-cli -p 6381                                   # consola de Redis (salir: exit)
cypher-shell -a bolt://localhost:7690 -u neo4j      # pide la clave; cada sentencia termina en ";" (salir: :exit)
```
Cuando termines:
```bash
redis-cli -p 6381 shutdown nosave
NEO4J_CONF=$HOME/u9_act2/neo4j/conf neo4j stop
```
Para ejecutar un script completo sin la sesión guiada (con las instancias activas):
```bash
export NEO4J_PASSWORD='<tu clave>'
cypher-shell -a bolt://localhost:7690 -u neo4j -p "$NEO4J_PASSWORD" -f neo4j-omnimarket.cypher
grep -v '^#' redis-omnimarket.txt | grep -v '^$' | redis-cli -p 6381    # sin las esperas ni los pasos
```

---

## 4. Armar el informe PDF

La bitácora (`bitacora_resuelta.md`) ya está escrita con el formato del informe. Para entregarla:

1. **Completar los datos:** integrantes del grupo, y el valor del experimento de concurrencia (sección 3.6).
2. **Pegar cada captura** en su marcador `*[INSERTAR CAPTURA N: ...]*` (el número es el del paso de la tabla 2.1). Si descartás una captura opcional, borrá su marcador.
3. **Insertar los dos diagramas** (`diagrama_arquitectura.png` en la sección 2.5 y `diagrama_relacional.png` en la 3.1).
4. **Revisar que ninguna captura muestre la clave de Neo4j.** La sesión la pide con entrada oculta y los comandos no la contienen.
5. **Decidir con el grupo los supuestos de volumen** (sección 1.1): son números nuestros. Si los cambian, cambia la matriz; la regla de la sección 2.1 indica qué decisión se modifica.
6. **Completar el registro de objeciones** (sección 5.4) durante o después de la batalla.

### 4.1. Entregables de la consigna y dónde están

| Entregable | Archivo o sección |
| :--- | :--- |
| Informe PDF: matriz de requisitos, matriz de decisión de los cinco modelos, alternativas descartadas | Secciones 1 y 2 de la bitácora |
| Diagrama de arquitectura | `diagrama_arquitectura.png` (editable: `.svg`) |
| Modelos NoSQL: diseños, scripts, capturas y resultados | Sección 3.2 a 3.5; `redis-omnimarket.txt` y `neo4j-omnimarket.cypher` |
| Diseño relacional (sin implementación) | Sección 3.1, `diagrama_relacional.png` y Anexo A |
| Presentación para defensa y objeciones | Sección 5 de la bitácora y sección 6 de esta guía |
| Estrategia de integración | Sección 4 de la bitácora |

### 4.2. Los diagramas
- Los `.png` se insertan directamente en el PDF.
- Los `.svg` son editables con draw.io, Inkscape o PowerPoint si el grupo quiere cambiar colores, textos o agregar un componente.

---

## 5. Cómo leer la decisión (para poder defenderla)

Antes de la batalla, cada integrante tiene que poder explicar **sin mirar** estas cinco cosas:

1. **Por qué hay un núcleo relacional:** siete de diez dominios necesitan integridad entre sí (un pedido descuenta stock, registra el pago y acredita puntos en una sola transacción).
2. **Cuándo se suma un motor NoSQL:** solo si hay un criterio de peso 3 que el relacional no cubre bien. Eso pasa en tres dominios: sesiones (expiración), navegación (escritura masiva) y recomendaciones (recorridos).
3. **Por qué no MongoDB:** en el catálogo empata con el relacional (23 a 23) y `JSONB` cubre la flexibilidad. Sumarlo no se justifica.
4. **Qué es la fuente de verdad y el outbox:** cada dato tiene un dueño; los demás motores reciben copias por eventos que se guardan en la misma transacción del pedido y se reintentan hasta aplicarse.
5. **Qué demuestran los experimentos:** reentregar un evento no duplica (idempotencia), un evento viejo no pisa uno nuevo (versión), y la operación atómica no pierde actualizaciones (200 contra un valor muy inferior).

La teoría detallada de cada punto está en `explicacion_teorica.md`.

---

## 6. Preparar la defensa

### 6.1. Presentación de 8 minutos: diapositivas sugeridas

| N.º | Diapositiva | Contenido | Tiempo |
| :---: | :--- | :--- | :---: |
| 1 | Título y pregunta guía | OmniMarket; "¿existe una única arquitectura correcta?" | 0:30 |
| 2 | Diagnóstico | Los 10 dominios; obligatorios frente a preferencias | 1:00 |
| 3 | Supuestos de volumen | 4 cifras clave: 30 M de eventos por día, 400.000 sesiones, 100.000 pedidos por día, 50 M de relaciones | 0:30 |
| 4 | Método de decisión | 8 criterios con peso y la regla para sumar un motor | 1:00 |
| 5 | Resultado | Matriz de los cinco modelos; resaltar Catálogo (empate) y Marketing | 1:00 |
| 6 | Arquitectura | Diagrama; núcleo PostgreSQL y tres motores especializados | 1:00 |
| 7 | Fuente de verdad e integración | Outbox, evento, consumidor idempotente | 0:45 |
| 8 | Evidencia | Carrito → evento → Neo4j → recomendación en Redis (capturas 31 a 35) | 1:00 |
| 9 | Duplicación y concurrencia | Idempotencia, versión y el experimento 200 contra N | 0:45 |
| 10 | Costo y cierre | Costo por motor y cuándo se daría de baja; mensaje final | 0:30 |

Mensaje final sugerido: *"No elegimos la arquitectura con más tecnologías, sino la que menos motores necesita para cumplir cada requisito, y dejamos escrito cuándo cambiaríamos de opinión."*

### 6.2. Cuestionar a la propuesta rival (5 minutos)

1. Mientras presentan, anotá **qué motor eligieron para cada dominio** y buscá los dominios donde hay más de un motor posible.
2. Preparate 3 preguntas, elegidas entre las de la sección 5.3 de la bitácora. Las más fuertes suelen ser:
   - "¿Cuál es la fuente de verdad de este dato y cómo se sincroniza?"
   - "¿Qué pasa si falla la segunda de dos escrituras a motores distintos?"
   - "¿Cómo evitan vender por encima del stock y en qué motor está ese dato?"
   - "¿Qué evidencia ejecutada respalda esta decisión?"
3. Preguntá por **evidencia, no por opinión.** Una pregunta que se responde con "porque es más rápido" no se sostiene sin una medición.
4. No cuestiones por cuestionar: elegí los puntos donde su justificación sea débil o falte una alternativa descartada.

### 6.3. Responder objeciones (4 minutos)

- La sección 5.2 de la bitácora trae **15 objeciones anticipadas con respuesta**. Repartan en el grupo quién responde cuáles.
- Estructura de cada respuesta: **qué evaluamos → qué decidimos → por qué → qué evidencia tenemos → cuándo cambiaríamos de opinión.**
- Si no tenés una respuesta, decí qué dato falta y cómo lo obtendrías. Es mejor que inventar.
- **Anotá cada objeción recibida y tu respuesta** en la tabla de la sección 5.4 de la bitácora (es un entregable).

### 6.4. Ensayo
- Cronometrá la presentación completa: 8 minutos justos.
- Que alguien del grupo haga de rival y haga las 8 preguntas de la sección 5.3.
- Cada integrante tiene que poder explicar la matriz y el diagrama.

---

## 7. Checklist final de entrega

| Criterio de evaluación | Peso | ¿Qué lo respalda? | Listo |
| :--- | :---: | :--- | :---: |
| Análisis de requerimientos | 15 % | Matriz de requisitos (funcional y no funcional), supuestos y obligatorios frente a preferencias | ☐ |
| Selección y justificación de modelos | 25 % | Matriz de los cinco modelos, regla de adopción, alternativa descartada por dominio, costo de motores | ☐ |
| Modelado | 20 % | Diseño relacional con diagrama y DDL, diseños de Redis, Neo4j y Cassandra | ☐ |
| Implementación NoSQL y consultas | 20 % | Capturas de los pasos obligatorios y la integración | ☐ |
| Defensa y contraargumentación | 20 % | Presentación ensayada y registro de objeciones | ☐ |

Revisión final:
- ☐ Integrantes completados.
- ☐ Todas las capturas pegadas y legibles; ninguna muestra contraseñas.
- ☐ Ambos diagramas insertados.
- ☐ Valor del experimento de concurrencia completado.
- ☐ Scripts incluidos (`redis-omnimarket.txt`, `neo4j-omnimarket.cypher`) y sin credenciales.
- ☐ Tabla de objeciones recibidas completada tras la batalla.

---

## 8. Problemas frecuentes

| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `Clave incorrecta` al retomar | La clave de Neo4j no coincide con la del primer arranque | Repetir con `REINICIAR=1` (borra solo la carpeta `~/u9_act2`) |
| Neo4j no arranca o el puerto 7690 está ocupado | Quedó una instancia de una corrida anterior | `NEO4J_CONF=$HOME/u9_act2/neo4j/conf neo4j stop` y repetir |
| Redis: `Address already in use` | Quedó el Redis de la actividad corriendo | `redis-cli -p 6381 shutdown nosave` |
| Los conteos del paso 33 no son 2 y 4 | Se repitió la sesión sin reiniciar | `REINICIAR=1` |
| `El carrito de U01 está vacío` | Se retomó con `PASO_DESDE` después de detener las instancias (Redis pierde sus datos al detenerse) | `REINICIAR=1` |
| El paso 38 da exactamente 200 | La máquina ejecutó los procesos casi en serie (es posible, aunque raro) | Repetir los pasos 37 y 38 con `PASO_DESDE=37`; el valor varía en cada corrida |
| Poca memoria | Hay otros motores activos (Cassandra, Neo4j de la Actividad 1) | Detenerlos con `sudo systemctl stop cassandra neo4j` |
| Una captura no entra en pantalla | Terminal angosta | Maximizar la terminal o achicar la letra con `Ctrl` + `-` |
