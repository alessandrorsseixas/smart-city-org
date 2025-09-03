#!/bin/bash

# Script para deploy do PostgreSQL no cluster Kubernetes
# Author: Smart City Automation Project
# Date: $(date)

set -e  # Para o script em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl não está instalado ou não está no PATH"
        exit 1
    fi
    log_info "kubectl encontrado: $(kubectl version --client --short 2>/dev/null || echo 'versão não disponível')"
}

# Função para verificar conexão com o cluster
check_cluster_connection() {
    log_info "Verificando conexão com o cluster Kubernetes..."
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Não foi possível conectar ao cluster Kubernetes"
        log_error "Verifique se o cluster está executando e se o kubeconfig está configurado"
        exit 1
    fi
    log_success "Conexão com o cluster Kubernetes estabelecida"
}

# Função para aplicar um recurso Kubernetes
apply_resource() {
    local file_path=$1
    local resource_name=$2
    
    log_info "Aplicando $resource_name..."
    
    if [ ! -f "$file_path" ]; then
        log_error "Arquivo não encontrado: $file_path"
        return 1
    fi
    
    if kubectl apply -f "$file_path"; then
        log_success "$resource_name aplicado com sucesso"
    else
        log_error "Falha ao aplicar $resource_name"
        return 1
    fi
}

# Função para verificar status do deployment
check_deployment_status() {
    log_info "Verificando status do deployment do PostgreSQL..."
    
    # Aguarda o deployment estar pronto (timeout de 5 minutos)
    if kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n smartcity; then
        log_success "PostgreSQL deployment está pronto"
    else
        log_warning "PostgreSQL deployment ainda não está completamente pronto"
        log_info "Verifique o status com: kubectl get pods -n smartcity"
    fi
}

# Função para verificar status do PVC
check_pvc_status() {
    log_info "Verificando status do PVC..."
    
    local pvc_status=$(kubectl get pvc postgres-pvc -n smartcity -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    case $pvc_status in
        "Bound")
            log_success "PVC está vinculado com sucesso"
            ;;
        "Pending")
            log_warning "PVC está pendente - aguardando provisão de volume"
            ;;
        "NotFound")
            log_error "PVC não encontrado"
            ;;
        *)
            log_warning "Status do PVC: $pvc_status"
            ;;
    esac
}

# Função para testar conectividade do PostgreSQL
test_postgres_connection() {
    log_info "Testando conectividade do PostgreSQL..."
    
    # Aguarda alguns segundos para o PostgreSQL estar completamente pronto
    sleep 10
    
    if kubectl exec -n smartcity deployment/postgres-deployment -- pg_isready -U admin -d smartcity &> /dev/null; then
        log_success "PostgreSQL está respondendo às conexões"
        
        # Testa uma query simples
        if kubectl exec -n smartcity deployment/postgres-deployment -- psql -U admin -d smartcity -c "SELECT version();" &> /dev/null; then
            log_success "PostgreSQL está funcionando corretamente"
        else
            log_warning "PostgreSQL está rodando, mas há problemas com queries SQL"
        fi
    else
        log_warning "PostgreSQL ainda não está pronto para conexões"
    fi
}

# Função principal
main() {
    echo "===================================="
    echo "  PostgreSQL Deployment Script"
    echo "  Smart City Automation Project"
    echo "===================================="
    echo
    
    # Verificações preliminares
    check_kubectl
    check_cluster_connection
    
    echo
    log_info "Iniciando deploy do PostgreSQL..."
    echo
    
    # Aplicar recursos na ordem correta
    apply_resource "k8s/base/namespace-smartcity.yaml" "Namespace SmartCity" || exit 1
    echo
    
    apply_resource "k8s/base/postgres/configmap.yaml" "PostgreSQL ConfigMap" || exit 1
    echo
    
    apply_resource "k8s/base/postgres/pvc.yaml" "PostgreSQL PVC" || exit 1
    echo
    
    apply_resource "k8s/base/postgres/deployment.yaml" "PostgreSQL Deployment" || exit 1
    echo
    
    apply_resource "k8s/base/postgres/service.yaml" "PostgreSQL Service" || exit 1
    echo
    
    # Verificações pós-deploy
    check_pvc_status
    echo
    
    check_deployment_status
    echo
    
    test_postgres_connection
    echo
    
    log_success "Deploy do PostgreSQL concluído!"
    echo
    log_info "Informações de conexão:"
    echo "  - Host: postgres-service.smartcity.svc.cluster.local"
    echo "  - Port: 5432"
    echo "  - Database: smartcity"
    echo "  - User: admin"
    echo "  - Password: smartcity123"
    echo
    log_info "Comandos úteis:"
    echo "  - Verificar pods: kubectl get pods -n smartcity"
    echo "  - Verificar services: kubectl get svc -n smartcity"
    echo "  - Verificar PVC: kubectl get pvc -n smartcity"
    echo "  - Logs do PostgreSQL: kubectl logs -f deployment/postgres-deployment -n smartcity"
    echo "  - Conectar ao PostgreSQL: kubectl exec -it deployment/postgres-deployment -n smartcity -- psql -U admin -d smartcity"
    echo "  - Listar databases: kubectl exec -it deployment/postgres-deployment -n smartcity -- psql -U admin -d smartcity -c '\l'"
}

# Executar função principal
main "$@"
