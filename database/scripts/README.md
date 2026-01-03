# 📁 Scripts Base de Données

Ce dossier contient des scripts utilitaires pour la gestion de la base de données PostgreSQL.

---

## 🗑️ Scripts de Vidage des Tables

### 1. `clear_all_tables.sql` - Tout supprimer

**⚠️ DANGER : Supprime TOUTES les données !**

Vide toutes les tables de la base de données, y compris la liste des actions.

**Quand l'utiliser :**
- Réinitialisation complète en développement
- Nettoyage avant reimport complet de données
- Tests de création de schéma

**Commande :**
```bash
# Via Docker (recommandé)
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/scripts/clear_all_tables.sql

# Via psql local
psql -U root -d pea_advisor -f database/scripts/clear_all_tables.sql
```

**Ce qui est vidé :**
- ✅ Toutes les tables (14 tables)
- ✅ Réinitialisation des IDs à 1
- ✅ Suppression en cascade des dépendances

---

### 2. `clear_data_tables.sql` - Garder les stocks

**ℹ️ Plus sûr : Garde la configuration des actions**

Vide uniquement les données collectées (prix, news, indicateurs, etc.) mais conserve la liste des actions et la watchlist.

**Quand l'utiliser :**
- Réinitialiser les données sans reconfigurer les actions
- Nettoyer avant de relancer workflow 00 (Historical Data Loader)
- Tests de collecte de données

**Commande :**
```bash
# Via Docker (recommandé)
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/scripts/clear_data_tables.sql

# Via psql local
psql -U root -d pea_advisor -f database/scripts/clear_data_tables.sql
```

**Ce qui est conservé :**
- ✅ `stocks` - Liste des actions
- ✅ `watchlist` - Actions suivies

**Ce qui est vidé :**
- 🗑️ `stock_prices` - Prix historiques
- 🗑️ `stock_fundamentals` - Données fondamentales
- 🗑️ `technical_indicators` - Indicateurs techniques
- 🗑️ `news` - Actualités
- 🗑️ `trading_signals` - Signaux de trading
- 🗑️ `ai_recommendations` - Recommandations IA
- 🗑️ `portfolio` - Positions
- 🗑️ `transactions` - Historique transactions
- 🗑️ `portfolio_performance` - Performance
- 🗑️ `alerts` - Alertes
- 🗑️ `reports` - Rapports
- 🗑️ `system_logs` - Logs système

---

## 📊 Vérification après vidage

Les deux scripts affichent automatiquement un rapport avec le nombre de lignes dans chaque table.

**Exemple de sortie :**
```
  table_name         | row_count | status
---------------------+-----------+----------
  stocks             |    50     | ✅ Conservé
  watchlist          |    10     | ✅ Conservé
  stock_prices       |     0     | 🗑️ Vidé
  technical_indicators|    0     | 🗑️ Vidé
  news               |     0     | 🗑️ Vidé
  ...
```

---

## 🔄 Workflow de Réinitialisation Recommandé

### Scénario 1 : Réinitialisation complète

```bash
# 1. Vider toutes les tables
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/scripts/clear_all_tables.sql

# 2. Réimporter le schéma complet
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/schema.sql

# 3. Lancer Workflow 00 (Historical Data Loader)
# Via n8n UI
```

### Scénario 2 : Recharger les données uniquement

```bash
# 1. Vider les données (garder les stocks)
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < database/scripts/clear_data_tables.sql

# 2. Lancer Workflow 00 (Historical Data Loader)
# Via n8n UI

# 3. Lancer Workflow 01 (Daily Market Data Collector)
# Via n8n UI

# 4. Lancer Workflow 03 (Technical Indicators Calculator)
# Via n8n UI
```

---

## ⚠️ Précautions de Sécurité

### Avant de vider les tables :

1. **Backup** : Toujours faire une sauvegarde avant !
   ```bash
   docker exec self-hosted-ai-starter-kit-postgres-1 pg_dump -U root pea_advisor > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Vérifier l'environnement** :
   - ❌ **JAMAIS en production** sans backup
   - ✅ OK en développement local
   - ✅ OK en environnement de test

3. **Confirmer la base de données** :
   ```bash
   # Vérifier qu'on est bien sur la bonne base
   docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "SELECT current_database();"
   ```

---

## 🔙 Restauration depuis Backup

Si vous avez fait un backup :

```bash
# Restaurer depuis un backup
docker exec -i self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor < backup_20260103_120000.sql
```

---

## 📝 Logs et Vérification

Vérifier le nombre de lignes dans toutes les tables :

```bash
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = tablename) as columns
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
"
```

---

## 🆘 Aide et Support

- **Documentation principale** : `/docs/DATABASE_SETUP.md`
- **Schéma complet** : `/database/schema.sql`
- **Migrations** : `/database/migrations/`
- **Convention Timezone** : `/docs/TIMEZONE_CONVENTION.md`

---

**Dernière mise à jour** : 3 janvier 2026
**Version** : 1.0
