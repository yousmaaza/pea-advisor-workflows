# Conseiller Intelligent PEA Boursorama

## Description du Projet

Système automatisé de recommandations d'investissement pour optimiser un Plan d'Épargne en Actions (PEA) sur Boursorama. Le système utilise n8n pour orchestrer la collecte de données financières, l'analyse technique et fondamentale, et génère des recommandations d'investissement basées sur l'IA.

## Stack Technique

- **n8n**: Orchestration des workflows
- **PostgreSQL**: Base de données principale pour stocker prix, indicateurs, signaux
- **APIs**: Yahoo Finance, Alpha Vantage, NewsAPI, Financial Modeling Prep, OpenAI/Claude
- **Langages**: SQL, JavaScript/Python (dans les nodes n8n), JSON

## Structure du Projet

### Dossiers principaux
- `workflows/`: Workflows n8n (JSON) organisés par catégorie
  - `data-collection/`: Collecte des données de marché
  - `analysis/`: Analyses techniques et fondamentales
  - `ai-engine/`: Moteur d'analyse IA
  - `portfolio-management/`: Gestion de portefeuille
  - `risk-management/`: Gestion des risques
  - `reporting/`: Rapports et notifications

- `database/`: Schémas PostgreSQL
  - `schema.sql`: Schéma complet de la base de données

- `config/`: Configuration
  - `.env`: Variables d'environnement (API keys - ne pas commiter)
  - `.env.example`: Template des variables
  - `stocks-watchlist.json`: Liste des actions suivies
  - `pea-eligible-stocks.json`: Actions éligibles PEA
  - `strategies.json`: Configuration des stratégies

- `docs/`: Documentation
  - `QUICKSTART.md`: Guide de démarrage rapide
  - `DATABASE_SETUP.md`: Setup PostgreSQL
  - `architecture.md`: Architecture détaillée
  - `workflow-01-guide.md`: Documentation du workflow principal

- `scripts/`: Scripts utilitaires
  - Scripts de test et validation

## Conventions et Règles

### Contraintes PEA
Le système doit TOUJOURS respecter les règles du PEA:
- Actions émises dans l'UE/EEE uniquement
- Minimum 75% en actions européennes
- Plafond de versement: 150 000€
- Vérifier `is_pea_eligible` dans la table `stocks`

### Base de Données PostgreSQL
- **Tables principales**: `stocks`, `stock_prices`, `stock_fundamentals`, `technical_indicators`, `news`, `portfolio`, `trading_signals`, `ai_recommendations`
- Utiliser les indexes existants pour les requêtes fréquentes
- Toujours inclure `stock_id` pour les jointures
- Les prix sont en DECIMAL(10, 2)
- Les dates sont en format DATE ou TIMESTAMP
- **Timezone**: Europe/Paris (CET/CEST) configuré dans PostgreSQL

### Workflows n8n
- Les workflows sont au format JSON
- Chaque node a un ID unique et des positions (x, y)
- Les credentials sont référencées par ID, jamais en dur
- Utiliser les variables d'environnement pour les API keys
- Implémenter retry logic avec backoff exponentiel
- **Langage Python avec Node Merge**: Architecture actuelle (v1.1+)
  - Utilise un node `Merge` pour combiner les données stocks + Yahoo Finance
  - ⚠️ **IMPORTANT**: Utiliser `_item` (avec underscore), pas `item`
  - Variables disponibles: `_item`, `_items`, `_input` (tous avec underscore)
  - Pas d'accès à `$itemIndex` ou `$node` en Python (d'où le besoin du Merge)
  - Mode: `runOnceForEachItem` avec `language: "python"`
  - Configuration Merge: `"mode": "combine"` et `"combinationMode": "mergeByPosition"`
  - Imports disponibles: `datetime`, `json`, etc.
  - **Guide variables Python**: `docs/python-variables-n8n.md` (_item vs item)
  - **Architecture détaillée**: `docs/python-workflow-architecture.md`
  - **Guide de migration**: `docs/python-migration-guide.md`

