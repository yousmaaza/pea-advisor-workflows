# 📊 Workflow 04 : Fundamental Data Collector

## 🎯 Vue d'ensemble

Le **Workflow 04: Fundamental Data Collector** collecte les données fondamentales des entreprises pour évaluer leur santé financière et leur valorisation. Ces données complètent l'analyse technique (workflows 00, 01, 03) pour avoir une vision complète de chaque action.

## 📋 Objectifs

1. **Collecter les ratios de valorisation** (P/E, P/B, P/S, PEG)
2. **Évaluer la rentabilité** (ROE, ROA, marge)
3. **Analyser les dividendes** (rendement, payout ratio)
4. **Mesurer la croissance** (CA, bénéfices)
5. **Évaluer la santé financière** (dette, liquidité)
6. **Obtenir les recommandations** (analystes)

---

## 🏗️ Architecture du Workflow

### Schéma de flux

```
Trigger Hebdomadaire (Dimanche 10h)
    ↓
Récupérer actions (PostgreSQL)
    ↓
    ├──→ Yahoo Finance API (quoteSummary)
    └──→ Merge ←──┘
         ↓
    Parser Python (extraction des ratios)
         ↓
    Filtrer succès
         ↓
    Insérer en BDD (stock_fundamentals)
         ↓
    Log succès
```

### Nodes du workflow

1. **Schedule Trigger** - Déclenchement hebdomadaire (dimanche 10h)
2. **PostgreSQL** - Récupération des actions éligibles PEA
3. **HTTP Request** - Appel Yahoo Finance API (quoteSummary)
4. **Merge** - Combinaison données PostgreSQL + Yahoo Finance
5. **Code (Python)** - Parsing et extraction des ratios
6. **Filter** - Filtrage des succès
7. **PostgreSQL** - Insertion dans stock_fundamentals
8. **PostgreSQL** - Logging

---

## 📡 API Yahoo Finance - quoteSummary

### Endpoint utilisé

```
https://query1.finance.yahoo.com/v10/finance/quoteSummary/{TICKER}?modules=defaultKeyStatistics,financialData,summaryDetail
```

### Modules demandés

- **defaultKeyStatistics**: P/B, PEG, beta
- **financialData**: ROE, ROA, marges, dette, croissance
- **summaryDetail**: P/E, P/S, dividendes

### Exemple de réponse

```json
{
  "quoteSummary": {
    "result": [
      {
        "defaultKeyStatistics": {
          "priceToBook": {"raw": 8.5},
          "pegRatio": {"raw": 1.2},
          "beta": {"raw": 1.15}
        },
        "financialData": {
          "returnOnEquity": {"raw": 0.25},
          "returnOnAssets": {"raw": 0.12},
          "profitMargins": {"raw": 0.15},
          "revenueGrowth": {"raw": 0.08},
          "earningsGrowth": {"raw": 0.10},
          "debtToEquity": {"raw": 45.5},
          "currentRatio": {"raw": 1.8},
          "recommendationKey": "buy"
        },
        "summaryDetail": {
          "trailingPE": {"raw": 18.5},
          "priceToSalesTrailing12Months": {"raw": 2.3},
          "dividendYield": {"raw": 0.025},
          "dividendRate": {"raw": 4.5},
          "payoutRatio": {"raw": 0.45}
        }
      }
    ]
  }
}
```

---

## 🐍 Code Python - Extraction des données

### Logique principale

