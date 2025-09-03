#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Apply prometheus and grafana overlays/dev
kubectl apply -k "$ROOT_DIR/prometheus"
kubectl apply -k "$ROOT_DIR/grafana"
