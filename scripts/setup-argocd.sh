#!/bin/bash

set -e

echo "🚀 Configuration d'ArgoCD..."

# Vérifier que le cluster existe
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Aucun cluster Kubernetes trouvé. Exécutez d'abord ./scripts/setup-kind.sh"
    exit 1
fi

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Installer ArgoCD CRDs si nécessaire
echo "📦 Vérification des CRDs ArgoCD..."
if ! kubectl get crd applications.argoproj.io &> /dev/null; then
    echo "📥 Installation des CRDs ArgoCD..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "⏳ Attente que ArgoCD soit prêt..."
    kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s || true
    kubectl wait --for=condition=available deployment/argocd-application-controller -n argocd --timeout=300s || true
    kubectl wait --for=condition=available deployment/argocd-repo-server -n argocd --timeout=300s || true
else
    echo "✅ CRDs ArgoCD déjà installés"
fi

# Appliquer la configuration ArgoCD
echo "⚙️  Configuration d'ArgoCD..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/gitops/argocd-namespace.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/gitops/argocd-rbac.yaml"

# Créer l'ingress pour ArgoCD
kubectl apply -f "$PROJECT_ROOT/k8s/base/gitops/argocd-install.yaml" || true

# Attendre un peu pour que les services soient prêts
sleep 10

# Récupérer le mot de passe admin
echo ""
echo "🔑 Récupération du mot de passe admin ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "admin")

echo ""
echo "✅ ArgoCD configuré!"
echo ""
echo "📋 Informations d'accès:"
echo "  - URL: http://localhost:30080/argocd"
echo "  - Username: admin"
echo "  - Password: $ARGOCD_PASSWORD"
echo ""
echo "💡 Pour créer les applications ArgoCD, exécutez:"
echo "   kubectl apply -f k8s/base/gitops/argocd-application.yaml"
echo ""
echo "⚠️  Note: Les applications ArgoCD pointeront vers le repo GitHub."
echo "   Assurez-vous que le repo est accessible et que la branche 'test' existe."

