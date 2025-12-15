#!/bin/bash
set -e

echo ">>> Applying ArgoCD applications"
kubectl apply -f argocd/
echo ">>> ArgoCD applications applied"