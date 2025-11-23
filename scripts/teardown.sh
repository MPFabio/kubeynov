#!/bin/bash

set -e

echo "🗑️  Nettoyage de la plateforme DevOps..."

# Supprimer les ressources Kubernetes
echo "📦 Suppression des ressources Kubernetes..."

kubectl delete -f k8s/base/app/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/frontend-service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/frontend-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/backend-service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/backend-secret.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/backend-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-pvc.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-secret.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/base/app/postgres-init-configmap.yaml --ignore-not-found=true

kubectl delete -f k8s/base/monitoring/grafana-ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-pvc.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-dashboards-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-datasources-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/grafana-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/prometheus-ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/prometheus-service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/prometheus-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/prometheus-pvc.yaml --ignore-not-found=true
kubectl delete -f k8s/base/monitoring/prometheus-configmap.yaml --ignore-not-found=true

# Supprimer les namespaces (cela supprime aussi toutes les ressources)
echo "📁 Suppression des namespaces..."
kubectl delete namespace app --ignore-not-found=true --wait=true
kubectl delete namespace monitoring --ignore-not-found=true --wait=true
kubectl delete namespace gitops --ignore-not-found=true --wait=true

# Optionnel: supprimer le cluster KinD
read -p "Voulez-vous supprimer le cluster KinD? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Suppression du cluster KinD..."
    kind delete cluster --name metrics-cluster
    echo "✅ Cluster supprimé!"
else
    echo "ℹ️  Cluster KinD conservé."
fi

echo "✅ Nettoyage terminé!"


