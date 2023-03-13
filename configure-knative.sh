#!/bin/bash

kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.8.3/serving-crds.yaml


kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.8.3/serving-core.yaml


kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.8.1/kourier.yaml

kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'


kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.8.3/serving-default-domain.yaml

kubectl apply -f knative-config.yaml
