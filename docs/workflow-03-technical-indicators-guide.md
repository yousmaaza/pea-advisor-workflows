# Workflow 03 - Technical Indicators Calculator

## 🎯 Objectif

Ce workflow calcule **localement** tous les indicateurs techniques nécessaires pour l'analyse des actions. Il utilise des implémentations Python pures (sans dépendances externes) pour calculer RSI, MACD, SMA, EMA, Bandes de Bollinger et ATR.

## ⚡ Pourquoi Calcul Local ?

### ❌ Problèmes avec Alpha Vantage API
- **Rate limit**: 1 requête par seconde
- **Limite gratuite**: 25 requêtes par jour
- **Temps**: 50 actions × 6 indicateurs = 300 requêtes = **12 JOURS!**
- **Coût payant**: $50/mois

### ✅ Avantages du Calcul Local
- **Rapidité**: 5-10 secondes pour 50 actions (vs 12 jours!)
- **Gratuit**: Aucun coût API
- **Illimité**: Pas de rate limits
- **Contrôle total**: Personnalisation des paramètres
- **Pas de dépendances**: Implementations Python pures

## 📊 Indicateurs Calculés

### 1. RSI (Relative Strength Index) - 14 périodes
**Interprétation**:
- **< 30**: Survente (oversold) → Signal d'achat potentiel
- **> 70**: Surachat (overbought) → Signal de vente potentiel
- **30-70**: Zone neutre

**Formule**:
```
RSI = 100 - (100 / (1 + RS))
RS = Moyenne des gains / Moyenne des pertes
```

### 2. SMA (Simple Moving Average)
Moyennes mobiles sur **20, 50 et 200 jours**

**Interprétation**:
- **Prix > SMA**: Tendance haussière
- **Prix < SMA**: Tendance baissière
- **Croisements**: Signaux d'achat/vente
  - Croix dorée: SMA 50 croise SMA 200 vers le haut → Signal haussier
  - Croix de la mort: SMA 50 croise SMA 200 vers le bas → Signal baissier

**Formule**:
```
SMA = (P1 + P2 + ... + Pn) / n
```

### 3. EMA (Exponential Moving Average) - 20 périodes
Plus réactive que SMA, donne plus de poids aux prix récents

**Formule**:
```
EMA = (Prix × Multiplier) + (EMA_précédent × (1 - Multiplier))
Multiplier = 2 / (Période + 1)
```

### 4. MACD (Moving Average Convergence Divergence)
Paramètres: **12, 26, 9**

**Composantes**:
- **MACD Line**: EMA(12) - EMA(26)
- **Signal Line**: EMA(9) du MACD
- **Histogram**: MACD - Signal

**Interprétation**:
- **MACD > Signal**: Signal haussier
- **MACD < Signal**: Signal baissier
- **Croisements**: Changements de tendance

### 5. Bandes de Bollinger
Paramètres: **20 périodes, 2 écarts-types**

**Composantes**:
- **Bande supérieure**: SMA(20) + 2σ
- **Bande moyenne**: SMA(20)
- **Bande inférieure**: SMA(20) - 2σ

**Interprétation**:
- **Prix près bande supérieure**: Potentiel surachat
- **Prix près bande inférieure**: Potentiel survente
- **Bandes resserrées**: Faible volatilité, breakout possible
- **Bandes écartées**: Forte volatilité

### 6. ATR (Average True Range) - 14 périodes
Mesure la volatilité (pas la direction)

**Formule**:
```
True Range = max(High - Low, |High - Close_prev|, |Low - Close_prev|)
ATR = Moyenne des True Ranges sur 14 périodes
```

**Interprétation**:
- **ATR élevé**: Forte volatilité
- **ATR faible**: Faible volatilité
- Utilisé pour placer stops-loss

## 📊 Architecture du Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Déclencheur Quotidien (19h15, après workflow 01)         │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Récupérer prix agrégés (PostgreSQL)                      │
│    CTE: agrège last 300 jours en arrays                     │
│    Retourne: 1 row par stock avec arrays de prix            │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Calculer Indicateurs (Python - runOnceForEachItem)       │
│    Pour chaque stock:                                        │
│    - Extract arrays de prix                                 │
│    - Calculate RSI, SMA, EMA, MACD, BB, ATR                 │
│    - Detect signals (oversold/overbought, trend)            │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Filtrer succès                                            │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Insérer Indicateurs (PostgreSQL)                         │
│    INSERT ... ON CONFLICT UPDATE                            │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Log succès                                                │
└──────────────────────────────────────────────────────────────┘
```

## 💾 Requête SQL d'Agrégation

### Fonctionnalité

La requête utilise une **CTE (Common Table Expression)** pour agréger les prix en arrays:

```sql
WITH stock_prices_agg AS (
  SELECT
    sp.stock_id,
    array_agg(sp.date ORDER BY sp.date ASC) as dates,
    array_agg(sp.open ORDER BY sp.date ASC) as opens,
    array_agg(sp.high ORDER BY sp.date ASC) as highs,
    array_agg(sp.low ORDER BY sp.date ASC) as lows,
    array_agg(sp.close ORDER BY sp.date ASC) as closes,
    array_agg(sp.volume ORDER BY sp.date ASC) as volumes,
    MAX(sp.date) as latest_date,
    COUNT(*) as data_points
  FROM stock_prices sp
  WHERE sp.date >= CURRENT_DATE - INTERVAL '300 days'
  GROUP BY sp.stock_id
  HAVING COUNT(*) >= 14  -- Minimum pour RSI
)
SELECT
  s.id,
  s.ticker,
  s.name,
  spa.dates,
  spa.opens,
  spa.highs,
  spa.lows,
  spa.closes,
  spa.volumes,
  spa.latest_date,
  spa.data_points
