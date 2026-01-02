# 🖥️ Guide pgAdmin - Interface Web PostgreSQL

## ✅ pgAdmin installé et configuré !

pgAdmin est maintenant accessible depuis votre navigateur pour gérer facilement votre base de données PostgreSQL.

---

## 🌐 Accès à pgAdmin

### URL d'accès
```
http://localhost:5050
```

### Identifiants de connexion
```
Email: admin@example.com
Mot de passe: admin123
```

---

## 🔧 Configuration de la connexion PostgreSQL

### Première connexion

1. **Ouvrir pgAdmin** : http://localhost:5050

2. **Se connecter** avec les identifiants ci-dessus

3. **Ajouter un serveur** :
   - Clic droit sur "Servers" → "Register" → "Server..."

4. **Onglet "General"** :
   - Name: `PEA Advisor`

5. **Onglet "Connection"** :
   ```
   Host name/address: postgres
   Port: 5432
   Maintenance database: pea_advisor
   Username: root
   Password: 3e06831d498324ea8b0b5bc8a72bc5d0
   ```
   ☑️ Cocher "Save password"

6. **Cliquer sur "Save"**

---

## 📊 Explorer la base de données

### Navigation dans pgAdmin

```
Servers
  └── PEA Advisor
      └── Databases
          └── pea_advisor
              ├── Schemas
              │   └── public
              │       ├── Tables (14)
              │       │   ├── stocks
              │       │   ├── stock_prices
              │       │   ├── stock_fundamentals
              │       │   ├── technical_indicators
              │       │   ├── news
              │       │   ├── trading_signals
              │       │   ├── portfolio
              │       │   ├── transactions
              │       │   ├── portfolio_performance
              │       │   ├── ai_recommendations
              │       │   ├── alerts
              │       │   ├── watchlist
              │       │   ├── reports
              │       │   └── system_logs
              │       └── Views (2)
              │           ├── v_portfolio_summary
              │           └── v_top_opportunities
```

### Voir le contenu d'une table

1. Naviguer vers : **pea_advisor → Schemas → public → Tables**
2. Clic droit sur une table (ex: `stocks`) → **View/Edit Data** → **All Rows**
3. Les données s'affichent dans le panneau du bas

---

## 💻 Exécuter des requêtes SQL

### Ouvrir le Query Tool

1. Clic droit sur **pea_advisor** → **Query Tool**
2. Ou utilisez le raccourci dans la barre d'outils

### Exemples de requêtes

#### Voir toutes les actions
```sql
SELECT * FROM stocks ORDER BY ticker;
```

#### Voir les 10 derniers prix
```sql
SELECT s.ticker, s.name, sp.date, sp.close
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
ORDER BY sp.date DESC
LIMIT 10;
```

#### Résumé du portefeuille (via vue)
```sql
SELECT * FROM v_portfolio_summary;
```

#### Top opportunités
```sql
SELECT * FROM v_top_opportunities;
```

#### Statistiques de la base
```sql
SELECT
    (SELECT COUNT(*) FROM stocks) as nb_actions,
    (SELECT COUNT(*) FROM stock_prices) as nb_prix,
    (SELECT COUNT(*) FROM news) as nb_actualites,
    (SELECT COUNT(*) FROM trading_signals) as nb_signaux,
    (SELECT COUNT(*) FROM portfolio WHERE is_open = true) as positions_ouvertes;
```

---

## 🛠️ Fonctionnalités utiles de pgAdmin

### 1. Import/Export de données

**Exporter une table en CSV** :
- Clic droit sur la table → **Import/Export**
- Sélectionner "Export"
- Choisir le format (CSV, JSON, etc.)

### 2. Visualisation graphique

**Voir le schéma de la base (ERD)** :
- Clic droit sur **pea_advisor** → **ERD For Database**
- Affiche un diagramme des relations entre tables

### 3. Backup de la base

**Créer un backup** :
- Clic droit sur **pea_advisor** → **Backup...**
- Choisir le format (Custom, Plain, Tar)
- Sélectionner le chemin de sauvegarde

### 4. Monitoring

**Voir les statistiques** :
- Dashboard (clic sur le serveur)
- Affiche : connexions actives, taille des bases, transactions/sec

### 5. Édition de données

**Modifier des données directement** :
- Ouvrir une table en mode édition
- Cliquer sur une cellule pour modifier
- Sauvegarder avec F6 ou le bouton "Save"

---

## 🔍 Requêtes utiles pour le projet PEA

### Vérifier la collecte de données

