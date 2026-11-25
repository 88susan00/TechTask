#!/bin/bash
set -e

echo ">>> Waiting for ArgoCD CRDs"
kubectl wait --for=condition=Established \
  crd/applications.argoproj.io crd/appprojects.argoproj.io --timeout=60s

echo ">>> Waiting for ArgoCD components to be ready"
kubectl wait --for=condition=Available deployment --all \
  -n argocd --timeout=300s
kubectl rollout status statefulset/argocd-application-controller \
  -n argocd --timeout=300s

echo ">>> Waiting for ArgoCD initial admin secret"
for i in $(seq 1 60); do
  kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1 && break
  sleep 2
done
echo ">>> ArgoCD is ready"
