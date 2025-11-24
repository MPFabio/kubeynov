#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Configuration de Flux..."

# Vérifier que kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo "ERREUR: kubectl n'est pas installé"
    exit 1
fi

# Installer Flux si nécessaire
if ! kubectl get namespace flux-system &> /dev/null; then
    echo "Installation de Flux..."
    kubectl apply --server-side -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
    
    echo "Attente que Flux soit prêt..."
    kubectl wait --for=condition=ready pod -l app=helm-controller -n flux-system --timeout=300s || true
    kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s || true
    kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s || true
    
    echo "Flux installé"
else
    echo "Flux déjà installé"
fi

# Appliquer la configuration Flux
echo "Configuration de Flux..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/gitops/flux-application.yaml" || true

echo "Flux configuré!"
echo ""
echo "Informations Flux:"
echo "  - Namespace: flux-system"
echo "  - GitRepository: kubeynov"
echo "  - Kustomization: kubeynov-app"
echo ""
echo "Pour vérifier le statut:"
echo "   kubectl get gitrepository,kustomization -n flux-system"
echo ""
echo "Note: Flux surveille le repo GitHub et déploie automatiquement les changements."

