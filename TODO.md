# 📋 TODO - Conseiller Intelligent PEA Boursorama

## 🎯 Objectif
Créer un système intelligent de recommandations pour optimiser les placements dans un compte PEA sur Boursorama.

---

## 📊 État Actuel du Projet

### ✅ Complété (4 janvier 2026)

#### Workflows Opérationnels
- ✅ **Workflow 00**: Historical Data Loader (Yahoo Finance)
  - Charge 250 jours d'historique (1 an) pour chaque action
  - Expansion massive: 1 action → 250 jours (~12 500 items pour 50 actions)
  - Trigger manuel (exécution unique au démarrage)
  - Durée: ~2-3 minutes pour 50 actions
  - **FIX**: Extraction correcte du champ `adjusted_close` depuis Yahoo Finance API
  - Documentation complète

- ✅ **Workflow 01**: Daily Market Data Collector (Yahoo Finance)
  - Architecture Python + Merge node
  - Variables n8n: `_item`, `_items` (avec underscore)
  - Collecte quotidienne des prix (open, high, low, close, volume, adjusted_close)
  - Timezone: Europe/Paris (standardisé)
  - Documentation complète

- ✅ **Workflow 02**: News Collector (NewsAPI)
  - 5 articles par action, expansion d'items (1 stock → 5 articles)
  - Mode Python: `runOnceForAllItems` avec boucle sur `_items`
  - Opération native PostgreSQL `insert` (protection SQL injection)
  - Rate limiting: 2s entre requêtes
  - Timezone: Europe/Paris (standardisé)
  - Documentation complète

- ✅ **Workflow 03**: Technical Indicators Calculator (Local)
  - Calcul local des indicateurs techniques (RSI, MACD, SMA, EMA, Bollinger, ATR)
  - Implémentations Python pures (pas de dépendances TA-Lib requises)
  - CTE SQL pour agréger 300 jours de prix en arrays
  - Détection automatique de signaux (oversold/overbought, tendances)
  - Mode Python: `runOnceForEachItem` (traite chaque stock individuellement)
  - Durée: ~12 secondes pour 50 actions (vs 12 JOURS avec Alpha Vantage!)
  - Schedule: 19h15 quotidien (après workflow 01)
  - Timezone: Europe/Paris (standardisé)
  - Documentation complète

- ✅ **Workflow 08**: AI News Sentiment Analyzer (Llama3.2)
  - **100% gratuit et local** avec Ollama + Llama3.2 (Meta)
  - Architecture LangChain: Ollama Chat Model + AI Agent + Merge node
  - Analyse sentiment (-10 à +10), label (negative/neutral/positive), impact (0-10)
  - Génération de résumés et points clés
  - Échappement PostgreSQL pour apostrophes dans ai_summary et ai_key_points
  - Code Python robuste avec gestion d'erreurs et valeurs par défaut
  - Schedule: 20h quotidien (après news collector)
  - Timezone: Europe/Paris
  - Économie: ~15-22€/mois vs OpenAI/Claude
  - Documentation complète

#### Documentation
- ✅ Guide configuration API keys n8n (4 méthodes)
- ✅ Guide Python variables n8n (_item vs item)
- ✅ Architecture Python + Merge node
- ✅ Guide workflow 00 (historical data loader)
- ✅ Guide workflow 01 (market data)
- ✅ Guide workflow 02 (news collector)
- ✅ Guide workflow 03 (technical indicators calculator)
- ✅ Guide workflow 08 (AI news sentiment analyzer with Llama3.2)
- ✅ Convention Timezone (Europe/Paris pour tous les workflows)
- ✅ Scripts de migration database (TIMESTAMP → TIMESTAMPTZ)
- ✅ Scripts de nettoyage database (clear_all_tables.sql, clear_data_tables.sql)
- ✅ Notes dépréciation Alpha Vantage
- ✅ Fichier .claude pour le projet

#### Décisions Techniques
- ✅ Migration JavaScript → Python pour tous les workflows
- ✅ Architecture Merge node (combine data sources)
- ✅ Abandon Alpha Vantage (rate limits: 1 req/s, 25 req/jour)
- ✅ Calcul local des indicateurs techniques (TA-Lib) au lieu d'API externe
- ✅ Timezone standardisé: Europe/Paris pour tous les workflows (Schedule Triggers + Python)
- ✅ PostgreSQL TIMESTAMPTZ au lieu de TIMESTAMP (timezone-aware)
- ✅ LLM local avec Ollama + Llama3.2 au lieu de OpenAI/Claude (économie ~20€/mois)
- ✅ Architecture LangChain pour intégration LLM dans n8n
- ✅ Échappement PostgreSQL pour apostrophes dans les champs texte IA

