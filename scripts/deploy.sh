#!/bin/bash

set -e

echo "🚀 Déploiement de la plateforme DevOps..."

# Vérifier que le cluster existe
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Aucun cluster Kubernetes trouvé. Exécutez d'abord ./scripts/setup-kind.sh"
    exit 1
fi

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build des images Docker
echo "🔨 Construction des images Docker..."

# Build backend avec cache et timeout augmenté
echo "📦 Construction de l'image backend..."
cd "$PROJECT_ROOT/app/backend"
docker build --progress=plain --no-cache=false -t backend:latest . || {
    echo "❌ Erreur lors du build de l'image backend"
    exit 1
}

# Build frontend avec cache et timeout augmenté
echo "📦 Construction de l'image frontend..."
cd "$PROJECT_ROOT/app/frontend"
docker build --progress=plain --no-cache=false -t frontend:latest . || {
    echo "❌ Erreur lors du build de l'image frontend"
    exit 1
}

# Retourner au répertoire racine
cd "$PROJECT_ROOT"

# Charger les images dans KinD
echo "📥 Chargement des images dans KinD..."
kind load docker-image backend:latest --name metrics-cluster
kind load docker-image frontend:latest --name metrics-cluster

# Créer les namespaces
echo "📁 Création des namespaces..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/namespace/namespace.yaml"

# Déployer la base de données
echo "🗄️  Déploiement de PostgreSQL..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-secret.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-pvc.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-init-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/postgres-service.yaml"

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente que PostgreSQL soit prêt..."
kubectl wait --for=condition=ready pod -l app=postgres -n app --timeout=120s

# Déployer le backend
echo "🔧 Déploiement du backend..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/backend-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/backend-secret.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/backend-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/backend-service.yaml"

# Déployer le frontend
echo "🎨 Déploiement du frontend..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/frontend-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/frontend-service.yaml"

# Déployer l'ingress
echo "🌐 Déploiement de l'Ingress..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/app/ingress.yaml"

# Déployer Prometheus
echo "📊 Déploiement de Prometheus..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/prometheus-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/prometheus-pvc.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/prometheus-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/prometheus-service.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/prometheus-ingress.yaml"

# Déployer Grafana
echo "📈 Déploiement de Grafana..."
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-datasources-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-dashboards-configmap.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-pvc.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-deployment.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-service.yaml"
kubectl apply -f "$PROJECT_ROOT/k8s/base/monitoring/grafana-ingress.yaml"

# Attendre que les pods soient prêts
echo "⏳ Attente que les pods soient prêts..."
kubectl wait --for=condition=ready pod -l app=backend -n app --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=frontend -n app --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || true

echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "📋 URLs d'accès:"
echo "  - Application: http://localhost:30080"
echo "  - Prometheus: http://localhost:30080/prometheus"
echo "  - Grafana: http://localhost:30080/grafana (admin/admin)"
echo ""
echo "📊 Statut des pods:"
kubectl get pods -n app
kubectl get pods -n monitoring

