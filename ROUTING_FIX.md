# Correction du Routing Ingress

## Problème identifié

Le catch-all `/` dans `app-ingress` interceptait toutes les requêtes avant que les autres ingresses (Grafana, Prometheus) ne soient évalués, causant :
- Toutes les requêtes redirigées vers le frontend
- Grafana inaccessible
- Prometheus inaccessible

## Solution appliquée

1. **Ingresses séparés avec priorité** :
   - `grafana-ingress` : Priorité 500 (évalué en premier)
   - `prometheus-ingress` : Priorité 500 (évalué en premier)
   - `app-ingress` : Priorité 100 (évalué en dernier)

2. **Ordre des paths dans app-ingress** :
   - `/api` en premier (Prefix)
   - `/` en dernier (catch-all)

3. **Configuration Grafana** :
   - `GF_SERVER_ROOT_URL`: `http://localhost:30080/grafana/` (avec slash final)
   - `GF_SERVER_SERVE_FROM_SUB_PATH`: `true`

## État actuel

✅ **Grafana** : Accessible sur http://localhost:30080/grafana/
- API health : ✅ Fonctionnel
- Login : Accessible

✅ **Prometheus** : Accessible sur http://localhost:30080/prometheus/
- API : ✅ Fonctionnel

✅ **API Backend** : Accessible sur http://localhost:30080/api/metrics
- Endpoints : ✅ Fonctionnels

✅ **Frontend** : Accessible sur http://localhost:30080/
- Dashboard : ✅ Fonctionnel

## Tests

```bash
# Grafana
curl http://localhost:30080/grafana/api/health

# Prometheus
curl http://localhost:30080/prometheus/api/v1/status/config

# API
curl http://localhost:30080/api/metrics

# Frontend
curl http://localhost:30080/
```

