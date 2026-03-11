#!/usr/bin/env bash
# =============================================================================
# 03_submit_job.sh  —  Invia il job Spark al cluster DataProc
#
# Uso: bash scripts/03_submit_job.sh <cluster_name> <num_workers>
# Esempio: bash scripts/03_submit_job.sh earthquake-cluster-2w 2
# =============================================================================
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Uso: bash scripts/submit_job.sh <cluster_name> <num_workers>"
  exit 1
fi

CLUSTER_NAME="$1"
NUM_WORKERS="$2"

PROJECT="spark-earthquakes-cooccurance"
REGION="europe-west8"
BUCKET="gs://spark-earthquakes-bucket"

INPUT="$BUCKET/data/dataset-full.csv"
OUTPUT="$BUCKET/output/${CLUSTER_NAME}-$(date +%Y%m%d_%H%M%S)"
JAR="$BUCKET/jars/earthquake.jar"

echo ">>> Submit job su cluster '$CLUSTER_NAME' ($NUM_WORKERS workers)..."
echo "    Input:  $INPUT"
echo "    Output: $OUTPUT"
echo ""

# Su single-node (1 worker) YARN ha solo ~13.5GB totali.
# DataProc di default prova ad allocare driver(4g) + 2xexecutor(6g) = 16g -> OOM crash.
# Con questa config: driver(2g) + 1 executor(9g, 4 core) = 11g -> ci sta.
# Per i cluster multi-node lasciamo che DataProc scelga da solo (funziona gia bene).
if [ "$NUM_WORKERS" -eq 1 ]; then
  echo "    [single-node] Config prudente: dynamic allocation OFF, 1 executor piccolo"
gcloud dataproc jobs submit spark \
  --cluster="$CLUSTER_NAME" \
  --region="$REGION" \
  --project="$PROJECT" \
  --class=Main \
  --jars="$JAR" \
  --properties="spark.dynamicAllocation.enabled=false,spark.executor.instances=1,spark.executor.cores=2,spark.executor.memory=4g,spark.executor.memoryOverhead=768m,spark.driver.memory=1g,spark.driver.memoryOverhead=512m,spark.rdd.compress=true" \
  -- \
  "$INPUT" \
  "$NUM_WORKERS" \
  "$OUTPUT"
else
  gcloud dataproc jobs submit spark \
    --cluster="$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT" \
    --class=Main \
    --jars="$JAR" \
    -- \
    "$INPUT" \
    "$NUM_WORKERS" \
    "$OUTPUT"
fi

echo ""
echo ">>> Job completato. Per risultato:"
echo "    gcloud storage cat $OUTPUT/part-00000"
echo ""
echo ">>> cancella il cluster:"
echo "    bash scripts/delete_cluster.sh $CLUSTER_NAME"
