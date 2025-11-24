# Plateforme DevOps Kubernetes avec GitOps

Une plateforme DevOps complète déployée sur Kubernetes (KinD) avec monitoring, GitOps, et une application web moderne.

## Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Déploiement](#déploiement)
- [Accès aux services](#accès-aux-services)
- [GitOps avec Flux](#gitops-avec-flux)
- [Structure du projet](#structure-du-projet)
- [Dépannage](#dépannage)
- [Développement](#développement)

## Vue d'ensemble

Ce projet démontre une plateforme DevOps complète incluant :

- **Application Web** : Dashboard React moderne avec visualisation de métriques en temps réel
- **API Backend** : Service Node.js/Express avec exposition de métriques Prometheus
- **Base de données** : PostgreSQL pour stockage des métriques historiques
- **Monitoring** : Prometheus pour collecte de métriques et Grafana pour visualisation
- **GitOps** : Flux pour déploiement continu depuis Git
- **Infrastructure** : Tout déployé sur Kubernetes (KinD) avec scripts d'automatisation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Ingress (Nginx)                       │
│                    http://localhost                         │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
│   Frontend   │ │   Backend   │ │  PostgreSQL │
│   (React)    │ │  (Node.js)  │ │             │
│   Port 80    │ │  Port 8080  │ │  Port 5432  │
└──────────────┘ └──────┬──────┘ └──────┬──────┘
                        │               │
                        │               │
                ┌───────▼───────────────▼───────┐
                │      Prometheus               │
                │   (Collecte métriques)         │
                └───────┬───────────────────────┘
                        │
                ┌───────▼───────┐
                │    Grafana    │
                │ (Visualisation)│
                └───────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Flux (GitOps)                          │
│              Surveille le repo GitHub                        │
│              Déploie automatiquement                         │
└─────────────────────────────────────────────────────────────┘
```

### Composants

- **Namespace `app`** : Application principale (frontend, backend, database)
- **Namespace `monitoring`** : Stack de monitoring (Prometheus, Grafana)
- **Namespace `flux-system`** : Flux pour GitOps

## Prérequis

- **Docker** : Version 20.10 ou supérieure
- **KinD** : Kubernetes in Docker ([Installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- **kubectl** : Client Kubernetes ([Installation](https://kubernetes.io/docs/tasks/tools/))
- **Git** : Pour cloner le repository
- **GitHub CLI (gh)** : Pour la gestion du repo (optionnel)

### Installation rapide des prérequis

#### Sur Linux/MacOS

```bash
# KinD
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Sur Windows

```powershell
# KinD (via Chocolatey)
choco install kind

# kubectl (via Chocolatey)
choco install kubernetes-cli
```

## Installation

1. **Cloner le repository**

```bash
git clone https://github.com/MPFabio/kubeynov.git
cd kubeynov
git checkout test
```

2. **Configurer le cluster KinD**

```bash
./scripts/setup-kind.sh
```

Ce script va :
- Créer un cluster KinD nommé `metrics-cluster`
- Installer l'Ingress Controller Nginx
- Préparer l'environnement pour Flux

3. **Déployer l'application**

```bash
./scripts/deploy.sh
```

Ce script va :
- Construire les images Docker (frontend, backend)
- Charger les images dans KinD
- Déployer tous les composants (app, monitoring)
- Configurer les services et ingress

## Accès aux services

Une fois le déploiement terminé, les services sont accessibles via :

| Service | URL | Credentials |
|---------|-----|-------------|
| **Application** | http://localhost:30080 | - |
| **Prometheus** | http://localhost:30080/prometheus | - |
| **Grafana** | http://localhost:30080/grafana | admin / admin |
| **Flux** | Namespace: flux-system | (GitOps, pas d'UI web) |

### Vérifier le statut

```bash
# Voir tous les pods
kubectl get pods -A

# Voir les services
kubectl get svc -A

# Voir les ingress
kubectl get ingress -A
```

## GitOps avec Flux

Flux surveille le repository GitHub et déploie automatiquement les changements.

### Configuration initiale

```bash
./scripts/setup-flux.sh
```

### Workflow GitOps

1. **Modifier les manifests** dans `k8s/base/`
2. **Commit et push** vers la branche `main`
3. **Flux détecte** les changements automatiquement (intervalle: 5 minutes)
4. **Déploiement automatique** dans le cluster

### Ressources Flux configurées

- **GitRepository (kubeynov)** : Pointe vers https://github.com/MPFabio/kubeynov (branche main)
- **Kustomization (kubeynov-app)** : Applique les manifests depuis `k8s/base/`

### Vérifier le statut Flux

```bash
# Voir les GitRepositories
kubectl get gitrepository -n flux-system

# Voir les Kustomizations
kubectl get kustomization -n flux-system

# Voir les logs
kubectl logs -n flux-system -l app=kustomize-controller
```

## Structure du projet

```
kubeynov/
├── .github/                 # Workflows CI/CD (optionnel)
├── app/
│   ├── frontend/            # Application React
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── backend/             # API Node.js
│   │   ├── server.js
│   │   ├── Dockerfile
│   │   └── package.json
│   └── database/            # Configuration PostgreSQL
│       ├── Dockerfile
│       └── init.sql
├── k8s/
│   └── base/                # Manifests Kubernetes
│       ├── namespace/
│       ├── app/             # Manifests application
│       ├── monitoring/      # Manifests monitoring
│       └── gitops/          # Manifests Flux
├── scripts/
│   ├── setup-kind.sh        # Configuration cluster KinD
│   ├── deploy.sh            # Déploiement complet
│   ├── teardown.sh          # Nettoyage
│   └── setup-flux.sh        # Configuration Flux
└── README.md
```

## Dépannage

### Les pods ne démarrent pas

```bash
# Vérifier les logs
kubectl logs -n app <pod-name>

# Vérifier les événements
kubectl describe pod -n app <pod-name>

# Vérifier les ressources
kubectl top pods -n app
```

### L'application n'est pas accessible

```bash
# Vérifier l'ingress
kubectl get ingress -A
kubectl describe ingress -n app app-ingress

# Vérifier les services
kubectl get svc -n app

# Tester la connectivité
kubectl port-forward -n app svc/backend-service 8080:8080
curl http://localhost:8080/health
```

### Prometheus ne collecte pas de métriques

```bash
# Vérifier la configuration Prometheus
kubectl get configmap -n monitoring prometheus-config -o yaml

# Vérifier les targets
# Accéder à http://localhost/prometheus/targets

# Vérifier les logs
kubectl logs -n monitoring -l app=prometheus
```

### Flux ne synchronise pas

```bash
# Vérifier le statut des GitRepositories
kubectl get gitrepository -n flux-system
kubectl describe gitrepository kubeynov -n flux-system

# Vérifier le statut des Kustomizations
kubectl get kustomization -n flux-system
kubectl describe kustomization kubeynov-app -n flux-system

# Vérifier les logs
kubectl logs -n flux-system -l app=kustomize-controller
kubectl logs -n flux-system -l app=source-controller
```

### Réinitialiser complètement

```bash
# Nettoyer tout
./scripts/teardown.sh

# Recréer le cluster
./scripts/setup-kind.sh
./scripts/deploy.sh
```

## Développement

### Modifier l'application

1. **Frontend** : Modifier les fichiers dans `app/frontend/src/`
2. **Backend** : Modifier `app/backend/server.js`
3. **Rebuild et redéployer** :

```bash
# Rebuild les images
cd app/backend && docker build -t backend:latest .
cd ../frontend && docker build -t frontend:latest .

# Recharger dans KinD
kind load docker-image backend:latest --name metrics-cluster
kind load docker-image frontend:latest --name metrics-cluster

# Redémarrer les deployments
kubectl rollout restart deployment/backend -n app
kubectl rollout restart deployment/frontend -n app
```

### Ajouter de nouvelles métriques

1. Modifier `app/backend/server.js` pour exposer de nouvelles métriques
2. Modifier `app/frontend/src/components/Dashboard.jsx` pour les afficher
3. Rebuild et redéployer

### Modifier les dashboards Grafana

1. Modifier `k8s/base/monitoring/grafana-dashboards-configmap.yaml`
2. Appliquer : `kubectl apply -f k8s/base/monitoring/grafana-dashboards-configmap.yaml`
3. Redémarrer Grafana : `kubectl rollout restart deployment/grafana -n monitoring`

## Métriques exposées

L'application expose les métriques suivantes via Prometheus :

- `cpu_usage_percent` : Utilisation CPU
- `memory_usage_percent` : Utilisation mémoire
- `requests_per_second` : Requêtes par seconde
- `request_latency_ms` : Latence des requêtes
- `http_requests_total` : Total des requêtes HTTP
- `http_request_duration_seconds` : Durée des requêtes HTTP

## Sécurité

**Note importante** : Cette configuration est destinée à un environnement de développement. Pour la production :

- Utiliser des secrets Kubernetes sécurisés
- Configurer TLS/SSL pour les ingress
- Utiliser des images Docker scannées
- Implémenter des politiques de sécurité réseau
- Configurer RBAC approprié

## Workflow Git

Le projet utilise un workflow avec deux branches :

- **`main`** : Branche de production
- **`test`** : Branche de développement/test

Tous les changements sont faits sur `test`, puis mergés vers `main` après validation.

## Contribution

1. Créer une branche depuis `test`
2. Faire les modifications
3. Tester localement
4. Créer une Pull Request vers `test`
5. Après validation, merge vers `main`

## Licence

Ce projet est un projet éducatif/démonstration.

## Remerciements

- [KinD](https://kind.sigs.k8s.io/) pour Kubernetes in Docker
- [Flux](https://fluxcd.io/) pour GitOps
- [Prometheus](https://prometheus.io/) pour le monitoring
- [Grafana](https://grafana.com/) pour la visualisation

---

**Auteur** : Fabio  
**Date** : 2025  
**Version** : 1.0.0