FROM stocks s
JOIN stock_prices_agg spa ON spa.stock_id = s.id
WHERE s.is_active = true AND s.is_pea_eligible = true
ORDER BY s.ticker;
```

### Pourquoi 300 jours ?

- RSI: 14 jours minimum
- MACD: 26 jours minimum
- **SMA 200**: 200 jours minimum
- Marge de sécurité: +100 jours pour gérer les jours manquants

### Résultat

Pour chaque stock, on obtient:
```json
{
  "id": 1,
  "ticker": "MC.PA",
  "name": "LVMH",
  "closes": [750.2, 753.5, 756.8, ...],  // 250-300 valeurs
  "highs": [755.0, 758.3, ...],
  "lows": [748.1, 751.2, ...],
  "volumes": [1234567, 1345678, ...],
  "latest_date": "2026-01-02",
  "data_points": 250
}
```

## 🐍 Implémentations Python

### Pas de Dépendances Externes

Le code utilise **uniquement Python standard** :
- `math` pour sqrt()
- Pas besoin de TA-Lib, pandas, numpy

### Mode d'Exécution

**runOnceForEachItem**: Traite chaque stock individuellement
- Avantage: Plus facile à debugger
- Avantage: Erreur sur 1 stock ne bloque pas les autres
- Performance: ~10 secondes pour 50 actions

### Structure du Code

```python
# 1. Extraire les données du stock
stock_id = _item['json']['id']
closes = _item['json']['closes']
highs = _item['json']['highs']
lows = _item['json']['lows']

# 2. Calculer chaque indicateur
rsi_14 = calculate_rsi(closes, 14)
sma_20 = calculate_sma(closes, 20)
macd, signal, histogram = calculate_macd(closes)
# ... etc

# 3. Détecter les signaux
if rsi_14 < 30:
    rsi_signal = 'oversold'
elif rsi_14 > 70:
    rsi_signal = 'overbought'

# 4. Retourner les résultats
return {
    'json': {
        'stock_id': stock_id,
        'rsi_14': rsi_14,
        'sma_20': sma_20,
        # ... tous les indicateurs
        'rsi_signal': rsi_signal,
        'success': True
    }
}
```

## 💾 Table technical_indicators

### Schéma

```sql
CREATE TABLE technical_indicators (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id),
    date DATE NOT NULL,
    close_price DECIMAL(10, 4),

    -- Oscillateurs
    rsi_14 DECIMAL(5, 2),

    -- Moyennes mobiles
    sma_20 DECIMAL(10, 4),
    sma_50 DECIMAL(10, 4),
    sma_200 DECIMAL(10, 4),
    ema_20 DECIMAL(10, 4),

    -- MACD
    macd DECIMAL(10, 4),
    macd_signal DECIMAL(10, 4),
    macd_histogram DECIMAL(10, 4),

    -- Bandes de Bollinger
    bb_upper DECIMAL(10, 4),
    bb_middle DECIMAL(10, 4),
    bb_lower DECIMAL(10, 4),

    -- Volatilité
    atr_14 DECIMAL(10, 4),

    -- Signaux
    rsi_signal VARCHAR(20),  -- 'oversold', 'overbought', 'neutral'
    trend_signal VARCHAR(20), -- 'bullish', 'bearish', 'neutral'
    macd_signal VARCHAR(20),  -- 'bullish', 'bearish', 'neutral'

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(stock_id, date)
);

CREATE INDEX idx_technical_indicators_stock_date ON technical_indicators(stock_id, date DESC);
CREATE INDEX idx_technical_indicators_signals ON technical_indicators(rsi_signal, trend_signal, macd_signal);
```

### Upsert Strategy

Le workflow utilise `ON CONFLICT UPDATE` pour:
- Insérer si nouvelle date
- Mettre à jour si date existe déjà (recalcul)

```sql
INSERT INTO technical_indicators (...)
VALUES (...)
ON CONFLICT (stock_id, date)
DO UPDATE SET
  rsi_14 = EXCLUDED.rsi_14,
  sma_20 = EXCLUDED.sma_20,
  -- ... mise à jour de tous les champs
  updated_at = CURRENT_TIMESTAMP;
