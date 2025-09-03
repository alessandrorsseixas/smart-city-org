#!/bin/bash

set -e

check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo "kubectl não encontrado"
    exit 1
  fi
}

main() {
  check_kubectl
  kubectl apply -f k8s/base/namespace-smartcity.yaml
  kubectl apply -f k8s/base/rabbitmq/configmap.yaml
  kubectl apply -f k8s/base/rabbitmq/pvc.yaml
  kubectl apply -f k8s/base/rabbitmq/deployment.yaml
  kubectl apply -f k8s/base/rabbitmq/service.yaml
  echo "Deploy RabbitMQ aplicado"
}

main "$@"
