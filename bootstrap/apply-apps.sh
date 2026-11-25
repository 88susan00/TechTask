#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ">>> Applying ArgoCD applications"
kubectl apply -f "${REPO_ROOT}/argocd/"
echo ">>> ArgoCD applications applied"