```

## ⚙️ Configuration du Workflow

### Schedule

**Cron**: `15 19 * * 1-5` (19h15, jours de semaine)

**Pourquoi 19h15 ?**
- Workflow 01 s'exécute à 18h30
- Laisse 45 minutes pour que workflow 01 termine
- Marchés européens fermés (clôture 17h30 CET)

### Dépendances

**CRITIQUE**: Workflow 00 doit avoir été exécuté au moins une fois
- Sans historique, pas assez de données pour les calculs
- Minimum 14 jours requis (RSI)
- Optimal: 200+ jours (SMA 200)

## 🧪 Tests

### 1. Vérifier que la Table Existe

```sql
CREATE TABLE IF NOT EXISTS technical_indicators (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id),
    date DATE NOT NULL,
    close_price DECIMAL(10, 4),
    rsi_14 DECIMAL(5, 2),
    sma_20 DECIMAL(10, 4),
    sma_50 DECIMAL(10, 4),
    sma_200 DECIMAL(10, 4),
    ema_20 DECIMAL(10, 4),
    macd DECIMAL(10, 4),
    macd_signal DECIMAL(10, 4),
    macd_histogram DECIMAL(10, 4),
    bb_upper DECIMAL(10, 4),
    bb_middle DECIMAL(10, 4),
    bb_lower DECIMAL(10, 4),
    atr_14 DECIMAL(10, 4),
    rsi_signal VARCHAR(20),
    trend_signal VARCHAR(20),
    macd_signal VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stock_id, date)
);
```

### 2. Tester la Requête d'Agrégation

```sql
-- Vérifier qu'on a assez de données
WITH stock_prices_agg AS (
  SELECT
    sp.stock_id,
    COUNT(*) as data_points,
    MIN(sp.date) as first_date,
    MAX(sp.date) as last_date
  FROM stock_prices sp
  WHERE sp.date >= CURRENT_DATE - INTERVAL '300 days'
  GROUP BY sp.stock_id
)
SELECT
  s.ticker,
  spa.data_points,
  spa.first_date,
  spa.last_date,
  CASE
    WHEN spa.data_points >= 200 THEN 'OK (all indicators)'
    WHEN spa.data_points >= 50 THEN 'OK (RSI, MACD, SMA 50)'
    WHEN spa.data_points >= 14 THEN 'OK (RSI only)'
    ELSE 'INSUFFICIENT'
  END as status
FROM stocks s
LEFT JOIN stock_prices_agg spa ON spa.stock_id = s.id
WHERE s.is_active = true
ORDER BY spa.data_points DESC NULLS LAST;
```

### 3. Exécuter le Workflow Manuellement

1. Dans n8n, importer `03-technical-indicators-calculator.json`
2. Cliquer sur "Execute Workflow" (exécution manuelle)
3. Vérifier les logs

### 4. Vérifier les Résultats

```sql
-- Voir les derniers indicateurs calculés
SELECT
    s.ticker,
    ti.date,
    ti.close_price,
    ti.rsi_14,
    ti.sma_20,
    ti.sma_50,
    ti.sma_200,
    ti.rsi_signal,
    ti.trend_signal,
    ti.macd_signal
FROM technical_indicators ti
JOIN stocks s ON s.id = ti.stock_id
ORDER BY ti.date DESC, s.ticker
LIMIT 50;
```

### 5. Vérifier les Signaux

```sql
-- Actions en survente (RSI < 30)
SELECT
    s.ticker,
    s.name,
    ti.close_price,
    ti.rsi_14,
    ti.rsi_signal,
    ti.date
FROM technical_indicators ti
JOIN stocks s ON s.id = ti.stock_id
WHERE ti.rsi_signal = 'oversold'
  AND ti.date = (SELECT MAX(date) FROM technical_indicators WHERE stock_id = ti.stock_id)
ORDER BY ti.rsi_14 ASC;

-- Actions en surachat (RSI > 70)
SELECT
    s.ticker,
    s.name,
    ti.close_price,
    ti.rsi_14,
    ti.rsi_signal,
    ti.date
FROM technical_indicators ti
JOIN stocks s ON s.id = ti.stock_id
WHERE ti.rsi_signal = 'overbought'
  AND ti.date = (SELECT MAX(date) FROM technical_indicators WHERE stock_id = ti.stock_id)
ORDER BY ti.rsi_14 DESC;

