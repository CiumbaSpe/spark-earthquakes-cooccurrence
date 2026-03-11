import org.apache.spark.sql.{Row, SparkSession}
import scala.util.Try
import scala.math.BigDecimal.RoundingMode
import scala.collection.mutable
import org.apache.spark.storage.StorageLevel


object Main {

  // arrotonda alla prima cifra decimale, "al più vicino"
  private def round1(x: Double): Double =
    BigDecimal(x).setScale(1, RoundingMode.HALF_UP).toDouble

  // estrae YYYY-MM-DD 
  private def dayFromTimestamp(s: String): String = s.substring(0, 10)
  
  // Normalized event: (day, Cell)
  private def rowToEvent(row: Row): (String, Cell) = {
    val lon = row.getAs[String]("longitude").toDouble
    val lat = row.getAs[String]("latitude").toDouble
    val day = dayFromTimestamp(row.getAs[String]("date"))
    day -> Cell(round1(lat), round1(lon))
  }

  case class Cell(lat: Double, lon: Double)
  implicit val cellOrdering: Ordering[Cell] = Ordering.by(c => (c.lat, c.lon))

  case class Pair(a: Cell, b: Cell)
  implicit val pairOrdering: Ordering[Pair] =
    Ordering.by(p => (p.a.lat, p.a.lon, p.b.lat, p.b.lon))

  private def formatCell(c: Cell): String = f"(${c.lat}%.1f, ${c.lon}%.1f)"
  private def formatPair(p: Pair): String = s"(${formatCell(p.a)}, ${formatCell(p.b)})"


  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("Earthquake Application")
      .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
      // .config("spark.executor.memory", "6g")
      // .config("spark.driver.memory",   "4g")
      // .config("spark.executor.cores",  "4")
      .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")

    val inputPath = args(0)
    val outputPath = args(2)

    val numWorkers = args(1).toInt 
    val coresPerWorker = 4 
    val numPartitions = numWorkers * coresPerWorker * 3 // k=3 

    // --- START TIME ---
    val startTime = System.nanoTime()

    val raw = spark.read.option("header", value = true).csv(inputPath).rdd

    val partitioner = new org.apache.spark.HashPartitioner(numPartitions)
    
    val events = raw.map(rowToEvent).distinct().partitionBy(partitioner).persist(StorageLevel.MEMORY_AND_DISK)    
    // println(s"Distinct (day,cell) events = ${events.count()}")
    // events.take(5).foreach(println)

    // day -> celle uniche (array ordinato per poter creare coppie ordinate)
    val dayToCells = events
      .aggregateByKey(mutable.HashSet.empty[Cell])(
        (set, cell) => { set += cell; set },
        (a, b) => { if (a.size < b.size) { b ++= a; b } else { a ++= b; a } }
      )
      .mapValues(set => set.toArray.sorted)
      .persist(StorageLevel.MEMORY_AND_DISK)

    // Conta co-occorrenze: Pair -> numero di date in cui compaiono entrambi
    val pairCounts = dayToCells
      .flatMap { case (_, cells) =>
        val n = cells.length
        if (n < 2) Iterator.empty
        else {
          Iterator.range(0, n - 1).flatMap { i =>
            val ci = cells(i)
            Iterator.range(i + 1, n).map { j =>
              (Pair(ci, cells(j)), 1)
            }
          }
        }
      }
      .reduceByKey(_ + _)

    // Prendi la coppia col massimo count (tie-break: coppia lessicograficamente minima)
    val best: (Pair, Int) = pairCounts.reduce { (x, y) =>
      val (px, cx) = x
      val (py, cy) = y
      if (cx > cy) x
      else if (cy > cx) y
      else if (pairOrdering.lteq(px, py)) x else y
    }

    val bestPair = best._1

    // Date in cui co-occorrono: filtro eventi solo per le 2 celle e verifico presenza di entrambe (bitmask OR)
    val dates = events
      .filter { case (_, c) => c == bestPair.a || c == bestPair.b }
      .map { case (day, c) => (day, if (c == bestPair.a) 1 else 2) }
      .reduceByKey(_ | _)
      .filter(_._2 == 3)
      .keys
      .collect()
      .sorted

    // --- END TIME ---
    val endTime = System.nanoTime()
    val durationSeconds = (endTime - startTime) / 1e9d

    val resultLines: Seq[String] =
    Seq(formatPair(bestPair)) ++
    dates ++
    Seq(f"\nTEMPO DI ESECUZIONE: $durationSeconds%.3f secondi")


    spark.sparkContext
    .parallelize(resultLines)
    .repartition(1)
    .saveAsTextFile(outputPath)

    spark.stop()
  }
}
