#!/usr/bin/env bash
set -euo pipefail

# Wrapper para validar dependências e executar os scripts padronizados em k8s/scripts/dev
# Uso: run.sh [--all] [--components comp1,comp2] [-n namespace] [-x allowedContext] [-t timeout] [--force]

usage() {
  cat <<EOF
Usage: $(basename "$0") [--all] [--components comp1,comp2] [-n namespace] [-x allowedContext] [-t timeout] [--force] [-h]

Options:
  --all                Aplicar todos os overlays encontrados em k8s/overlays/dev
  --components LIST    Lista separada por vírgula dos componentes (ex: mongo,postgres,n8n)
  -n namespace         Namespace Kubernetes (default: smartcity)
  -x allowedContext    Se definido, exige que kubectl current-context bata com este valor (security)
  -t timeout           Tempo de espera em segundos para readiness (default: 120)
  --force              Ignora checagem de contexto
  -h                   Ajuda

Este script valida:
  - presença do kubectl
  - existência do namespace (tenta criar se não existir)
  - presença de arquivos de secret no overlay (avisa se não encontrar)

Ele invoca, por componente, o script correspondente em k8s/scripts/dev/deploy-<component>.sh
se existir, senão executa "kubectl apply -k <overlay>".
EOF
}

NAMESPACE="smartcity"
TIMEOUT=120
ALLOWED_CONTEXT=""
FORCE=0
COMPONENTS=""
ALL=0

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL=1; shift 1 ;;
    --components) COMPONENTS="$2"; shift 2 ;;
    -n) NAMESPACE="$2"; shift 2 ;;
    -x) ALLOWED_CONTEXT="$2"; shift 2 ;;
    -t) TIMEOUT="$2"; shift 2 ;;
    --force) FORCE=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OVERLAYS_DIR="$ROOT_DIR/k8s/overlays/dev"
SCRIPTS_DIR="$ROOT_DIR/k8s/scripts/dev"
NAMESPACE_FILE="$ROOT_DIR/k8s/base/namespace-smartcity.yaml"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl não encontrado" >&2; exit 1; }

# Context safety check
if [[ -n "$ALLOWED_CONTEXT" && "$FORCE" -eq 0 ]]; then
  CURRENT_CTX="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$CURRENT_CTX" != "$ALLOWED_CONTEXT" ]]; then
    echo "Current kubectl context '$CURRENT_CTX' does not match allowed context '$ALLOWED_CONTEXT'. Use --force to override." >&2
    exit 3
  fi
fi

# Ensure namespace exists (try to apply base manifest if present, else create)
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace '$NAMESPACE' não encontrado. Tentando criar..."
  if [[ -f "$NAMESPACE_FILE" ]]; then
    kubectl apply -f "$NAMESPACE_FILE"
  else
    kubectl create namespace "$NAMESPACE"
  fi
fi

# Build list of components
components_to_run=()
if [[ "$ALL" -eq 1 ]]; then
  for d in "$OVERLAYS_DIR"/*/ ; do
    [[ -d "$d" ]] || continue
    comp=$(basename "$d")
    components_to_run+=("$comp")
  done
elif [[ -n "$COMPONENTS" ]]; then
  IFS=',' read -r -a comps <<< "$COMPONENTS"
  for c in "${comps[@]}"; do
    components_to_run+=("$(echo "$c" | xargs)")
  done
else
  echo "Nenhum componente especificado. Use --all ou --components." >&2
  usage
  exit 2
fi

# Run each component: pre-check overlay and secrets, then invoke deploy script or kubectl
for comp in "${components_to_run[@]}"; do
  overlay_dir="$OVERLAYS_DIR/$comp"
  if [[ ! -d "$overlay_dir" ]]; then
    echo "Overlay para componente '$comp' não encontrado em: $overlay_dir" >&2
    continue
  fi

  # Check for secret manifests inside overlay (common names)
  secret_files=("$overlay_dir/secret.yaml" "$overlay_dir/*secret*.yaml" "$overlay_dir/*-secret*.yaml")
  has_secret_file=0
  for f in $overlay_dir/*; do
    if [[ -f "$f" && "$(basename "$f")" == *secret* ]]; then
      has_secret_file=1
      break
    fi
  done
  if [[ "$has_secret_file" -eq 0 ]]; then
    echo "Aviso: overlay '$comp' não contém arquivo de secret detectável. Verifique se os segredos necessários existem no cluster." >&2
  fi

  deploy_script="$SCRIPTS_DIR/deploy-$comp.sh"
  if [[ -x "$deploy_script" ]]; then
    echo "Executando script de deploy para: $comp"
    # pass through flags; if ALLOWED_CONTEXT empty, scripts handle it
    cmd=("$deploy_script" -n "$NAMESPACE" -k "$overlay_dir" -t "$TIMEOUT")
    if [[ -n "$ALLOWED_CONTEXT" ]]; then
      cmd+=( -x "$ALLOWED_CONTEXT" )
    fi
    if [[ "$FORCE" -eq 1 ]]; then
      cmd+=( --force )
    fi
    "${cmd[@]}"
  else
    echo "Script de deploy específico não encontrado para $comp, aplicando overlay diretamente"
    kubectl apply -k "$overlay_dir"
    echo "Aguardando pods do componente $comp ficarem prontos (se aplicável)"
    LABEL_SELECTOR="app=$comp"
    if kubectl -n "$NAMESPACE" get pods -l "$LABEL_SELECTOR" >/dev/null 2>&1; then
      kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l "$LABEL_SELECTOR" --timeout=${TIMEOUT}s || {
        echo "Aviso: alguns pods de $comp não ficaram prontos dentro do timeout" >&2
      }
    else
      echo "Nenhum pod com label $LABEL_SELECTOR encontrado para $comp"
    fi
  fi

done

echo "Execução concluída."