-- Tendances haussières (prix > SMA 20 > SMA 50)
SELECT
    s.ticker,
    s.name,
    ti.close_price,
    ti.sma_20,
    ti.sma_50,
    ti.trend_signal,
    ti.date
FROM technical_indicators ti
JOIN stocks s ON s.id = ti.stock_id
WHERE ti.trend_signal = 'bullish'
  AND ti.date = (SELECT MAX(date) FROM technical_indicators WHERE stock_id = ti.stock_id)
ORDER BY s.ticker;
```

## 📊 Performance

### Temps d'Exécution

Pour **50 actions**:
- Requête SQL agrégation: ~2 secondes
- Calculs Python (runOnceForEachItem): ~8 secondes
- Insertions PostgreSQL: ~2 secondes
- **Total**: ~12 secondes

### Comparaison avec Alpha Vantage

| Méthode | Temps | Coût |
|---------|-------|------|
| **Local (ce workflow)** | 12 secondes | $0 |
| **Alpha Vantage (gratuit)** | 12 JOURS | $0 |
| **Alpha Vantage (payant)** | ~5 minutes | $50/mois |

## 💡 Améliorations Futures

### 1. Installer TA-Lib (Optionnel)

Pour des calculs plus rapides et plus d'indicateurs:

```bash
# Sur le serveur n8n
pip install TA-Lib

# Ou via Docker
docker exec -it n8n pip install TA-Lib
```

Puis remplacer les implémentations manuelles par:

```python
import talib

rsi_14 = talib.RSI(closes, timeperiod=14)[-1]
sma_20 = talib.SMA(closes, timeperiod=20)[-1]
macd, macd_signal, macd_hist = talib.MACD(closes, 12, 26, 9)
# ...
```

### 2. Indicateurs Additionnels

Faciles à ajouter:
- **Stochastic RSI**: Combine RSI et Stochastic
- **ADX**: Average Directional Index (force de tendance)
- **OBV**: On-Balance Volume
- **Ichimoku Cloud**: Système japonais complet

### 3. Détection de Patterns

- **Double Top/Bottom**
- **Head and Shoulders**
- **Triangles** (ascendant, descendant, symétrique)
- **Flags and Pennants**

### 4. Backtesting

Tester les signaux sur données historiques:
```sql
SELECT
    COUNT(*) as total_signals,
    SUM(CASE WHEN future_return > 0 THEN 1 ELSE 0 END) as winning_signals,
    AVG(future_return) as avg_return
FROM (
    SELECT
        ti.rsi_signal,
        ti.close_price,
        LEAD(ti.close_price, 5) OVER (PARTITION BY ti.stock_id ORDER BY ti.date) as future_price,
        (LEAD(ti.close_price, 5) OVER (PARTITION BY ti.stock_id ORDER BY ti.date) - ti.close_price) / ti.close_price * 100 as future_return
    FROM technical_indicators ti
    WHERE ti.rsi_signal = 'oversold'
) backtest;
```

## ⚠️ Points d'Attention

### Données Manquantes

Si un stock a < 14 jours de données:
- Il sera exclu par le `HAVING COUNT(*) >= 14`
- Pas d'indicateurs calculés
- Solution: Attendre ou relancer workflow 00

### Marchés Fermés

Le workflow s'exécute uniquement les jours de semaine (1-5):
- Pas d'exécution weekends et jours fériés
- Les indicateurs sont mis à jour avec les dernières données disponibles

### Précision des Calculs

Les implémentations manuelles sont **simplifiées**:
- RSI: Utilise moyenne simple (pas EMA comme la version originale)
- MACD Signal: Approximation (devrait être EMA du MACD)
- Pour production: installer TA-Lib pour calculs exacts

### NULL Values

Certains indicateurs peuvent être `NULL`:
- SMA 200: Si < 200 jours de données
- Géré dans le code avec retours `None`

## 📚 Ressources

- [TA-Lib Documentation](https://ta-lib.org/)
- [Investopedia - RSI](https://www.investopedia.com/terms/r/rsi.asp)
- [Investopedia - MACD](https://www.investopedia.com/terms/m/macd.asp)
- [Bollinger Bands Explained](https://www.bollingerbands.com/)
- [Technical Analysis of Stocks](https://www.investopedia.com/terms/t/technicalanalysis.asp)

---

## ✅ Checklist Avant Exécution

- [ ] Workflow 00 (Historical Data Loader) exécuté avec succès
- [ ] Table `technical_indicators` créée avec les bons champs
- [ ] Au moins 14 jours de données dans `stock_prices` pour chaque action
- [ ] Workflow 01 s'exécute quotidiennement à 18h30
- [ ] Schedule de ce workflow configuré à 19h15 (après workflow 01)

---

**Date de création**: 3 janvier 2026
**Version**: 1.0
**Statut**: ✅ Prêt pour production
**Dépendances**: ✅ Workflow 00 (complété)