```sql
-- Dernière date de prix collectés
SELECT MAX(date) as derniere_collecte FROM stock_prices;

-- Nombre de prix par action
SELECT s.ticker, COUNT(*) as nb_jours
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
GROUP BY s.ticker
ORDER BY nb_jours DESC;
```

### Analyser les signaux de trading

```sql
-- Signaux actifs par action
SELECT s.ticker, ts.signal_type, ts.overall_score, ts.created_at
FROM trading_signals ts
JOIN stocks s ON ts.stock_id = s.id
WHERE ts.is_active = true
ORDER BY ts.overall_score DESC;
```

### Performance du portefeuille

```sql
-- Calcul du rendement global
SELECT calculate_portfolio_return() as rendement_pct;

-- Performance par position
SELECT
    ticker,
    name,
    unrealized_pnl_percentage as performance_pct,
    unrealized_pnl as gain_perte_eur
FROM v_portfolio_summary
ORDER BY unrealized_pnl_percentage DESC;
```

### Actualités récentes

```sql
-- Dernières actualités avec sentiment
SELECT
    s.ticker,
    n.title,
    n.sentiment_label,
    n.sentiment_score,
    n.published_at
FROM news n
JOIN stocks s ON n.stock_id = s.id
WHERE n.published_at > CURRENT_DATE - INTERVAL '7 days'
ORDER BY n.published_at DESC
LIMIT 20;
```

---

## ⚙️ Configuration avancée

### Activer l'autocomplétion SQL

**Tools → Preferences → Query Tool** :
- ☑️ Auto-complete
- ☑️ Keywords in uppercase

### Personnaliser l'interface

**File → Preferences → Miscellaneous** :
- Thème sombre/clair
- Taille de police
- Format de date

### Sauvegarder les requêtes favorites

1. Écrire une requête dans le Query Tool
2. Menu **File** → **Save** (ou Ctrl+S)
3. La requête est sauvegardée pour usage futur

---

## 🚀 Raccourcis clavier utiles

| Raccourci | Action |
|-----------|--------|
| `F5` | Exécuter la requête |
| `F7` | Formater la requête SQL |
| `Ctrl + Space` | Autocomplétion |
| `Ctrl + S` | Sauvegarder la requête |
| `Ctrl + T` | Nouveau Query Tool |

---

## 📱 Alternatives à pgAdmin

Si vous préférez une autre interface :

### 1. **Adminer** (léger, 1 fichier PHP)
```bash
docker run -d -p 8080:8080 --name adminer --network self-hosted-ai-starter-kit_demo adminer
```
Accès: http://localhost:8080

### 2. **DBeaver** (application desktop)
- Télécharger : https://dbeaver.io/
- Très complet, supporte beaucoup de BDD

### 3. **psql** (ligne de commande)
```bash
docker exec -it self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor
```

---

## 🔒 Sécurité

### ⚠️ Important en production

Si vous exposez pgAdmin publiquement :

1. **Changer le mot de passe** dans docker-compose.yml
2. **Activer le mode serveur** :
   ```yaml
   - PGADMIN_CONFIG_SERVER_MODE=True
   - PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=True
   ```
3. **Utiliser HTTPS** avec un reverse proxy (nginx)
4. **Limiter l'accès** par IP ou VPN

### Configuration actuelle (développement)

- ✅ Accessible uniquement en local (localhost:5050)
- ⚠️ Mot de passe simple (à changer en prod)
- ⚠️ Pas d'authentification multi-facteurs

---

## 🆘 Troubleshooting

### pgAdmin ne démarre pas

```bash
# Vérifier les logs
docker logs pgadmin

# Redémarrer
docker restart pgadmin
```

### Impossible de se connecter à PostgreSQL

Vérifier que :
- Le hostname est bien `postgres` (pas `localhost`)
- Le port est `5432`
- Les credentials sont corrects
- PostgreSQL est démarré : `docker ps | grep postgres`

### "Too many login attempts"

Attendre 1 minute ou :
```bash
docker restart pgadmin
```

### L'interface est lente

pgAdmin peut être gourmand en ressources. Pour améliorer :
- Limiter le nombre de lignes affichées
- Utiliser des filtres dans les requêtes
- Fermer les onglets inutilisés

---

## 📚 Documentation officielle

- **pgAdmin** : https://www.pgadmin.org/docs/
- **PostgreSQL** : https://www.postgresql.org/docs/

---

**Interface configurée** : ✅ pgAdmin sur http://localhost:5050
**Base de données** : pea_advisor
**Tables** : 14
**Prêt à l'emploi** : ✅

---

**Astuce** : Ajoutez cette page à vos favoris pour un accès rapide ! 🔖
