# 🗄️ Configuration de la Base de Données - Conseiller PEA

## ✅ Statut de l'installation

**Date de création** : 2 janvier 2026
**Statut** : ✅ Base de données configurée avec succès

---

## 📊 Informations de connexion

### Conteneur Docker
- **Nom** : `self-hosted-ai-starter-kit-postgres-1`
- **Image** : `postgres:16-alpine`
- **Statut** : Running (healthy)

### Credentials PostgreSQL
```
Host: self-hosted-ai-starter-kit-postgres-1
Port: 5432
Database: pea_advisor
User: root
Password: 3e06831d498324ea8b0b5bc8a72bc5d0
```

**⚠️ Important** : Ces credentials sont configurés dans `config/.env`

---

## 🏗️ Structure de la base

### Tables créées (14 au total)

| Table | Description | Lignes initiales |
|-------|-------------|------------------|
| `stocks` | Référentiel des actions éligibles PEA | 10 |
| `stock_prices` | Historique des cours | 0 |
| `stock_fundamentals` | Données fondamentales (P/E, ROE, etc.) | 0 |
| `technical_indicators` | Indicateurs techniques calculés | 0 |
| `news` | Actualités financières et sentiment | 0 |
| `trading_signals` | Signaux de trading générés | 0 |
| `portfolio` | Positions actuelles du portefeuille | 0 |
| `transactions` | Historique des transactions | 0 |
| `portfolio_performance` | Performance historique | 0 |
| `ai_recommendations` | Recommandations générées par IA | 0 |
| `alerts` | Alertes du système | 0 |
| `watchlist` | Watchlist personnalisée | 0 |
| `reports` | Rapports générés | 0 |
| `system_logs` | Logs du système | 0 |

### Vues SQL (2)

- **`v_portfolio_summary`** : Résumé du portefeuille actuel avec poids et P&L
- **`v_top_opportunities`** : Top 10 opportunités du jour (score > 70)

### Fonctions

- `calculate_portfolio_return()` : Calcule le rendement total du portefeuille
- `update_updated_at_column()` : Mise à jour automatique du timestamp

---

## 📈 Données initiales

### Actions CAC 40 pré-chargées

10 actions ont été insérées automatiquement :

| Ticker | Nom | ISIN | Secteur |
|--------|-----|------|---------|
| MC.PA | LVMH | FR0000121014 | Luxe |
| OR.PA | L'Oréal | FR0000120321 | Cosmétiques |
| SAN.PA | Sanofi | FR0000120578 | Pharmacie |
| AIR.PA | Airbus | NL0000235190 | Aéronautique |
| TTE.PA | TotalEnergies | FR0000120271 | Énergie |
| BNP.PA | BNP Paribas | FR0000131104 | Banque |
| SAF.PA | Safran | FR0000073272 | Aéronautique |
| SU.PA | Schneider Electric | FR0000121972 | Industrie |
| VIV.PA | Vivendi | FR0000127771 | Médias |
| RMS.PA | Hermès | FR0000052292 | Luxe |

---

## 🔧 Commandes utiles

### Se connecter à la base

```bash
docker exec -it self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor
```

### Tester la connexion

```bash
./scripts/test-db-connection.sh
```

### Lister les tables

```sql
\dt
```

### Voir le contenu d'une table

```sql
SELECT * FROM stocks;
SELECT * FROM stock_prices ORDER BY date DESC LIMIT 10;
```

### Utiliser les vues

```sql
-- Résumé du portefeuille
SELECT * FROM v_portfolio_summary;

-- Top opportunités
SELECT * FROM v_top_opportunities;
```

### Requêtes utiles

