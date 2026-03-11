name := "earthquake"
version := "1.0"
scalaVersion := "2.12.18"

libraryDependencies += "org.apache.spark" %% "spark-sql" % "3.5.3" % "provided"

// Crea un fat JAR con tutte le dipendenze incluse (tranne Spark, che è "provided")
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", _*) => MergeStrategy.discard
  case _                        => MergeStrategy.first
}
