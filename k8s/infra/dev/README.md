Dev infra (k8s/infra/dev)

This folder contains Kubernetes manifests for local development (Minikube).

Secrets
- Secrets here are dev-only and use `stringData` with placeholder values.
- Do NOT use these secrets in production.

How to regenerate secrets locally
- Using kubectl create secret:
  kubectl create secret generic postgres-secrets \
    --from-literal=POSTGRES_USER=postgres \
    --from-literal=POSTGRES_PASSWORD=postgres -n <namespace>

- Or apply the provided secret manifests:
  kubectl apply -f k8s/infra/dev/postgres-secret.yaml -n <namespace>
  kubectl apply -f k8s/infra/dev/redis-secret.yaml -n <namespace>
  kubectl apply -f k8s/infra/dev/rabbitmq-secret.yaml -n <namespace>
  kubectl apply -f k8s/infra/dev/keycloak-secret.yaml -n <namespace>

Notes
- For production, use SealedSecrets / ExternalSecrets / Vault.
- Adjust resources in manifests if your Minikube has less than 2 CPU / 4Gi memory.
