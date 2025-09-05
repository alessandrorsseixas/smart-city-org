#!/bin/bash

# Script para deploy do n8n no cluster Kubernetes usando overlays de desenvolvimento
# Author: Smart City Automation Project
# Date: $(date)

# Este script aplica os overlays de desenvolvimento do n8n:
# - Utiliza kustomize para aplicar as configurações base com patches de dev
# - Configurações otimizadas para ambiente de desenvolvimento
# - Recursos reduzidos e configurações específicas de dev

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
  echo "  n8n Deployment Script"
  echo "=================================="

  check_kubectl

  apply() {
    if [ ! -d "$1" ]; then
      log_error "Diretório não encontrado: $1"
      exit 1
    fi
    log_info "Aplicando overlay: $1"
    kubectl apply -k "$1"
  }

  # Aplica namespace primeiro
  log_info "Aplicando namespace smartcity..."
  kubectl apply -f "../../k8s/base/namespace-smartcity.yaml"

  # Aplica os overlays de desenvolvimento do n8n
  apply "../../k8s/overlays/dev/n8n"

  log_success "Deploy n8n com overlays de desenvolvimento aplicado"
  echo "Verificar pods: kubectl get pods -n smartcity"
}

main "$@"
