# Architecture Workflow avec Python et Node Merge

## 🎯 Objectif

Ce document explique la nouvelle architecture du workflow `01-daily-market-data-collector` utilisant Python avec un node Merge pour combiner les données.

## 📊 Schéma du Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Déclencheur Quotidien (18h, lun-ven)                     │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Récupérer les actions (PostgreSQL)                       │
│    SELECT id, ticker, name FROM stocks                      │
│    WHERE is_pea_eligible = true AND is_active = true        │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌──────────────────────┐   ┌──────────────────────┐
│ 3a. Yahoo Finance    │   │ 3b. Passer données   │
│     API              │   │     stock directes   │
│     (HTTP Request)   │   │     vers Merge       │
└──────┬───────────────┘   └───────┬──────────────┘
       │                           │
       └────────────┬──────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 4. Combiner données      │
       │    (Merge by position)   │
       │    Input 1: stocks       │
       │    Input 2: Yahoo API    │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 5. Parser Python         │
       │    Accès à _item['json'] │
       │    (stocks + Yahoo data) │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 6. Filtrer succès        │
       │    success == true       │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 7. Insérer en BDD        │
       │    INSERT stock_prices   │
       └────────────┬─────────────┘
                    ▼
       ┌──────────────────────────┐
       │ 8. Log succès            │
       │    INSERT system_logs    │
       └──────────────────────────┘
```

## 🔧 Configuration des Nodes

### Node 1: Déclencheur Quotidien
```json
{
  "type": "n8n-nodes-base.scheduleTrigger",
  "parameters": {
    "rule": {
      "interval": [{
        "field": "cronExpression",
        "expression": "0 18 * * 1-5"
      }]
    }
  }
}
```
- **Fréquence**: Tous les jours de semaine à 18h
- **Timezone**: Heure locale du serveur

### Node 2: Récupérer les actions
```json
{
  "type": "n8n-nodes-base.postgres",
  "parameters": {
    "operation": "executeQuery",
    "query": "SELECT id, ticker, name FROM stocks WHERE is_pea_eligible = true AND is_active = true ORDER BY ticker;"
  }
}
```
- **Output**: Array d'items, chaque item contient `{id, ticker, name}`
- **Ordre**: Trié par ticker pour assurer la cohérence avec le Merge

### Node 3a: Yahoo Finance API
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "=https://query1.finance.yahoo.com/v8/finance/chart/{{ $json.ticker }}?interval=1d&range=1d",
    "options": {
      "timeout": 10000,
      "batchSize": 1,
      "batchInterval": 2000
    }
  }
}
```
- **Input**: Items depuis "Récupérer les actions"
- **URL dynamique**: Utilise `{{ $json.ticker }}` de chaque item
- **Rate limiting**: 1 requête toutes les 2 secondes
- **Output**: Réponses JSON de Yahoo Finance

### Node 3b: Branche directe
- Les données des stocks passent directement au node Merge (Input 1)
- Connexion parallèle depuis "Récupérer les actions"

### Node 4: Combiner données (CRUCIAL!)
```json
{
  "type": "n8n-nodes-base.merge",
  "parameters": {
    "mode": "combine",
    "combinationMode": "mergeByPosition"
  }
}
```
- **Mode**: `combine` - Fusionne deux flux d'items
- **Combination Mode**: `mergeByPosition` - Associe items par position (index)
- **Input 1** (index 0): Données stocks originales
- **Input 2** (index 1): Réponses Yahoo Finance
- **Output**: Items fusionnés contenant les deux sources

**Exemple d'item fusionné:**
```json
{
  "json": {
    "id": 1,
    "ticker": "MC.PA",
    "name": "LVMH",
    "chart": {
      "result": [{
        "timestamp": [1704326400],
        "indicators": {
          "quote": [{
            "open": [745.20],
            "high": [752.30],
            "close": [748.50],
            ...
          }]
        }
      }]
    }
  }
}
```

