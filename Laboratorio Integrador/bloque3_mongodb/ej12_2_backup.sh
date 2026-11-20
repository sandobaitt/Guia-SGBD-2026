#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 12.2 - Respaldo con mongodump y restauración con mongorestore en la
#                  base local LabMongoDB_Restore
# Uso: ./ej12_2_backup.sh       (cada herramienta pide la clave de adminG11;
#                                o MONGO_TOOLS_CONFIG=archivo.yaml con "password: ...")
# =============================================================================
set -euo pipefail
AUTH=(--host 127.0.0.1:27017 --username adminG11 --authenticationDatabase admin)
[ -n "${MONGO_TOOLS_CONFIG:-}" ] && AUTH+=(--config "$MONGO_TOOLS_CONFIG")
DESTINO="$HOME/backup_labmongodb"

echo "=== 1. Respaldo de LabMongoDB"
rm -rf "$DESTINO"
mongodump "${AUTH[@]}" --db LabMongoDB --out "$DESTINO"

echo; echo "=== 2. Archivos generados (.bson = datos, .metadata.json = índices y opciones)"
ls -lh "$DESTINO/LabMongoDB/"
echo "documentos en tiendas.bson: $(bsondump --quiet "$DESTINO/LabMongoDB/tiendas.bson" | wc -l)"

echo; echo "=== 3. Restauración en LabMongoDB_Restore (no pisa la base original)"
mongorestore "${AUTH[@]}" --drop \
  --nsInclude 'LabMongoDB.*' --nsFrom 'LabMongoDB.*' --nsTo 'LabMongoDB_Restore.*' \
  "$DESTINO"
