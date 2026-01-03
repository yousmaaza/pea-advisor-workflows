# Workflow 02 - News Collector (NewsAPI)

## 🎯 Objectif

Ce workflow collecte automatiquement les actualités financières pour chaque action du portefeuille via l'API NewsAPI et les stocke dans PostgreSQL pour analyse ultérieure par l'IA.

## 📊 Architecture du Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Déclencheur Toutes les 4h                                │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Récupérer les actions (PostgreSQL)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────────┐   ┌──────────────────────┐
│ 3. NewsAPI Request   │   │ Passer données       │
│    (5 articles/stock)│   │ stock directes       │
└──────┬───────────────┘   └───────┬──────────────┘
       │                           │
       └────────────┬──────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 4. Combiner données      │
       │    (Merge by position)   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 5. Parser News Python    │
       │    Crée 1 item/article   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 6. Filtrer succès        │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 7. Insérer en BDD        │
       │    Table: news           │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 8. Log succès            │
       └──────────────────────────┘
```

## 🔑 Configuration NewsAPI

### Obtenir une API Key

1. Aller sur https://newsapi.org/
2. Créer un compte gratuit
3. Récupérer votre API key

### Limites de la Version Gratuite

- **100 requêtes par jour**
- **Articles limités aux 30 derniers jours**
- **Délai de ~15 minutes** sur les dernières actualités
- Pas d'accès commercial

### Calcul pour le Workflow

```
50 actions × 4 exécutions/jour = 200 requêtes/jour
→ Limite dépassée! 😱

Solution: Limiter les exécutions ou upgrader
```

**Recommandations:**
- **Option 1**: Exécuter 2 fois par jour (9h et 18h) = 100 requêtes ✅
- **Option 2**: Version développeur ($449/mois) = illimité
- **Option 3**: Limiter à 25 actions par exécution

## 📡 API NewsAPI

### Endpoint Utilisé

```
GET https://newsapi.org/v2/everything
?q={NOM_ENTREPRISE}
&language=fr
&sortBy=publishedAt
&pageSize=5
&apiKey={API_KEY}
```

### Paramètres

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `q` | Nom de l'entreprise | "LVMH", "Total Energies", etc. |
| `language` | `fr` | Articles en français |
| `sortBy` | `publishedAt` | Plus récents en premier |
| `pageSize` | `5` | 5 articles par action |
| `apiKey` | Votre clé | API key gratuite |

### Réponse Type

```json
{
  "status": "ok",
  "totalResults": 127,
  "articles": [
    {
      "source": {"id": null, "name": "Les Échos"},
      "author": "Jean Dupont",
      "title": "LVMH dépasse les attentes au T4",
      "description": "Le géant du luxe...",
      "url": "https://...",
      "publishedAt": "2024-01-03T10:30:00Z",
      "content": "Le groupe LVMH a publié..."
    }
  ]
}
```

## 🐍 Code Python du Parser

### Fonctionnalités

Le parser Python:
1. ✅ Parse les articles depuis NewsAPI
2. ✅ Crée **un item par article** (expansion)
3. ✅ Convertit les dates au format PostgreSQL
4. ✅ Échappe les quotes dans les textes
5. ✅ Gère les erreurs API

### Code Simplifié

```python
from datetime import datetime

merged_data = _item['json']
stock_info = {'id': merged_data.get('id'), ...}
news_response = merged_data

results = []

# Pour chaque article trouvé
for article in news_response.get('articles', []):
    published_at = article.get('publishedAt')
    published_date = datetime.strptime(published_at, '%Y-%m-%dT%H:%M:%SZ')

    article_data = {
        'stock_id': stock_info['id'],
        'title': article.get('title'),
        'description': article.get('description'),
        'content': article.get('content'),
        'url': article.get('url'),
        'source': article['source']['name'],
        'published_at': published_date.strftime('%Y-%m-%d %H:%M:%S'),
        'success': True
    }
    results.append({'json': article_data})

