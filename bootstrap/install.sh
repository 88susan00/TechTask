#!/bin/bash
set -e

echo ">>> Starting Minikube"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo ">>> Detected Apple Silicon (arm64)"
    echo ">>> Starting Minikube with amd64 emulation support"
    # Використовуємо docker driver з підтримкою емуляції
    minikube start --cpus=4 --memory=4096 --driver=docker
else
    echo ">>> Starting Minikube"
    minikube start --cpus=4 --memory=4096
fi

echo ">>> Enabling Ingress"
minikube addons enable ingress

echo ">>> Installing Argo CD"
kubectl create namespace argocd || true
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
