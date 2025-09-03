#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="$ROOT_DIR/k8s/base/mcp-server"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl não encontrado"; exit 1; }

echo "Aplicando ConfigMap..."
kubectl apply -f "$MANIFEST_DIR/configmap.yaml"

echo "Aplicando Secret..."
kubectl apply -f "$MANIFEST_DIR/secret.yaml"

echo "Aplicando PVC..."
kubectl apply -f "$MANIFEST_DIR/pvc.yaml"

echo "Aplicando Service..."
kubectl apply -f "$MANIFEST_DIR/service.yaml"

echo "Aplicando Deployment..."
kubectl apply -f "$MANIFEST_DIR/deployment.yaml"

echo "MCP Server aplicado. Verifique os pods: kubectl -n smartcity get pods -l app=mcp-server"
