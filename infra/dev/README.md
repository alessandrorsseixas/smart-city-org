Infra dev (infra/dev)

Este diretório contém recursos Kubernetes para expor o domínio local usado pelo Rancher (rancher.local) em um ambiente Minikube.

Objetivo
- Criar Service/Ingress que encaminhem para o Rancher instalado no namespace `cattle-system`.

Rápido passo-a-passo (dev)
1) Certifique-se de que Minikube está rodando com recursos suficientes (recomendado 2 CPU / 4Gi mínimo; 4 CPU / 8Gi recomendado para Rancher):
   minikube start --driver=docker --cpus=2 --memory=4096

1.1) Instalar/checar Ingress Controller (nginx)
   - Habilitar addon (Minikube):
     minikube addons enable ingress
   - Verificar o deployment do ingress-nginx:
     kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=3m

2) Aplique os manifests deste diretório (cria service e ingress):
   kubectl apply -k infra/dev

3) Execute o instalador do Rancher (script que já aplica infra/dev automaticamente e gera TLS autoassinado):
   ./scripts/dev/install-rancher-minikube.sh

4) Quando solicitado, confirme a adição da entrada em /etc/hosts (o script propõe: echo "$(minikube ip) rancher.local" | sudo tee -a /etc/hosts).

Acesso
- Após a instalação, acesse: https://rancher.local
- Se o navegador avisar sobre certificado autoassinado, aceite exceção (dev-only).

Limpeza / recriar
- Para recriar um ambiente limpo, remova o namespace do Rancher e reaplique (o instalador oferece flag --recreate):
  ./scripts/dev/install-rancher-minikube.sh --recreate

Notas
- Este conteúdo é para desenvolvimento/local. Não comite segredos de produção.
- Se preferir expor via NodePort ou ajustar portas, modifique os manifests em `infra/dev`.
