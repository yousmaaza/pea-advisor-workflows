# Workflow 00 - Historical Data Loader

## 🎯 Objectif

Ce workflow charge **l'historique initial des prix** (250 jours) pour chaque action du portefeuille. C'est un workflow **critique** qui doit être exécuté **UNE SEULE FOIS** au démarrage du projet, avant de pouvoir calculer les indicateurs techniques.

## ⚡️ Pourquoi c'est CRITIQUE

Sans historique de prix, impossible de calculer :
- **RSI** (Relative Strength Index) → Besoin de 14 jours minimum
- **MACD** (Moving Average Convergence Divergence) → Besoin de 26 jours minimum
- **SMA 200** (Simple Moving Average 200 jours) → Besoin de 200 jours minimum
- **Bandes de Bollinger** → Besoin de 20 jours minimum

Le workflow 01 (Daily Market Data Collector) ne récupère que **1 jour** par exécution. Il faudrait donc attendre **250 jours** (1 an) avant d'avoir assez de données pour les indicateurs techniques !

## 📊 Architecture du Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Déclencheur Manuel (exécution unique)                    │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Récupérer les actions (PostgreSQL)                       │
│    SELECT stocks WHERE is_pea_eligible AND is_active        │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────────┐   ┌──────────────────────┐
│ 3. Yahoo Finance     │   │ Passer données       │
│    range=1y (250j)   │   │ stock directes       │
└──────┬───────────────┘   └───────┬──────────────┘
       │                           │
       └────────────┬──────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 4. Combiner données      │
       │    (Merge by position)   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 5. Parser Historical     │
       │    1 stock → 250 jours   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 6. Filtrer succès        │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 7. Insérer en BDD        │
       │    Table: stock_prices   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 8. Log succès            │
       └──────────────────────────┘
```

## 📡 API Yahoo Finance

### Endpoint Utilisé

```
GET https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?range=1y&interval=1d
```

### Paramètres

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `ticker` | Code action | "MC.PA", "AIR.PA", etc. |
| `range` | `1y` | 1 an d'historique (~250 jours de trading) |
| `interval` | `1d` | 1 jour (daily) |

### Réponse Type

```json
{
  "chart": {
    "result": [
      {
        "meta": {
          "currency": "EUR",
          "symbol": "MC.PA",
          "exchangeName": "PAR"
        },
        "timestamp": [1672531200, 1672617600, ...],
        "indicators": {
          "quote": [
            {
              "open": [750.2, 753.5, ...],
              "high": [755.0, 758.3, ...],
              "low": [748.1, 751.2, ...],
              "close": [752.5, 756.8, ...],
              "volume": [1234567, 1345678, ...]
            }
          ]
        }
      }
    ]
  }
}
```

**Format des données** :
- `timestamp` : Array de timestamps Unix (secondes depuis 1970)
- `open`, `high`, `low`, `close` : Arrays de prix (float)
- `volume` : Array de volumes (int)

**Longueur des arrays** : ~250 éléments (jours de trading sur 1 an, hors weekends et jours fériés)

## 🐍 Code Python du Parser

### Fonctionnalités

Le parser Python :
1. ✅ Parse les arrays de timestamps et prix
2. ✅ Crée **un item par jour** (expansion : 1 stock → 250 jours)
3. ✅ Convertit timestamps Unix en dates (YYYY-MM-DD)
4. ✅ Gère les valeurs None/null
5. ✅ Arrondit les prix à 4 décimales
6. ✅ Skip les jours avec données invalides

### Code Simplifié

```python
from datetime import datetime

results = []

# Pour chaque action
for item in _items:
    merged_data = item['json']
    stock_info = {'id': merged_data.get('id'), ...}
    yahoo_response = merged_data

    # Extraire les données du chart
    chart_data = yahoo_response['chart']['result'][0]
    timestamps = chart_data['timestamp']
    quote_data = chart_data['indicators']['quote'][0]

    opens = quote_data['open']
    highs = quote_data['high']
    lows = quote_data['low']
    closes = quote_data['close']
    volumes = quote_data['volume']

    # Créer un item pour chaque jour
    for i in range(len(timestamps)):
        date = datetime.fromtimestamp(timestamps[i]).strftime('%Y-%m-%d')

        day_data = {
            'stock_id': stock_info['id'],
            'ticker': stock_info['ticker'],
            'date': date,
            'open': round(opens[i], 4),
            'high': round(highs[i], 4),
            'low': round(lows[i], 4),
            'close': round(closes[i], 4),
            'volume': int(volumes[i]),
            'success': True
        }
        results.append({'json': day_data})