return results  # Retourne plusieurs items!
```

### ⚠️ Particularité: Expansion des Items

Contrairement aux workflows précédents qui retournent **1 item par action**, celui-ci retourne **5 items par action** (1 par article).

**Exemple:**
- Input: 10 actions
- NewsAPI: 5 articles/action
- Output: **50 items** (articles)

## 💾 Insertion en Base de Données

### Table: `news`

```sql
INSERT INTO news (
    stock_id,
    title,
    description,
    content,
    url,
    source,
    published_at,
    created_at
)
VALUES (
    $stock_id,
    $title,
    $description,
    $content,
    $url,
    $source,
    $published_at,
    CURRENT_TIMESTAMP
)
ON CONFLICT (url) DO NOTHING  -- Évite les doublons
RETURNING id, stock_id, title;
```

**Champs analysés plus tard par l'IA:**
- `sentiment_score` - Score de sentiment (-10 à +10)
- `sentiment_label` - negative/neutral/positive
- `impact_score` - Impact estimé (0 à 10)
- `ai_summary` - Résumé généré par l'IA
- `ai_key_points` - Points clés (JSON)

## ⚙️ Configuration du Workflow

### Horaire d'Exécution

**Option 1: 2 fois par jour** (Recommandé pour version gratuite)
```cron
0 9,18 * * *  # 9h et 18h chaque jour
```

**Option 2: Toutes les 4h** (Nécessite version payante)
```cron
0 */4 * * *  # Toutes les 4 heures
```

### Rate Limiting

```json
{
  "batchSize": 1,
  "batchInterval": 2000,
  "timeout": 15000
}
```

- **Délai**: 2 secondes entre requêtes
- **Timeout**: 15 secondes max par requête

### Gestion d'Erreurs

Le workflow gère:
- ✅ Rate limit API dépassé
- ✅ Aucun article trouvé
- ✅ Erreurs de parsing
- ✅ Doublons d'URL (via `ON CONFLICT`)

## 🧪 Tests

### Test Manuel

1. **Obtenir l'API key** NewsAPI (gratuite)
2. **Modifier le workflow** dans n8n:
   - Remplacer `VOTRE_CLE_API_ICI` par votre clé
   - Limiter à 3 actions pour tester:
     ```sql
     SELECT id, ticker, name
     FROM stocks
     WHERE is_pea_eligible = true
     LIMIT 3;
     ```

3. **Exécuter manuellement**
4. **Vérifier les résultats**

### Vérifier les News Collectées

```sql
-- Voir les dernières news
SELECT
    s.ticker,
    n.title,
    n.source,
    n.published_at,
    n.created_at
FROM news n
JOIN stocks s ON s.id = n.stock_id
ORDER BY n.published_at DESC
LIMIT 20;
```

### Vérifier les Doublons

```sql
-- Compter les articles par action
SELECT
    s.ticker,
    s.name,
    COUNT(*) as nb_articles
FROM news n
JOIN stocks s ON s.id = n.stock_id
WHERE n.created_at > CURRENT_DATE - INTERVAL '7 days'
GROUP BY s.ticker, s.name
ORDER BY nb_articles DESC;
```

## 📊 Statistiques Attendues

### Pour 50 Actions

| Fréquence | Requêtes/jour | Articles/jour | BDD Growth |
|-----------|---------------|---------------|------------|
| 2x/jour | 100 | ~250 articles | ~50 KB/jour |
| 4x/jour | 200 | ~500 articles | ~100 KB/jour |
| 6x/jour | 300 | ~750 articles | ~150 KB/jour |

**Note**: NewsAPI ne retourne que les articles **pertinents**, donc moins de 5 articles/action en pratique.

## 🔄 Workflow Suivant: Analyse Sentiment IA

Une fois les news collectées, le **Workflow 08: AI News Analyzer** va:

1. Lire les articles sans sentiment
   ```sql
   SELECT * FROM news
   WHERE sentiment_score IS NULL
   LIMIT 50;
   ```

2. Analyser avec OpenAI/Claude
3. Mettre à jour les champs sentiment

## ⚠️ Points d'Attention

### Rate Limit NewsAPI Gratuit

- **100 requêtes/jour** maximum
- **Solution**: Réduire la fréquence ou upgrader

### Pertinence des Résultats

NewsAPI recherche par **nom d'entreprise**. Problèmes possibles:
- Homonymes (ex: "Orange" → fruit ou entreprise?)
- **Solution**: Affiner la requête avec des mots-clés

### Langue des Articles

- **Paramètre**: `language=fr`
- Mais certains articles peuvent être en anglais

### Délai des Actualités

- Version gratuite: ~15 minutes de délai
- Pas de temps réel!

## 💡 Améliorations Futures

### Alternative Gratuite

Si NewsAPI est trop limité:
- **RSS feeds** des médias financiers
- **Google News RSS** (gratuit, illimité)
- **Scraping** (Les Échos, Le Figaro Bourse, etc.)

### Filtrage Avancé

Ajouter un node pour filtrer:
- Articles trop courts (< 100 caractères)
- Sources peu fiables
- Articles trop anciens (> 7 jours)

### Dédoublonnage Intelligent

Détecter les articles similaires:
```python
from difflib import SequenceMatcher

def are_similar(title1, title2):
    return SequenceMatcher(None, title1, title2).ratio() > 0.8
```

## 📚 Ressources

- [NewsAPI Documentation](https://newsapi.org/docs)
- [NewsAPI Pricing](https://newsapi.org/pricing)
- [Liste des sources](https://newsapi.org/sources)

---

**Date de création**: 3 janvier 2026
**Version**: 1.0
**Statut**: ✅ Prêt pour tests
