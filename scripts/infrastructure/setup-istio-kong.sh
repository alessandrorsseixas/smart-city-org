#!/bin/bash
# setup-istio-kong.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configurando Istio e Kong para Smart City Mini${NC}"

# Criar namespace smartcity se não existir
echo -e "${YELLOW}📂 Criando namespace smartcity...${NC}"
kubectl create namespace smartcity --dry-run=client -o yaml | kubectl apply -f -

# Aplicar Gateway do Istio
echo -e "${YELLOW}🌐 Aplicando Gateway do Istio...${NC}"
cat <<EOF | kubectl apply -f -
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
EOF

# Aplicar VirtualServices para os microserviços
echo -e "${YELLOW}🔗 Aplicando VirtualServices...${NC}"

# Dashboard API
cat <<EOF | kubectl apply -f -
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
EOF

# Device Management
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: device-management
  namespace: smartcity
spec:
  hosts:
  - "*"
  gateways:
  - smartcity-gateway
  http:
  - match:
    - uri:
        prefix: "/api/devices"
    route:
    - destination:
        host: device-management
        port:
          number: 80
EOF

# Energy Monitor
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: energy-monitor
  namespace: smartcity
spec:
  hosts:
  - "*"
  gateways:
  - smartcity-gateway
  http:
  - match:
    - uri:
        prefix: "/api/energy"
    route:
    - destination:
        host: energy-monitor
        port:
          number: 80
EOF

# AI Tutor
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ai-tutor
  namespace: smartcity
spec:
  hosts:
  - "*"
  gateways:
  - smartcity-gateway
  http:
  - match:
    - uri:
        prefix: "/api/tutor"
    route:
    - destination:
        host: ai-tutor
        port:
          number: 80
EOF

# Notification Service
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: notification-service
  namespace: smartcity
spec:
  hosts:
  - "*"
  gateways:
  - smartcity-gateway
  http:
  - match:
    - uri:
        prefix: "/api/notifications"
    route:
    - destination:
        host: notification-service
        port:
          number: 80
EOF

# Aplicar DestinationRules para controle de tráfego
echo -e "${YELLOW}🎯 Aplicando DestinationRules...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: smartcity-services
  namespace: smartcity
spec:
  host: "*.smartcity.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF

# Configurar Kong Services e Routes
echo -e "${YELLOW}🌐 Configurando Kong...${NC}"

# Aguardar Kong estar pronto
echo "Aguardando Kong ficar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kong -n kong --timeout=300s

# Dashboard API no Kong
cat <<EOF | kubectl apply -f -
apiVersion: configuration.konghq.com/v1
kind: KongService
metadata:
  name: dashboard-api-service
  namespace: smartcity
  annotations:
    kubernetes.io/ingress.class: "kong"
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
  name: dashboard-api-cors
  namespace: smartcity
spec:
  serviceRef:
    name: dashboard-api-service
  plugin: cors
  config:
    origins:
    - "*"
    methods:
    - GET
    - POST
    - PUT
    - DELETE
    - OPTIONS
    headers:
    - Accept
    - Accept-Version
    - Content-Length
    - Content-MD5
    - Content-Type
    - Date
    - X-Auth-Token
    credentials: true
EOF

# Device Management no Kong
cat <<EOF | kubectl apply -f -
apiVersion: configuration.konghq.com/v1
kind: KongService
metadata:
  name: device-management-service
  namespace: smartcity
spec:
  name: device-management
  protocol: http
  host: device-management.smartcity.svc.cluster.local
  port: 80
  path: /
---
apiVersion: configuration.konghq.com/v1
kind: KongRoute
metadata:
  name: device-management-route
  namespace: smartcity
spec:
  serviceRef:
    name: device-management-service
  routes:
  - methods:
    - GET
    - POST
    - PUT
    - DELETE
    paths:
    - /api/devices
  strip_path: false
EOF

# Configurar Telemetria do Istio
echo -e "${YELLOW}📊 Configurando telemetria do Istio...${NC}"
cat <<EOF | kubectl apply -f -
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
    - match:
        metric: REQUEST_DURATION
      mode: CLIENT_AND_SERVER
  accessLogging:
  - providers:
    - name: envoy
EOF

# Configurar PeerAuthentication para mTLS
echo -e "${YELLOW}🔒 Configurando mTLS...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: smartcity
spec:
  mtls:
    mode: PERMISSIVE
EOF

# Configurar Network Policies
echo -e "${YELLOW}🛡️  Aplicando Network Policies...${NC}"
cat <<EOF | kubectl apply -f -
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
    - namespaceSelector:
        matchLabels:
          name: kong
    - namespaceSelector:
        matchLabels:
          name: istio-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: smartcity
    - namespaceSelector:
        matchLabels:
          name: kong
    - namespaceSelector:
        matchLabels:
          name: monitoring
    - namespaceSelector:
          name: istio-system
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
EOF

# Configurar ServiceMonitor para Prometheus
echo -e "${YELLOW}📊 Configurando ServiceMonitor...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: smartcity-services-monitor
  namespace: smartcity
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: smartcity-service
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
  namespaceSelector:
    matchNames:
    - smartcity
EOF

echo -e "${GREEN}✅ Configuração do Istio e Kong concluída!${NC}"
echo ""
echo -e "${BLUE}🌐 URLs de acesso:${NC}"
MINIKUBE_IP=$(minikube ip)
KONG_PORT=$(kubectl get svc kong-kong-proxy -n kong -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
echo "Kong Gateway: http://${MINIKUBE_IP}:${KONG_PORT}"
echo "API Dashboard: http://${MINIKUBE_IP}:${KONG_PORT}/api/dashboard"
echo "API Devices: http://${MINIKUBE_IP}:${KONG_PORT}/api/devices"
echo "API Energy: http://${MINIKUBE_IP}:${KONG_PORT}/api/energy"
echo "API Tutor: http://${MINIKUBE_IP}:${KONG_PORT}/api/tutor"
echo "API Notifications: http://${MINIKUBE_IP}:${KONG_PORT}/api/notifications"

echo ""
echo -e "${YELLOW}💡 Teste as configurações:${NC}"
echo "curl http://${MINIKUBE_IP}:${KONG_PORT}/api/dashboard/health"
echo "curl http://${MINIKUBE_IP}:${KONG_PORT}/api/devices/health"
