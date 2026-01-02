# 📂 Workflows n8n - Conseiller PEA

Ce dossier contient tous les workflows n8n organisés par catégorie.

## 📊 Structure des workflows

### 1️⃣ Data Collection (Collecte de données)
Workflows pour récupérer les données de marché, actualités et fondamentaux.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `01-daily-market-data-collector.json` | Collecte des prix quotidiens | 18h en semaine | ⏳ À créer |
| `02-news-collector.json` | Collecte des actualités financières | Toutes les 4h | ⏳ À créer |
| `03-fundamental-data-collector.json` | Données fondamentales (P/E, ROE, etc.) | Hebdomadaire | ⏳ À créer |

### 2️⃣ Analysis (Analyse)
Workflows d'analyse technique et fondamentale.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `04-technical-analysis-engine.json` | Calcul RSI, MACD, SMA, Bollinger | 19h en semaine | ⏳ À créer |
| `05-pattern-detector.json` | Détection de patterns (croix d'or, etc.) | 19h30 en semaine | ⏳ À créer |
| `06-fundamental-analysis.json` | Analyse des ratios financiers | Hebdomadaire | ⏳ À créer |
| `07-stock-screener.json` | Filtrage et sélection d'actions | Hebdomadaire | ⏳ À créer |

### 3️⃣ AI Engine (Intelligence Artificielle)
Workflows utilisant l'IA pour l'analyse et les recommandations.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `08-ai-news-analyzer.json` | Analyse de sentiment des news par IA | Toutes les 4h | ⏳ À créer |
| `09-ai-recommendation-engine.json` | Génération de recommandations IA | Quotidien 20h | ⏳ À créer |

### 4️⃣ Portfolio Management (Gestion de portefeuille)
Workflows pour gérer et optimiser votre portefeuille.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `10-portfolio-analyzer.json` | Analyse du portefeuille actuel | Quotidien | ⏳ À créer |
| `11-portfolio-optimizer.json` | Suggestions de rééquilibrage | Hebdomadaire | ⏳ À créer |

### 5️⃣ Risk Management (Gestion des risques)
Workflows de surveillance des risques et alertes.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `12-risk-monitor.json` | Surveillance volatilité et VaR | Quotidien | ⏳ À créer |
| `13-real-time-alerts.json` | Alertes en temps réel (webhook) | Temps réel | ⏳ À créer |

### 6️⃣ Reporting (Rapports et notifications)
Workflows de génération de rapports et notifications.

| Workflow | Description | Fréquence | Statut |
|----------|-------------|-----------|--------|
| `14-daily-report.json` | Rapport quotidien | 20h en semaine | ⏳ À créer |
| `15-weekly-report.json` | Rapport hebdomadaire | Dimanche 20h | ⏳ À créer |
| `16-notification-manager.json` | Gestion des notifications | Événementiel | ⏳ À créer |

## 🔄 Flux de données

```
┌─────────────────────────────────────────────────────────────────┐
│                    COLLECTE DE DONNÉES                          │
├─────────────────────────────────────────────────────────────────┤
│  01-daily-market-data-collector                                 │
│  02-news-collector                                              │
│  03-fundamental-data-collector                                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                         BASE DE DONNÉES                          │
│                         (PostgreSQL)                             │
└────────────────────┬────────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐
│  ANALYSE TECHNIQUE  │  │  ANALYSE IA         │
│  04-technical       │  │  08-ai-news         │
│  05-pattern         │  │  09-ai-recomm       │
└─────────┬───────────┘  └──────────┬──────────┘
          │                         │
          └────────┬────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GÉNÉRATION SIGNAUX                            │
│               (trading_signals table)                            │
└────────────────────┬────────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐
│  GESTION            │  │  GESTION RISQUES    │
│  PORTEFEUILLE       │  │  12-risk-monitor    │
│  10-portfolio       │  │  13-real-time       │
│  11-optimizer       │  │                     │
└─────────┬───────────┘  └──────────┬──────────┘
          │                         │
          └────────┬────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RAPPORTS & NOTIFICATIONS                      │
│  14-daily-report                                                │
│  15-weekly-report                                               │
│  16-notification-manager                                        │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Ordre d'implémentation recommandé

### Phase 1 : Infrastructure de base
1. ✅ Créer le schéma de base de données
2. 📝 Configurer les variables d'environnement
3. 📝 Tester les connexions API

### Phase 2 : Collecte de données
4. 📝 `01-daily-market-data-collector`
5. 📝 `02-news-collector`
6. 📝 `03-fundamental-data-collector`

### Phase 3 : Analyses
7. 📝 `04-technical-analysis-engine`
8. 📝 `06-fundamental-analysis`
9. 📝 `08-ai-news-analyzer`

### Phase 4 : Signaux et recommandations
10. 📝 `05-pattern-detector`
11. 📝 `09-ai-recommendation-engine`

### Phase 5 : Portfolio et risques
12. 📝 `10-portfolio-analyzer`
13. 📝 `12-risk-monitor`
14. 📝 `13-real-time-alerts`

### Phase 6 : Reporting
15. 📝 `14-daily-report`
16. 📝 `15-weekly-report`
17. 📝 `16-notification-manager`

### Phase 7 : Optimisation
18. 📝 `11-portfolio-optimizer`
19. 📝 `07-stock-screener`

## 🔧 Import dans n8n

Pour importer un workflow dans n8n :

1. Se connecter à votre instance : https://n8n01.dataforsciences.best/
2. Cliquer sur "+" → "Import from File"
3. Sélectionner le fichier JSON
4. Configurer les credentials nécessaires
5. Activer le workflow

## 📝 Notes importantes

- **Credentials** : Ne jamais inclure de credentials dans les workflows exportés
- **Webhooks** : Les URLs de webhook seront régénérées à l'import
- **Horaires** : Adapter les cron selon votre timezone
- **Rate limiting** : Respecter les limites des APIs gratuites

## 🔗 Dépendances entre workflows

Certains workflows dépendent d'autres :

- `04-technical-analysis` → nécessite `01-daily-market-data`
- `09-ai-recommendation` → nécessite tous les workflows d'analyse
- `14-daily-report` → nécessite tous les workflows précédents
- `12-risk-monitor` → nécessite `10-portfolio-analyzer`

## 📊 Données requises

Avant de lancer les workflows, assurez-vous d'avoir :

- [ ] Liste des actions à suivre (config/stocks-watchlist.json)
- [ ] API keys configurées dans .env
- [ ] Base de données créée et initialisée
- [ ] Portefeuille initial saisi (si applicable)

## 🆘 Troubleshooting

### Workflow ne démarre pas
- Vérifier que les credentials sont configurés
- Vérifier les logs n8n
- Tester les connexions API

### Données manquantes
- Vérifier que les workflows de collecte ont bien été exécutés
- Consulter la table `system_logs` dans PostgreSQL

### Erreurs API
- Vérifier les rate limits
- Régénérer les API keys si nécessaire
- Consulter la documentation de l'API

---

**Dernière mise à jour** : 2 janvier 2026
