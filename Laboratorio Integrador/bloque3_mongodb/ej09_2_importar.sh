#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 9.2 - Carga masiva con mongoimport en la base LabMongoDB
# Uso: ./ej09_2_importar.sh <carpeta con customers.json, films.json, stores.json>
#
# - Los archivos son JSON Lines (un documento por línea): no lleva --jsonArray.
# - Colecciones con los nombres en castellano que usa la guía (clientes,
#   peliculas, tiendas), para el $lookup del Ejercicio 11 y el $jsonSchema del 12.1.
# - --drop hace la carga repetible (vacía la colección antes de importar).
# - La clave de adminG11 se lee de un archivo de opciones (--config, YAML con
#   "password: ...") con permisos 600: no queda en la línea de comandos ni en el
#   historial. Sin --config, mongoimport la pide por teclado.
# =============================================================================
set -euo pipefail

DATOS="${1:?Indicar la carpeta con los archivos JSON}"
CONFIG="${MONGO_TOOLS_CONFIG:-$HOME/lab_integrador_g11/tools_admin.yaml}"
DB="LabMongoDB"

importar() {   # $1 = archivo, $2 = colección
  echo "=== $1 -> $DB.$2"
  mongoimport --host 127.0.0.1:27017 \
    --username adminG11 --authenticationDatabase admin --config "$CONFIG" \
    --db "$DB" --collection "$2" --drop \
    --file "$DATOS/$1"
  echo
}

time {
  importar customers.json clientes
  importar films.json     peliculas
  importar stores.json    tiendas
}
