#!/bin/bash
set -eo pipefail
aws s3 cp images/sample-s3-java.png s3://$1/inbound/sample-s3-java.png
TEMPLATE=template.yml
gradle build -i
aws cloudformation package --template-file $TEMPLATE --s3-bucket $1 --output-template-file out.yml
aws cloudformation deploy --template-file out.yml --stack-name s3-java --capabilities CAPABILITY_NAMED_IAM
