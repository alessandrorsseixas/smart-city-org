House Control k8s base manifests

This directory contains the base kustomize manifests for the house-control microservice.

Files:
- deployment.yaml
- service.yaml
- configmap.yaml

Notes:
- Secrets are provided by overlays (dev/prod)
- Deployment references `house-control-secrets` for DB and Redis credentials
