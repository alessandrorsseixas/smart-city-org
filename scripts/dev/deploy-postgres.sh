#!/bin/bash

# Script para deploy do PostgreSQL no cluster Kubernetes usando overlays de desenvolvimento
# Author: Smart City Automation Project
# Objetivo: Deploy do PostgreSQL usando StatefulSet com configurações base + overlays dev

# Este script aplica os overlays de desenvolvimento do PostgreSQL:
# - Base: k8s/base/postgres (StatefulSet, Service, ConfigMap)
# - Overlay dev: k8s/overlays/dev/postgres (Secret, patches de recursos e config)
# - Utiliza kustomize para aplicar configurações base com patches de dev
# - StatefulSet com PVC template para dados persistentes
# - ConfigMap com scripts de inicialização para schemas e usuários
# - Secret com credenciais para ambiente de desenvolvimento

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

# Função para aplicar overlay Kubernetes
apply_overlay() {
    local overlay_path=$1
    local resource_name=$2
    
    log_info "Aplicando overlay $resource_name..."
    
    if [ ! -d "$overlay_path" ]; then
        log_error "Diretório overlay não encontrado: $overlay_path"
        return 1
    fi
    
    if kubectl apply -k "$overlay_path"; then
        log_success "$resource_name aplicado com sucesso"
    else
        log_error "Falha ao aplicar $resource_name"
        return 1
    fi
}

# Função para verificar status do statefulset
check_statefulset_status() {
    log_info "Verificando status do StatefulSet do PostgreSQL..."
    
    # Verifica se o StatefulSet existe
    if ! kubectl get statefulset postgres -n smartcity &> /dev/null; then
        log_error "StatefulSet postgres não encontrado no namespace smartcity"
        return 1
    fi
    
    # Aguarda o StatefulSet estar pronto (timeout de 5 minutos)
    log_info "Aguardando StatefulSet estar pronto..."
    if kubectl wait --for=jsonpath='{.status.readyReplicas}'=1 statefulset/postgres -n smartcity --timeout=300s; then
        log_success "PostgreSQL StatefulSet está pronto"
        
        # Verifica o status dos pods
        local pod_status=$(kubectl get pods -n smartcity -l app=postgres -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
        log_info "Status do pod PostgreSQL: $pod_status"
    else
        log_warning "PostgreSQL StatefulSet ainda não está completamente pronto"
        log_info "Verifique o status com: kubectl get pods -n smartcity -l app=postgres"
        log_info "Verifique os eventos com: kubectl describe statefulset postgres -n smartcity"
    fi
}

# Função para verificar status do PVC
check_pvc_status() {
    log_info "Verificando status dos PVCs do PostgreSQL..."
    
    # StatefulSet usa volumeClaimTemplates, então o PVC será postgres-data-postgres-0
    local pvc_name="postgres-data-postgres-0"
    local pvc_status=$(kubectl get pvc "$pvc_name" -n smartcity -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    
    case $pvc_status in
        "Bound")
            log_success "PVC $pvc_name está vinculado com sucesso"
            local storage=$(kubectl get pvc "$pvc_name" -n smartcity -o jsonpath='{.status.capacity.storage}' 2>/dev/null)
            log_info "Capacidade do volume: $storage"
            ;;
        "Pending")
            log_warning "PVC $pvc_name está pendente - aguardando provisão de volume"
            kubectl describe pvc "$pvc_name" -n smartcity | grep -A 3 "Events:" || true
            ;;
        "NotFound")
            log_warning "PVC $pvc_name ainda não foi criado (StatefulSet pode estar iniciando)"
            ;;
        *)
            log_warning "Status do PVC $pvc_name: $pvc_status"
            ;;
    esac
}

