
# Is it Observable
<p align="center"><img src="/image/logo.png" width="40%" alt="Is It observable Logo" /></p>

## Episode : The value of ADOT
This repository contains the files utilized during the tutorial presented in the dedicated IsItObservable episode related to AWS Distro For OpenTelemetry.
<p align="center"><img src="/image/adot_logo.png" width="40%" alt="ADOT Logo" /></p>

What you will learn
* How to use  [ADOT](https://aws-otel.github.io/docs/introduction)

This repository showcase the usage of ADOT  with :
* EKS
* S3
* Lambda
* Dynatrace

For this example we are using a modified example built by AWS to showcase the usage of S3 and Lambda.
THis example has been adjusted to deploy :
- the webclient & a small k6 loadtest on EKS
- the java lambda function with ADOT

We will send all Telemetry data produced by this  application to Dynatrace.

## Prerequisite
The following tools need to be install on your machine :
- jq
- kubectl
- git
- ekctl
- Helm
- java 8
- gradle

## Deployment Steps in AWS
### 1.Clone the Github Repository
```shell
https://github.com/isItObservable/adot
cd adot
```
You will first need a Kubernetes cluster with 2 Nodes.
You can either deploy on Minikube or K3s or follow the instructions to create GKE cluster:
### 2.Create a EKS cluster
```shell
ZONE=europe-west-3
NAME=isitobservable-adot-demo
sed -i "s,REGION_TO_REPLACE,$ZONE," eks-cluster.yaml
sed -i "s,NAME_TO_REPLACE,$NAME," eks-cluster.yaml
eksctl create cluster -f eks-cluster.yaml
```
Create the variable with your AWS account id:
```
AWS_ACCOUNT_ID=<Your AWS Account id>
```
### 3.Create the S3 Bucket
```shell
./src/s3-java/1-create-bucket.sh
ARTIFACT_BUCKET=$(cat bucket-name.txt)
```
#### Create a IAM user 
Create a IAM user having the following policy on the S3 bucket created.
the role needs to :
```json
"policies": [
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                    "Effect": "Allow",
                    "Action": [
                            "s3:PutObject",
                            "s3:GetObject",
                            "s3:ListBucket",
                            "s3:DeleteObject",
                            "s3:GetBucketLocation"
                     ],
                    "Resource": [
                        "arn:aws:s3:::<BUCKET_NAME>",
                        "arn:aws:s3:::<BUCKET_NAME>/*"
                    ]
            }
        ]
    }
]
```
once the user created copy the access key and the secret access key.
```
AWS_ACCESS_KEY=<YOUR IAM USER ACESS KEY>
AWS_SECRET_ACCESS_KEY=<YOUR IAM USER SECRET ACESS KEY>
```

## Getting started
### Dynatrace Tenant
#### 1. Dynatrace Tenant - start a trial
If you don't have any Dyntrace tenant , then i suggest to create a trial using the following link : [Dynatrace Trial](https://bit.ly/3KxWDvY)
Once you have your Tenant save the Dynatrace tenant hostname in the variable `DT_TENANT_URL` (for example : https://dedededfrf.live.dynatrace.com)
```
DT_TENANT_URL=<YOUR TENANT URL>
```

#### 2. Create the Dynatrace API Tokens
Create a Dynatrace token with the following scope ( left menu Acces Token):
* ingest metrics
* ingest OpenTelemetry traces
* ingest logs
<p align="center"><img src="/image/data_ingest.png" width="40%" alt="data token" /></p>
Save the value of the token . We will use it later to store in a k8S secret

```
DATA_INGEST_TOKEN=<YOUR TOKEN VALUE>
```

### 4.Deploy most of the components

#### Deploy

```shell
chmod 777 deployment.sh
./deployment.sh  --clustername "${NAME}" --dturl "${DT_TENANT_URL}" --dttoken "${DATA_INGEST_TOKEN}" --aws_access_key_id "${AWS_ACCESS_KEY}" --aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" --awsaccountid "${AWS_ACCOUNT_ID}" --bucketname "${ARTIFACT_BUCKET} --region "${REGION}"
```
### 5.Add the Adot Layer on the lambda function
Once the Lambda function is deployed go to the AWS console , and click on your lambda.
Click on add a layer :
<p align="center"><img src="/image/lambda_layer.png" width="80%" alt="lambda layer" /></p>

Adot provides a arn with the lambda , add the layer  arn:aws:lambda:<region>:901920570463:layer:aws-otel-java-agent-amd64-ver-1-24-0:1
<p align="center"><img src="/image/add_layer.png" width="80%" alt="adot layer" /></p>

### 6.Add collector layer on the lambda function
In this tutorial we are deploying the collector pipeline in a seperate layer.
First we will need to create a zip file of the file `src/adot/collector.yaml`

Then in the AWS console ( in AWS lambda) , click on 'Additionnal ressources/layers' 
Create a new Layer :
<p align="center"><img src="/image/collector_pipeline_layer.png" width="80%" alt="adot layer" /></p>

Then add this layer in your Lambda function.
<p align="center"><img src="/image/lambda_function_layer.png" width="80%" alt="adot layer" /></p>

### 7.Add Environment variables 

Last to enable the instrumentation on our lambda function and use our custom pipeline we need to add several environment variable in our lambda.

* AWS_LAMBDA_EXEC_WRAPPER to load the ADOT layer : `/opt/otel-handler`
* JAVA_TOOL_OPTIONS to enable the instrumentation : `-Dotel.java.global-autoconfigure.enabled=true`
* OPENTELEMETRY_COLLECTOR_CONFIG_FILE with the path to our collector file :`/opt/collector.yaml`
* OTEL_SDK_DISABLED : `false`
* OTEL_SERVICE_NAME to overrite the OpenTelemetry service name of our lambda :	`s3-java`
<p align="center"><img src="/image/environment_variables.png" width="80%" alt="adot layer" /></p>

### 7.Telemetry Data in Dynatrace

After few seconds you should see in the `Services`, 2 openTelemetry serivces:
* front ( the webclient deployed in EKS)
* s3-java ( the lambda function)

<p align="center"><img src="/image/front_service.png" width="80%" alt="adot layer" /></p>

Here is an example of the Traces generated by the webclient :
<p align="center"><img src="/image/front_trace.png" width="80%" alt="adot layer" /></p>
