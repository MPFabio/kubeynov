#!/bin/bash

set -e

echo "🚀 Configuration du cluster KinD..."

# Vérifier si kind est installé
if ! command -v kind &> /dev/null; then
    echo "❌ KinD n'est pas installé. Installation..."
    echo "Veuillez installer KinD: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Vérifier si le cluster existe déjà
if kind get clusters | grep -q "metrics-cluster"; then
    echo "⚠️  Le cluster 'metrics-cluster' existe déjà."
    read -p "Voulez-vous le supprimer et en créer un nouveau? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Suppression du cluster existant..."
        kind delete cluster --name metrics-cluster
    else
        echo "✅ Utilisation du cluster existant."
        exit 0
    fi
fi

# Créer la configuration KinD
cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: metrics-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 30080
    protocol: TCP
  - containerPort: 443
    hostPort: 30443
    protocol: TCP
EOF

# Créer le cluster
echo "📦 Création du cluster KinD..."
kind create cluster --name metrics-cluster --config /tmp/kind-config.yaml

# Attendre que le cluster soit prêt
echo "⏳ Attente que le cluster soit prêt..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Installer l'ingress controller
echo "🌐 Installation de l'Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Attendre que l'ingress soit prêt
echo "⏳ Attente que l'Ingress Controller soit prêt..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Installer les CRDs ArgoCD
echo "📦 Installation des CRDs ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true

echo "✅ Cluster KinD configuré avec succès!"
echo ""
echo "📋 Informations du cluster:"
kubectl cluster-info --context kind-metrics-cluster

