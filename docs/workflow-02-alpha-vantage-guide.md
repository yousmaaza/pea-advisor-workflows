# Workflow 02 - Technical Indicators Collector (Alpha Vantage)

## 🎯 Objectif

Ce workflow collecte automatiquement les indicateurs techniques depuis l'API Alpha Vantage et les stocke dans PostgreSQL. Il utilise la même architecture Python + Merge que le workflow 01.

## 📊 Architecture du Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Déclencheur Quotidien (19h, lun-ven)                     │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Récupérer les actions (PostgreSQL)                       │
│    SELECT id, ticker, name FROM stocks                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────────┐   ┌──────────────────────┐
│ 3. Alpha Vantage RSI │   │ Passer données       │
│    API               │   │ stock directes       │
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
       │ 5. Parser RSI Python     │
       │    Utilise _item         │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 6. Filtrer succès        │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 7. Insérer en BDD        │
       │    technical_indicators  │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 8. Log succès            │
       └──────────────────────────┘
```

## 🔑 Configuration Alpha Vantage

### Obtenir une API Key

1. Aller sur https://www.alphavantage.co/support/#api-key
2. S'inscrire gratuitement
3. Récupérer votre API key

### Ajouter la clé dans .env

```bash
# Alpha Vantage API
ALPHA_VANTAGE_API_KEY=your_api_key_here
```

### Limites de l'API Gratuite

- **5 requêtes par minute**
- **500 requêtes par jour**
- Pour 50 actions: ~10 minutes de traitement (avec délai de 12 secondes entre chaque)

## 📡 API Alpha Vantage - RSI

### Endpoint Utilisé

```
GET https://www.alphavantage.co/query
?function=RSI
&symbol={TICKER}
&interval=daily
&time_period=14
&apikey={API_KEY}
```

### Réponse Type

```json
{
  "Meta Data": {
    "1: Symbol": "IBM",
    "2: Indicator": "Relative Strength Index (RSI)",
    "3: Last Refreshed": "2024-01-04",
    "4: Interval": "daily",
    "5: Time Period": 14
  },
  "Technical Analysis: RSI": {
    "2024-01-04": {
      "RSI": "52.3456"
    },
    "2024-01-03": {
      "RSI": "51.2345"
    }
  }
}
```

### Gestion du Rate Limit

Si le rate limit est atteint, Alpha Vantage retourne:

```json
{
  "Note": "Thank you for using Alpha Vantage! Our standard API call frequency is 5 calls per minute..."
}
```

Le workflow détecte ce cas et marque l'item comme `success: false`.

## 🐍 Code Python du Parser

```python
from datetime import datetime, timedelta

# Récupérer les données combinées depuis le Merge
merged_data = _item['json']

# Extraire les données du stock
stock_info = {
    'id': merged_data.get('id'),
    'ticker': merged_data.get('ticker'),
    'name': merged_data.get('name')
}

# Les données Alpha Vantage sont aussi dans merged_data
alpha_response = merged_data

try:
    # Vérifier si on a les données RSI
    if alpha_response.get('Technical Analysis: RSI'):
        rsi_data = alpha_response['Technical Analysis: RSI']

        # Récupérer la date la plus récente
        latest_date = max(rsi_data.keys())
        latest_rsi = float(rsi_data[latest_date]['RSI'])

        # Convertir la date
        date = datetime.strptime(latest_date, '%Y-%m-%d').strftime('%Y-%m-%d')

        return {
            'json': {
                'stock_id': stock_info['id'],
                'ticker': stock_info['ticker'],
                'name': stock_info['name'],
                'date': date,
                'rsi_14': latest_rsi,
                'success': True
            }
        }
    elif alpha_response.get('Note'):
        # API rate limit atteint
        return {
            'json': {
                'stock_id': stock_info['id'],
                'ticker': stock_info['ticker'],
                'name': stock_info['name'],
                'success': False,
                'error': 'API rate limit reached'
            }
        }
except Exception as error:
    return {
        'json': {
            'stock_id': stock_info['id'],
            'ticker': stock_info['ticker'],
            'name': stock_info['name'],
            'success': False,
            'error': str(error)
        }
    }
```

## 💾 Insertion en Base de Données

### Table: `technical_indicators`

```sql
INSERT INTO technical_indicators (stock_id, date, rsi_14, created_at)
VALUES ($stock_id, $date, $rsi_14, CURRENT_TIMESTAMP)
ON CONFLICT (stock_id, date)
DO UPDATE SET
  rsi_14 = EXCLUDED.rsi_14,
  created_at = CURRENT_TIMESTAMP
