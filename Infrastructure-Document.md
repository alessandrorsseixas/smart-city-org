# Infraestrutura - Smart City Mini

## Visão Geral
Este documento descreve a infraestrutura completa para a plataforma Smart City Mini, otimizada para execução em um cluster Minikube com 16GB RAM e 8 cores. A arquitetura utiliza Service Mesh Istio com Kiali para observabilidade, API Gateway Kong para gerenciamento de APIs, e uma stack completa de monitoramento e segurança.

## Pré-requisitos

### Sistema Operacional
- Linux (recomendado) ou macOS/Windows com WSL2
- Docker 20.10+ instalado
- kubectl 1.25+ instalado
- Helm 3.9+ instalado

### Recursos do Cluster
```bash
# Configuração recomendada para Minikube
minikube start --cpus=8 --memory=16384 --disk-size=50g \
  --kubernetes-version=v1.28.0 \
  --driver=docker \
  --addons=ingress,metrics-server,dashboard
```

## Arquitetura de Componentes

### Core Services
- **PostgreSQL**: Banco de dados principal para configurações e metadados
- **MongoDB**: Banco NoSQL para dados de dispositivos e logs
- **Redis**: Cache e armazenamento de sessões
- **RabbitMQ**: Message broker para comunicação assíncrona
- **InfluxDB**: Time-series database para métricas energéticas

### Microserviços da Aplicação
- **Device Management** (.NET 8): Gerenciamento de dispositivos IoT
- **Energy Monitor** (Python/FastAPI): Monitoramento de energia renovável
- **Dashboard API** (.NET 8): APIs de agregação de dados
- **AI Tutor** (Python): Tutoria inteligente personalizada
- **Notification Service** (Node.js): Sistema de notificações

### Infraestrutura de Suporte
- **Keycloak**: Identity and Access Management
- **N8N**: Workflow automation
- **Cert-Manager**: Gerenciamento automático de certificados TLS

## Service Mesh - Istio + Kiali

### Instalação do Istio
```bash
# Download e instalação
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Instalação com perfil demo (adequado para Minikube)
istioctl install --set profile=demo -y

# Habilitação de injeção automática
kubectl label namespace default istio-injection=enabled
kubectl label namespace smartcity istio-injection=enabled
```

### Configuração do Istio
```yaml
# istio-config.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: smartcity-gateway
  namespace: smartcity
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: smartcity-tls
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: dashboard-api
  namespace: smartcity
spec:
  hosts:
  - "*"
  gateways:
  - smartcity-gateway
  http:
  - match:
    - uri:
        prefix: "/api/dashboard"
    route:
    - destination:
        host: dashboard-api
        port:
          number: 80
```

### Kiali para Observabilidade
```bash
# Instalação do Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Acesso ao Kiali
kubectl port-forward svc/kiali -n istio-system 20001:20001
# Acesse: http://localhost:20001
```

### Configuração de Telemetria
```yaml
# telemetry.yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: smartcity
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      mode: CLIENT_AND_SERVER
```

## API Gateway - Kong

### Instalação do Kong
```bash
# Adicionar repositório Helm do Kong
helm repo add kong https://charts.konghq.com
helm repo update

# Instalação com PostgreSQL
helm install kong kong/kong \
  --namespace kong \
  --create-namespace \
  --set ingressController.installCRDs=false \
  --set postgresql.enabled=true \
  --set env.database=postgres \
  --set service.type=ClusterIP \
  --set resources.requests.memory=512Mi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=1Gi \
  --set resources.limits.cpu=1000m
```

### Configuração de Serviços no Kong
```yaml
# kong-services.yaml
apiVersion: configuration.konghq.com/v1
kind: KongService
metadata:
  name: dashboard-api-service
  namespace: smartcity
spec:
  name: dashboard-api
  protocol: http
  host: dashboard-api.smartcity.svc.cluster.local
  port: 80
  path: /
---
apiVersion: configuration.konghq.com/v1
kind: KongRoute
metadata:
  name: dashboard-api-route
  namespace: smartcity
spec:
  serviceRef:
    name: dashboard-api-service
  routes:
  - methods:
    - GET
    - POST
    - PUT
    - DELETE
    paths:
    - /api/dashboard
  strip_path: false
---
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: dashboard-api-rate-limiting
  namespace: smartcity
spec:
  serviceRef:
    name: dashboard-api-service
  plugin: rate-limiting
  config:
    minute: 100
    policy: local
---
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: dashboard-api-jwt
  namespace: smartcity
spec:
  serviceRef:
    name: dashboard-api-service
  plugin: jwt
  config:
    secret_is_base64: false
    run_on_preflight: true
```

## Observabilidade e Monitoramento

### Prometheus + Grafana
```bash
# Instalação do Prometheus Stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.service.type=ClusterIP \
  --set grafana.service.type=ClusterIP \
  --set alertmanager.enabled=false \
  --set resources.requests.memory=512Mi \
  --set resources.requests.cpu=250m \
  --set resources.limits.memory=1Gi \
  --set resources.limits.cpu=500m
```

### Configuração de Métricas Customizadas
```yaml
# service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: device-management-monitor
  namespace: smartcity
spec:
  selector:
    matchLabels:
      app: device-management
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

### Jaeger para Distributed Tracing
```bash
# Instalação do Jaeger
kubectl create namespace observability
kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml

# Configuração do Jaeger
kubectl apply -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: smartcity-jaeger
  namespace: observability
spec:
  strategy: allInOne
  allInOne:
    image: jaegertracing/all-in-one:latest
    options:
      log-level: info
