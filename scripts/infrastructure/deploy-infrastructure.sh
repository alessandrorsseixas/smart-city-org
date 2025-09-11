#!/bin/bash
# deploy-infrastructure.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando deploy da infraestrutura Smart City Mini${NC}"

# Verificar pré-requisitos
echo -e "${YELLOW}📋 Verificando pré-requisitos...${NC}"
command -v minikube >/dev/null 2>&1 || { echo -e "${RED}❌ Minikube não encontrado. Instale: https://minikube.sigs.k8s.io/docs/start/${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl não encontrado. Instale: https://kubernetes.io/docs/tasks/tools/${NC}"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}❌ Helm não encontrado. Instale: https://helm.sh/docs/intro/install/${NC}"; exit 1; }

# Verificar se Minikube está rodando
if ! minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}🔧 Iniciando Minikube...${NC}"
    minikube start --cpus=8 --memory=16384 --disk-size=50g --driver=docker --kubernetes-version=v1.28.0
else
    echo -e "${GREEN}✅ Minikube já está rodando${NC}"
fi

# Configurar kubectl para usar Minikube
kubectl config use-context minikube

# Instalar Istio
echo -e "${YELLOW}🔗 Instalando Istio Service Mesh...${NC}"
if ! kubectl get namespace istio-system >/dev/null 2>&1; then
    curl -L https://istio.io/downloadIstio | sh - >/dev/null 2>&1
    cd istio-*
    export PATH=$PWD/bin:$PATH
    istioctl install --set profile=demo -y
    kubectl wait --for=condition=ready pod --all -n istio-system --timeout=300s
    echo -e "${GREEN}✅ Istio instalado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Istio já está instalado${NC}"
fi

# Instalar Kiali
echo -e "${YELLOW}📊 Instalando Kiali...${NC}"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
kubectl wait --for=condition=ready pod -l app=kiali -n istio-system --timeout=300s

# Instalar Kong
echo -e "${YELLOW}🌐 Instalando Kong API Gateway...${NC}"
if ! helm list -n kong | grep -q kong; then
    kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -
    helm repo add kong https://charts.konghq.com --force-update
    helm repo update
    helm install kong kong/kong \
        --namespace kong \
        --set postgresql.enabled=true \
        --set env.database=postgres \
        --set service.type=ClusterIP \
        --set resources.requests.memory=512Mi \
        --set resources.requests.cpu=500m \
        --set resources.limits.memory=1Gi \
        --set resources.limits.cpu=1000m \
        --wait
    echo -e "${GREEN}✅ Kong instalado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Kong já está instalado${NC}"
fi

# Instalar Cert-Manager
echo -e "${YELLOW}🔒 Instalando Cert-Manager...${NC}"
if ! kubectl get namespace cert-manager >/dev/null 2>&1; then
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    kubectl wait --for=condition=ready pod --all -n cert-manager --timeout=300s
    echo -e "${GREEN}✅ Cert-Manager instalado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Cert-Manager já está instalado${NC}"
fi

# Instalar Monitoring Stack
echo -e "${YELLOW}📊 Instalando stack de monitoramento...${NC}"
if ! helm list -n monitoring | grep -q prometheus; then
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.service.type=ClusterIP \
        --set grafana.service.type=ClusterIP \
        --set alertmanager.enabled=false \
        --set resources.requests.memory=512Mi \
        --set resources.requests.cpu=250m \
        --set resources.limits.memory=1Gi \
        --set resources.limits.cpu=500m \
        --wait
    echo -e "${GREEN}✅ Monitoring stack instalado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Monitoring stack já está instalado${NC}"
fi

# Aplicar manifests base
echo -e "${YELLOW}📦 Aplicando manifests do projeto...${NC}"
kubectl apply -f k8s/base/namespace-smartcity.yaml
kubectl apply -f k8s/base/

# Habilitar injeção Istio nos namespaces
echo -e "${YELLOW}🔗 Habilitando Istio injection...${NC}"
kubectl label namespace default istio-injection=enabled --overwrite
kubectl label namespace smartcity istio-injection=enabled --overwrite

# Aguardar todos os serviços ficarem prontos
echo -e "${YELLOW}⏳ Aguardando serviços ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod --all -n smartcity --timeout=600s || echo -e "${YELLOW}⚠️  Alguns pods podem ainda estar inicializando${NC}"

# Obter URLs de acesso
MINIKUBE_IP=$(minikube ip)
KONG_PROXY_PORT=$(kubectl get svc kong-kong-proxy -n kong -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
KONG_ADMIN_PORT=$(kubectl get svc kong-kong-admin -n kong -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
GRAFANA_PORT=$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
KIALI_PORT=$(kubectl get svc kiali -n istio-system -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

echo -e "${GREEN}✅ Infraestrutura implantada com sucesso!${NC}"
echo -e "${BLUE}🌐 URLs de acesso:${NC}"
echo "Kong Proxy: http://${MINIKUBE_IP}:${KONG_PROXY_PORT}"
echo "Kong Admin: http://${MINIKUBE_IP}:${KONG_ADMIN_PORT}"
echo "Grafana: http://${MINIKUBE_IP}:${GRAFANA_PORT} (admin/prom-operator)"
echo "Kiali: http://${MINIKUBE_IP}:${KIALI_PORT}"
echo "Minikube Dashboard: http://${MINIKUBE_IP}:$(kubectl get svc kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")"

echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "1. Execute: ./scripts/infrastructure/health-check.sh"
echo "2. Configure aplicações: kubectl apply -f k8s/overlays/dev/"
echo "3. Teste APIs: curl http://${MINIKUBE_IP}:${KONG_PROXY_PORT}/api/dashboard/health"
