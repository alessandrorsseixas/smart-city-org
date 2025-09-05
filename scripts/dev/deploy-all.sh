#!/usr/bin/env bash
set -euo pipefail

# deploy-all.sh - Orquestra a execução de todos os scripts de deploy dos serviços
# Local: scripts/dev
# Objetivo: Aplicar todos os overlays de desenvolvimento no namespace smartcity
# Uso: ./deploy-all.sh [--services] [--infra] [--all] [--dry-run] [--verbose] [-h]

# Ordem recomendada de deploy:
# INFRA (banco de dados e middlewares):
# 1) deploy-postgres.sh     -> PostgreSQL com criação do banco n8n
# 2) deploy-mongodb.sh      -> MongoDB para auditoria e logs
# 3) deploy-redis.sh        -> Cache Redis 
# 4) deploy-rabbitmq.sh     -> Message broker RabbitMQ
# 5) deploy-keycloak.sh     -> Identity provider Keycloak
#
# SERVICES (aplicações e automação):
# 6) deploy-n8n.sh          -> Automação n8n (depende de Postgres)
# 7) deploy-mcp-server.sh   -> Model Context Protocol server (se existir)
#
# Todos os scripts usam kustomize overlays (kubectl apply -k) e são idempotentes.

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploy todos os serviços do smart-city no namespace smartcity usando kustomize overlays.

OPTIONS:
  --all           Deploy completo: infra + services (default)
  --infra         Deploy apenas da infraestrutura (postgres, mongo, redis, rabbitmq, keycloak)
  --services      Deploy apenas dos serviços (n8n, mcp-server)
  --dry-run       Lista os scripts que seriam executados sem executar
  --verbose       Output detalhado de cada script
  --reset-rancher Reset da senha do admin do Rancher antes do deploy
  --skip-db-job   Pula a execução do Job de criação do banco n8n
  -h, --help      Mostra esta ajuda

EXAMPLES:
  $(basename "$0")                    # Deploy completo
  $(basename "$0") --infra            # Apenas infraestrutura  
  $(basename "$0") --services         # Apenas serviços
  $(basename "$0") --dry-run          # Simula execução
  $(basename "$0") --reset-rancher    # Reset senha + deploy completo

NOTES:
  - Todos os scripts usam kubectl apply -k k8s/overlays/dev/<service>
  - O namespace 'smartcity' é criado automaticamente se não existir
  - PostgreSQL é implantado primeiro pois n8n depende dele
  - Usar --verbose para debug de problemas
EOF
}

# Funções utilitárias
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

check_prerequisites() {
  log_info "Verificando pré-requisitos..."
  
  # Verificar kubectl
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl não encontrado. Instale kubectl primeiro."
    exit 1
  fi
  
  # Verificar acesso ao cluster
  if ! kubectl cluster-info &> /dev/null; then
    log_error "Não foi possível conectar ao cluster Kubernetes."
    log_info "Certifique-se de que o minikube está rodando: minikube status"
    exit 1
  fi
  
  # Verificar contexto atual
  local current_context
  current_context=$(kubectl config current-context)
  log_info "Contexto atual: $current_context"
  
  # Verificar se o namespace smartcity existe, criar se necessário
  if ! kubectl get namespace smartcity &> /dev/null; then
    log_warning "Namespace 'smartcity' não existe. Criando..."
    kubectl create namespace smartcity
    log_success "Namespace 'smartcity' criado."
  else
    log_info "Namespace 'smartcity' já existe."
  fi
}