---

## 🔥 Prochaines Priorités (Par Ordre)

### 🟡 PRIORITÉ MOYENNE

#### 1. Workflow 04: Fundamental Data Collector 📊
**Statut**: 📋 À faire
**Durée estimée**: 5h

**Objectif**: Collecter données fondamentales (P/E, P/B, ROE, dividendes)

**Sources possibles**:
- Yahoo Finance (gratuit, mais limité)
- Financial Modeling Prep (gratuit: 250 req/jour)
- Alpha Vantage (déjà écarté pour les indicateurs techniques)

**Fréquence**: Hebdomadaire (données fondamentales changent lentement)

---

### 🟢 PRIORITÉ BASSE (Plus tard)

- Workflow 05: Pattern Detector (croix dorée, supports/résistances)
- Workflow 06: Fundamental Analysis (scores Value, Growth, Quality)
- Workflow 07: Stock Screener
- Workflow 09: AI Recommendation Engine
- Workflows 10-11: Portfolio Management
- Workflows 12-13: Risk Management & Alerts
- Workflows 14-16: Reporting & Notifications
- Workflow 17: Backtesting

---

## 📅 Phase 1 : Infrastructure & Configuration (Semaine 1-2)

### ✅ Configuration de base
- [x] Créer la structure de dossiers
- [x] Configurer les variables d'environnement (.env)
- [x] Documenter les API keys nécessaires (guide complet créé)
- [ ] Créer le schéma de base de données PostgreSQL
- [ ] Initialiser les tables de données

### 🔌 Connexions API à configurer
- [x] Yahoo Finance API (gratuit) - Utilisé dans workflows 00, 01
- [x] ~~Alpha Vantage API~~ - **ABANDONNÉ** (rate limits trop restrictifs)
- [ ] Financial Modeling Prep API
- [x] NewsAPI pour les actualités - Utilisé dans workflow 02
- [x] ~~OpenAI/Claude API pour l'IA~~ - Remplacé par Ollama + Llama3.2 (local, gratuit)
- [x] Ollama (local LLM) - Utilisé dans workflow 08
- [ ] Telegram Bot (pour notifications)

### 🗄️ Base de données
- [x] Créer table `stock_prices` (historique des cours) - TIMESTAMPTZ
- [ ] Créer table `stock_fundamentals` (données fondamentales)
- [ ] Créer table `portfolio` (positions actuelles)
- [ ] Créer table `recommendations` (historique des recommandations)
- [x] Créer table `news` avec champs sentiment (sentiment_score, sentiment_label, impact_score, ai_summary, ai_key_points)
- [x] Créer table `technical_indicators` (indicateurs calculés)
- [x] Migration TIMESTAMP → TIMESTAMPTZ pour timezone Europe/Paris
- [x] Scripts de nettoyage database (clear_all_tables.sql, clear_data_tables.sql)

---

## 📊 Phase 2 : Collecte de Données (Semaine 3-4)

### ✅ Workflow 1 : Collecte des prix de marché (COMPLÉTÉ)
- [x] Créer `01-daily-market-data-collector.json`
- [x] Définir la liste des actions éligibles PEA
- [x] Récupérer les prix de clôture quotidiens (OHLCV)
- [x] Stocker dans PostgreSQL
- [x] Gérer les erreurs et retry
- [x] Tester avec 5-10 actions
- [x] Migration vers Python + Merge node
- [x] Documentation complète

### ✅ Workflow 2 : Collecte des actualités financières (COMPLÉTÉ)
- [x] Créer `02-news-collector.json`
- [x] Configurer NewsAPI
- [x] Filtrer les news pertinentes (5 articles par action)
- [x] Stocker les articles
- [x] Planifier exécution toutes les 4h
- [x] Gérer expansion d'items (1 action → 5 articles)
- [x] Protection SQL injection (native insert operation)
- [x] Documentation complète

### Workflow 3 : Collecte des données fondamentales
- [ ] Créer `03-fundamental-data-collector.json`
- [ ] Récupérer ratios financiers (P/E, P/B, ROE)
- [ ] Récupérer données dividendes
- [ ] Mise à jour hebdomadaire
- [ ] Validation des données

---

## 🧮 Phase 3 : Analyse Technique (Semaine 5)