```sql
-- Compter les données
SELECT
    (SELECT COUNT(*) FROM stocks) as nb_stocks,
    (SELECT COUNT(*) FROM stock_prices) as nb_prices,
    (SELECT COUNT(*) FROM news) as nb_news,
    (SELECT COUNT(*) FROM trading_signals) as nb_signals;

-- Derniers prix par action
SELECT s.ticker, s.name, sp.date, sp.close
FROM stocks s
LEFT JOIN stock_prices sp ON s.id = sp.stock_id
WHERE sp.date = (SELECT MAX(date) FROM stock_prices WHERE stock_id = s.id)
ORDER BY s.ticker;

-- Performance du portefeuille
SELECT calculate_portfolio_return() as portfolio_return_pct;
```

---

## 🔄 Maintenance

### Backup de la base

```bash
# Backup complet
docker exec self-hosted-ai-starter-kit-postgres-1 pg_dump -U root pea_advisor > backup_$(date +%Y%m%d).sql

# Backup compressé
docker exec self-hosted-ai-starter-kit-postgres-1 pg_dump -U root pea_advisor | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restauration

```bash
# Depuis un backup SQL
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < backup.sql

# Depuis un backup compressé
gunzip -c backup.sql.gz | docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor
```

### Réinitialiser la base

```bash
# Supprimer et recréer
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "DROP DATABASE pea_advisor;"
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "CREATE DATABASE pea_advisor;"

# Réappliquer le schéma
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/schema.sql
```

### Nettoyer les anciennes données

```sql
-- Supprimer les données de plus de 2 ans
DELETE FROM stock_prices WHERE date < CURRENT_DATE - INTERVAL '2 years';
DELETE FROM news WHERE published_at < CURRENT_DATE - INTERVAL '1 year';

-- Nettoyer les signaux inactifs
DELETE FROM trading_signals WHERE is_active = false AND created_at < CURRENT_DATE - INTERVAL '6 months';

-- Vacuum pour récupérer l'espace
VACUUM ANALYZE;
```

---

## 🔐 Sécurité

### Bonnes pratiques

1. **Ne jamais exposer le port 5432** publiquement
2. **Changer le mot de passe** en production
3. **Créer un utilisateur dédié** avec des permissions limitées
4. **Activer SSL** pour les connexions
5. **Backups réguliers** (quotidiens recommandés)

### Créer un utilisateur dédié (recommandé pour production)

```sql
-- Créer l'utilisateur
CREATE USER pea_advisor_user WITH PASSWORD 'votre_mot_de_passe_securise';

-- Donner les permissions
GRANT CONNECT ON DATABASE pea_advisor TO pea_advisor_user;
GRANT USAGE ON SCHEMA public TO pea_advisor_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pea_advisor_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pea_advisor_user;
```

---

## 📝 Logs et monitoring

### Vérifier les logs PostgreSQL

```bash
docker logs self-hosted-ai-starter-kit-postgres-1 --tail 100
```

### Vérifier les connexions actives

```sql
SELECT
    datname,
    usename,
    application_name,
    client_addr,
    state,
    query
FROM pg_stat_activity
WHERE datname = 'pea_advisor';
```

### Statistiques des tables

```sql
SELECT
    schemaname,
    tablename,
    n_live_tup as row_count,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

---

## 🚀 Prochaines étapes

1. ✅ Base de données créée
2. ✅ Schéma initialisé
3. ✅ Données de test insérées
4. 📝 **À faire** : Configurer les API keys dans `config/.env`
5. 📝 **À faire** : Créer le premier workflow de collecte de données
6. 📝 **À faire** : Tester l'insertion de données via n8n

---

## ❓ Troubleshooting

### Erreur "database does not exist"
```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d n8n -c "CREATE DATABASE pea_advisor;"
```

### Erreur "relation does not exist"
```bash
# Réexécuter le schéma
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/schema.sql
```

### Conteneur PostgreSQL arrêté
```bash
docker start self-hosted-ai-starter-kit-postgres-1
```

### Vérifier la santé du conteneur
```bash
docker inspect self-hosted-ai-starter-kit-postgres-1 | grep -A 10 Health
```

---

**Dernière mise à jour** : 2 janvier 2026
**Version du schéma** : 1.0
**PostgreSQL version** : 16 (Alpine)