### Timezone Convention
- **Standard du projet**: Toujours utiliser `Europe/Paris` (CET/CEST)
- **Schedule Triggers**: Tous doivent inclure `"timezone": "Europe/Paris"`
- **Python datetime**: Utiliser `from zoneinfo import ZoneInfo` avec `ZoneInfo('Europe/Paris')`
- **Conversions timestamps**: Toujours spécifier `tz=ZoneInfo('Europe/Paris')`
- **Documentation complète**: `docs/TIMEZONE_CONVENTION.md`
- ⚠️ **NE PAS utiliser**: `datetime.now()` sans timezone, `pytz` (obsolète)

### API Usage
- **Yahoo Finance**: Prix de marché + historique (gratuit, illimité)
  - Endpoint daily: `/v8/finance/chart/{ticker}?interval=1d&range=1d`
  - Endpoint historical: `/v8/finance/chart/{ticker}?interval=1d&range=1y` (250 jours)
- **Alpha Vantage**: ❌ ABANDONNÉ (rate limits: 1 req/s, 25 req/jour)
  - Alternative: Calcul local des indicateurs avec TA-Lib
- **NewsAPI**: Actualités financières (100 calls/jour gratuit)
- **OpenAI/Claude**: Analyse IA (coût par token)
- Toujours gérer les rate limits et timeouts

### Scoring et Signaux
- **Score Technique** (0-100): RSI 25%, MACD 25%, Trend 30%, Volume 20%
- **Score Fondamental** (0-100): Valuation 30%, Quality 30%, Growth 25%, Dividend 15%
- **Score IA** (0-100): News Sentiment 40%, AI Confidence 30%, Impact 30%
- **Score Global** = Technical 35% + Fundamental 35% + AI 30%
- **Signaux**: Strong Buy (80-100), Buy (60-79), Hold (40-59), Sell (20-39), Strong Sell (0-19)

## Instructions de Développement

### Lors de l'ajout de nouveaux workflows
1. Suivre la structure de nomenclature: `XX-descriptive-name.json`
2. Documenter le workflow dans `workflows/README.md`
3. Ajouter les credentials nécessaires dans n8n
4. Tester avec un petit subset d'actions d'abord
5. Implémenter la gestion d'erreurs et retry logic
6. Rajouter un commit avec un message clair a chaque fois que vous modifiez les workflows ou la documentation associée

### Lors de modifications du schéma DB
1. Créer un script de migration SQL
2. Tester sur une copie de la base d'abord
3. Mettre à jour la documentation dans `docs/DATABASE_SETUP.md`
4. Vérifier l'impact sur les workflows existants

### Lors de l'ajout d'indicateurs techniques
1. Documenter la formule et les paramètres
2. Ajouter les colonnes nécessaires dans `technical_indicators`
3. Implémenter le calcul dans un workflow dédié
4. Valider avec des données historiques connues
5. Intégrer dans le score technique

### Sécurité
- NE JAMAIS commiter les API keys ou `.env`
- Utiliser des variables d'environnement pour toutes les credentials
- Activer l'authentification sur les webhooks n8n
- Valider et nettoyer toutes les entrées utilisateur
- Éviter les injections SQL (utiliser des requêtes paramétrées)

### Tests et Validation
- Utiliser les scripts dans `scripts/` pour valider les changements
- `test-db-connection.sh`: Vérifier la connexion PostgreSQL
- `test-parser-logic.js`: Valider la logique de parsing (JavaScript)
- `test-python-parser.py`: Valider la logique de parsing (Python)
- `test-yahoo-api.js`: Tester l'API Yahoo Finance
- Toujours tester avec des données réelles avant de déployer

## Patterns Communs

### Lecture des prix historiques
```sql
SELECT date, close, volume
FROM stock_prices
WHERE stock_id = (SELECT id FROM stocks WHERE ticker = 'MC.PA')
AND date >= CURRENT_DATE - INTERVAL '200 days'
ORDER BY date ASC;
```

### Calcul d'indicateurs techniques
Les indicateurs sont calculés dans les workflows et stockés dans `technical_indicators`:
- RSI (14 périodes)
- MACD (12, 26, 9)
- SMA/EMA (20, 50, 200 jours)
- Bollinger Bands (20 périodes, 2 std dev)

