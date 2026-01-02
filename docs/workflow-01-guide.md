# 📊 Workflow 01 - Collecte Quotidienne des Prix

## 🎯 Objectif

Ce workflow collecte automatiquement les prix de clôture quotidiens de toutes les actions éligibles PEA depuis Yahoo Finance et les stocke dans PostgreSQL.

---

## ⚙️ Configuration

### Fichier
`workflows/data-collection/01-daily-market-data-collector.json`

### Déclenchement
- **Type** : Programmé (Cron)
- **Fréquence** : Quotidien à 18h (lundi-vendredi)
- **Expression cron** : `0 18 * * 1-5`

### Prérequis
- ✅ Base de données PostgreSQL configurée
- ✅ Table `stocks` avec au moins 1 action active
- ✅ Connexion internet pour accéder à Yahoo Finance

---

## 🔄 Fonctionnement détaillé

### Étapes du workflow

```
1. Déclencheur Quotidien (18h en semaine)
   ↓
2. Récupérer les actions depuis PostgreSQL
   ↓
3. Traiter une par une (Split in Batches)
   ↓
4. Appeler Yahoo Finance API
   ↓
5. Extraire les données (Code)
   ↓
6. Vérifier validité (IF)
   ├─ OUI → 7. Insérer en BDD
   └─ NON → 8. Logger l'erreur
   ↓
9. Attendre 1.2s (rate limit)
   ↓
10. Boucle sur action suivante
    ↓
11. Agréger les résultats
    ↓
12. Log final
```

### Description des nœuds

#### 1. Déclencheur Quotidien
- **Type** : Schedule Trigger
- **Configuration** : Cron `0 18 * * 1-5`
- **Rôle** : Lance le workflow automatiquement chaque jour à 18h (hors weekend)

#### 2. Récupérer les actions
- **Type** : PostgreSQL
- **Requête** :
  ```sql
  SELECT id, ticker, name
  FROM stocks
  WHERE is_pea_eligible = true
    AND is_active = true
  ORDER BY ticker;
  ```
- **Rôle** : Récupère la liste de toutes les actions à suivre

#### 3. Traiter une par une
- **Type** : Split in Batches
- **Batch Size** : 1
- **Rôle** : Traite chaque action individuellement pour contrôler le débit

#### 4. Yahoo Finance API
- **Type** : HTTP Request
- **URL** : `https://query1.finance.yahoo.com/v8/finance/chart/{{ticker}}?interval=1d&range=1d`
- **Méthode** : GET
- **Timeout** : 10 secondes
- **Rôle** : Récupère les données de prix depuis Yahoo Finance

#### 5. Extraire les données
- **Type** : Code (JavaScript)
- **Rôle** : Parse la réponse JSON et extrait :
  - Date
  - Open, High, Low, Close
  - Volume
  - Adjusted Close

**Code JavaScript** :
```javascript
const response = $input.item.json;
const stockInfo = items[0].json;

try {
  const chart = response.chart.result[0];
  const quote = chart.indicators.quote[0];
  const timestamp = chart.timestamp[0];

  const date = new Date(timestamp * 1000).toISOString().split('T')[0];

  return {
    stock_id: stockInfo.id,
    ticker: stockInfo.ticker,
    date: date,
    open: quote.open[0],
    high: quote.high[0],
    low: quote.low[0],
    close: quote.close[0],
    volume: quote.volume[0],
    adjusted_close: chart.indicators.adjclose
      ? chart.indicators.adjclose[0].adjclose[0]
      : quote.close[0]
  };
} catch (error) {
  return {
    stock_id: stockInfo.id,
    ticker: stockInfo.ticker,
    error: error.message
  };
}
```

#### 6. Données valides ?
- **Type** : IF
- **Conditions** :
  - Pas d'erreur
  - Close price existe
- **Rôle** : Vérifie que les données sont exploitables

#### 7. Insérer en BDD
- **Type** : PostgreSQL
- **Requête** :
  ```sql
  INSERT INTO stock_prices (stock_id, date, open, high, low, close, volume, adjusted_close)
  VALUES (...)
  ON CONFLICT (stock_id, date)
  DO UPDATE SET ...
  ```
- **Rôle** : Insère ou met à jour les prix (upsert)

#### 8. Logger l'erreur
- **Type** : PostgreSQL
- **Rôle** : Enregistre les échecs dans `system_logs`

#### 9. Attendre (rate limit)
- **Type** : Wait
- **Durée** : 1200 ms (1.2 secondes)
- **Rôle** : Respecte les rate limits de Yahoo Finance

#### 10. Agréger les résultats
- **Type** : Code
- **Rôle** : Calcule les statistiques (total, succès, erreurs)

#### 11. Log final
- **Type** : PostgreSQL
- **Rôle** : Enregistre le résumé de l'exécution

---

## 📥 Import dans n8n

### Méthode 1 : Import via l'interface

1. Accéder à n8n : https://n8n01.dataforsciences.best/
2. Cliquer sur **"+"** → **"Import from File"**
3. Sélectionner `workflows/data-collection/01-daily-market-data-collector.json`
4. Configurer les credentials PostgreSQL

### Méthode 2 : Import via API

```bash
curl -X POST https://n8n01.dataforsciences.best/api/v1/workflows \
  -H "X-N8N-API-KEY: your_api_key" \
  -H "Content-Type: application/json" \
  -d @workflows/data-collection/01-daily-market-data-collector.json
```

---

## 🔑 Configuration des Credentials

### PostgreSQL Credential

Créer une nouvelle credential PostgreSQL dans n8n :

```
Name: PostgreSQL PEA Advisor
Host: postgres (nom du conteneur Docker)
Database: pea_advisor
User: root
Password: 3e06831d498324ea8b0b5bc8a72bc5d0
Port: 5432
SSL: Disabled
```

