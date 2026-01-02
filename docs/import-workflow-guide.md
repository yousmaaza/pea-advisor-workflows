# 📥 Guide d'Import des Workflows dans n8n

## 🎯 Objectif

Ce guide explique comment importer et configurer le premier workflow dans votre instance n8n.

---

## ✅ Prérequis

Avant d'importer le workflow :

- [x] n8n accessible sur https://n8n01.dataforsciences.best/
- [x] PostgreSQL configuré et opérationnel
- [x] Base de données `pea_advisor` créée avec les tables
- [x] Au moins 1 action dans la table `stocks`

---

## 📥 Étape 1 : Créer les Credentials PostgreSQL

### Dans n8n

1. **Accéder aux Credentials**
   - Ouvrir n8n : https://n8n01.dataforsciences.best/
   - Menu latéral → **"Credentials"**
   - Cliquer sur **"+ Add Credential"**

2. **Sélectionner PostgreSQL**
   - Chercher "PostgreSQL"
   - Cliquer dessus

3. **Configurer la connexion**

   ```
   Credential Name: PostgreSQL PEA Advisor

   Connection:
   ├─ Host: postgres
   ├─ Database: pea_advisor
   ├─ User: root
   ├─ Password: 3e06831d498324ea8b0b5bc8a72bc5d0
   ├─ Port: 5432
   └─ SSL Mode: disable
   ```

   **⚠️ IMPORTANT** : Le Host doit être `postgres` (nom du conteneur Docker), PAS `localhost` !

4. **Tester la connexion**
   - Cliquer sur **"Test Connection"**
   - Doit afficher "Connection successful" ✅

5. **Sauvegarder**
   - Cliquer sur **"Save"**

---

## 📤 Étape 2 : Importer le Workflow

### Méthode 1 : Import via l'interface (Recommandé)

1. **Accéder à l'import**
   - Dans n8n, cliquer sur **"+"** en haut à gauche
   - Sélectionner **"Import from File"**

2. **Sélectionner le fichier**
   - Naviguer vers votre dossier projet
   - Aller dans `pea-advisor-workflows/workflows/data-collection/`
   - Sélectionner `01-daily-market-data-collector.json`
   - Cliquer sur **"Open"**

3. **Le workflow s'ouvre automatiquement**

### Méthode 2 : Copier-Coller (Alternative)

1. **Copier le contenu**
   ```bash
   cat pea-advisor-workflows/workflows/data-collection/01-daily-market-data-collector.json
   ```

2. **Dans n8n**
   - Cliquer sur **"+"** → **"Import from File"**
   - Ou utiliser **Ctrl+I** (Windows/Linux) / **Cmd+I** (Mac)
   - Coller le JSON
   - Cliquer sur **"Import"**

---

## 🔧 Étape 3 : Configurer le Workflow

### 3.1 Vérifier les Credentials

Le workflow utilise PostgreSQL dans plusieurs nœuds. Pour chacun :

1. **Nœud "Récupérer les actions"**
   - Cliquer dessus
   - Section "Credential to connect with"
   - Sélectionner **"PostgreSQL PEA Advisor"**

2. **Répéter pour** :
   - Nœud "Insérer en BDD"
   - Nœud "Logger l'erreur"
   - Nœud "Log final"

### 3.2 Adapter le déclencheur (optionnel)

Par défaut : **18h du lundi au vendredi**

Pour modifier :
1. Cliquer sur le nœud **"Déclencheur Quotidien"**
2. Modifier l'expression cron
3. Exemples :
   - `0 8 * * 1-5` → 8h en semaine
   - `0 20 * * *` → 20h tous les jours
   - `0 12 * * 1-5` → 12h en semaine

---

## ✅ Étape 4 : Sauvegarder le Workflow

1. **Sauvegarder**
   - Cliquer sur **"Save"** en haut à droite
   - Ou **Ctrl+S** / **Cmd+S**

2. **Renommer** (optionnel)
   - Cliquer sur le nom du workflow en haut
   - Renommer si nécessaire
   - Ex: "PEA - Collecte Prix Quotidiens"

---

## 🧪 Étape 5 : Test manuel

### Test complet du workflow

1. **Exécuter manuellement**
   - Cliquer sur **"Execute Workflow"** en haut à droite
   - Observer l'exécution de chaque nœud