```python
from datetime import datetime
from zoneinfo import ZoneInfo

# Récupérer les données combinées
merged_data = _item['json']

# Extraire les modules Yahoo Finance
result = yahoo_response['quoteSummary']['result'][0]
default_stats = result.get('defaultKeyStatistics', {})
financial_data = result.get('financialData', {})
summary_detail = result.get('summaryDetail', {})

# Fonction helper pour extraire les valeurs
def get_value(data, default=None):
    if data and isinstance(data, dict) and 'raw' in data:
        return data['raw']
    return default

# Construire l'objet de données fondamentales
fundamentals = {
    'stock_id': stock_info['id'],
    'date': datetime.now(ZoneInfo('Europe/Paris')).strftime('%Y-%m-%d'),

    # Ratios de valorisation
    'pe_ratio': get_value(summary_detail.get('trailingPE')),
    'pb_ratio': get_value(default_stats.get('priceToBook')),
    'ps_ratio': get_value(summary_detail.get('priceToSalesTrailing12Months')),
    'peg_ratio': get_value(default_stats.get('pegRatio')),

    # Rentabilité
    'roe': get_value(financial_data.get('returnOnEquity')),
    'roa': get_value(financial_data.get('returnOnAssets')),
    'profit_margin': get_value(financial_data.get('profitMargins')),

    # Dividendes
    'dividend_yield': get_value(summary_detail.get('dividendYield')),
    'dividend_per_share': get_value(summary_detail.get('dividendRate')),
    'payout_ratio': get_value(summary_detail.get('payoutRatio')),

    # Croissance
    'revenue_growth': get_value(financial_data.get('revenueGrowth')),
    'earnings_growth': get_value(financial_data.get('earningsGrowth')),

    # Dette
    'debt_to_equity': get_value(financial_data.get('debtToEquity')),
    'current_ratio': get_value(financial_data.get('currentRatio')),

    # Autres
    'beta': get_value(default_stats.get('beta')),
    'analyst_rating': get_value(financial_data.get('recommendationKey'))
}

# Convertir les pourcentages (décimal → %)
percentage_fields = ['roe', 'roa', 'profit_margin', 'dividend_yield', 'revenue_growth', 'earnings_growth']
for field in percentage_fields:
    if fundamentals.get(field) is not None:
        fundamentals[field] = round(fundamentals[field] * 100, 2)
```

### Conversion des pourcentages

Yahoo Finance retourne certaines valeurs en décimal (0.15 = 15%). Le code les convertit automatiquement :

- **ROE** : 0.25 → 25%
- **ROA** : 0.12 → 12%
- **Profit Margin** : 0.15 → 15%
- **Dividend Yield** : 0.025 → 2.5%
- **Revenue Growth** : 0.08 → 8%
- **Earnings Growth** : 0.10 → 10%

---

## 🗄️ Table PostgreSQL - stock_fundamentals

### Schéma

```sql
CREATE TABLE stock_fundamentals (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Ratios de valorisation
    pe_ratio DECIMAL(10, 2),
    pb_ratio DECIMAL(10, 2),
    ps_ratio DECIMAL(10, 2),
    peg_ratio DECIMAL(10, 2),

    -- Rentabilité
    roe DECIMAL(10, 2),
    roa DECIMAL(10, 2),
    profit_margin DECIMAL(10, 2),

    -- Dividendes
    dividend_yield DECIMAL(10, 4),
    dividend_per_share DECIMAL(10, 4),
    payout_ratio DECIMAL(10, 2),

    -- Croissance
    revenue_growth DECIMAL(10, 2),
    earnings_growth DECIMAL(10, 2),

    -- Dette
    debt_to_equity DECIMAL(10, 2),
    current_ratio DECIMAL(10, 2),

    -- Autres
    beta DECIMAL(10, 4),
    analyst_rating VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stock_id, date)
);
```

### Insertion avec UPSERT

```sql
INSERT INTO stock_fundamentals (
  stock_id, date,
  pe_ratio, pb_ratio, ps_ratio, peg_ratio,
  roe, roa, profit_margin,
  dividend_yield, dividend_per_share, payout_ratio,
  revenue_growth, earnings_growth,
  debt_to_equity, current_ratio,
  beta, analyst_rating,
  created_at
)
VALUES (...)
ON CONFLICT (stock_id, date)
DO UPDATE SET
  pe_ratio = EXCLUDED.pe_ratio,
  pb_ratio = EXCLUDED.pb_ratio,
  ...
```

---

## ⏰ Planification

### Cron Expression

```
0 10 * * 0
```

- **Fréquence** : Hebdomadaire (dimanche)
- **Heure** : 10h00 (Europe/Paris)
- **Raison** : Les données fondamentales changent lentement (trimestriellement)

### Pourquoi hebdomadaire ?

Les données fondamentales (P/E, ROE, dividendes) sont mises à jour :
- **Trimestriellement** : Résultats financiers
- **Annuellement** : Rapports annuels
- **Mensuellement** : Recommandations analystes

Une collecte hebdomadaire est suffisante pour capturer les changements importants.

---

## 🔍 Données Collectées

### 1. Ratios de Valorisation

