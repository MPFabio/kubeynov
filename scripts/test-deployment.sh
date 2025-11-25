#!/bin/bash

set -e

echo "Test du deploiement complet..."

# Vérifier le cluster
echo "1. Verification du cluster..."
kubectl cluster-info > /dev/null 2>&1 || { echo "ERREUR: Cluster non accessible"; exit 1; }
echo "Cluster accessible"

# Vérifier les images
echo "2. Vérification des images Docker..."
if docker images | grep -q "backend.*latest"; then
    echo "Image backend trouvee"
else
    echo "ERREUR: Image backend manquante"
    exit 1
fi

if docker images | grep -q "frontend.*latest"; then
    echo "Image frontend trouvee"
else
    echo "ATTENTION: Image frontend manquante - construction..."
    docker build -t frontend:latest app/frontend
    kind load docker-image frontend:latest --name metrics-cluster
fi

# Vérifier les namespaces
echo "3. Vérification des namespaces..."
kubectl get namespace app > /dev/null 2>&1 || kubectl create namespace app
kubectl get namespace monitoring > /dev/null 2>&1 || kubectl create namespace monitoring
echo "Namespaces crees"

# Charger les images dans KinD
echo "4. Chargement des images dans KinD..."
kind load docker-image backend:latest --name metrics-cluster 2>/dev/null || true
kind load docker-image frontend:latest --name metrics-cluster 2>/dev/null || true
echo "Images chargees"

# Déployer l'application
echo "5. Deploiement de l'application..."
kubectl apply -f k8s/base/app/ --recursive=true
echo "Application deployee"

# Déployer le monitoring
echo "6. Deploiement du monitoring..."
kubectl apply -f k8s/base/monitoring/ --recursive=true
echo "Monitoring deploye"

# Attendre que les pods soient prêts
echo "7. Attente que les pods soient prêts..."
sleep 10
kubectl wait --for=condition=ready pod -l app=postgres -n app --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=backend -n app --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=frontend -n app --timeout=120s || true

# Vérifier l'état
echo "8. État des pods:"
kubectl get pods -n app
kubectl get pods -n monitoring

# Vérifier les services
echo "9. Services:"
kubectl get svc -n app
kubectl get ingress -n app

echo ""
echo "Tests termines!"
echo "URLs:"
echo "  - Application: http://localhost:30080"
echo "  - Grafana: http://localhost:30080/grafana (admin/admin)"
echo "  - Prometheus: http://localhost:30080/prometheus"