**⚠️ Important** : Le host doit être `postgres` (nom du conteneur), pas `localhost` !

---

## 🧪 Test du workflow

### Test manuel

1. Ouvrir le workflow dans n8n
2. Cliquer sur **"Execute Workflow"** en haut à droite
3. Observer l'exécution de chaque nœud
4. Vérifier les données insérées

### Vérifier les résultats dans PostgreSQL

```sql
-- Voir les derniers prix collectés
SELECT s.ticker, sp.date, sp.close, sp.volume
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
ORDER BY sp.date DESC, s.ticker
LIMIT 20;

-- Compter les prix par action
SELECT s.ticker, COUNT(*) as nb_jours
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
GROUP BY s.ticker
ORDER BY s.ticker;
```

### Vérifier les logs

```sql
-- Logs d'exécution
SELECT * FROM system_logs
WHERE workflow_name = 'daily-market-data-collector'
ORDER BY created_at DESC
LIMIT 10;
```

---

## 📊 Résultats attendus

### Après la première exécution

Pour **10 actions** en base :
- ✅ 10 lignes insérées dans `stock_prices`
- ✅ 1 log "info" dans `system_logs`
- ✅ Durée totale : ~15-20 secondes

### Données collectées par action

| Champ | Description | Exemple |
|-------|-------------|---------|
| stock_id | ID de l'action | 1 |
| date | Date du prix | 2026-01-02 |
| open | Prix d'ouverture | 825.50 |
| high | Plus haut du jour | 832.00 |
| low | Plus bas du jour | 820.00 |
| close | Prix de clôture | 828.75 |
| volume | Volume échangé | 1500000 |
| adjusted_close | Close ajusté | 828.75 |

---

## ⚠️ Gestion des erreurs

### Erreurs possibles

#### 1. Erreur de connexion à Yahoo Finance

**Symptôme** : Timeout ou HTTP 500

**Solution** :
- Vérifier la connexion internet
- Augmenter le timeout (dans HTTP Request node)
- Réessayer plus tard

#### 2. Ticker invalide

**Symptôme** : Erreur lors du parsing

**Solution** :
- Vérifier que les tickers sont corrects (format Yahoo : `MC.PA` pour LVMH)
- Corriger dans la table `stocks`

#### 3. Connexion PostgreSQL échouée

**Symptôme** : Erreur de connexion BDD

**Solution** :
- Vérifier que PostgreSQL est démarré : `docker ps | grep postgres`
- Vérifier les credentials
- Host = `postgres` (pas `localhost`)

#### 4. Rate limiting Yahoo Finance

**Symptôme** : HTTP 429 ou blocage

**Solution** :
- Augmenter le délai dans "Attendre (rate limit)"
- Réduire le nombre d'actions suivies
- Utiliser une autre source de données (Alpha Vantage)

### Logs d'erreurs

Les erreurs sont automatiquement loggées dans `system_logs` :

```sql
SELECT * FROM system_logs
WHERE workflow_name = 'daily-market-data-collector'
  AND level = 'error'
ORDER BY created_at DESC;
```

---

## 🔧 Personnalisation

### Changer l'heure d'exécution

Modifier l'expression cron dans le nœud "Déclencheur Quotidien" :

| Heure souhaitée | Expression cron |
|----------------|-----------------|
| 8h du matin | `0 8 * * 1-5` |
| 12h (midi) | `0 12 * * 1-5` |
| 20h (soir) | `0 20 * * 1-5` |
| Toute la semaine | `0 18 * * *` |

### Ajouter des actions à suivre

```sql
INSERT INTO stocks (ticker, name, isin, country, sector, is_pea_eligible)
VALUES ('AC.PA', 'Accor', 'FR0000120404', 'FR', 'Hôtellerie', true);
```

Le workflow les récupérera automatiquement lors de la prochaine exécution.

### Collecter plus d'historique

Modifier l'URL Yahoo Finance pour récupérer plus de jours :

```
https://query1.finance.yahoo.com/v8/finance/chart/{{ticker}}?interval=1d&range=5d
```

Puis adapter le code JavaScript pour traiter tous les jours retournés.

---

## 📈 Monitoring

### Vérifier que le workflow tourne

```sql
-- Dernière exécution
SELECT
    message,
    (details->>'total_stocks')::int as total,
    (details->>'successful')::int as success,
    (details->>'errors')::int as errors,
    created_at
FROM system_logs
WHERE workflow_name = 'daily-market-data-collector'
  AND level = 'info'
ORDER BY created_at DESC
LIMIT 5;
```

### Alertes recommandées

Créer des alertes si :
- ❌ Aucune exécution depuis 24h
- ❌ Taux d'erreur > 20%
- ❌ Aucune donnée collectée

---

## 🚀 Prochaines étapes

Une fois ce workflow opérationnel :

1. ✅ Laisser collecter des données pendant quelques jours
2. 📊 Créer le workflow 04 (analyse technique)
3. 📈 Visualiser les données dans pgAdmin
4. 🔔 Ajouter des notifications en cas d'erreur

---

## 📝 Notes importantes

- **Yahoo Finance** : API gratuite, pas d'authentification requise
- **Rate limits** : ~2000 requêtes/heure (~1 requête/seconde)
- **Données** : Prix de clôture du jour précédent (disponible après 18h)
- **Weekend** : Pas d'exécution samedi/dimanche (marchés fermés)
- **Upsert** : Si les données existent déjà pour une date, elles sont mises à jour

---

**Créé le** : 2 janvier 2026
**Version** : 1.0
**Statut** : ✅ Prêt à l'emploi