return results  # ~12 500 items pour 50 actions!
```

### ⚠️ Particularité : Expansion Massive des Items

Contrairement aux autres workflows :
- **Input** : 50 actions
- **Yahoo Finance** : 250 jours par action
- **Output** : **12 500 items** (50 × 250)

C'est pourquoi on utilise `runOnceForAllItems` avec une boucle sur `_items`.

## 💾 Insertion en Base de Données

### Table: `stock_prices`

```sql
INSERT INTO stock_prices (
    stock_id,
    date,
    open,
    high,
    low,
    close,
    volume,
    created_at
)
VALUES (
    $stock_id,
    $date,
    $open,
    $high,
    $low,
    $close,
    $volume,
    CURRENT_TIMESTAMP
)
ON CONFLICT (stock_id, date) DO NOTHING;  -- Évite les doublons
```

**Option importante** : `skipOnConflict: true` permet de relancer le workflow sans créer de doublons.

## ⚙️ Configuration du Workflow

### Trigger Manuel

Ce workflow utilise un **trigger manuel** (pas de schedule) car il doit être lancé **UNE SEULE FOIS** au démarrage.

```json
{
  "type": "n8n-nodes-base.manualTrigger",
  "name": "Déclencheur Manuel"
}
```

### Rate Limiting

```json
{
  "batchSize": 5,
  "batchInterval": 2000,
  "timeout": 30000
}
```

- **Batch size** : 5 actions à la fois
- **Délai** : 2 secondes entre chaque batch
- **Timeout** : 30 secondes max par requête (historique = plus lourd que 1 jour)

### Gestion d'Erreurs

Le workflow gère :
- ✅ Symboles invalides (ticker inexistant)
- ✅ Données manquantes (certains jours)
- ✅ Valeurs null (remplacées par 0.0)
- ✅ Doublons (via `ON CONFLICT`)

## 🧪 Tests

### Test Manuel

1. **S'assurer que la table `stock_prices` existe** :
   ```sql
   CREATE TABLE IF NOT EXISTS stock_prices (
       id SERIAL PRIMARY KEY,
       stock_id INTEGER REFERENCES stocks(id),
       date DATE NOT NULL,
       open DECIMAL(10, 4),
       high DECIMAL(10, 4),
       low DECIMAL(10, 4),
       close DECIMAL(10, 4),
       volume BIGINT,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       UNIQUE(stock_id, date)
   );
   ```

2. **Tester avec 3 actions** d'abord :
   ```sql
   -- Modifier temporairement la requête dans le node "Récupérer les actions"
   SELECT id, ticker, name
   FROM stocks
   WHERE is_pea_eligible = true
   LIMIT 3;
   ```

3. **Exécuter manuellement** dans n8n

4. **Vérifier les résultats** :
   ```sql
   SELECT
       s.ticker,
       s.name,
       COUNT(*) as nb_jours,
       MIN(sp.date) as date_min,
       MAX(sp.date) as date_max,
       AVG(sp.close) as avg_close
   FROM stock_prices sp
   JOIN stocks s ON s.id = sp.stock_id
   GROUP BY s.ticker, s.name
   ORDER BY s.ticker;
   ```

   **Résultat attendu** :
   - ~250 jours par action
   - Date min : il y a ~1 an
   - Date max : hier ou aujourd'hui

### Vérifier la Qualité des Données

```sql
-- Jours avec des données invalides (close = 0)
SELECT
    s.ticker,
    sp.date,
    sp.open,
    sp.high,
    sp.low,
    sp.close,
    sp.volume
FROM stock_prices sp
JOIN stocks s ON s.id = sp.stock_id
WHERE sp.close = 0
ORDER BY sp.date DESC;
```

Normalement, il ne devrait y avoir **aucune ligne** (les jours invalides sont skippés par le parser).

### Vérifier la Cohérence

```sql
-- Vérifier que high >= low, close <= high, close >= low
SELECT
    s.ticker,
    sp.date,
    sp.open,
    sp.high,
    sp.low,
    sp.close
