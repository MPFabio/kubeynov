#!/bin/bash
set -e

echo "🧪 TEST COMPLET DU PROJET"
echo "========================"

# 1. Build frontend
echo "[1/6] Construction frontend..."
cd app/frontend
docker build -t frontend:latest . > /tmp/frontend-build.log 2>&1 &
FRONTEND_PID=$!
cd ../..

# 2. Vérifier backend
echo "[2/6] Vérification backend..."
docker images | grep backend || echo "Backend manquant"

# 3. Charger images
echo "[3/6] Chargement images KinD..."
wait $FRONTEND_PID
kind load docker-image backend:latest --name metrics-cluster
kind load docker-image frontend:latest --name metrics-cluster

# 4. Déployer
echo "[4/6] Déploiement..."
kubectl apply -f k8s/base/namespace/namespace.yaml
kubectl apply -f k8s/base/app/ --recursive
kubectl apply -f k8s/base/monitoring/ --recursive

# 5. Attendre
echo "[5/6] Attente pods..."
sleep 30

# 6. Vérifier
echo "[6/6] Vérification..."
kubectl get pods -n app
kubectl get pods -n monitoring
kubectl get svc -n app
kubectl get ingress -n app

echo "✅ TEST TERMINÉ"

