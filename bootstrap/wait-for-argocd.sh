#!/bin/bash
set -e

echo ">>> Waiting for ArgoCD to be ready"
kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=180s
echo ">>> ArgoCD is ready"