2. **Vérifier les résultats**

   Les nœuds doivent s'exécuter dans cet ordre :
   ```
   ✅ Déclencheur Quotidien
   ✅ Récupérer les actions (retourne 10 actions)
   ✅ Traiter une par une
   ✅ Yahoo Finance API (pour chaque action)
   ✅ Extraire les données
   ✅ Données valides ?
   ✅ Insérer en BDD
   ✅ Attendre (rate limit)
   ✅ [Boucle sur les 10 actions]
   ✅ Agréger les résultats
   ✅ Log final
   ```

3. **Durée attendue**
   - Pour 10 actions : ~15-20 secondes
   - 1.2s par action (rate limit)

### Vérifier dans PostgreSQL

Ouvrir pgAdmin (http://localhost:5050) ou psql :

```sql
-- Voir les prix collectés
SELECT s.ticker, sp.date, sp.close
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
ORDER BY sp.date DESC, s.ticker;

-- Doit retourner 10 lignes (1 par action)
```

---

## 🚀 Étape 6 : Activer l'exécution automatique

1. **Activer le workflow**
   - Toggle "Active" en haut à droite
   - Doit passer au vert ✅

2. **Vérifier le planning**
   - Le workflow s'exécutera automatiquement à 18h chaque jour ouvré

3. **Voir les exécutions**
   - Menu **"Executions"** dans la barre latérale
   - Historique de toutes les exécutions

---

## 🔍 Troubleshooting

### Problème 1 : "Connection refused" PostgreSQL

**Cause** : Mauvais hostname

**Solution** :
```
❌ Host: localhost
✅ Host: postgres
```

### Problème 2 : "Credential not found"

**Cause** : Credentials mal liées

**Solution** :
1. Vérifier que la credential "PostgreSQL PEA Advisor" existe
2. Dans chaque nœud PostgreSQL, sélectionner la bonne credential

### Problème 3 : "No data returned" depuis stocks

**Cause** : Table vide

**Solution** :
```sql
-- Vérifier qu'il y a des actions
SELECT * FROM stocks WHERE is_active = true;

-- Si vide, elles ont été insérées normalement lors du schema.sql
-- Vérifier la connexion à la bonne BDD
```

### Problème 4 : Yahoo Finance timeout

**Cause** : Problème réseau ou ticker invalide

**Solution** :
1. Vérifier la connexion internet
2. Tester manuellement : https://finance.yahoo.com/quote/MC.PA
3. Augmenter le timeout dans le nœud HTTP Request

### Problème 5 : Workflow ne se déclenche pas

**Cause** : Pas activé ou mauvais timezone

**Solution** :
1. Vérifier que le toggle "Active" est vert
2. Vérifier le timezone de n8n (doit être Europe/Paris)
3. Variable d'environnement : `TZ=Europe/Paris`

---

## 📊 Voir les résultats

### Dans n8n

**Executions** :
- Menu latéral → **"Executions"**
- Voir l'historique complet
- Cliquer sur une exécution pour voir les détails

### Dans PostgreSQL

```sql
-- Statistiques de collecte
SELECT
    (details->>'total_stocks')::int as total,
    (details->>'successful')::int as success,
    (details->>'errors')::int as errors,
    created_at
FROM system_logs
WHERE workflow_name = 'daily-market-data-collector'
  AND level = 'info'
ORDER BY created_at DESC
LIMIT 10;

-- Prix collectés aujourd'hui
SELECT s.ticker, sp.close, sp.volume
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
WHERE sp.date = CURRENT_DATE
ORDER BY s.ticker;
```

---

## ✅ Checklist finale

Avant de considérer le workflow prêt :

- [ ] Credentials PostgreSQL créées et testées
- [ ] Workflow importé dans n8n
- [ ] Tous les nœuds liés aux bonnes credentials
- [ ] Test manuel réussi (Execute Workflow)
- [ ] Données visibles dans PostgreSQL
- [ ] Workflow activé (toggle vert)
- [ ] Première exécution programmée visible dans "Executions"

---

## 🎯 Prochaines étapes

Maintenant que le workflow de collecte fonctionne :

1. **Laisser collecter pendant quelques jours** pour avoir de l'historique
2. **Vérifier quotidiennement** que les données arrivent
3. **Préparer le workflow 04** (analyse technique) qui utilisera ces données

---

## 📚 Ressources

- **Documentation workflow** : [docs/workflow-01-guide.md](workflow-01-guide.md)
- **Documentation n8n** : https://docs.n8n.io/
- **PostgreSQL via pgAdmin** : http://localhost:5050

---

**Créé le** : 2 janvier 2026
**Version** : 1.0
