# 🔧 Troubleshooting - Workflow 01 qui s'arrête

## ❌ Problème : Le workflow s'arrête à "Traiter une par une"

### Symptôme
Le workflow s'exécute mais s'arrête au nœud "Traiter une par une" (Split in Batches) et ne continue pas.

### Cause
Le nœud "Split in Batches" dans n8n nécessite une configuration spéciale de la boucle. La connexion entre "Attendre (rate limit)" et "Traiter une par une" doit être faite d'une manière particulière.

---

## ✅ Solution 1 : Utiliser la version simplifiée (RECOMMANDÉ)

La version 2 du workflow est plus simple et ne nécessite pas de Split in Batches.

### Étapes

1. **Importer le nouveau workflow**
   ```
   workflows/data-collection/01-daily-market-data-collector-v2.json
   ```

2. **Configurer les credentials PostgreSQL**
   (Même configuration que la v1)

3. **Tester**
   - Execute Workflow
   - Tous les nœuds doivent s'exécuter en séquence

### Avantages de la v2
- ✅ Plus simple (pas de boucle)
- ✅ Un seul nœud Code fait tout le travail
- ✅ Plus facile à déboguer
- ✅ Même résultat final

---

## ✅ Solution 2 : Corriger le workflow actuel

Si vous voulez garder la version avec Split in Batches :

### Dans n8n

1. **Vérifier les connexions du nœud "Attendre (rate limit)"**

   Ce nœud doit avoir **2 sorties** :
   - Une qui retourne vers "Traiter une par une" (INPUT)
   - Une qui va vers "Agréger les résultats" (QUAND FINI)

2. **Reconnecter correctement**

   a. Cliquer sur le nœud "Attendre (rate limit)"

   b. Dans les connections :
   - Main Output → doit aller vers "Traiter une par une" (pour la boucle)

   c. Cliquer sur "Traiter une par une"

   d. Dans Output → "Loop Output" doit être activé

3. **Ajouter un nœud "No Operation" après la boucle**

   Pour récupérer tous les résultats une fois la boucle terminée

---

## 🧪 Test de la version corrigée

### Exécution manuelle

1. Cliquer sur "Execute Workflow"

2. **Vous devriez voir** :
   ```
   ✅ Déclencheur Quotidien (1 item)
   ✅ Récupérer les actions (10 items - toutes les actions)
   ✅ Récupérer tous les prix (traite les 10 en boucle interne)
   ✅ Filtrer succès (10 items si tout va bien)
   ✅ Insérer en BDD (10 insertions)
   ✅ Créer résumé (1 item avec stats)
   ✅ Log succès (1 item)
   ```

3. **Durée attendue** : ~20-25 secondes pour 10 actions

---

## 📊 Vérifier les résultats

### Dans PostgreSQL (pgAdmin)

```sql
-- Voir les prix collectés
SELECT
    s.ticker,
    sp.date,
    sp.close,
    sp.volume
FROM stock_prices sp
JOIN stocks s ON sp.stock_id = s.id
ORDER BY sp.date DESC, s.ticker;
```

**Résultat attendu** : 10 lignes (une par action)

### Vérifier les logs

```sql
SELECT
    message,
    details,
    created_at
FROM system_logs
WHERE workflow_name = 'daily-market-data-collector'
ORDER BY created_at DESC
LIMIT 5;
```

---

## 🔍 Différences entre v1 et v2

| Aspect | Version 1 (Split in Batches) | Version 2 (Code simplifié) |
|--------|------------------------------|----------------------------|
| **Complexité** | Élevée (boucle manuelle) | Simple (tout en un nœud) |
| **Nœuds** | 12 nœuds | 7 nœuds |
| **Debugging** | Difficile | Facile |
| **Performance** | Similaire | Similaire |
| **Fiabilité** | Dépend de la config | ✅ Plus stable |

---

## 🎯 Recommandation

**Utilisez la version 2** (simplifiée) :
- Plus facile à maintenir
- Moins de points de failure
- Même résultat
- Code plus lisible

---

## 📝 Si le problème persiste

### Vérifier les logs n8n

Dans le terminal où n8n tourne :
```bash
docker logs n8n --tail 50
```

### Erreurs courantes

**1. "Cannot read property of undefined"**
→ Problème de parsing Yahoo Finance
→ Vérifier que le ticker existe

**2. "Connection refused" PostgreSQL**
→ Host doit être `postgres`, pas `localhost`

**3. "Timeout"**
→ Yahoo Finance peut rate-limiter
→ Augmenter les délais dans le code

---

## 🚀 Prochaines étapes

Une fois le workflow qui fonctionne :

1. ✅ Laisser collecter pendant quelques jours
2. ✅ Vérifier quotidiennement que les données arrivent
3. ✅ Passer au workflow 04 (analyse technique)

---

**Créé le** : 2 janvier 2026
**Version** : 1.0
