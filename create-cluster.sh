#!/bin/sh

while getopts n: option
do
  case "${option}"
    in
      n) CLUSTER_NAME=${OPTARG};;
  esac
done

if [ -z "$CLUSTER_NAME" ]; then
  echo "Must specify -n for the cluster name."
  exit 1
fi

cat cluster.yaml.template | sed "s|CLUSTER_NAME|$CLUSTER_NAME|g" > cluster.yaml
eksctl create cluster -f cluster.yaml

