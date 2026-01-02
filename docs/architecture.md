# 🏗️ Architecture du Système - Conseiller PEA

## Vue d'ensemble

Le Conseiller Intelligent PEA est un système automatisé composé de plusieurs modules interconnectés qui collectent, analysent et génèrent des recommandations d'investissement pour votre Plan d'Épargne en Actions.

## 🎯 Schéma d'architecture global

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SOURCES DE DONNÉES                          │
├─────────────────────────────────────────────────────────────────────┤
│  Yahoo Finance  │  Alpha Vantage  │  NewsAPI  │  FMP  │  Autres... │
└────────┬─────────────────────┬─────────────────────┬────────────────┘
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      COUCHE DE COLLECTE (n8n)                       │
├─────────────────────────────────────────────────────────────────────┤
│  • Workflows de collecte programmés (cron)                          │
│  • Gestion des erreurs et retry                                     │
│  • Normalisation des données                                        │
│  • Rate limiting et cache                                           │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BASE DE DONNÉES (PostgreSQL)                   │
├─────────────────────────────────────────────────────────────────────┤
│  Tables principales :                                               │
│  • stocks - Référentiel des actions                                 │
│  • stock_prices - Historique des cours                              │
│  • stock_fundamentals - Données fondamentales                       │
│  • technical_indicators - Indicateurs calculés                      │
│  • news - Actualités et sentiment                                   │
│  • portfolio - Positions actuelles                                  │
│  • trading_signals - Signaux générés                                │
│  • ai_recommendations - Recommandations IA                          │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      COUCHE D'ANALYSE (n8n)                         │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │  ANALYSE         │  │  ANALYSE         │  │  ANALYSE IA     │  │
│  │  TECHNIQUE       │  │  FONDAMENTALE    │  │                 │  │
│  ├──────────────────┤  ├──────────────────┤  ├─────────────────┤  │
│  │ • RSI            │  │ • P/E, P/B       │  │ • Sentiment     │  │
│  │ • MACD           │  │ • ROE, ROA       │  │ • Résumés       │  │
│  │ • SMA/EMA        │  │ • Croissance     │  │ • Insights      │  │
│  │ • Bollinger      │  │ • Dividendes     │  │ • Scoring       │  │
│  │ • Patterns       │  │ • Dette          │  │                 │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    MOTEUR DE RECOMMANDATIONS                        │
├─────────────────────────────────────────────────────────────────────┤
│  • Agrégation des scores (technique, fondamental, IA)              │
│  • Calcul du score global (0-100)                                   │
│  • Génération des signaux (buy/sell/hold)                           │
│  • Définition des prix cibles et stops                              │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  GESTION DE PORTEFEUILLE & RISQUES                  │
├─────────────────────────────────────────────────────────────────────┤
│  • Analyse des positions actuelles                                  │
│  • Calcul de la performance                                         │
│  • Optimisation de l'allocation                                     │
│  • Monitoring de la volatilité (VaR)                                │
│  • Gestion des stops-loss                                           │
│  • Alertes en temps réel                                            │
└────────┬────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RAPPORTS & NOTIFICATIONS                         │
├─────────────────────────────────────────────────────────────────────┤
│  • Rapports quotidiens (email/Telegram)                             │
│  • Rapports hebdomadaires détaillés                                 │
│  • Alertes instantanées                                             │
│  • Dashboard web (optionnel)                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔧 Stack Technique

### Infrastructure
- **n8n** : Orchestration des workflows
- **PostgreSQL** : Base de données principale
- **Qdrant** : Base vectorielle pour RAG (optionnel)
- **Docker** : Conteneurisation

### APIs et Services
- **Yahoo Finance** : Prix de marché (gratuit)
- **Alpha Vantage** : Indicateurs techniques
- **Financial Modeling Prep** : Données fondamentales
- **NewsAPI** : Actualités financières
- **OpenAI/Claude** : Intelligence artificielle
- **Telegram Bot** : Notifications instantanées

### Langages et outils
- **SQL** : Requêtes et schéma de base de données
- **JavaScript/Python** : Scripts personnalisés dans n8n
- **JSON** : Configuration et échange de données

## 📊 Flux de données détaillé

### 1. Collecte de données (quotidien 18h)

```
┌──────────────────┐
│ Yahoo Finance    │
│ API Call         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐      ┌──────────────────┐
│ Normalisation    │──────>│ PostgreSQL       │
│ & Validation     │      │ stock_prices     │
└──────────────────┘      └──────────────────┘
```

### 2. Analyse technique (quotidien 19h)

