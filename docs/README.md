# 📚 Documentation - Conseiller Intelligent PEA

Bienvenue dans la documentation complète du projet Conseiller Intelligent PEA.

---

## 🚀 Pour commencer

### Guides de démarrage rapide

| Document | Description | Pour qui ? |
|----------|-------------|------------|
| [QUICKSTART.md](QUICKSTART.md) | Guide de démarrage rapide | ⭐ Tout le monde |
| [DATABASE_SETUP.md](DATABASE_SETUP.md) | Configuration PostgreSQL | Débutants |
| [PGADMIN_GUIDE.md](PGADMIN_GUIDE.md) | Interface web PostgreSQL | Débutants |

---

## 🏗️ Documentation technique

### Architecture et conception

| Document | Description | Pour qui ? |
|----------|-------------|------------|
| [architecture.md](architecture.md) | Architecture complète du système | Développeurs |
| [../workflows/README.md](../workflows/README.md) | Documentation des workflows | Utilisateurs n8n |

### Workflows n8n

| Document | Description | Pour qui ? |
|----------|-------------|------------|
| [import-workflow-guide.md](import-workflow-guide.md) | Guide d'import des workflows | ⭐ Tous |
| [workflow-01-guide.md](workflow-01-guide.md) | Workflow 01 : Collecte des prix | Utilisateurs |

---

## 📋 Organisation de la documentation

```
docs/
├── README.md                    # Ce fichier (index)
├── QUICKSTART.md                # Guide de démarrage rapide
├── DATABASE_SETUP.md            # Configuration de la base de données
├── PGADMIN_GUIDE.md             # Guide d'utilisation pgAdmin
├── architecture.md              # Architecture technique
└── [À venir]
    ├── api-setup.md             # Configuration des APIs
    ├── user-guide.md            # Guide utilisateur complet
    ├── strategies-explained.md  # Explication des stratégies
    ├── workflow-guide.md        # Création de workflows
    └── troubleshooting.md       # Résolution de problèmes
```

---

## 🎯 Par cas d'usage

### Je veux installer le système
1. Lire [QUICKSTART.md](QUICKSTART.md)
2. Suivre [DATABASE_SETUP.md](DATABASE_SETUP.md)
3. Consulter [PGADMIN_GUIDE.md](PGADMIN_GUIDE.md)

### Je veux comprendre l'architecture
1. Lire [architecture.md](architecture.md)
2. Consulter [../workflows/README.md](../workflows/README.md)

### Je veux créer mon premier workflow
1. Vérifier la configuration : [DATABASE_SETUP.md](DATABASE_SETUP.md)
2. Comprendre le flux : [architecture.md](architecture.md)
3. Suivre les exemples : [../workflows/README.md](../workflows/README.md)

### Je veux gérer la base de données
1. Interface web : [PGADMIN_GUIDE.md](PGADMIN_GUIDE.md)
2. Commandes utiles : [DATABASE_SETUP.md](DATABASE_SETUP.md)

---

## 📖 Documentation externe

### n8n
- Documentation officielle : https://docs.n8n.io/
- Forum communautaire : https://community.n8n.io/

### PostgreSQL
- Documentation officielle : https://www.postgresql.org/docs/
- Tutoriels : https://www.postgresqltutorial.com/

### APIs financières
- Yahoo Finance : https://finance.yahoo.com/
- Alpha Vantage : https://www.alphavantage.co/documentation/
- NewsAPI : https://newsapi.org/docs

### IA
- OpenAI API : https://platform.openai.com/docs
- Anthropic Claude : https://docs.anthropic.com/

---

## 🆘 Besoin d'aide ?

### Problèmes courants

**La base de données ne fonctionne pas**
→ Voir [DATABASE_SETUP.md - Troubleshooting](DATABASE_SETUP.md#-troubleshooting)

**pgAdmin ne se connecte pas**
→ Voir [PGADMIN_GUIDE.md - Troubleshooting](PGADMIN_GUIDE.md#-troubleshooting)

**Mon workflow n8n échoue**
→ Vérifier les logs et la configuration dans [../workflows/README.md](../workflows/README.md)

---

## 📝 Contribuer à la documentation

Si vous trouvez des erreurs ou souhaitez améliorer la documentation :

1. Les fichiers sont en Markdown (.md)
2. Placez les nouveaux documents dans `docs/`
3. Mettez à jour cet index (README.md)

---

## 📅 Historique des versions

| Version | Date | Changements |
|---------|------|-------------|
| 1.0 | 2026-01-02 | Documentation initiale créée |

---

**Dernière mise à jour** : 2 janvier 2026
**Version** : 1.0