# Função para testar conectividade do PostgreSQL
test_postgres_connection() {
    log_info "Testando conectividade do PostgreSQL..."
    
    # Aguarda alguns segundos para o PostgreSQL estar completamente pronto
    sleep 15
    
    # O pod do StatefulSet tem nome postgres-0
    local pod_name="postgres-0"
    
    if kubectl exec -n smartcity "$pod_name" -- pg_isready -U admin -d smartcity &> /dev/null; then
        log_success "PostgreSQL está respondendo às conexões"
        
        # Testa uma query simples para verificar se o banco está funcionando
        if kubectl exec -n smartcity "$pod_name" -- psql -U admin -d smartcity -c "SELECT version();" &> /dev/null; then
            log_success "PostgreSQL está funcionando corretamente"
            
            # Verifica se os schemas foram criados pelos scripts de inicialização
            local schemas=$(kubectl exec -n smartcity "$pod_name" -- psql -U admin -d smartcity -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('smartcity', 'iot', 'audit', 'auth');" 2>/dev/null | wc -l)
            if [ "$schemas" -gt 0 ]; then
                log_success "Schemas de inicialização foram criados ($schemas encontrados)"
            else
                log_warning "Schemas de inicialização não foram encontrados"
            fi
        else
            log_warning "PostgreSQL está rodando, mas há problemas com queries SQL"
        fi
    else
        log_warning "PostgreSQL ainda não está pronto para conexões"
        log_info "Verificar logs com: kubectl logs postgres-0 -n smartcity"
    fi
}

# Função principal
main() {
    echo "===================================="
    echo "  PostgreSQL StatefulSet Deployment"
    echo "  Smart City Automation Project"
    echo "===================================="
    echo
    
    # Verificações preliminares
    check_kubectl
    check_cluster_connection
    
    echo
    log_info "Iniciando deploy do PostgreSQL StatefulSet com overlays de desenvolvimento..."
    log_info "Base: k8s/base/postgres | Overlay: k8s/overlays/dev/postgres"
    echo
    
    # Verificar se namespace existe
    if ! kubectl get namespace smartcity &> /dev/null; then
        log_info "Criando namespace smartcity..."
        kubectl create namespace smartcity
        log_success "Namespace smartcity criado"
    else
        log_info "Namespace smartcity já existe"
    fi
    echo
    
    # Aplicar overlay de desenvolvimento
    apply_overlay "../../k8s/overlays/dev/postgres" "PostgreSQL Development Overlay" || exit 1
    echo
    
    # Verificações pós-deploy
    check_pvc_status
    echo
    
    check_statefulset_status
    echo
    
    test_postgres_connection
    echo
    
    log_success "Deploy do PostgreSQL StatefulSet com overlays de desenvolvimento concluído!"
    echo
    log_info "Componentes implantados:"
    echo "  - StatefulSet: postgres (postgres:15)"
    echo "  - Service: postgres (Headless ClusterIP)"  
    echo "  - Secret: postgres-secrets (credenciais)"
    echo "  - ConfigMap: postgres-init-config (scripts de inicialização)"
    echo "  - PVC: postgres-data-postgres-0 (dados persistentes)"
    echo
    log_info "Informações de conexão:"
    echo "  - Host interno: postgres.smartcity.svc.cluster.local"
    echo "  - Host de pod direto: postgres-0.postgres.smartcity.svc.cluster.local"
    echo "  - Port: 5432"
    echo "  - Database: smartcity"
    echo "  - User: admin"
    echo "  - Password: smartcity123"
    echo
    log_info "Schemas criados automaticamente:"
    echo "  - smartcity (principal)"
    echo "  - iot (dispositivos IoT)"
    echo "  - audit (auditoria)"
    echo "  - auth (autenticação)"
    echo
    log_info "Comandos úteis:"
    echo "  - Verificar StatefulSet: kubectl get statefulset postgres -n smartcity"
    echo "  - Verificar pods: kubectl get pods -n smartcity -l app=postgres"
    echo "  - Verificar services: kubectl get svc postgres -n smartcity"
    echo "  - Verificar PVC: kubectl get pvc -n smartcity"
    echo "  - Logs do PostgreSQL: kubectl logs postgres-0 -n smartcity"
    echo "  - Conectar ao PostgreSQL: kubectl exec -it postgres-0 -n smartcity -- psql -U admin -d smartcity"
    echo "  - Listar databases: kubectl exec postgres-0 -n smartcity -- psql -U admin -d smartcity -c '\l'"
    echo "  - Listar schemas: kubectl exec postgres-0 -n smartcity -- psql -U admin -d smartcity -c '\dn'"
}

# Executar função principal
main "$@"
