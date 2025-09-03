Monitoring infra (Prometheus + Grafana)

This folder contains minimal manifests to deploy Prometheus and Grafana for development.

Notes:
- For production use prefer the kube-prometheus-stack Helm chart or operator.
- ServiceMonitor resources assume Prometheus Operator present.
