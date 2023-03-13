#!/bin/sh

while getopts i:h: option
do
  case "${option}"
    in
      i) IMAGE_NAME=${OPTARG};;
      h) REPO_HOST=${OPTARG};;
  esac
done


if [ -z "$IMAGE_NAME" ]; then
  echo "Must specify -i for the image name."
  exit 1
fi
if [ -z "$REPO_HOST" ]; then
  echo "Must specify -h for the repository host."
  exit 1
fi


cat deployment-knative.yaml.template | sed "s|IMAGE_NAME|$IMAGE_NAME|g" | sed "s|REPO_HOST|$REPO_HOST|g" > deployment-knative.yaml
kubectl apply -f deployment-knative.yaml

