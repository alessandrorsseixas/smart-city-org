#!/bin/bash
# health-check.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verificando saúde da infraestrutura Smart City Mini${NC}"
echo "=================================================="

# Verificar status do Minikube
echo -e "${YELLOW}🐳 Status do Minikube:${NC}"
minikube status
echo ""

# Verificar namespaces
echo -e "${YELLOW}📂 Namespaces:${NC}"
kubectl get namespaces
echo ""

# Verificar pods por namespace
NAMESPACES=("smartcity" "kong" "monitoring" "istio-system" "cert-manager")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace $ns >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Pods no namespace '$ns':${NC}"
        kubectl get pods -n $ns --no-headers | wc -l | xargs echo "Total de pods: "
        kubectl get pods -n $ns
        echo ""

        # Verificar pods com problemas
        PROBLEMATIC_PODS=$(kubectl get pods -n $ns --no-headers | grep -v Running | grep -v Completed | wc -l)
        if [ $PROBLEMATIC_PODS -gt 0 ]; then
            echo -e "${RED}⚠️  Pods com problemas em $ns:${NC}"
            kubectl get pods -n $ns | grep -v Running | grep -v Completed
            echo ""
        fi
    else
        echo -e "${YELLOW}📦 Namespace '$ns' não existe${NC}"
        echo ""
    fi
done

# Verificar serviços
echo -e "${YELLOW}🌐 Serviços principais:${NC}"
kubectl get svc -n smartcity 2>/dev/null || echo "Namespace smartcity não encontrado"
kubectl get svc -n kong 2>/dev/null || echo "Namespace kong não encontrado"
kubectl get svc -n monitoring 2>/dev/null || echo "Namespace monitoring não encontrado"
echo ""

# Verificar ingress
echo -e "${YELLOW}🚪 Ingress:${NC}"
kubectl get ingress -n smartcity 2>/dev/null || echo "Nenhum ingress encontrado"
echo ""

# Verificar recursos
echo -e "${YELLOW}📊 Uso de recursos:${NC}"
kubectl top nodes 2>/dev/null || echo "Métricas não disponíveis"
echo ""
kubectl top pods -n smartcity 2>/dev/null || echo "Pods smartcity não encontrados"
echo ""

# Testar conectividade básica
echo -e "${YELLOW}🌐 Testes de conectividade:${NC}"

# Testar Kong
if kubectl get svc kong-kong-proxy -n kong >/dev/null 2>&1; then
    KONG_URL="http://$(minikube ip):$(kubectl get svc kong-kong-proxy -n kong -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "Testando Kong Proxy: $KONG_URL"
    if curl -s --max-time 5 $KONG_URL >/dev/null; then
        echo -e "${GREEN}✅ Kong Proxy acessível${NC}"
    else
        echo -e "${RED}❌ Kong Proxy não responde${NC}"
    fi
else
    echo -e "${RED}❌ Serviço Kong não encontrado${NC}"
fi

# Testar Grafana
if kubectl get svc prometheus-grafana -n monitoring >/dev/null 2>&1; then
    GRAFANA_URL="http://$(minikube ip):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "Grafana disponível em: $GRAFANA_URL"
    echo -e "${GREEN}✅ Grafana instalado${NC}"
else
    echo -e "${RED}❌ Grafana não encontrado${NC}"
fi

# Testar Kiali
if kubectl get svc kiali -n istio-system >/dev/null 2>&1; then
    KIALI_URL="http://$(minikube ip):$(kubectl get svc kiali -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "Kiali disponível em: $KIALI_URL"
    echo -e "${GREEN}✅ Kiali instalado${NC}"
else
    echo -e "${RED}❌ Kiali não encontrado${NC}"
fi

echo ""
echo -e "${BLUE}📋 Resumo da verificação:${NC}"
echo "=================================================="

# Contar pods saudáveis
TOTAL_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep Running | wc -l)
PENDING_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep Pending | wc -l)
FAILED_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(Error|CrashLoopBackOff|Failed)" | wc -l)

echo "Total de pods: $TOTAL_PODS"
echo -e "Pods rodando: ${GREEN}$RUNNING_PODS${NC}"
if [ $PENDING_PODS -gt 0 ]; then
    echo -e "Pods pendentes: ${YELLOW}$PENDING_PODS${NC}"
fi
if [ $FAILED_PODS -gt 0 ]; then
    echo -e "Pods com falha: ${RED}$FAILED_PODS${NC}"
fi

# Verificar se infraestrutura crítica está OK
CRITICAL_SERVICES=("kong-kong-proxy" "prometheus-grafana" "kiali")
CRITICAL_OK=0
for service in "${CRITICAL_SERVICES[@]}"; do
    if kubectl get svc $service --all-namespaces >/dev/null 2>&1; then
        ((CRITICAL_OK++))
    fi
done

if [ $CRITICAL_OK -eq ${#CRITICAL_SERVICES[@]} ]; then
    echo -e "${GREEN}✅ Infraestrutura crítica OK${NC}"
else
    echo -e "${RED}❌ Problemas na infraestrutura crítica${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Comandos úteis para troubleshooting:${NC}"
echo "kubectl logs -f <pod-name> -n <namespace>"
echo "kubectl describe pod <pod-name> -n <namespace>"
echo "kubectl exec -it <pod-name> -n <namespace> -- /bin/bash"
echo "minikube dashboard"
echo "istioctl dashboard kiali"
