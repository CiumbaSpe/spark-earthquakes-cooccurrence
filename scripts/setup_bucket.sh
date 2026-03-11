#!/usr/bin/env bash
# =============================================================================
# setup_bucket.sh  —  Crea il bucket GCS e carica dataset + JAR
#
# Da eseguire UNA SOLA VOLTA prima di qualsiasi job su DataProc.
# Uso: bash scripts/setup_bucket.sh
# =============================================================================
set -euo pipefail

# --- Configurazione (modifica se necessario) ---
PROJECT="spark-earthquakes-cooccurance"
REGION="europe-west8"
BUCKET="gs://spark-earthquakes-bucket"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

JAR="$PROJECT_DIR/target/scala-2.12/earthquake-assembly-1.0.jar"

# --- Verifica che il JAR esista (devi aver già fatto sbt assembly) ---
if [ ! -f "$JAR" ]; then
  echo "ERRORE: JAR non trovato in $JAR"
  echo "Esegui prima: sbt assembly"
  exit 1
fi

# --- Crea bucket (ignora errore se esiste già) ---
echo ">>> Creazione bucket $BUCKET nella region $REGION..."
gcloud storage buckets create "$BUCKET" \
  --location="$REGION" \
  --project="$PROJECT" 2>/dev/null || echo "    (bucket già esistente, skip)"

# --- Carica dataset full ---
echo ">>> Upload dataset completo..."
gcloud storage cp \
  "$PROJECT_DIR/Datasets/dataset-earthquakes-full.csv" \
  "$BUCKET/data/dataset-full.csv"

# --- Carica JAR ---
echo ">>> Upload JAR..."
gcloud storage cp "$JAR" "$BUCKET/jars/earthquake.jar"

echo ""
echo ">>> Setup completato. Contenuto del bucket:"
gcloud storage ls "$BUCKET/**"
