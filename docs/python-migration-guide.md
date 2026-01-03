# Migration JavaScript → Python dans le Workflow

## 🎯 Objectif

Ce document explique la migration du node "Parser réponse" du workflow `01-daily-market-data-collector` de JavaScript vers Python.

## ✅ Changements Effectués

### 1. Configuration du Node

**Avant (JavaScript):**
```json
{
  "parameters": {
    "jsCode": "..."
  }
}
```

**Après (Python):**
```json
{
  "parameters": {
    "language": "python",
    "pythonCode": "..."
  }
}
```

### 2. Syntaxe des Variables n8n

| JavaScript | Python | Description |
|------------|--------|-------------|
| `$input.item.json` | `_input.item.json` | Données d'entrée |
| `$itemIndex` | `_item_index` | Index de l'item |
| `$node['nom'].json` | `_node['nom'].json` | Accès aux nodes précédents |
| `$json` | Accès direct via dict | Variable JSON courante |

### 3. Code Converti

**JavaScript Original:**
```javascript
const yahooResponse = $input.item.json;
const itemIndex = $itemIndex;
const allStocks = $node['Récupérer les actions'].json;
const stockInfo = allStocks[itemIndex];

try {
  if (yahooResponse.chart && yahooResponse.chart.result && yahooResponse.chart.result[0]) {
    const chart = yahooResponse.chart.result[0];
    const quote = chart.indicators.quote[0];
    const timestamp = chart.timestamp[0];

    const date = new Date(timestamp * 1000).toISOString().split('T')[0];

    return {
      json: {
        stock_id: stockInfo.id,
        ticker: stockInfo.ticker,
        // ...
      }
    };
  }
}
```

**Python Équivalent:**
```python
from datetime import datetime

yahoo_response = _input.item.json
item_index = _item_index
all_stocks = _node['Récupérer les actions'].json
stock_info = all_stocks[item_index]

try:
    if yahoo_response.get('chart') and yahoo_response['chart'].get('result'):
        chart = yahoo_response['chart']['result'][0]
        quote = chart['indicators']['quote'][0]
        timestamp = chart['timestamp'][0]

        date = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d')

        return {
            'json': {
                'stock_id': stock_info['id'],
                'ticker': stock_info['ticker'],
                # ...
            }
        }
```

## 🔑 Différences Clés

### 1. Gestion des Timestamps

**JavaScript:**
```javascript
new Date(timestamp * 1000).toISOString().split('T')[0]
```

**Python:**
```python
datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d')
```

### 2. Vérification d'Existence

**JavaScript:**
```javascript
chart.indicators.adjclose ? chart.indicators.adjclose[0].adjclose[0] : quote.close[0]
```

**Python:**
```python
adj_close_data = chart['indicators'].get('adjclose')
if adj_close_data and len(adj_close_data) > 0 and adj_close_data[0].get('adjclose'):
    adjusted_close = adj_close_data[0]['adjclose'][0]
else:
    adjusted_close = quote['close'][0]
```

### 3. Gestion des Erreurs

**JavaScript:**
```javascript
catch (error) {
  error.message
}
```

**Python:**
```python
except Exception as error:
    str(error)
```

## 🧪 Tests

Un script de test a été créé: `scripts/test-python-parser.py`

### Exécuter les tests:
```bash
python3 scripts/test-python-parser.py
```

### Tests inclus:
1. ✅ Parsing d'une réponse valide
2. ✅ Réponse vide (gestion d'erreur)
3. ✅ Réponse sans adjusted close
4. ✅ Exceptions et erreurs

## 📋 Checklist de Déploiement

Avant d'importer le workflow modifié dans n8n:

- [ ] Vérifier que Python est installé sur le serveur n8n
- [ ] Tester le workflow avec 1-2 actions d'abord
- [ ] Vérifier les logs n8n pour détecter d'éventuelles erreurs
- [ ] Comparer les résultats avec l'ancienne version JS
- [ ] Monitorer la performance (Python peut être légèrement plus lent)

## ⚠️ Points d'Attention

### Performance
- Python dans n8n peut être 10-20% plus lent que JavaScript
- Pour ce workflow (1x par jour), l'impact est négligeable
- Pour des workflows en temps réel, considérer l'impact

### Bibliothèques
- `datetime` est disponible par défaut
- Pour des bibliothèques externes (pandas, numpy), vérifier qu'elles sont installées sur n8n

### Débogage
- Utiliser `print()` en Python pour déboguer (visible dans les logs n8n)
- En JavaScript, utilisez `console.log()`

## 🚀 Prochaines Étapes

1. **Importer le workflow dans n8n**
   - Aller sur https://n8n01.dataforsciences.best/
   - Importer le fichier JSON modifié
   - Vérifier que le node Python est bien configuré

2. **Tester manuellement**
   - Lancer le workflow manuellement
   - Vérifier les données insérées en BDD
   - Comparer avec les résultats précédents

3. **Activer en production**
   - Une fois validé, activer le workflow
   - Monitorer les premières exécutions automatiques

## 📚 Ressources

- [n8n Code Node Documentation](https://docs.n8n.io/code-examples/javascript/)
- [Python in n8n](https://docs.n8n.io/code-examples/python/)
- [Yahoo Finance API](https://finance.yahoo.com/)

## 🔄 Retour en Arrière

Si nécessaire, la version JavaScript originale est disponible dans l'historique Git:

```bash
git log --oneline workflows/data-collection/01-daily-market-data-collector.json
git show <commit-hash>:workflows/data-collection/01-daily-market-data-collector.json
```

---

**Date de migration**: 3 janvier 2026
**Version**: 1.1
**Statut**: ✅ Prêt pour tests
