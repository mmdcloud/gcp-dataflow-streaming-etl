#!/bin/bash
mkdir pipeline-code
cp -r ../src/* pipeline-code/
cd pipeline-code

docker buildx build --tag pubsub-bq-job --file ./Dockerfile .
docker tag pubsub-bq-job:latest $2-docker.pkg.dev/$1/pubsub-bq-job/pubsub-bq-job:latest
docker push $2-docker.pkg.dev/$1/pubsub-bq-job/pubsub-bq-job:latest