| Ratio | Description | Interprétation |
|-------|-------------|----------------|
| **P/E** | Price/Earnings | < 15 : Sous-évalué<br>> 25 : Surévalué |
| **P/B** | Price/Book | < 1 : Sous-évalué<br>> 3 : Surévalué |
| **P/S** | Price/Sales | < 1 : Bon<br>> 2 : Cher |
| **PEG** | P/E to Growth | < 1 : Sous-évalué<br>> 2 : Surévalué |

### 2. Rentabilité

| Ratio | Description | Bon niveau |
|-------|-------------|------------|
| **ROE** | Return on Equity | > 15% |
| **ROA** | Return on Assets | > 5% |
| **Profit Margin** | Marge nette | > 10% |

### 3. Dividendes

| Indicateur | Description | Bon niveau |
|------------|-------------|------------|
| **Dividend Yield** | Rendement | 2-5% |
| **Dividend Per Share** | Dividende par action | Croissant |
| **Payout Ratio** | % bénéfices distribués | 30-60% |

### 4. Croissance

| Indicateur | Description | Bon niveau |
|------------|-------------|------------|
| **Revenue Growth** | Croissance CA | > 5% |
| **Earnings Growth** | Croissance bénéfices | > 10% |

### 5. Dette

| Ratio | Description | Bon niveau |
|-------|-------------|------------|
| **Debt to Equity** | Dette / Capitaux propres | < 50% |
| **Current Ratio** | Liquidité | > 1.5 |

### 6. Autres

| Indicateur | Description |
|------------|-------------|
| **Beta** | Volatilité vs marché (1.0 = marché) |
| **Analyst Rating** | buy, hold, sell |

---

## 📊 Exemples de Données

### LVMH (MC.PA)

```json
{
  "stock_id": 1,
  "ticker": "MC.PA",
  "date": "2026-01-04",
  "pe_ratio": 28.5,
  "pb_ratio": 6.2,
  "ps_ratio": 4.8,
  "peg_ratio": 1.8,
  "roe": 24.5,
  "roa": 12.3,
  "profit_margin": 18.2,
  "dividend_yield": 1.8,
  "dividend_per_share": 12.0,
  "payout_ratio": 45.0,
  "revenue_growth": 8.5,
  "earnings_growth": 12.0,
  "debt_to_equity": 35.0,
  "current_ratio": 1.9,
  "beta": 1.15,
  "analyst_rating": "buy"
}
```

**Interprétation** :
- ✅ **Rentabilité excellente** : ROE 24.5%, marge 18.2%
- ✅ **Croissance solide** : CA +8.5%, bénéfices +12%
- ⚠️ **Valorisation élevée** : P/E 28.5, P/B 6.2 (luxe = valorisation premium)
- ✅ **Dividende stable** : 1.8%, payout 45%
- ✅ **Dette maîtrisée** : 35% debt/equity

---

## 🎯 Utilisation des Données

### Workflow 06: Fundamental Analysis

Les données du Workflow 04 servent à calculer des **scores fondamentaux** :

```python
# Score Value (valorisation)
value_score = calculate_value_score(pe_ratio, pb_ratio, ps_ratio, peg_ratio)

# Score Growth (croissance)
growth_score = calculate_growth_score(revenue_growth, earnings_growth)

# Score Quality (qualité)
quality_score = calculate_quality_score(roe, roa, profit_margin, debt_to_equity, current_ratio)

# Score Dividende
dividend_score = calculate_dividend_score(dividend_yield, payout_ratio)

# Score Global Fondamental (0-100)
fundamental_score = (
    value_score * 0.30 +
    quality_score * 0.30 +
    growth_score * 0.25 +
    dividend_score * 0.15
)
```

### Workflow 09: AI Recommendation Engine

L'IA combine **analyse technique** + **analyse fondamentale** :

```
Recommandation = f(
    Technical Score (35%),
    Fundamental Score (35%),
    AI News Sentiment (30%)
)
```

---

## 🔧 Configuration

### 1. Importer le workflow

Voir `/docs/import-workflow-guide.md`

### 2. Configurer les credentials PostgreSQL

ID: `1` - Nom: `PostgreSQL PEA Advisor`

### 3. Activer le workflow

Le workflow se déclenche automatiquement chaque dimanche à 10h.

### 4. Exécution manuelle

Pour tester immédiatement :
1. Ouvrir n8n
2. Sélectionner "04-fundamental-data-collector"
3. Cliquer "Execute Workflow"

---

## ⚙️ Gestion des erreurs

### Valeurs manquantes (NULL)