### Workflow 4 : Calcul des indicateurs techniques
- [ ] Créer `04-technical-analysis-engine.json`
- [ ] Implémenter calcul RSI (Relative Strength Index)
- [ ] Implémenter calcul MACD
- [ ] Implémenter Moyennes Mobiles (SMA 20, 50, 200)
- [ ] Implémenter Bandes de Bollinger
- [ ] Détecter les signaux d'achat/vente
- [ ] Stocker les résultats

### Workflow 5 : Détection de patterns
- [ ] Créer `05-pattern-detector.json`
- [ ] Détecter croix dorée/croix de la mort
- [ ] Détecter cassures de supports/résistances
- [ ] Détecter divergences RSI
- [ ] Scorer les opportunités (0-100)

---

## 📈 Phase 4 : Analyse Fondamentale (Semaine 6)

### Workflow 6 : Analyse fondamentale
- [ ] Créer `06-fundamental-analysis.json`
- [ ] Calculer score Value (P/E, P/B comparés au secteur)
- [ ] Calculer score Growth (croissance CA, bénéfices)
- [ ] Calculer score Qualité (ROE, marge, dette)
- [ ] Calculer score Dividendes
- [ ] Score global fondamental

### Workflow 7 : Screening d'actions
- [ ] Créer `07-stock-screener.json`
- [ ] Filtrer actions éligibles PEA
- [ ] Appliquer critères de sélection
- [ ] Classer par potentiel
- [ ] Mettre à jour watchlist

---

## 🤖 Phase 5 : Intelligence Artificielle (Semaine 7)

### ✅ Workflow 8 : Analyse de sentiment des news (COMPLÉTÉ)
- [x] Créer `08-ai-news-analyzer.json`
- [x] Intégrer Ollama + Llama3.2 (local, gratuit)
- [x] Architecture LangChain (Ollama Chat Model + AI Agent + Merge)
- [x] Analyser sentiment (positif/neutre/négatif)
- [x] Extraire insights clés (ai_summary, ai_key_points)
- [x] Scorer impact sur cours (-10 à +10)
- [x] Stocker résultats avec échappement PostgreSQL
- [x] Documentation complète

### Workflow 9 : Génération de recommandations IA
- [ ] Créer `09-ai-recommendation-engine.json`
- [ ] Agréger toutes les analyses
- [ ] Prompt engineering pour recommandations
- [ ] Générer explications en français
- [ ] Calculer niveau de confiance
- [ ] Formater les recommandations

---

## 🎯 Phase 6 : Gestion de Portefeuille (Semaine 8)

### Workflow 10 : Analyse du portefeuille actuel
- [ ] Créer `10-portfolio-analyzer.json`
- [ ] Interface pour saisir positions actuelles
- [ ] Calculer performance globale
- [ ] Analyser diversification sectorielle
- [ ] Calculer exposition géographique
- [ ] Identifier risques de concentration

### Workflow 11 : Optimisation du portefeuille
- [ ] Créer `11-portfolio-optimizer.json`
- [ ] Suggérer rééquilibrage
- [ ] Optimiser allocation sectorielle
- [ ] Respecter contraintes PEA
- [ ] Minimiser coûts de transaction
- [ ] Optimisation fiscale

---

## ⚠️ Phase 7 : Gestion des Risques (Semaine 9)

### Workflow 12 : Monitoring des risques
- [ ] Créer `12-risk-monitor.json`
- [ ] Calculer volatilité du portefeuille
- [ ] Calculer VaR (Value at Risk)
- [ ] Détecter corrélations excessives
- [ ] Alertes sur variations brutales
- [ ] Surveiller stops-loss

### Workflow 13 : Alertes en temps réel
- [ ] Créer `13-real-time-alerts.json`
- [ ] Webhook pour variations >5%
- [ ] Alertes actualités importantes
- [ ] Alertes signaux techniques forts
- [ ] Envoi Telegram/Email immédiat

---

## 📱 Phase 8 : Notifications & Reporting (Semaine 10)

### Workflow 14 : Rapport quotidien
- [ ] Créer `14-daily-report.json`
- [ ] Résumé marchés (CAC40, Euro Stoxx)
- [ ] Top 5 opportunités du jour
- [ ] Performance portefeuille
- [ ] Actualités importantes
- [ ] Envoi à 20h chaque jour

### Workflow 15 : Rapport hebdomadaire
- [ ] Créer `15-weekly-report.json`
- [ ] Performance hebdomadaire
- [ ] Analyse détaillée des positions
- [ ] Recommandations de rééquilibrage
- [ ] Évolution des objectifs
- [ ] Envoi dimanche soir

