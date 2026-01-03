# Configuration des API Keys dans n8n

## 🔑 Problème

Les fichiers `.env` ne sont **pas automatiquement lus** par n8n. Les variables d'environnement doivent être configurées différemment selon votre méthode de déploiement.

## 💡 Solutions

### Option 1: API Key Directement dans l'URL (Pour Tester)

**✅ Avantages**: Rapide, simple pour tester
**❌ Inconvénients**: Moins sécurisé, visible dans les workflows

**Comment faire:**

1. Dans n8n, ouvrir le workflow `02-technical-indicators-collector`
2. Cliquer sur le node **"Alpha Vantage RSI"**
3. Dans l'URL, remplacer `VOTRE_CLE_API_ICI` par votre vraie API key:

```
https://www.alphavantage.co/query?function=RSI&symbol={{ $json.ticker }}&interval=daily&time_period=14&apikey=ABC123XYZ456
```

4. Sauvegarder le workflow

⚠️ **Attention**: Ne commitez jamais le workflow avec l'API key en clair dans Git!

---

### Option 2: Variables d'Environnement au Démarrage de n8n (Recommandé pour Production)

**✅ Avantages**: Sécurisé, partagé entre workflows
**❌ Inconvénients**: Nécessite redémarrage de n8n

#### Si n8n tourne avec Docker

**Fichier `docker-compose.yml`:**
```yaml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - ALPHA_VANTAGE_API_KEY=votre_cle_api_ici
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=pea_advisor
      # ... autres variables
    volumes:
      - n8n_data:/home/node/.n8n
```

**Puis dans le workflow:**
```
apikey={{ $env.ALPHA_VANTAGE_API_KEY }}
```

**Redémarrer n8n:**
```bash
docker-compose down
docker-compose up -d
```

#### Si n8n tourne en direct (sans Docker)

**Linux/Mac:**
```bash
export ALPHA_VANTAGE_API_KEY=votre_cle_api_ici
n8n start
```

**Ou créer un script `start-n8n.sh`:**
```bash
#!/bin/bash
export ALPHA_VANTAGE_API_KEY=votre_cle_api_ici
export POSTGRES_HOST=localhost
export POSTGRES_DB=pea_advisor
# ... autres variables

n8n start
```

**Windows (PowerShell):**
```powershell
$env:ALPHA_VANTAGE_API_KEY="votre_cle_api_ici"
n8n start
```

---

### Option 3: Node "Set" au Début du Workflow

**✅ Avantages**: Centralisé dans le workflow
**❌ Inconvénients**: Visible dans le workflow, doit être dupliqué

**Comment faire:**

1. **Ajouter un node "Set"** après le trigger:
   - Type: `n8n-nodes-base.set`
   - Position: Juste après "Déclencheur Quotidien"

2. **Configurer le node:**
   ```json
   {
     "parameters": {
       "mode": "manual",
       "fields": {
         "values": [
           {
             "name": "ALPHA_VANTAGE_API_KEY",
             "value": "votre_cle_api_ici"
           }
         ]
       }
     }
   }
   ```

3. **Dans l'URL du HTTP Request:**
   ```
   apikey={{ $('Set Variables').item.json.ALPHA_VANTAGE_API_KEY }}
   ```

---

### Option 4: Credentials n8n (Le Plus Propre)

**✅ Avantages**: Le plus sécurisé, natif n8n, UI dédiée
**❌ Inconvénients**: Plus complexe à configurer

#### Étape 1: Créer un Credential Type Personnalisé

Dans n8n, il n'y a pas de credential type natif pour Alpha Vantage. On va utiliser **"Header Auth"**.

1. Dans n8n: **Settings** → **Credentials**
2. Cliquer sur **"Create New"**
3. Chercher **"Header Auth"**
4. Configurer:
   - **Name**: `Alpha Vantage API`
   - **Header Name**: `X-API-KEY` (ou laisser vide si on l'ajoute dans l'URL)
   - **Header Value**: `votre_cle_api_ici`

#### Étape 2: Méthode Alternative - Generic Credential

