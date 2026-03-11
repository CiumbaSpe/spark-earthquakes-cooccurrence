#!/usr/bin/env bash
# =============================================================================
# run_local.sh  —  Compila e lancia il job in locale sul dataset trimmed
# Uso: bash scripts/run_local.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

JAR="$PROJECT_DIR/target/scala-2.12/earthquake-assembly-1.0.jar"
DATASET="$PROJECT_DIR/Datasets/dataset-earthquakes-trimmed.csv"
OUTPUT="/tmp/earthquake_output"
NUM_WORKERS=1   # in locale non cambia nulla, serve solo per il calcolo partizioni

# --- Pulizia output precedente ---
rm -rf "$OUTPUT"

# --- Compilazione ---
echo ">>> Compilazione fat JAR..."
cd "$PROJECT_DIR"
sbt assembly

# --- Esecuzione locale ---
echo ">>> Lancio in locale con dataset trimmed..."
spark-submit \
  --master "local[*]" \
  --class Main \
  "$JAR" \
  "$DATASET" \
  "$NUM_WORKERS" \
  "$OUTPUT"

echo ""
echo ">>> Risultato:"
cat "$OUTPUT/part-00000"
