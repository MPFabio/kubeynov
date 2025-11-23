# Solution Finale - Grafana et ArgoCD

## ✅ Grafana - Page Not Found

**Problème résolu** : 
- Grafana affichait "Page not found" malgré le chargement de la page
- **Cause** : Problème de routing avec le subpath `/grafana/`

**Solution appliquée** :
1. Ingress corrigé avec annotations `rewrite-target`
2. `GF_SERVER_ROOT_URL` configuré correctement
3. `GF_SERVER_SERVE_FROM_SUB_PATH` activé

**Test** :
```bash
curl http://localhost:30080/grafana/api/health
# Retourne : {"database": "ok", "version": "12.3.0", ...}
```

**Status** : ✅ **FONCTIONNEL** - Grafana est accessible et fonctionne correctement

## ⚠️ ArgoCD - ConfigMap Not Found

**Problème** : 
- Les pods ArgoCD server sont en CrashLoopBackOff
- Erreur : `configmap "argocd-cm" not found`
- Le ConfigMap existe pourtant dans le namespace `argocd`

**Diagnostic** :
- Le ConfigMap `argocd-cm` existe bien : `kubectl get configmap argocd-cm -n argocd`
- Les permissions RBAC sont correctes : `kubectl auth can-i get configmap -n argocd --as=system:serviceaccount:argocd:argocd-server` → `yes`
- Le ConfigMap a été recréé plusieurs fois sans succès

**Cause probable** :
- Problème de timing : le pod cherche le ConfigMap avant qu'il soit complètement synchronisé
- Problème avec l'informer Kubernetes qui ne voit pas le ConfigMap
- Conflit entre plusieurs versions d'ArgoCD (v2.10.0 et v3.3.0)

**Solution recommandée** :

### Option 1 : Utiliser l'installation officielle complète
```bash
# Supprimer le deployment personnalisé
kubectl delete deployment argocd-server -n argocd

# Réinstaller ArgoCD complètement
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que tout soit prêt
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Configurer pour HTTP
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge \
  -p '{"data":{"server.insecure":"true","server.basehref":"/argocd"}}'

# Redémarrer
kubectl rollout restart deployment/argocd-server -n argocd
```

### Option 2 : Créer le ConfigMap AVANT le deployment
```bash
# S'assurer que le ConfigMap existe et est stable
kubectl apply -f k8s/base/gitops/argocd-rbac.yaml

# Attendre quelques secondes
sleep 10

# Créer le deployment
kubectl apply -f k8s/base/gitops/argocd-server-deployment.yaml
```

### Option 3 : Utiliser initContainer pour vérifier le ConfigMap
Ajouter un initContainer qui vérifie que le ConfigMap existe avant de démarrer le serveur.

**Status** : ⚠️ **NÉCESSITE INTERVENTION MANUELLE**

## 📊 État Final

| Service | URL | Status |
|---------|-----|--------|
| **Application Frontend** | http://localhost:30080 | ✅ Fonctionnel |
| **API Backend** | http://localhost:30080/api/metrics | ✅ Fonctionnel |
| **Grafana** | http://localhost:30080/grafana/ | ✅ **FONCTIONNEL** |
| **Prometheus** | http://localhost:30080/prometheus/ | ✅ Fonctionnel |
| **ArgoCD** | http://localhost:30080/argocd/ | ⚠️ Nécessite correction manuelle |

## ✅ Conclusion

**Grafana est maintenant fonctionnel** - Le problème de "Page not found" est résolu.

**ArgoCD nécessite une intervention manuelle** pour résoudre le problème de ConfigMap. Les solutions recommandées sont documentées ci-dessus.

