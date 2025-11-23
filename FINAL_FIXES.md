# Corrections Finales - ArgoCD et Grafana

## ✅ Problèmes Résolus

### 1. Grafana - Redirection incorrecte
**Problème** : Redirection vers `/grafana/grafana/` (double path)

**Solution** :
- Modifié `GF_SERVER_ROOT_URL` de `http://localhost:30080/grafana/` à `http://localhost:30080/grafana` (sans slash final)
- Retiré `GF_SERVER_DOMAIN` qui causait des conflits

**Status** : ✅ RÉSOLU - Grafana accessible sur http://localhost:30080/grafana/

### 2. ArgoCD - Échec de connexion sécurisée
**Problème** : ArgoCD tentait de forcer HTTPS

**Solution** :
- Ajouté `server.insecure: "true"` dans le ConfigMap `argocd-cm`
- Ajouté variable d'environnement `ARGOCD_SERVER_INSECURE: "true"` dans le deployment
- Configuré URL : `http://localhost:30080/argocd`

**Status** : ✅ RÉSOLU - ArgoCD accessible en HTTP sur http://localhost:30080/argocd/

## URLs Finales

- ✅ **Application** : http://localhost:30080
- ✅ **API** : http://localhost:30080/api/metrics
- ✅ **Grafana** : http://localhost:30080/grafana/
- ✅ **Prometheus** : http://localhost:30080/prometheus/
- ✅ **ArgoCD** : http://localhost:30080/argocd/

## Fichiers Modifiés

1. `k8s/base/monitoring/grafana-deployment.yaml` - Correction ROOT_URL
2. `k8s/base/gitops/argocd-rbac.yaml` - Ajout server.insecure
3. `k8s/base/gitops/argocd-install.yaml` - Ajout ARGOCD_SERVER_INSECURE

