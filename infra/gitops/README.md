GitOps helpers for Smart City

This folder contains templates and guides for wiring ArgoCD and initial Application CRs.

- apps/ and projects/ should be created under k8s/argocd for production GitOps.
- Use overlays/dev when testing locally and ArgoCD for sync in QA/prod.
