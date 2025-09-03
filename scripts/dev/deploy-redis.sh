#!/bin/bash

# Script para deploy do Redis no cluster Kubernetes
# Author: Smart City Automation Project
# Date: $(date)

# Este script aplica os manifests do Redis na ordem correta:
# 1. Namespace
# 2. ConfigMap (redis.conf)
# 3. PVC
# 4. Deployment
# 5. Service

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verifica se kubectl está disponível no PATH
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl não encontrado"
    exit 1
  fi
}

main() {
  echo "=================================="
  echo "  Redis Deployment Script"
  echo "=================================="

  check_kubectl

  apply() {
    if [ ! -f "$1" ]; then
      log_error "Arquivo não encontrado: $1"
      exit 1
    fi
    kubectl apply -f "$1"
  }

  # Aplica os manifests do Redis
  apply "k8s/base/namespace-smartcity.yaml"
  apply "k8s/base/redis/configmap.yaml"
  apply "k8s/base/redis/pvc.yaml"
  apply "k8s/base/redis/deployment.yaml"
  apply "k8s/base/redis/service.yaml"

  log_success "Deploy Redis aplicado"
  echo "Verificar pods: kubectl get pods -n smartcity"
}

main "$@"