Certaines actions peuvent ne pas avoir toutes les données (ex: startups sans dividendes).

Le code Python utilise `|| 'NULL'` dans la requête SQL pour insérer `NULL` si la valeur n'existe pas.

```sql
{{ $json.dividend_yield || 'NULL' }}
```

### Rate Limiting

- **Batch Size** : 1 requête à la fois
- **Batch Interval** : 2 secondes entre chaque requête
- Pour 50 actions : ~2 minutes (raisonnable pour une exécution hebdomadaire)

### Timeout

- **Timeout** : 10 secondes par requête

---

## 📈 Performance

### Temps d'exécution

- **50 actions** : ~2-3 minutes
- **1 action** : ~2 secondes (rate limit)

### Volume de données

- **1 exécution** : 50 lignes (1 par action)
- **1 an** : ~2 600 lignes (52 semaines × 50 actions)
- **Taille** : ~200 KB/an (très léger)

---

## 🧪 Tests

### Requête de vérification

```sql
-- Vérifier les dernières données collectées
SELECT
    s.ticker,
    s.name,
    sf.date,
    sf.pe_ratio,
    sf.roe,
    sf.dividend_yield,
    sf.revenue_growth,
    sf.debt_to_equity,
    sf.analyst_rating
FROM stock_fundamentals sf
JOIN stocks s ON sf.stock_id = s.id
WHERE sf.date = CURRENT_DATE
ORDER BY s.ticker;
```

### Actions avec meilleur ROE

```sql
SELECT
    s.ticker,
    s.name,
    sf.roe,
    sf.profit_margin,
    sf.pe_ratio
FROM stock_fundamentals sf
JOIN stocks s ON sf.stock_id = s.id
WHERE sf.date = (SELECT MAX(date) FROM stock_fundamentals)
  AND sf.roe IS NOT NULL
ORDER BY sf.roe DESC
LIMIT 10;
```

### Actions sous-évaluées (P/E < 15)

```sql
SELECT
    s.ticker,
    s.name,
    sf.pe_ratio,
    sf.pb_ratio,
    sf.roe,
    sf.dividend_yield
FROM stock_fundamentals sf
JOIN stocks s ON sf.stock_id = s.id
WHERE sf.date = (SELECT MAX(date) FROM stock_fundamentals)
  AND sf.pe_ratio IS NOT NULL
  AND sf.pe_ratio < 15
ORDER BY sf.pe_ratio ASC;
```

---

## 🚨 Troubleshooting

### Problème : Pas de données pour certaines actions

**Cause** : Yahoo Finance n'a pas les données fondamentales pour cette action (petite capitalisation, ETF)

**Solution** : Normal, les valeurs seront NULL en BDD

### Problème : Valeurs aberrantes (P/E > 1000)

**Cause** : Entreprises en perte ou bénéfices très faibles

**Solution** : Filtrer dans les analyses ultérieures

### Problème : analyst_rating toujours NULL

**Cause** : Yahoo Finance ne fournit pas toujours cette donnée gratuitement

**Solution** : Utiliser une autre source (Financial Modeling Prep) ou ignorer

---

## 📚 Ressources

### Documentation

- **Yahoo Finance API** : Endpoint quoteSummary
- **Ratios financiers** : Investopedia
- **Analyse fondamentale** : /docs/architecture.md

### Workflows liés

- **Workflow 01** : Daily Market Data (prix)
- **Workflow 03** : Technical Indicators (analyse technique)
- **Workflow 06** : Fundamental Analysis (scores) - À venir
- **Workflow 09** : AI Recommendation Engine - À venir

---

## 📝 Notes importantes

### Différence avec Workflow 03

| Workflow | Type | Fréquence | Données |
|----------|------|-----------|---------|
| **03** | Technique | Quotidien | Prix, RSI, MACD, SMA |
| **04** | Fondamental | Hebdomadaire | P/E, ROE, Dividendes |

### Complémentarité

- **Workflow 03** → "Quand acheter ?" (timing)
- **Workflow 04** → "Quoi acheter ?" (qualité)

### Timezone

- **Europe/Paris** : Standardisé sur tous les workflows
- Voir `/docs/TIMEZONE_CONVENTION.md`

---

**Version** : 1.0
**Dernière mise à jour** : 4 janvier 2026
**Auteur** : PEA Advisor Team
**Statut** : ✅ Opérationnel