### Node 5: Parser Python
```python
from datetime import datetime

# Récupérer les données combinées depuis le Merge
# IMPORTANT: Utiliser _item (avec underscore) en Python n8n
merged_data = _item['json']

# Extraire les informations du stock
stock_info = {
    'id': merged_data.get('id'),
    'ticker': merged_data.get('ticker'),
    'name': merged_data.get('name')
}

# Les données Yahoo Finance sont aussi dans merged_data
yahoo_response = merged_data

try:
    # Parser les données Yahoo Finance
    if yahoo_response.get('chart') and yahoo_response['chart'].get('result'):
        chart = yahoo_response['chart']['result'][0]
        quote = chart['indicators']['quote'][0]
        timestamp = chart['timestamp'][0]

        # Convertir timestamp en date
        date = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d')

        # Récupérer adjusted close
        adj_close_data = chart['indicators'].get('adjclose')
        adjusted_close = adj_close_data[0]['adjclose'][0] if adj_close_data else quote['close'][0]

        return {
            'json': {
                'stock_id': stock_info['id'],
                'ticker': stock_info['ticker'],
                'name': stock_info['name'],
                'date': date,
                'open': quote['open'][0],
                'high': quote['high'][0],
                'low': quote['low'][0],
                'close': quote['close'][0],
                'volume': quote['volume'][0],
                'adjusted_close': adjusted_close,
                'success': True
            }
        }
except Exception as error:
    return {
        'json': {
            'stock_id': stock_info.get('id'),
            'ticker': stock_info.get('ticker', 'error'),
            'name': stock_info.get('name', 'error'),
            'success': False,
            'error': str(error)
        }
    }
```

**Variables Python disponibles:**
- `_item`: L'item courant (contenant données fusionnées) - **AVEC underscore!**
- `_items`: Tous les items (en mode "all items")
- `_input`: Objet d'entrée complet
- ⚠️ Pas d'accès à `$itemIndex` ou `$node`

**Note importante**: Voir `/docs/python-variables-n8n.md` pour le guide complet sur `_item` vs `item`

## ✅ Avantages de cette Architecture

### 1. **Python Pur**
- Pas de syntaxe spéciale `$itemIndex` ou `$node`
- Code Python standard et portable
- Plus facile à tester en dehors de n8n

### 2. **Clarté**
- Flux de données explicite et visuel
- Le node Merge montre clairement la fusion des données
- Debugging plus facile

### 3. **Maintenabilité**
- Séparation claire des responsabilités
- Chaque node a un rôle unique
- Modifications localisées

### 4. **Testabilité**
- Le code Python peut être testé avec `scripts/test-python-parser.py`
- Mock data facile à créer
- Pas de dépendance aux variables n8n spéciales

## ⚠️ Points d'Attention

### Ordre des Items
Le `mergeByPosition` associe les items par leur **position** dans les arrays:
- Item 0 du flux 1 + Item 0 du flux 2 = Item fusionné 0
- Item 1 du flux 1 + Item 1 du flux 2 = Item fusionné 1
- etc.

**Important**: Les deux flux doivent avoir:
- Le même nombre d'items
- Le même ordre (d'où le `ORDER BY ticker` dans la requête SQL)

### Gestion des Erreurs
Si Yahoo Finance échoue pour une action:
- L'item fusionné contiendra une erreur
- Le parser Python doit gérer ce cas
- Le filtre "Filtrer succès" éliminera les échecs

### Performance
- Le HTTP Request traite les items séquentiellement (batchSize: 1)
- Délai de 2 secondes entre chaque requête (rate limiting)
- Pour 50 actions: ~100 secondes de traitement

## 🧪 Tests

### Test Manuel dans n8n
1. Importer le workflow dans n8n
2. Désactiver le trigger automatique
3. Exécuter manuellement avec 2-3 actions test
4. Vérifier les données dans chaque node:
   - Après "Récupérer les actions": Voir les stocks
   - Après "Yahoo Finance API": Voir les réponses brutes
   - Après "Combiner données": **Vérifier la fusion!**
   - Après "Parser Python": Voir les données parsées

### Test avec Script Python
```bash
python3 scripts/test-python-parser.py
```

## 📚 Ressources

- [n8n Merge Node Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.merge/)
- [n8n Python Code Examples](https://docs.n8n.io/code-examples/python/)
- Guide de migration: `/docs/python-migration-guide.md`

## 🔄 Comparaison avec l'Ancienne Version

| Aspect | Ancienne (JS) | Nouvelle (Python + Merge) |
|--------|---------------|---------------------------|
| Langage | JavaScript | Python |
| Accès aux données | `$node['nom']`, `$itemIndex` | `item` uniquement |
| Complexité | Moyenne | Simple |
| Nodes | 6 | 8 (+2 pour Merge) |
| Testabilité | Difficile | Facile |
| Performance | Identique | Identique |

---

**Date de création**: 3 janvier 2026
**Version workflow**: 1.1
**Statut**: ✅ Prêt pour tests
