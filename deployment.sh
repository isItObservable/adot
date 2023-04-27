#!/usr/bin/env bash

################################################################################
### Script deploying the Observ-K8s environment
### Parameters:
### Clustern name: name of your k8s cluster
### dttoken: Dynatrace api token with ingest metrics and otlp ingest scope
### dturl : url of your DT tenant wihtout any / at the end for example: https://dedede.live.dynatrace.com
################################################################################


### Pre-flight checks for dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq before continuing"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Please install git before continuing"
    exit 1
fi


if ! command -v helm >/dev/null 2>&1; then
    echo "Please install helm before continuing"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Please install kubectl before continuing"
    exit 1
fi
echo "parsing arguments"
while [ $# -gt 0 ]; do
  case "$1" in
  --dttoken)
    DTTOKEN="$2"
   shift 2
    ;;
  --dturl)
    DTURL="$2"
   shift 2
    ;;
  --clustername)
    CLUSTERNAME="$2"
   shift 2
    ;;
  --aws_access_key_id)
    AWS_ACCESS_KEY="$2"
   shift 2
    ;;
  --aws_secret_access_key)
    AWS_SECRET_ACESS_KEY="$2"
   shift 2
    ;;
  --aws_secret_access_key)
    AWS_SECRET_ACESS_KEY="$2"
   shift 2
    ;;
  --awsaccountid)
     AWS_ACCOUNTID="$2"
   shift 2
    ;;
  --region)
     REGION="$2"
   shift 2
    ;;
   --bucketname)
     BUCKET_NAME="$2"
   shift 2
    ;;
  *)
    echo "Warning: skipping unsupported option: $1"
    shift
    ;;
  esac
done
echo "Checking arguments"
if [ -z "$CLUSTERNAME" ]; then
  echo "Error: clustername not set!"
  exit 1
fi
if [ -z "$DTURL" ]; then
  echo "Error: Dt hostname not set!"
  exit 1
fi

if [ -z "$DTTOKEN" ]; then
  echo "Error: api-token not set!"
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY" ]; then
  echo "Error: aws Acess key is not set! Please define one"
  exit 1
fi
if [ -z "$AWS_SECRET_ACESS_KEY" ]; then
  echo "Error: aws Secret access key  is  not set! please define one"
  exit 1
fi
if [ -z "$AWS_ACCOUNTID" ]; then
  echo "Error: aws accountid  is  not set! please define one"
  exit 1
fi
if [ -z "$REGION" ]; then
  echo "Error: region is  not set! please define one"
  exit 1
fi
if [ -z "$BUCKET_NAME" ]; then
  echo "Error: bucket name is  not set! please define one"
  exit 1
fi

## Deploy eks ingress

curl https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json \
     -o iam-policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
       --cluster=$CLUSTERNAME \
       --namespace=kube-system \
       --name=aws-load-balancer-controller \
       --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNTID:policy/AWSLoadBalancerControllerIAMPolicy \
       --override-existing-serviceaccounts \
       --region $REGION \
       --approve

helm repo add eks https://aws.github.io/eks-charts

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=$CLUSTERNAME \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller
### Add ADOT addon to the cluster
eksctl create iamserviceaccount \
--name adot-collector \
--namespace default \
--cluster $CLUSTERNAME \
--attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
--attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
--attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
--approve \
--override-existing-serviceaccounts

kubectl apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
kubectl wait pod -l app.kubernetes.io/component=webhook -n cert-manager --for=condition=Ready --timeout=2m


kubectl apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml
aws eks create-addon --addon-name adot --cluster-name $CLUSTERNAME

#install prometheus operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack  --set grafana.sidecar.dashboards.enabled=true
kubectl wait pod --namespace default -l "release=prometheus" --for=condition=Ready --timeout=2m

# Deploy collector
kubectl create secret generic dynatrace  --from-literal=dynatrace_oltp_url="$DTURL" --from-literal=dt_api_token="$DTTOKEN"
kubectl apply -f manifest/openTelemetry-manifest_debut.yaml
# Deploy the webapplication
kubecl create ns imageuploader
kubectl apply -f manifest/openTelemetry-sidecar.yaml -n imageuploader
kubectl create secret generic s3settings -n imageuploader --from-literal=aws_access_key_id="$AWS_ACCESS_KEY" --from-literal=aws_secret_access_key="$AWS_SECRET_ACESS_KEY"

# Create bucket
sed -i "s,BUCKET_TO_REPLACE,$BUCKET_NAME," manifest/deployment.yaml
kubectl apply -f manifest/deployment.yaml -n imageuploader
ingress_host=$(kubectl get ingress -n imageuploader -ojson | jq -j '.items[].status.loadBalancer.ingress[].hostname')
sed -i "s,HOST_TO_REPLACE,$IP," manifest/deployment_load.yaml
kubectl apply -f manifest/deployment_load.yaml -n imageuploader

# Build lambda java code
cd src/s3-java
./2-build-layer.sh
./3-deploy.sh $BUCKET_NAME
cd ../..
# Echo environ*
echo "--------------Demo--------------------"
echo "url of the demo: "
echo "imageuploader demo url: http://$ingress_host"
echo "========================================================"