reset_rancher_password() {
  log_info "Resetando senha do admin do Rancher..."
  
  # Verificar se o Rancher está instalado
  if ! kubectl get deployment -n cattle-system rancher &> /dev/null; then
    log_warning "Rancher não encontrado no namespace cattle-system. Pulando reset de senha."
    return 0
  fi
  
  # Nova senha padrão
  local new_password="smartcity123!"
  
  # Criar/atualizar o secret de bootstrap
  log_info "Criando secret de bootstrap com nova senha..."
  kubectl -n cattle-system create secret generic bootstrap-secret \
    --from-literal=bootstrapPassword="$new_password" \
    --dry-run=client -o yaml | kubectl apply -f -
  
  # Reiniciar o deployment do Rancher
  log_info "Reiniciando deployment do Rancher..."
  kubectl -n cattle-system rollout restart deployment rancher
  
  # Aguardar rollout
  log_info "Aguardando rollout do Rancher..."
  kubectl -n cattle-system rollout status deployment rancher --timeout=300s
  
  log_success "Senha do Rancher resetada para: $new_password"
  log_info "Acesse https://rancher.local com usuário 'admin' e senha '$new_password'"
}

execute_script() {
  local script_name=$1
  local script_path="$SCRIPTS_DIR/$script_name"
  
  if [[ ! -f "$script_path" ]]; then
    log_warning "Script não encontrado: $script_path - pulando"
    return 0
  fi
  
  if [[ ! -x "$script_path" ]]; then
    log_info "Tornando $script_name executável..."
    chmod +x "$script_path"
  fi
  
  log_info "Executando: $script_name"
  
  if [[ "$VERBOSE" -eq 1 ]]; then
    # Output completo
    "$script_path" || {
      log_error "Falha ao executar $script_name"
      return 1
    }
  else
    # Output resumido
    if "$script_path" &> /tmp/"${script_name%.*}.log"; then
      log_success "$script_name executado com sucesso"
    else
      log_error "Falha ao executar $script_name"
      log_info "Ver logs em: /tmp/${script_name%.*}.log"
      if [[ "$DRY_RUN" -eq 0 ]]; then
        return 1
      fi
    fi
  fi
}

create_n8n_database_job() {
  if [[ "$SKIP_DB_JOB" -eq 1 ]]; then
    log_info "Pulando criação do Job de banco do n8n (--skip-db-job)"
    return 0
  fi
  
  log_info "Aplicando Job de criação do banco n8n..."
  local job_manifest="k8s/overlays/dev/postgres/create-n8n-db-job.yaml"
  
  if [[ ! -f "$job_manifest" ]]; then
    log_warning "Job manifest não encontrado: $job_manifest - pulando"
    return 0
  fi
  
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_info "DRY RUN: kubectl apply -f $job_manifest"
    return 0
  fi
  
  # Deletar job anterior se existir (jobs são imutáveis)
  if kubectl get job -n smartcity create-n8n-database &> /dev/null; then
    log_info "Removendo Job anterior create-n8n-database..."
    kubectl delete job -n smartcity create-n8n-database
  fi
  
  kubectl apply -f "$job_manifest"
  log_success "Job create-n8n-database aplicado"
  
  # Aguardar conclusão do job (timeout 2 minutos)
  log_info "Aguardando conclusão do Job create-n8n-database..."
  if kubectl wait --for=condition=complete job/create-n8n-database -n smartcity --timeout=120s; then
    log_success "Job create-n8n-database concluído com sucesso"
  else
    log_warning "Job create-n8n-database ainda executando ou falhou. Verificar logs:"
    log_info "kubectl logs -n smartcity -l job-name=create-n8n-database"
  fi
}

# Variáveis de configuração
DRY_RUN=0
VERBOSE=0
DEPLOY_INFRA=0
DEPLOY_SERVICES=0
DEPLOY_ALL=1
RESET_RANCHER=0
SKIP_DB_JOB=0

# Parse dos argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      DEPLOY_ALL=1
      DEPLOY_INFRA=0
      DEPLOY_SERVICES=0
      shift
      ;;
    --infra)
      DEPLOY_INFRA=1
      DEPLOY_ALL=0
      DEPLOY_SERVICES=0
      shift
      ;;
    --services)
      DEPLOY_SERVICES=1
      DEPLOY_ALL=0
      DEPLOY_INFRA=0
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --reset-rancher)
      RESET_RANCHER=1
      shift
      ;;
    --skip-db-job)
      SKIP_DB_JOB=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Opção desconhecida: $1"
      usage
      exit 1
      ;;
  esac