1. Créer un credential **"HTTP Header Auth"**
2. Ou utiliser **"Generic Credential"** avec des champs personnalisés

#### Étape 3: Utiliser dans le Workflow

Malheureusement, comme Alpha Vantage utilise un **query parameter** (pas un header), cette méthode est moins pratique.

**Solution hybride**: Créer un credential et l'utiliser avec une expression:
1. Créer un credential de type "Generic Credential"
2. Ajouter un champ: `apiKey`
3. Dans l'URL: `apikey={{ $credentials.alphaVantageApi.apiKey }}`

---

## 🎯 Recommandation par Cas d'Usage

| Cas | Solution Recommandée |
|-----|----------------------|
| **Test rapide** | Option 1: Directement dans l'URL |
| **Production** | Option 2: Variables d'environnement Docker |
| **Multiple workflows** | Option 2 ou 4: Variables env ou Credentials |
| **Sécurité maximale** | Option 4: Credentials n8n |

## 🔒 Bonnes Pratiques de Sécurité

### ✅ À FAIRE

1. **Ne jamais commiter les API keys** dans Git
2. **Utiliser `.gitignore`** pour exclure les fichiers sensibles
3. **Rotations régulières** des API keys
4. **Limiter les permissions** des API keys quand possible
5. **Monitoring des usages** API pour détecter les abus

### ❌ À ÉVITER

1. ❌ Hardcoder les API keys dans les workflows
2. ❌ Partager les API keys par email/chat
3. ❌ Utiliser la même API key pour dev et prod
4. ❌ Commiter les credentials dans Git
5. ❌ Laisser les API keys dans les logs

## 📝 Exemple de Configuration Complète

### docker-compose.yml

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # Base de données
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}

      # APIs Financières
      - ALPHA_VANTAGE_API_KEY=${ALPHA_VANTAGE_API_KEY}
      - YAHOO_FINANCE_API_KEY=${YAHOO_FINANCE_API_KEY:-}

      # PEA Advisor Database
      - PEA_POSTGRES_HOST=pea-postgres
      - PEA_POSTGRES_DB=pea_advisor
      - PEA_POSTGRES_USER=postgres
      - PEA_POSTGRES_PASSWORD=${PEA_POSTGRES_PASSWORD}

      # n8n Configuration
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=Europe/Paris

    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - pea-postgres

  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data

  pea-postgres:
    image: postgres:15
    restart: unless-stopped
    ports:
      - "5433:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${PEA_POSTGRES_PASSWORD}
      - POSTGRES_DB=pea_advisor
    volumes:
      - pea_postgres_data:/var/lib/postgresql/data
      - ./database/schema.sql:/docker-entrypoint-initdb.d/schema.sql

volumes:
  n8n_data:
  postgres_data:
  pea_postgres_data:
```

### .env (pour docker-compose)

```bash
# N8N
N8N_USER=admin
N8N_PASSWORD=secure_password_here
WEBHOOK_URL=https://n8n01.dataforsciences.best

# Databases
POSTGRES_PASSWORD=n8n_db_password
PEA_POSTGRES_PASSWORD=pea_db_password

# APIs
ALPHA_VANTAGE_API_KEY=your_alpha_vantage_key
YAHOO_FINANCE_API_KEY=
```

## 🧪 Vérifier que les Variables sont Chargées

Dans n8n, créer un workflow de test:

1. **Trigger Manuel**
2. **Node Code (JavaScript)**:
   ```javascript
   return {
     json: {
       alpha_key: $env.ALPHA_VANTAGE_API_KEY,
       postgres_host: $env.PEA_POSTGRES_HOST,
       all_env: Object.keys(process.env)
     }
   };
   ```
3. **Exécuter** et vérifier que les variables sont présentes

## 📚 Ressources

- [n8n Environment Variables](https://docs.n8n.io/hosting/environment-variables/)
- [n8n Credentials](https://docs.n8n.io/credentials/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Date de création**: 3 janvier 2026
**Dernière mise à jour**: 3 janvier 2026
**Statut**: ✅ Validé
