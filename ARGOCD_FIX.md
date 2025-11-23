# Correction ArgoCD - Instructions

## Problème
ArgoCD redirige vers HTTPS et cause "Échec de connexion sécurisée"

## Solution

ArgoCD a été installé via le script `setup-kind.sh` qui utilise l'installation officielle. Le déploiement personnalisé a été supprimé car il entrait en conflit.

### Pour corriger ArgoCD :

1. **Vérifier le type de ressource** :
```bash
kubectl get statefulset,deployment -n argocd | grep server
```

2. **Si c'est un StatefulSet** :
```bash
kubectl patch statefulset argocd-server -n argocd --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'
```

3. **Si c'est un Deployment** :
```bash
kubectl patch deployment argocd-server -n argocd --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'
```

4. **Redémarrer** :
```bash
kubectl rollout restart statefulset/argocd-server -n argocd
# ou
kubectl rollout restart deployment/argocd-server -n argocd
```

5. **Vérifier le ConfigMap** :
```bash
kubectl patch configmap argocd-cm -n argocd --type merge \
  -p '{"data":{"server.insecure":"true","url":"http://localhost:30080/argocd"}}'
```

## État Actuel

- ✅ Grafana : Fonctionnel
- ✅ Prometheus : Fonctionnel  
- ✅ API : Fonctionnel
- ⚠️ ArgoCD : Nécessite application manuelle du patch ci-dessus