EOF
```

## Segurança

### Cert-Manager para TLS
```bash
# Instalação
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ClusterIssuer para Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@smartcity.edu
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: istio
EOF
```

### Network Policies
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: smartcity
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal
  namespace: smartcity
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: smartcity
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: smartcity
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

## Storage e Persistência

### Configuração de Storage Classes
```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: smartcity-storage
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

### Persistent Volumes para Serviços
```yaml
# postgres-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: smartcity-storage
  hostPath:
    path: /data/postgres
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: smartcity
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: smartcity-storage
  resources:
    requests:
      storage: 10Gi
```

## CI/CD Pipeline

### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy to Minikube
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Minikube
      uses: manusa/actions-setup-minikube@v2.7.2
      with:
        minikube version: 'v1.30.1'
        kubernetes version: 'v1.27.3'
        start args: --cpus=8 --memory=16384
    - name: Build and Push Docker Images
      run: |
        eval $(minikube docker-env)
        docker build -t device-management:latest ./apps/device-management
        docker build -t energy-monitor:latest ./apps/energy-monitor
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f k8s/base/
        kubectl apply -f k8s/overlays/dev/
```

## Scripts de Automação

### Script de Deploy Completo
```bash
#!/bin/bash
# deploy-infrastructure.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Iniciando deploy da infraestrutura Smart City Mini${NC}"

# Verificar pré-requisitos
echo -e "${YELLOW}📋 Verificando pré-requisitos...${NC}"
command -v minikube >/dev/null 2>&1 || { echo -e "${RED}❌ Minikube não encontrado${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl não encontrado${NC}"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}❌ Helm não encontrado${NC}"; exit 1; }

# Iniciar Minikube
echo -e "${YELLOW}🔧 Configurando Minikube...${NC}"
minikube start --cpus=8 --memory=16384 --disk-size=50g --driver=docker

# Instalar Istio
echo -e "${YELLOW}🔗 Instalando Istio Service Mesh...${NC}"
curl -L https://istio.io/downloadIstio | sh - >/dev/null 2>&1
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y

# Instalar Kong
echo -e "${YELLOW}🌐 Instalando Kong API Gateway...${NC}"
kubectl create namespace kong
helm install kong kong/kong --namespace kong --set postgresql.enabled=true

# Instalar Monitoring
echo -e "${YELLOW}📊 Instalando stack de monitoramento...${NC}"
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring

# Aplicar manifests
echo -e "${YELLOW}📦 Aplicando manifests do projeto...${NC}"
kubectl apply -f k8s/base/namespace-smartcity.yaml
kubectl apply -f k8s/base/

echo -e "${GREEN}✅ Infraestrutura implantada com sucesso!${NC}"
echo -e "${GREEN}🌐 URLs de acesso:${NC}"
echo "Kong Admin: http://$(minikube ip):$(kubectl get svc kong-kong-admin -n kong -o jsonpath='{.spec.ports[0].nodePort}')"
echo "Grafana: http://$(minikube ip):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
echo "Kiali: http://$(minikube ip):$(kubectl get svc kiali -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')"
```

### Script de Health Check
```bash
#!/bin/bash
# health-check.sh

echo "🔍 Verificando saúde dos serviços..."

# Verificar pods
kubectl get pods -n smartcity
kubectl get pods -n kong
kubectl get pods -n monitoring
kubectl get pods -n istio-system

# Verificar serviços
kubectl get svc -n smartcity
kubectl get ingress -n smartcity

# Testar conectividade
echo "🌐 Testando conectividade..."
curl -I http://$(minikube ip):$(kubectl get svc kong-kong-proxy -n kong -o jsonpath='{.spec.ports[0].nodePort}')/api/dashboard/health

echo "✅ Health check concluído!"
```

## Monitoramento de Recursos

### Configuração de Limites
```yaml
# resource-limits.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: smartcity-limits
  namespace: smartcity
spec:
  limits:
  - default:
      memory: 512Mi
      cpu: 500m
    defaultRequest:
      memory: 256Mi
      cpu: 250m
    type: Container
```

### HPA (Horizontal Pod Autoscaler)
```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: dashboard-api-hpa
  namespace: smartcity
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dashboard-api
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Próximos Passos

1. **Executar script de deploy**: `./scripts/deploy-infrastructure.sh`
2. **Configurar DNS local**: Adicionar entradas no `/etc/hosts`
3. **Configurar TLS**: Solicitar certificados Let's Encrypt
4. **Testar integração**: Validar comunicação entre serviços
5. **Configurar backup**: Implementar estratégia de backup para dados
6. **Monitorar performance**: Ajustar recursos conforme necessário

## Troubleshooting

### Problemas Comuns
- **Recursos insuficientes**: Ajustar configurações do Minikube
- **Conflitos de porta**: Verificar portas disponíveis no host
- **Certificados TLS**: Verificar configuração do Cert-Manager
- **Service Mesh**: Consultar logs do Istio via Kiali

### Comandos Úteis
```bash
# Ver logs de um pod
kubectl logs -f <pod-name> -n smartcity

# Executar shell em um pod
kubectl exec -it <pod-name> -n smartcity -- /bin/bash

# Reiniciar deployment
kubectl rollout restart deployment <deployment-name> -n smartcity

# Verificar recursos
kubectl top pods -n smartcity
kubectl top nodes
```

Esta infraestrutura fornece uma base sólida e escalável para a plataforma Smart City Mini, com foco em observabilidade, segurança e facilidade de manutenção.
