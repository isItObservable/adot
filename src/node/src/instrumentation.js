const opentelemetry = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } =  require('@opentelemetry/exporter-trace-otlp-grpc');
const { HttpInstrumentation } = require ('@opentelemetry/instrumentation-http');
const { ExpressInstrumentation } = require ('@opentelemetry/instrumentation-express');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');
const { PeriodicExportingMetricReader,MeterProvider,AggregationTemporality } = require('@opentelemetry/sdk-metrics');
const { containerDetector } = require('@opentelemetry/resource-detector-container');
const { envDetector, hostDetector, osDetector, processDetector,Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const otel = require('@opentelemetry/api');
const {  AwsInstrumentation, } = require("@opentelemetry/instrumentation-aws-sdk");



const sdk = new opentelemetry.NodeSDK({
  traceExporter: new OTLPTraceExporter(),
  instrumentations: [ getNodeAutoInstrumentations(),
                    new HttpInstrumentation(),
                    new ExpressInstrumentation(),
                    new AwsInstrumentation(),
                  ],
  metricReader: new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter()
    }),
     resourceDetectors: [
        containerDetector,
        envDetector,
        hostDetector,
        osDetector,
        processDetector,
      ],
})

sdk.start()


