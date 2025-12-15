#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> Starting bootstrap process"

echo ">>> Step 1: Installing Minikube and ArgoCD"
bash "${SCRIPT_DIR}/install.sh"

echo ">>> Step 2: Waiting for ArgoCD to be ready"
bash "${SCRIPT_DIR}/wait-for-argocd.sh"

echo ">>> Step 3: Getting ArgoCD password"
bash "${SCRIPT_DIR}/get-argocd-password.sh"

echo ">>> Step 4: Applying ArgoCD applications"
bash "${SCRIPT_DIR}/apply-apps.sh"

echo ">>> Bootstrap completed successfully"
