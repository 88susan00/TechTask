#!/bin/bash
set -e

echo ">>> Getting ArgoCD password"
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
echo "ArgoCD password: $ARGOCD_PASSWORD"
echo "ArgoCD is ready"
