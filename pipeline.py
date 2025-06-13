import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions

def run_pipeline():
    options = PipelineOptions(
        streaming=True,
        project="encoded-alpha-457108-e8",
        region="us-central1",
        # temp_location="gs://your-bucket/temp"
    )

    schema = "name:STRING,email:STRING,city:STRING,timestamp:TIMESTAMP,category:STRING"

    with beam.Pipeline(options=options) as p:
        (p
         | "Read from Pub/Sub" >> beam.io.ReadFromPubSub(
             topic="projects/encoded-alpha-457108-e8/topics/streaming-source")
         | "Parse JSON" >> beam.Map(lambda x: json.loads(x))
         | "Window into 1-minute intervals" >> beam.WindowInto(
            beam.window.FixedWindows(60))
         | "Compute Avg Temp" >> beam.CombineGlobally(
            beam.combiners.MeanCombineFn()).without_defaults()
         | "Write to BigQuery" >> beam.io.WriteToBigQuery(
             table="encoded-alpha-457108-e8:streaming_dest.users",
             schema=schema,
             create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED,
             write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND)
        )

if __name__ == "__main__":
    run_pipeline()