#!/bin/bash
set -e

if ! command -v kubectl &> /dev/null; then
  echo "kubectl não encontrado"
  exit 1
fi

kubectl apply -f k8s/base/namespace-smartcity.yaml
kubectl apply -f k8s/base/keycloak/pvc.yaml
kubectl apply -f k8s/base/keycloak/deployment.yaml
kubectl apply -f k8s/base/keycloak/service.yaml

echo "Keycloak deploy aplicado"
