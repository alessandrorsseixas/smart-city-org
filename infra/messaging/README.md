Messaging infra (RabbitMQ + Redis)

This folder holds minimal manifests and notes to deploy messaging components used by the Smart City project.

Included:
- RabbitMQ: StatefulSet + Service + kustomize
- Redis: Deployment + Service + PVC + kustomize

Dev notes:
- Secrets are intentionally left to overlays/dev.
- For production use, configure persistence storageClass and replicas.