RETURNING stock_id, date, rsi_14;
```

**Colonnes disponibles dans la table:**
- `rsi_14` - RSI sur 14 périodes
- `macd`, `macd_signal`, `macd_histogram` - MACD
- `sma_20`, `sma_50`, `sma_200` - Moyennes mobiles simples
- `ema_20` - Moyenne mobile exponentielle
- `bb_upper`, `bb_middle`, `bb_lower` - Bandes de Bollinger
- `volume_sma_20` - Volume moyen
- `atr_14` - Average True Range

## ⚙️ Configuration du Workflow

### Horaire d'Exécution

- **Trigger**: Cron `0 19 * * 1-5`
- **Fréquence**: Tous les jours de semaine à 19h
- **Après**: Le workflow 01 (prix de marché à 18h)

### Rate Limiting

```json
{
  "batchSize": 1,
  "batchInterval": 12000,
  "timeout": 15000
}
```

- **batchSize**: 1 requête à la fois
- **batchInterval**: 12 secondes entre chaque (= 5 requêtes/minute max)
- **timeout**: 15 secondes par requête

### Gestion d'Erreurs

Le workflow gère automatiquement:
- ✅ Rate limit API dépassé
- ✅ Timeout de requête
- ✅ Données manquantes
- ✅ Erreurs de parsing

Les erreurs sont loguées dans `system_logs`.

## 🧪 Tests

### Test Manuel

1. **Importer le workflow** dans n8n
2. **Configurer l'API key** Alpha Vantage dans `.env`
3. **Tester avec 1-2 actions**:
   - Désactiver le trigger
   - Modifier la requête SQL pour limiter: `LIMIT 2`
   - Exécuter manuellement

### Vérifier les Résultats

```sql
-- Voir les indicateurs collectés
SELECT
    s.ticker,
    ti.date,
    ti.rsi_14,
    ti.created_at
FROM technical_indicators ti
JOIN stocks s ON s.id = ti.stock_id
ORDER BY ti.date DESC, s.ticker
LIMIT 10;
```

### Vérifier les Logs

```sql
-- Voir les logs du workflow
SELECT
    level,
    message,
    details,
    created_at
FROM system_logs
WHERE workflow_name = 'technical-indicators-collector'
ORDER BY created_at DESC
LIMIT 20;
```

## 🔄 Évolutions Futures

### Autres Indicateurs à Ajouter

Ce workflow collecte uniquement le **RSI**. Pour ajouter d'autres indicateurs:

1. **MACD**: Endpoint `function=MACD`
2. **SMA**: Endpoint `function=SMA`
3. **EMA**: Endpoint `function=EMA`
4. **BBANDS**: Endpoint `function=BBANDS`
5. **ATR**: Endpoint `function=ATR`

Voir `/docs/alpha-vantage-indicators.md` pour les détails d'implémentation.

### Optimisations

- **Calcul local des SMA/EMA**: Calculer à partir des prix stockés au lieu d'appeler l'API
- **Cache**: Stocker les indicateurs pour réduire les appels API
- **Batch processing**: Grouper plusieurs indicateurs en une seule exécution

## ⚠️ Points d'Attention

### Rate Limiting

Avec 50 actions et 5 calls/minute:
- **Temps total**: ~10 minutes
- **Appels quotidiens**: 50 (bien en dessous de la limite de 500)

### Disponibilité des Données

Alpha Vantage peut ne pas avoir de données pour tous les tickers:
- Vérifier que le ticker est au bon format (ex: `IBM` pas `IBM.PA`)
- Pour les actions européennes, utiliser le format Alpha Vantage

### Coût

- **Version gratuite**: Suffisante pour ce workflow
- **Version premium** ($50/mois): Si besoin de plus d'indicateurs ou fréquence plus élevée

## 📚 Ressources

- [Alpha Vantage Documentation](https://www.alphavantage.co/documentation/)
- [RSI API](https://www.alphavantage.co/documentation/#rsi)
- [Technical Indicators List](https://www.alphavantage.co/documentation/#technical-indicators)

---

**Date de création**: 3 janvier 2026
**Version**: 1.0
**Statut**: ✅ Prêt pour tests