### Workflow 16 : Configuration des notifications
- [ ] Créer `16-notification-manager.json`
- [ ] Configurer Telegram Bot
- [ ] Templates de messages
- [ ] Gérer préférences utilisateur
- [ ] Historique des notifications

---

## 🧪 Phase 9 : Backtesting & Validation (Semaine 11-12)

### Tests et validation
- [ ] Créer `17-backtesting-engine.json`
- [ ] Tester stratégies sur données historiques
- [ ] Calculer taux de réussite
- [ ] Mesurer rendement vs CAC40
- [ ] Ajuster paramètres
- [ ] Documenter performances

### Documentation
- [x] Documenter chaque workflow (01, 02 complétés)
- [x] Créer guide d'utilisation (API keys, Python variables, architecture)
- [x] Documenter les stratégies (Migration Python, Merge node)
- [x] Exemples de configuration (4 méthodes API keys)
- [ ] FAQ

---

## 🚀 Phase 10 : Améliorations Avancées (Semaine 13+)

### Fonctionnalités avancées
- [ ] Dashboard web (intégration n8n)
- [ ] Interface de saisie manuelle de trades
- [ ] Calcul automatique des plus-values
- [ ] Intégration calendrier économique
- [ ] Analyse ESG (critères environnementaux)
- [ ] Comparaison avec benchmarks
- [ ] Simulation de scénarios
- [ ] Chatbot pour questions interactives

### Optimisations
- [ ] Optimiser performance des requêtes
- [ ] Réduire coûts API (caching)
- [ ] Améliorer précision IA
- [ ] Tests A/B sur stratégies
- [ ] Monitoring des temps d'exécution

---

## 🔒 Sécurité & Conformité

### Sécurité
- [ ] Chiffrement des API keys
- [ ] Authentification workflows sensibles
- [ ] Logs d'audit
- [ ] Backups automatiques quotidiens
- [ ] Plan de disaster recovery

### Conformité PEA
- [ ] Vérifier éligibilité des actions (UE/EEE)
- [ ] Respecter limite 75% actions européennes
- [ ] Tracker plafond de versement
- [ ] Calculer fiscalité (17,2% prélèvements sociaux)
- [ ] Alertes si non-conformité

---

## 📊 KPIs à suivre

- [ ] Taux de réussite des recommandations
- [ ] Performance vs CAC40 (alpha)
- [ ] Volatilité du portefeuille (beta)
- [ ] Sharpe ratio
- [ ] Max drawdown
- [ ] Taux de remplissage des données
- [ ] Uptime des workflows
- [ ] Coûts mensuels (API + infrastructure)

---

## 🛠️ Maintenance Continue

### Hebdomadaire
- [ ] Vérifier logs d'erreurs
- [ ] Contrôler qualité des données
- [ ] Backup manuel si nécessaire

### Mensuel
- [ ] Analyser performances globales
- [ ] Ajuster paramètres stratégies
- [ ] Mettre à jour liste actions éligibles
- [ ] Revoir allocation sectorielle

### Trimestriel
- [ ] Audit complet du système
- [ ] Mise à jour dépendances
- [ ] Optimisation coûts
- [ ] Évolution stratégie investissement

---

## 💡 Idées Futures
- Intégration avec compte Boursorama (lecture seule via scraping)
- ML pour prédiction de tendances
- Analyse de corrélation avec matières premières
- Alertes SMS en plus de Telegram
- Application mobile dédiée
- Communauté d'utilisateurs (partage stratégies)

### Ressources utiles
- Documentation Yahoo Finance API
- Guide indicateurs techniques
- Réglementation PEA (impots.gouv.fr)
- Liste actions éligibles PEA
- Best practices n8n

---

**Dernière mise à jour** : 4 janvier 2026
**Version** : 1.4
**Statut** : 🚧 En construction active

**Progression**: 5/17 workflows complétés (29%)
- ✅ Workflow 00: Historical Data Loader (avec adjusted_close fix)
- ✅ Workflow 01: Daily Market Data Collector (avec timezone)
- ✅ Workflow 02: News Collector (avec timezone)
- ✅ Workflow 03: Technical Indicators Calculator (avec timezone)
- ✅ Workflow 08: AI News Sentiment Analyzer (Ollama + Llama3.2)
- 🔜 Workflow 04: Fundamental Data Collector (PRIORITÉ MOYENNE)

**Améliorations Infrastructure**:
- ✅ Timezone standardisé (Europe/Paris) sur tous les workflows
- ✅ Migration PostgreSQL TIMESTAMP → TIMESTAMPTZ
- ✅ Scripts de nettoyage database
- ✅ Documentation complète Workflow 08 + Convention Timezone
