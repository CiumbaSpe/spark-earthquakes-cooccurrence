#!/usr/bin/env bash
# =============================================================================
# delete_cluster.sh  —  Cancella il cluster DataProc
#
# Uso: bash scripts/delete_cluster.sh <cluster_name>
# Esempio: bash scripts/delete_cluster.sh earthquake-cluster-2w
# =============================================================================
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: bash scripts/delete_cluster.sh <cluster_name>"
  exit 1
fi

CLUSTER_NAME="$1"
REGION="europe-west8"
PROJECT="spark-earthquakes-cooccurance"

echo ">>> Cancellazione cluster '$CLUSTER_NAME'..."

gcloud dataproc clusters delete "$CLUSTER_NAME" \
  --region="$REGION" \
  --project="$PROJECT" \
  --quiet   # non chiede conferma interattiva

echo ">>> Cluster '$CLUSTER_NAME' cancellato. Crediti al sicuro."
