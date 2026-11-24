# Earthquake Co-occurrence Analysis

Scala/Spark application that identifies the pair of geographic cells with the highest number of earthquake co-occurrences and returns the corresponding dates in chronological order.

## Requirements

- Java JDK 17
- SBT 1.11.6
- Scala 2.12.18 / Spark 3.5.3
- Google Cloud SDK

## Build

```bash
sbt clean assembly
```

## Run on Google Cloud Dataproc

With an existing GCP project and Cloud Storage bucket, set:

```bash
REGION=europe-west8
BUCKET=your-bucket-name
CLUSTER=earthquake-cluster
WORKERS=3
```

Upload the JAR and the full dataset:

```bash
gcloud storage cp target/scala-2.12/earthquake-assembly-1.0.jar gs://$BUCKET/
gcloud storage cp Datasets/dataset-earthquakes-full.csv gs://$BUCKET/
```

Create the cluster:

```bash
gcloud dataproc clusters create $CLUSTER \
  --region=$REGION \
  --num-workers=$WORKERS \
  --master-machine-type=n2-standard-4 \
  --worker-machine-type=n2-standard-4 \
  --master-boot-disk-size=240 \
  --worker-boot-disk-size=240
```

Submit the job:

```bash
gcloud dataproc jobs submit spark \
  --cluster=$CLUSTER \
  --region=$REGION \
  --jar=gs://$BUCKET/earthquake-assembly-1.0.jar \
  -- gs://$BUCKET/dataset-earthquakes-full.csv $WORKERS gs://$BUCKET/output
```

Arguments: input dataset, number of workers, output directory.

The output contains the selected pair, co-occurrence dates and execution time.

Delete the cluster after execution:

```bash
gcloud dataproc clusters delete $CLUSTER --region=$REGION
```
