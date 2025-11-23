# Migration ArgoCD → Flux

## ✅ Remplacement effectué

ArgoCD a été remplacé par **FluxCD** (Flux v2), une alternative GitOps plus légère et moderne.

## 📦 Installation Flux

Flux a été installé via le manifest officiel :
```bash
kubectl apply --server-side -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

## 🔧 Composants Flux installés

- **source-controller** : Gère les sources Git/Helm/OCI
- **kustomize-controller** : Applique les Kustomizations
- **helm-controller** : Gère les Helm releases
- **image-reflector-controller** : Surveille les images
- **image-automation-controller** : Automatise les mises à jour d'images
- **notification-controller** : Gère les notifications

## 📝 Configuration

### GitRepository
- **Nom** : `kubeynov`
- **URL** : `https://github.com/MPFabio/kubeynov`
- **Branche** : `main`
- **Intervalle** : 1 minute

### Kustomization
- **Nom** : `kubeynov-app`
- **Chemin** : `./k8s/base`
- **Intervalle** : 5 minutes
- **Prune** : Activé (supprime les ressources obsolètes)

## 🔍 Vérification

```bash
# Vérifier les pods Flux
kubectl get pods -n flux-system

# Vérifier les GitRepositories
kubectl get gitrepository -n flux-system

# Vérifier les Kustomizations
kubectl get kustomization -n flux-system

# Voir les logs
kubectl logs -n flux-system -l app=kustomize-controller
```

## 🎯 Avantages de Flux vs ArgoCD

- ✅ Plus léger (moins de ressources)
- ✅ Intégration native avec Kubernetes
- ✅ Support multi-tenancy
- ✅ API déclarative
- ✅ Pas besoin d'interface graphique (mais disponible via Weave GitOps)

## 📚 Documentation

- [Flux Documentation](https://fluxcd.io/docs/)
- [Flux GitHub](https://github.com/fluxcd/flux2)