```
┌──────────────────┐
│ PostgreSQL       │
│ stock_prices     │
│ (derniers 200j)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Calcul RSI       │
│ Calcul MACD      │
│ Calcul SMA       │
│ Calcul Bollinger │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐      ┌──────────────────┐
│ Détection        │──────>│ PostgreSQL       │
│ Patterns         │      │ technical_indic. │
└──────────────────┘      └──────────────────┘
```

### 3. Analyse IA (toutes les 4h)

```
┌──────────────────┐
│ NewsAPI          │
│ Récup actualités │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ OpenAI/Claude    │
│ Analyse          │
│ Sentiment        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ PostgreSQL       │
│ news table       │
│ + sentiment      │
└──────────────────┘
```

### 4. Génération de recommandations (quotidien 20h)

```
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ Scores           │   │ Scores           │   │ Scores           │
│ Techniques       │   │ Fondamentaux     │   │ IA/Sentiment     │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │ Agrégation           │
                    │ Score global (0-100) │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Signal               │
                    │ buy/sell/hold        │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ PostgreSQL           │
                    │ trading_signals      │
                    └──────────────────────┘
```

## 🧮 Algorithmes de scoring

### Score Technique (0-100)

```javascript
technical_score = (
  rsi_score * 0.25 +
  macd_score * 0.25 +
  trend_score * 0.30 +
  volume_score * 0.20
)

// Exemples de calculs :
// - RSI < 30 : achat (score 80-100)
// - RSI 30-70 : neutre (score 40-60)
// - RSI > 70 : vente (score 0-20)
// - MACD croix haussière : +20 points
// - Prix > SMA200 : tendance haussière +30 points
```

### Score Fondamental (0-100)

```javascript
fundamental_score = (
  valuation_score * 0.30 +    // P/E, P/B vs secteur
  quality_score * 0.30 +      // ROE, marges, dette
  growth_score * 0.25 +       // Croissance CA/BNA
  dividend_score * 0.15       // Rendement dividende
)
```

### Score IA/Sentiment (0-100)

```javascript
ai_score = (
  news_sentiment * 0.40 +     // Sentiment actualités (-10 à +10)
  ai_confidence * 0.30 +      // Confiance du modèle IA
  impact_score * 0.30         // Impact estimé sur cours
)
```

### Score Global

```javascript
overall_score = (
  technical_score * 0.35 +
  fundamental_score * 0.35 +
  ai_score * 0.30
)

// Classification :
// 80-100 : Strong Buy
// 60-79  : Buy
// 40-59  : Hold
// 20-39  : Sell
// 0-19   : Strong Sell
```

## 🔐 Sécurité et conformité

### Sécurité des données
- **Chiffrement** : API keys stockées dans variables d'environnement
- **Authentification** : Webhooks protégés par token
- **Logs** : Traçabilité complète dans `system_logs`
- **Backups** : Quotidiens automatisés

### Conformité PEA
- **Vérification éligibilité** : Uniquement actions UE/EEE
- **Limite de versement** : Tracking du plafond 150k€
- **Fiscalité** : Calcul automatique des prélèvements sociaux

## 📈 Scalabilité

### Optimisations possibles

1. **Cache Redis** : Réduire appels API
2. **Queue système** : RabbitMQ pour traitement asynchrone
3. **Parallélisation** : Analyse multi-actions simultanée
4. **Indexation** : Optimisation requêtes PostgreSQL
5. **CDN** : Pour le dashboard web

### Limites actuelles

- **Actions suivies** : ~50 actions (limites API gratuites)
- **Fréquence** : Quotidien (pas de données tick-by-tick)
- **Latence** : Délais de 5-30 min entre collecte et recommandation

## 🔄 Gestion des erreurs

### Stratégies de retry

```javascript
// Configuration n8n
max_retries: 3
retry_delay: [5min, 15min, 1h]
timeout: 30s

// Cas particuliers :
// - API rate limit : Attendre reset
// - Timeout : Réessayer avec timeout plus long
// - 500 error : Retry avec backoff exponentiel
```

### Monitoring

- **Healthcheck** : Endpoint /health pour chaque workflow
- **Alertes** : Notification si workflow échoue 3x
- **Métriques** : Temps d'exécution, taux de succès

## 🚀 Évolutions futures

### Phase 1 (court terme)
- [ ] Machine Learning pour prédiction de tendances
- [ ] Backtesting automatisé des stratégies
- [ ] Interface web interactive

### Phase 2 (moyen terme)
- [ ] Trading automatisé (via API broker)
- [ ] Analyse de corrélation avancée
- [ ] Chatbot conversationnel

### Phase 3 (long terme)
- [ ] Deep Learning pour patterns complexes
- [ ] Analyse de sentiment Twitter/Reddit
- [ ] Application mobile native

---

**Version** : 1.0
**Dernière mise à jour** : 2 janvier 2026
