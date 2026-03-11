#!/usr/bin/env bash
# =============================================================================
# 02_create_cluster.sh  —  Crea un cluster DataProc con N workers
#
# Uso: bash scripts/create_cluster.sh <num_workers>
# Esempio: bash scripts/create_cluster.sh 2
# =============================================================================
set -euo pipefail

NUM_WORKERS="${1:-2}"   # default 2 workers se non specificato

# --- Configurazione ---
PROJECT="spark-earthquakes-cooccurance"
REGION="europe-west8"
CLUSTER_NAME="earthquake-cluster-${NUM_WORKERS}w"

echo ">>> Creazione cluster '$CLUSTER_NAME' con $NUM_WORKERS workers..."
echo "    Macchina: n2-standard-4 | Disk: 240GB | Region: $REGION"
echo ""

if [ "$NUM_WORKERS" -eq 1 ]; then
  # DataProc non supporta --num-workers=1. Con --single-node il master
  # funge anche da worker (stesso setup che ha usato Tassi per la baseline).
  gcloud dataproc clusters create "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT" \
    --single-node \
    --master-machine-type=n2-standard-4 \
    --master-boot-disk-size=240
else
  gcloud dataproc clusters create "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT" \
    --num-workers="$NUM_WORKERS" \
    --master-machine-type=n2-standard-4 \
    --worker-machine-type=n2-standard-4 \
    --master-boot-disk-size=240 \
    --worker-boot-disk-size=240
fi

echo ""
echo ">>> Cluster '$CLUSTER_NAME' creato. Lancia subito il job con:"
echo "    bash scripts/submit_job.sh $CLUSTER_NAME $NUM_WORKERS"
