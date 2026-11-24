# Earthquake Co-occurrence Analysis

Scala/Spark application that identifies the pair of geographic cells
with the highest number of earthquake co-occurrences and returns
the corresponding dates in chronological order.

## Requirements

- Java JDK
- SBT 1.11.6
- Spark 3.5.3 / Scala 2.12.18
- Google Cloud SDK

## Setup

Place the following datasets in the `Datasets/` directory
(not included in the repository):

- dataset-earthquakes-full.csv
- dataset-earthquakes-trimmed.csv

Configure PROJECT, REGION and BUCKET where applicable in the scripts
according to Google Cloud environment.

## Local execution

```bash
bash scripts/run_local.sh
```

## Execution on Google Cloud Dataproc

Create the bucket and upload the dataset and JAR:

```bash
bash scripts/setup_bucket.sh
```

Create a cluster, submit the job and delete the cluster after execution:

```bash
bash scripts/create_cluster.sh 2
bash scripts/submit_job.sh earthquake-cluster-2w 2
bash scripts/delete_cluster.sh earthquake-cluster-2w
```

The same procedure can be used with 3 or 4 workers.
The configuration with 1 worker uses a single-node cluster.
