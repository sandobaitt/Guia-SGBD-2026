#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 8.4 - Exportar world_x.city a JSON con formato
#                 {"Ciudad": "Resistencia", "CodP": "ARG"}
# Uso: ./ej08_4_exportar_city.sh [archivo_salida]
#
# - Se exporta desde el cliente (no con SELECT ... INTO OUTFILE): el archivo queda
#   en la carpeta del usuario y no en secure_file_priv, listo para el Ej. 10.2.
#   -N sin encabezados, -B una fila por línea, -r sin escapar barras ni comillas.
# - Resultado en formato JSON Lines (un documento por línea): es el que acepta
#   mongoimport en el Ejercicio 10.2.
# - JSON_OBJECT() devuelve las claves ordenadas por longitud ({"CodP":..,"Ciudad":..}),
#   por eso el documento se arma con CONCAT + JSON_QUOTE: respeta el orden pedido
#   y JSON_QUOTE escapa comillas y caracteres especiales de cada nombre.
# =============================================================================
set -euo pipefail
SALIDA="${1:-ciudades.json}"
MYSQL=(mysql -h 127.0.0.1 -u usr_g11 -N -B -r)

"${MYSQL[@]}" -e "
  SELECT CONCAT('{\"Ciudad\": ', JSON_QUOTE(Name), ', \"CodP\": ', JSON_QUOTE(CountryCode), '}')
  FROM world_x.city
  ORDER BY ID" > "$SALIDA"

echo "Archivo: $SALIDA"
wc -l < "$SALIDA" | xargs echo "Líneas (documentos):"
"${MYSQL[@]}" -e "SELECT COUNT(*) FROM world_x.city" | xargs echo "Filas en world_x.city:"