FROM stock_prices sp
JOIN stocks s ON s.id = sp.stock_id
WHERE sp.high < sp.low
   OR sp.close > sp.high
   OR sp.close < sp.low
ORDER BY sp.date DESC;
```

Devrait retourner **0 lignes**.

## 📊 Statistiques Attendues

### Pour 50 Actions

| Métrique | Valeur |
|----------|--------|
| **Nombre d'actions** | 50 |
| **Jours par action** | ~250 (dépend des jours de trading) |
| **Total items insérés** | ~12 500 |
| **Durée d'exécution** | ~2-3 minutes |
| **Taille en BDD** | ~2-3 MB |

### Calcul du Temps d'Exécution

```
50 actions / 5 par batch = 10 batches
10 batches × 2 secondes = 20 secondes (requêtes)
+ Temps de parsing (~30 secondes)
+ Temps d'insertion (~60 secondes pour 12 500 rows)
= ~2 minutes total
```

## 🔄 Quand Relancer ce Workflow ?

Ce workflow est conçu pour être lancé **UNE SEULE FOIS** au démarrage. Cependant, vous pouvez le relancer si :

1. **Nouvelle action ajoutée** au portefeuille
   - Modifier la requête pour ne cibler que les nouvelles actions

2. **Données manquantes détectées**
   - Vérifier avec la requête de test ci-dessus

3. **Erreur lors de la première exécution**
   - L'option `skipOnConflict: true` évite les doublons

4. **Reset complet de la BDD**
   - Relancer pour tout recharger

## ⚠️ Points d'Attention

### Volume de Données

- **12 500 items** pour 50 actions, c'est beaucoup !
- n8n peut mettre du temps à traiter
- Surveillez l'utilisation mémoire de n8n pendant l'exécution

### API Yahoo Finance

- **Gratuit et illimité** (normalement)
- Mais respectez le rate limiting (batch de 5, délai de 2s)
- Si vous avez des erreurs 429 (Too Many Requests), augmentez le délai

### Cohérence des Données

Yahoo Finance peut avoir :
- Des valeurs `null` (marchés fermés, données manquantes)
- Des jours manquants (jours fériés)
- Des timestamps en UTC (gérez le timezone si besoin)

### Index de Performance

Pour optimiser les requêtes, créez des index :

```sql
-- Index sur (stock_id, date) pour les requêtes de range
CREATE INDEX idx_stock_prices_stock_date ON stock_prices(stock_id, date DESC);

-- Index sur date seule pour les agrégations
CREATE INDEX idx_stock_prices_date ON stock_prices(date DESC);
```

## 💡 Optimisations Futures

### Parallélisation

Pour accélérer l'exécution :
- Augmenter `batchSize` à 10 (si pas d'erreurs)
- Réduire `batchInterval` à 1000ms (1 seconde)

### Incremental Load

Si vous voulez mettre à jour l'historique :
```python
# Dans le parser, ne garder que les nouvelles dates
existing_dates = get_existing_dates_for_stock(stock_id)
if date not in existing_dates:
    results.append({'json': day_data})
```

### Détection d'Anomalies

Ajouter un node pour détecter :
- Variations de prix > 20% en 1 jour (split, erreur de donnée)
- Volumes anormalement bas (< 1000)
- Gaps importants entre dates

## 📚 Ressources

- [Yahoo Finance API (unofficial)](https://www.yahoofinanceapi.com/)
- [Documentation timestamps Unix](https://www.unixtimestamp.com/)
- [Guide Python datetime](https://docs.python.org/3/library/datetime.html)

---

## ✅ Checklist Avant Exécution

Avant de lancer ce workflow, vérifiez :

- [ ] Table `stock_prices` créée avec les bons champs
- [ ] Table `stocks` remplie avec les actions PEA
- [ ] Credentials PostgreSQL configurés dans n8n
- [ ] Test avec 3 actions d'abord (modifier la requête)
- [ ] n8n a assez de mémoire (au moins 2 GB disponibles)
- [ ] Pas d'autres workflows en cours (éviter la surcharge)

---

**Date de création** : 3 janvier 2026
**Version** : 1.0
**Statut** : ✅ Prêt pour tests
**Criticité** : 🔴 HAUTE (bloquant pour workflow 03)
