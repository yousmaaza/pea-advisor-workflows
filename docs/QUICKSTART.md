# 🚀 Guide de Démarrage Rapide

## ✅ Ce qui a été fait

La base de données PostgreSQL est maintenant configurée et prête à l'emploi !

### Infrastructure
- ✅ Base de données `pea_advisor` créée
- ✅ 14 tables créées
- ✅ 2 vues SQL créées
- ✅ Fonctions utilitaires créées
- ✅ 10 actions CAC40 pré-chargées
- ✅ Configuration `.env` mise à jour

### Fichiers créés
```
pea-advisor-workflows/
├── README.md                    # Documentation principale
├── TODO.md                      # Roadmap complète
├── DATABASE_SETUP.md            # Documentation base de données
├── QUICKSTART.md                # Ce fichier
├── .gitignore                   # Protection fichiers sensibles
├── config/
│   ├── .env                     # ✅ Configuration active
│   ├── .env.example             # Template de configuration
│   └── stocks-watchlist.json    # Watchlist avec 10 actions
├── database/
│   └── schema.sql               # ✅ Schéma appliqué
├── docs/
│   └── architecture.md          # Architecture du système
├── scripts/
│   └── test-db-connection.sh    # ✅ Script de test
└── workflows/
    └── [6 dossiers pour workflows]
```

---

## 🔌 Connexion PostgreSQL

### Informations de connexion
```
Host: self-hosted-ai-starter-kit-postgres-1
Port: 5432
Database: pea_advisor
User: root
Password: 3e06831d498324ea8b0b5bc8a72bc5d0
```

### Tester la connexion
```bash
cd pea-advisor-workflows
./scripts/test-db-connection.sh
```

---

## 📋 Prochaines étapes

### 1. Configurer les API keys

Éditer `config/.env` et ajouter vos clés API :

```bash
# Obligatoires pour commencer
ALPHA_VANTAGE_API_KEY=votre_clé    # https://www.alphavantage.co/support/#api-key
NEWS_API_KEY=votre_clé              # https://newsapi.org/

# Recommandé pour l'IA
OPENAI_API_KEY=votre_clé            # https://platform.openai.com/api-keys

# Optionnel pour notifications
TELEGRAM_BOT_TOKEN=votre_token      # https://core.telegram.org/bots
TELEGRAM_CHAT_ID=votre_chat_id
```

### 2. Créer le premier workflow n8n

Le premier workflow à créer est `01-daily-market-data-collector` qui va :
- Récupérer les prix des actions depuis Yahoo Finance
- Les stocker dans la table `stock_prices`
- S'exécuter automatiquement tous les jours à 18h

**Voulez-vous que je crée ce workflow maintenant ?**

### 3. Vérifier les données

Une fois le workflow créé, vous pourrez vérifier les données :

```sql
-- Se connecter à la base
docker exec -it self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor

-- Voir les prix collectés
SELECT s.ticker, sp.date, sp.close 
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
ORDER BY sp.date DESC
LIMIT 10;
```

---

## 📚 Documentation

- **README.md** : Vue d'ensemble du projet
- **TODO.md** : Liste complète des tâches (10 phases)
- **DATABASE_SETUP.md** : Tout sur la base de données
- **docs/architecture.md** : Architecture technique détaillée
- **workflows/README.md** : Documentation des workflows

---

## 🆘 Besoin d'aide ?

### Vérifier que tout fonctionne
```bash
# Test PostgreSQL
./scripts/test-db-connection.sh

# Vérifier n8n
curl https://n8n01.dataforsciences.best/healthz

# Vérifier les conteneurs Docker
docker ps | grep -E "n8n|postgres|qdrant"
```

### Problèmes courants

**Base de données ne répond pas**
```bash
docker restart self-hosted-ai-starter-kit-postgres-1
```

**Workflow n8n ne se connecte pas à PostgreSQL**
- Vérifier que `POSTGRES_HOST=self-hosted-ai-starter-kit-postgres-1` dans `.env`
- Dans n8n, utiliser le nom du conteneur, pas `localhost`

---

## 🎯 Objectif final

Avoir un système complet qui :
1. ✅ Collecte automatiquement les données de marché
2. ✅ Analyse les opportunités (technique + fondamental + IA)
3. ✅ Génère des recommandations personnalisées
4. ✅ Surveille votre portefeuille et les risques
5. ✅ Envoie des rapports quotidiens et hebdomadaires

**Prêt à créer le premier workflow ?** 🚀
