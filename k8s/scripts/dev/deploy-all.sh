#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OVERLAYS_DIR="$ROOT_DIR/k8s/overlays/dev"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl não encontrado" >&2; exit 1; }

for d in "$OVERLAYS_DIR"/*/ ; do
  [ -d "$d" ] || continue
  echo "Aplicando overlay: $d"
  kubectl apply -k "$d"
done

echo "Todos os overlays dev aplicados."