done

# Configurações
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/dev"

# Scripts de infraestrutura (ordem de dependência)
INFRA_SCRIPTS=(
  "deploy-postgres.sh"     # PostgreSQL primeiro (base para n8n)
  "deploy-mongodb.sh"      # MongoDB
  "deploy-redis.sh"        # Redis cache
  "deploy-rabbitmq.sh"     # Message broker
  "deploy-keycloak.sh"     # Identity provider
)

# Scripts de serviços (dependem da infra)
SERVICE_SCRIPTS=(
  "deploy-n8n.sh"          # Automação (depende de Postgres)
  "deploy-mcp-server.sh"   # MCP server (se existir)
)

# Determinar scripts a executar
SCRIPTS_TO_RUN=()
if [[ "$DEPLOY_ALL" -eq 1 ]]; then
  SCRIPTS_TO_RUN=("${INFRA_SCRIPTS[@]}" "${SERVICE_SCRIPTS[@]}")
elif [[ "$DEPLOY_INFRA" -eq 1 ]]; then
  SCRIPTS_TO_RUN=("${INFRA_SCRIPTS[@]}")
elif [[ "$DEPLOY_SERVICES" -eq 1 ]]; then
  SCRIPTS_TO_RUN=("${SERVICE_SCRIPTS[@]}")
fi

# Início da execução
log_info "=== Smart City Deploy All - Início ==="
log_info "Modo: $([ "$DRY_RUN" -eq 1 ] && echo "DRY RUN" || echo "EXECUÇÃO")"
log_info "Scripts a executar: ${SCRIPTS_TO_RUN[*]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log_info "=== DRY RUN - Simulação da execução ==="
  for script in "${SCRIPTS_TO_RUN[@]}"; do
    echo "  - $script"
  done
  
  if [[ "$RESET_RANCHER" -eq 1 ]]; then
    echo "  - Reset senha Rancher"
  fi
  
  if [[ "$SKIP_DB_JOB" -eq 0 ]] && [[ "$DEPLOY_ALL" -eq 1 || "$DEPLOY_INFRA" -eq 1 ]]; then
    echo "  - Job create-n8n-database"
  fi
  
  log_info "Use sem --dry-run para executar efetivamente."
  exit 0
fi

# Verificações pré-execução
check_prerequisites

# Reset senha Rancher se solicitado
if [[ "$RESET_RANCHER" -eq 1 ]]; then
  reset_rancher_password
fi

# Execução dos scripts
EXIT_CODE=0
for script in "${SCRIPTS_TO_RUN[@]}"; do
  if ! execute_script "$script"; then
    log_error "Deploy falhou no script: $script"
    EXIT_CODE=1
    break
  fi
done

# Criar database n8n se deploy incluiu Postgres
if [[ "$EXIT_CODE" -eq 0 ]] && ([[ "$DEPLOY_ALL" -eq 1 ]] || [[ "$DEPLOY_INFRA" -eq 1 ]]); then
  create_n8n_database_job
fi

# Resumo final
if [[ "$EXIT_CODE" -eq 0 ]]; then
  log_success "=== Deploy concluído com sucesso! ==="
  log_info "Verificar status dos pods:"
  log_info "  kubectl get pods -n smartcity -o wide"
  log_info "Verificar logs se necessário:"
  log_info "  kubectl logs -n smartcity <pod-name>"
else
  log_error "=== Deploy falhou ==="
  log_info "Verificar logs em /tmp/*.log"
  log_info "Status dos recursos:"
  log_info "  kubectl get all -n smartcity"
fi

exit $EXIT_CODE
