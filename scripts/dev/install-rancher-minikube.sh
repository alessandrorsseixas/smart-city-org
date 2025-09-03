#!/bin/bash
set -euo pipefail

# ====================================================================================
# Arquivo: install-rancher-linux-v2.sh
# Descrição: Script para provisionar um ambiente Rancher localmente usando
#            Minikube e Helm. Otimizado para Linux, incorporando lições de
#            depuração de resolução de DNS e ciclo de vida de segredos.
# Arquiteto: Alessandro Seixas
# ====================================================================================

# ====================================================================================
# Variáveis de Configuração Estratégica
# ====================================================================================
# Domínio de acesso ao Rancher. Usamos .local para evitar conflitos com o TLD
# protegido .localhost e garantir a correta resolução via /etc/hosts.
INGRESS_HOST="rancher.local"
# Namespace onde os componentes core do Rancher serão instalados.
NAMESPACE="cattle-system"
# Versão do Rancher. Fixar a versão garante a consistência entre ambientes.
RANCHER_VERSION="v2.7.3"

# --- Configurações técnicas ---
RANCHER_HELM_RELEASE="rancher"
RANCHER_HELM_CHART="rancher-latest/rancher"
INGRESS_NAMESPACE="ingress-nginx"
INGRESS_CLASS_NAME="nginx"
TLS_SECRET_NAME="tls-rancher-ingress"
CERT_FILE="./tls.crt"
KEY_FILE="./tls.key"

# ====================================================================================
# Funções de Validação e Pré-requisitos
# ====================================================================================

# Função para verificar se um comando CLI essencial existe no PATH.
function check_command() {
  command -v "$1" >/dev/null 2>&1 || { echo >&2 "ARQUITETURA-ERRO: O comando '$1' é um pré-requisito e não foi encontrado. Abortando."; exit 1; }
}

# Função para validar a ordem de resolução de nomes, um ponto crítico de falha.
function check_nsswitch() {
  # A ordem correta deve ser 'files' antes de 'dns' para priorizar /etc/hosts.
  if ! grep -q -E "^hosts:\s+files" /etc/nsswitch.conf; then
    echo "ARQUITETURA-AVISO: A configuração em /etc/nsswitch.conf não prioriza 'files'."
    echo "Isso pode fazer com que a entrada em /etc/hosts para '$INGRESS_HOST' seja ignorada."
    echo "Configuração atual:"
    grep "^hosts:" /etc/nsswitch.conf
    echo "Recomendado: 'hosts: files dns'"
    # Não aborta, mas alerta o usuário sobre um risco potencial.
  fi
}

# ====================================================================================
# Orquestração da Instalação
# ====================================================================================

echo "### [FASE 0] Validando pré-requisitos da arquitetura..."
check_command kubectl
check_command helm
check_command minikube
check_command openssl
check_nsswitch
echo "Pré-requisitos validados."

# --- Passo 1: Provisionamento do Cluster Kubernetes (Minikube) ---
echo -e "\n### [FASE 1] Verificando e, se necessário, inicializando o cluster Minikube..."
if ! minikube status >/dev/null 2>&1; then
  echo "Provisionando novo cluster Minikube com 4GB de RAM e 2 vCPUs..."
  minikube start --driver=docker --memory=4096 --cpus=2
else
  echo "Cluster Minikube já está em execução."
fi

# --- Passo 2: Configuração do Ingress Controller (Nginx) ---
echo -e "\n### [FASE 2] Habilitando e aguardando o Ingress Controller..."
minikube addons enable ingress
echo "Aguardando o deployment 'ingress-nginx-controller' atingir o estado 'pronto'..."
kubectl -n $INGRESS_NAMESPACE rollout status deployment/ingress-nginx-controller --timeout=5m

# --- Passo 3: Configuração do Repositório Helm do Rancher ---
echo -e "\n### [FASE 3] Adicionando o repositório Helm do Rancher..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# --- Passo 4: Criação do Namespace do Rancher ---
echo -e "\n### [FASE 4] Garantindo a existência do namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# --- Passo 5: Geração e Gestão do Certificado TLS ---
echo -e "\n### [FASE 5] Gerenciando o certificado TLS para o Ingress..."
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "Gerando novo certificado TLS autoassinado para o host '$INGRESS_HOST'..."
  openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days 365 \
    -subj "/CN=$INGRESS_HOST"
else
  echo "Certificado TLS ('$CERT_FILE', '$KEY_FILE') já existe."
fi

# --- Passo 6: Criação do Segredo TLS no Kubernetes ---
echo -e "\n### [FASE 6] Criando/Atualizando o segredo Kubernetes para o TLS..."
kubectl -n $NAMESPACE delete secret $TLS_SECRET_NAME --ignore-not-found
kubectl -n $NAMESPACE create secret tls $TLS_SECRET_NAME \
  --cert="$CERT_FILE" \
  --key="$KEY_FILE"

# --- Passo 7: Instalação do Rancher via Helm ---
echo -e "\n### [FASE 7] Realizando o deploy do Rancher (versão $RANCHER_VERSION) para o host '$INGRESS_HOST'..."
helm install $RANCHER_HELM_RELEASE $RANCHER_HELM_CHART \
  --namespace $NAMESPACE \
  --set hostname=$INGRESS_HOST \
  --set rancherImageTag=$RANCHER_VERSION \
  --set ingress.tls.source=secret \
  --set ingress.ingressClassName=$INGRESS_CLASS_NAME

# --- Passo 8: Aguardar o Rollout do Rancher ---
echo -e "\n### [FASE 8] Aguardando o deployment do Rancher ser concluído..."
kubectl -n $NAMESPACE rollout status deployment/rancher --timeout=10m

# --- Passo 9: Extração de Credenciais e Instruções de Acesso ---
echo -e "\n### [FASE 9] Instalação concluída. Preparando instruções de acesso..."

MINIKUBE_IP=$(minikube ip)

echo -e "\n========================= ACESSO AO RANCHER ========================="
echo "O Rancher foi instalado com sucesso. Siga os passos abaixo:"
echo ""
echo "1. Configure a resolução de nome local para o Rancher:"
if grep -q "$INGRESS_HOST" /etc/hosts; then
  echo "   -> A entrada para '$INGRESS_HOST' já existe em /etc/hosts. Verifique se o IP ($MINIKUBE_IP) está correto."
else
  echo "   -> Execute o comando abaixo para mapear '$INGRESS_HOST' ao IP do Minikube:"
  echo -e "\n      echo \"$MINIKUBE_IP $INGRESS_HOST\" | sudo tee -a /etc/hosts\n"
fi

echo "2. Acesse a UI do Rancher em seu navegador:"
echo -e "   URL: https://$INGRESS_HOST"
echo ""
echo "3. Obtenha a senha de administrador:"

# Tenta obter a senha de bootstrap. Se falhar, fornece o comando de reset.
if kubectl get secret --namespace $NAMESPACE bootstrap-secret &>/dev/null; then
  BOOTSTRAP_PASSWORD=$(kubectl get secret --namespace $NAMESPACE bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
  echo "   -> Senha de bootstrap encontrada:"
  echo "      Senha: $BOOTSTRAP_PASSWORD"
else
  echo "   -> O segredo 'bootstrap-secret' não foi encontrado (normal em reinstalações)."
  echo "      Para redefinir a senha do usuário 'admin', execute o seguinte comando:"
  POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=rancher -o jsonpath='{.items[0].metadata.name}')
  echo -e "\n      kubectl exec -n $NAMESPACE $POD_NAME -- reset-password\n"
fi
echo "======================================================================="
