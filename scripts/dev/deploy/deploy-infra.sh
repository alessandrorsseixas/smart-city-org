#!/usr/bin/env bash
set -euo pipefail

# deploy-infra.sh
# Deploy local infra (Redis, Postgres, RabbitMQ, Keycloak) from k8s/infra/dev using kubectl
# Usage: ./deploy-infra.sh [namespace] [--recreate-pvcs]

NAMESPACE=${1:-smartcity-dev}
# allow optional flag after namespace
RECREATE_PVCS=false
for arg in "${@:2}"; do
  case "$arg" in
    --recreate-pvcs) RECREATE_PVCS=true ;;
    *) echo "Unknown option: $arg" ;;
  esac
done

K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../k8s/infra/dev" && pwd)"

MIN_CPU_M=2000    # 2 CPU in millicores
MIN_MEM_MI=4096   # 4Gi in Mi

function check_minikube_resources() {
  echo "Checking cluster node allocatable resources (recommended: 2 CPU / 4Gi)..."
  NODE_NAME=$(kubectl get nodes -o name | head -n1 || true)
  if [[ -z "$NODE_NAME" ]]; then
    echo "No nodes found in cluster. Is kubectl configured?"
    exit 1
  fi
  CPU_ALLOC=$(kubectl get "$NODE_NAME" -o jsonpath='{.status.allocatable.cpu}')
  MEM_ALLOC=$(kubectl get "$NODE_NAME" -o jsonpath='{.status.allocatable.memory}')

  # convert CPU to millicores
  if [[ "$CPU_ALLOC" == *m ]]; then
    CPU_M=${CPU_ALLOC%m}
  else
    # integer CPUs like '2' -> 2000m
    CPU_M=$(( CPU_ALLOC * 1000 ))
  fi

  # convert memory to Mi
  if [[ "$MEM_ALLOC" == *Ki ]]; then
    MEM_KI=${MEM_ALLOC%Ki}
    MEM_MI=$(( MEM_KI / 1024 ))
  elif [[ "$MEM_ALLOC" == *Mi ]]; then
    MEM_MI=${MEM_ALLOC%Mi}
  elif [[ "$MEM_ALLOC" == *Gi ]]; then
    MEM_MI=$(( ${MEM_ALLOC%Gi} * 1024 ))
  else
    MEM_MI=0
  fi

  echo "Found node allocatable: CPU=${CPU_M}m, MEM=${MEM_MI}Mi"

  if (( CPU_M < MIN_CPU_M )) || (( MEM_MI < MIN_MEM_MI )); then
    echo "WARNING: Cluster node resources are below recommended minimum (${MIN_CPU_M}m CPU, ${MIN_MEM_MI}Mi memory)."
    read -r -p "Continue anyway? (y/N): " ans
    case "$ans" in
      [yY]) echo "Continuing despite low resources..." ;;
      *) echo "Aborting."; exit 1 ;;
    esac
  fi
}

check_minikube_resources

echo "Deploying infra to namespace: ${NAMESPACE}"

# create namespace if not exists
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

# Idempotent delete of existing resources (deployments/statefulsets/services/secrets)
# We do NOT delete Postgres PVCs by default. Use --recreate-pvcs to remove PVCs.
echo "Cleaning up existing infra resources (safe delete)..."
kubectl delete -n "${NAMESPACE}" -f "${K8S_DIR}/rabbitmq-deployment.yaml" --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" -f "${K8S_DIR}/keycloak-deployment.yaml" --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" -f "${K8S_DIR}/redis-deployment.yaml" --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" -f "${K8S_DIR}/postgres-statefulset.yaml" --ignore-not-found=true || true

# Delete services (if present)
kubectl delete -n "${NAMESPACE}" service rabbitmq --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" service keycloak --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" service redis --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" service postgres --ignore-not-found=true || true

# Delete secrets so they are recreated with current manifests
kubectl delete -n "${NAMESPACE}" secret postgres-secrets --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" secret redis-secrets --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" secret rabbitmq-secrets --ignore-not-found=true || true
kubectl delete -n "${NAMESPACE}" secret keycloak-secret --ignore-not-found=true || true

if [ "$RECREATE_PVCS" = true ]; then
  echo "Recreating Postgres PVCs as requested (--recreate-pvcs)"
  # Delete PVCs that include postgres-data in their name
  kubectl get pvc -n "${NAMESPACE}" -o name | grep postgres-data || true | xargs -r kubectl delete -n "${NAMESPACE}" --ignore-not-found=true || true
fi

# apply secrets first
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/postgres-secret.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/redis-secret.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/rabbitmq-secret.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/keycloak-secret.yaml"

# apply the rest of the manifests
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/postgres-statefulset.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/redis-deployment.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/rabbitmq-deployment.yaml"
kubectl apply -n "${NAMESPACE}" -f "${K8S_DIR}/keycloak-deployment.yaml"

# wait for deployments/statefulsets
echo "Waiting for rollouts and ready pods..."
kubectl rollout status -n "${NAMESPACE}" deployment/rabbitmq --timeout=120s || true
kubectl rollout status -n "${NAMESPACE}" deployment/keycloak --timeout=180s || true
kubectl wait --for=condition=ready pod -n "${NAMESPACE}" -l app=redis --timeout=120s || true
kubectl wait --for=condition=ready pod -n "${NAMESPACE}" -l app=postgres --timeout=180s || true


echo "Infra applied to namespace ${NAMESPACE}"

# Print basic access hints
echo "Access Keycloak: kubectl port-forward -n ${NAMESPACE} svc/keycloak 8080:8080"
echo "Access RabbitMQ management: kubectl port-forward -n ${NAMESPACE} svc/rabbitmq 15672:15672"