### Analyse de sentiment IA
Utiliser OpenAI/Claude pour analyser les actualités et générer un score de sentiment (-10 à +10).

## Commandes Utiles

```bash
# Tester la connexion PostgreSQL
./scripts/test-db-connection.sh

# Importer le schéma DB
psql -U postgres -d pea_advisor -f database/schema.sql

# Vérifier le status des workflows n8n
curl http://localhost:5678/healthz

# Lancer un workflow manuellement (avec ID)
n8n execute --id <workflow-id>
```

## Documentation de Référence

- **Documentation principale**: `/docs/README.md`
- **Démarrage rapide**: `/docs/QUICKSTART.md`
- **Architecture**: `/docs/architecture.md`
- **Workflow 00 - Historical Data Loader** ⚡: `/docs/workflow-00-historical-data-loader-guide.md` (CRITIQUE)
- **Workflow 01 - Prix de marché**: `/docs/workflow-01-guide.md`
- **Workflow 02 - News Collector**: `/docs/workflow-02-news-collector-guide.md`
- **Workflow 03 - Technical Indicators** 📊: `/docs/workflow-03-technical-indicators-guide.md`
- **Workflow 04 - Fundamental Data Collector** 💰: `/docs/workflow-04-fundamental-data-collector-guide.md`
- **Workflow 08 - AI News Sentiment** 🤖: `/docs/workflow-08-ai-news-sentiment-guide.md`
- **Configuration API Keys n8n** 🔑: `/docs/n8n-api-keys-setup.md`
- **Convention Timezone** 🌍: `/docs/TIMEZONE_CONVENTION.md` (Europe/Paris standard)
- **Migration Python**: `/docs/python-migration-guide.md`
- **Architecture Python + Merge**: `/docs/python-workflow-architecture.md`
- **Variables Python n8n** ⭐: `/docs/python-variables-n8n.md` (Guide _item vs item)
- **Troubleshooting**: `/docs/troubleshooting-workflow-01.md`
- **Roadmap**: `/TODO.md`

## URLs et Endpoints

- **Instance n8n**: https://n8n01.dataforsciences.best/
- **PostgreSQL**: Localhost (voir `.env` pour credentials)
- **pgAdmin**: Interface web pour PostgreSQL (voir `docs/PGADMIN_GUIDE.md`)

## Notes Importantes

1. **Disclaimer**: Ce système est un outil d'aide à la décision, pas un conseil en investissement
2. **Performance**: Limité à ~50 actions en raison des limites des APIs gratuites
3. **Fréquence**: Mises à jour quotidiennes, pas de données en temps réel
4. **Backup**: Sauvegardes automatiques de la base de données recommandées
5. **Conformité PEA**: Toujours vérifier l'éligibilité avant de recommander une action
6. **Documentation**: Toujours se référer à la documentation pour les mises à jour et changements. Egalement a chaque ajout d'un nouvelle documentation ou modification rajouter seulement dans le dossier `/docs/` 
7. **TODO**: Voir `/TODO.md` pour la liste complète des tâches et la roadmap. Mettre à jour régulièrement avec les progrès.
## Statut du Projet

**Version**: 1.5
**Dernière mise à jour**: 4 janvier 2026
**Statut**: En développement actif

**Workflows complétés**: 6/17 (35%)
- ✅ Workflow 00: Historical Data Loader (CRITIQUE - charge 250 jours d'historique)
- ✅ Workflow 01: Daily Market Data Collector
- ✅ Workflow 02: News Collector
- ✅ Workflow 03: Technical Indicators Calculator (RSI, MACD, SMA, EMA, Bollinger, ATR)
- ✅ Workflow 04: Fundamental Data Collector (P/E, P/B, ROE, dividendes, dette, croissance)
- ✅ Workflow 08: AI News Sentiment Analyzer (Ollama + Llama3.2)

**Prochaine priorité**:
- 🔜 Workflow 06: Fundamental Analysis Scores (calcul des scores fondamentaux)

