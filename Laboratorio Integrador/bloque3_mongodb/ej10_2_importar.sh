#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 10.2 - Importación de las colecciones auxiliares ciudades y paises
# Uso: ./ej10_2_importar.sh <carpeta con ciudades.json y paises.json>
#   ciudades.json: exportado de world_x.city en el Ejercicio 8.4 ({"Ciudad", "CodP"})
#   paises.json:   exportado de world_x.countryinfo (documentos JSON de MySQL):
#     mysql -h 127.0.0.1 -u usr_g11 -p -N -B -r -e "SELECT doc FROM world_x.countryinfo ORDER BY doc->>'$.Code'" > paises.json
# La clave de adminG11 se lee de un archivo de opciones (YAML "password: ...", chmod 600).
# =============================================================================
set -euo pipefail
DATOS="${1:?Indicar la carpeta con ciudades.json y paises.json}"
CONFIG="${MONGO_TOOLS_CONFIG:-$HOME/lab_mongodb_g11/tools_admin.yaml}"
HOST="${MONGO_HOST:-127.0.0.1:27017}"

importar() {   # $1 = archivo, $2 = colección
  echo "=== $1 -> LabMongoDB.$2"
  mongoimport --host "$HOST" \
    --username adminG11 --authenticationDatabase admin --config "$CONFIG" \
    --db LabMongoDB --collection "$2" --drop \
    --file "$DATOS/$1"
  echo
}

echo "Documentos en los archivos (JSON Lines: uno por línea):"
wc -l "$DATOS/paises.json" "$DATOS/ciudades.json"; echo
importar paises.json   paises
importar ciudades.json ciudades
