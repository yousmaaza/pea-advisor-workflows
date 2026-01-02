# 🤖 Conseiller Intelligent PEA Boursorama

Un système automatisé de recommandations d'investissement pour optimiser votre Plan d'Épargne en Actions (PEA) sur Boursorama.

## 📁 Structure du Projet

```
pea-advisor-workflows/
│
├── README.md                          # Ce fichier
├── TODO.md                            # Liste des tâches et roadmap
│
├── workflows/                         # Workflows n8n
│   ├── data-collection/              # Collecte de données
│   │   ├── 01-daily-market-data-collector.json
│   │   ├── 02-news-collector.json
│   │   └── 03-fundamental-data-collector.json
│   │
│   ├── analysis/                     # Analyses techniques et fondamentales
│   │   ├── 04-technical-analysis-engine.json
│   │   ├── 05-pattern-detector.json
│   │   ├── 06-fundamental-analysis.json
│   │   └── 07-stock-screener.json
│   │
│   ├── ai-engine/                    # Intelligence artificielle
│   │   ├── 08-ai-news-analyzer.json
│   │   └── 09-ai-recommendation-engine.json
│   │
│   ├── portfolio-management/         # Gestion de portefeuille
│   │   ├── 10-portfolio-analyzer.json
│   │   └── 11-portfolio-optimizer.json
│   │
│   ├── risk-management/              # Gestion des risques
│   │   ├── 12-risk-monitor.json
│   │   └── 13-real-time-alerts.json
│   │
│   └── reporting/                    # Rapports et notifications
│       ├── 14-daily-report.json
│       ├── 15-weekly-report.json
│       └── 16-notification-manager.json
│
├── config/                           # Configuration
│   ├── .env.example                 # Template variables d'environnement
│   ├── stocks-watchlist.json        # Liste des actions suivies
│   ├── pea-eligible-stocks.json     # Actions éligibles PEA
│   └── strategies.json              # Configuration des stratégies
│
├── database/                         # Schémas de base de données
│   └── schema.sql                   # Schéma PostgreSQL ✅
│
├── docs/                            # 📚 Documentation
│   ├── README.md                    # Index de la documentation
│   ├── QUICKSTART.md                # ⭐ Guide de démarrage rapide
│   ├── DATABASE_SETUP.md            # Configuration PostgreSQL
│   ├── PGADMIN_GUIDE.md             # Interface web PostgreSQL
│   └── architecture.md              # Architecture du système
│
└── scripts/                         # Scripts utilitaires
    └── test-db-connection.sh        # Test de connexion PostgreSQL ✅
```

## 🎯 Fonctionnalités

### ✅ Collecte de données automatisée
- Prix de marché en temps réel
- Actualités financières
- Données fondamentales des entreprises
- Indicateurs macro-économiques

### 📊 Analyses multi-dimensionnelles
- **Technique** : RSI, MACD, moyennes mobiles, bandes de Bollinger
- **Fondamentale** : P/E, P/B, ROE, croissance, dividendes
- **Sentiment** : Analyse des actualités par IA

### 🤖 Intelligence Artificielle
- Recommandations personnalisées
- Analyse de sentiment des news
- Explications en langage naturel
- Scoring des opportunités

### 💼 Gestion de portefeuille
- Suivi des positions
- Optimisation de l'allocation
- Rééquilibrage automatique
- Respect des contraintes PEA

### ⚠️ Gestion des risques
- Calcul de volatilité (VaR)
- Alertes en temps réel
- Monitoring des stops-loss
- Diversification sectorielle

### 📱 Notifications & Rapports
- Rapports quotidiens et hebdomadaires
- Alertes Telegram/Email
- Dashboard de suivi

## 🚀 Démarrage Rapide

### Prérequis
- n8n installé et fonctionnel
- PostgreSQL
- Qdrant (optionnel, pour RAG)
- Comptes API (voir docs/api-setup.md)

### Installation

1. **Configurer les variables d'environnement**
```bash
cp config/.env.example config/.env
# Éditer config/.env avec vos API keys
```

2. **Créer la base de données**
```bash
psql -U postgres -f database/schema.sql
```

3. **Importer les workflows dans n8n**
- Accéder à votre instance n8n : https://n8n01.dataforsciences.best/
- Importer les workflows depuis le dossier `workflows/`

4. **Configurer votre watchlist**
```bash
# Éditer config/stocks-watchlist.json avec vos actions
```

5. **Activer les workflows**
- Activer les workflows de collecte de données
- Vérifier les logs

## 🔑 Configuration des APIs

### APIs obligatoires
- **Yahoo Finance** : Gratuit (prix de marché)
- **Alpha Vantage** : Gratuit avec limites (indicateurs techniques)
- **NewsAPI** : Gratuit (actualités)

### APIs optionnelles
- **OpenAI/Claude** : Analyse IA avancée (~50€/mois)
- **Financial Modeling Prep** : Données fondamentales premium
- **Telegram Bot** : Notifications instantanées (gratuit)

## 📖 Documentation

### Guides de démarrage
- [docs/QUICKSTART.md](docs/QUICKSTART.md) - **Guide de démarrage rapide**
- [docs/DATABASE_SETUP.md](docs/DATABASE_SETUP.md) - Configuration de la base de données
- [docs/PGADMIN_GUIDE.md](docs/PGADMIN_GUIDE.md) - Utilisation de l'interface web PostgreSQL

### Documentation technique
- [TODO.md](TODO.md) - Roadmap complète et tâches
- [docs/architecture.md](docs/architecture.md) - Architecture du système
- [workflows/README.md](workflows/README.md) - Documentation des workflows

## 🔒 Sécurité

⚠️ **Important** :
- Ne commitez JAMAIS vos API keys
- Utilisez les variables d'environnement
- Activez l'authentification sur vos workflows
- Faites des backups réguliers

## 📊 Contraintes PEA

Le système respecte automatiquement les règles du PEA :
- ✅ Actions émises dans l'UE/EEE uniquement
- ✅ Minimum 75% en actions européennes
- ✅ Plafond de versement : 150 000€
- ✅ Fiscalité : exonération après 5 ans (17,2% prélèvements sociaux)

## 🤝 Contribution

Ce projet est personnel, mais les suggestions sont bienvenues !

## 📝 Licence

MIT - Usage personnel

## ⚠️ Disclaimer

**Ce système est un outil d'aide à la décision. Il ne constitue en aucun cas un conseil en investissement.**

- Les recommandations sont générées automatiquement et peuvent contenir des erreurs
- Investir en bourse comporte des risques de perte en capital
- Faites vos propres recherches avant tout investissement
- Consultez un conseiller financier professionnel si nécessaire

## 📞 Support

- 📧 Issues : Créer une issue dans ce projet
- 📚 Documentation : Voir dossier `docs/`
- 💬 Questions : Consulter le README et la FAQ

---

**Version** : 1.0
**Dernière mise à jour** : 2 janvier 2026
**Statut** : 🚧 En développement
