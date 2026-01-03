# Variables Python dans n8n - Guide Complet

## 🔑 Différence entre `item` et `_item`

### ❌ `item` (Sans underscore) - N'EXISTE PAS
```python
# ❌ ERREUR: NameError: name 'item' is not defined
data = item['json']
```

**`item`** sans underscore n'existe pas dans le contexte Python de n8n. C'était une confusion de ma part dans la documentation initiale.

### ✅ `_item` (Avec underscore) - CORRECT
```python
# ✅ CORRECT: Variable Python officielle dans n8n
data = _item['json']
```

**`_item`** avec underscore est la variable officielle fournie par n8n pour accéder à l'item courant en mode "Run Once for Each Item".

## 📋 Variables Python Disponibles dans n8n

### Mode: "Run Once for Each Item"

| Variable | Type | Description | Exemple |
|----------|------|-------------|---------|
| `_item` | dict | L'item courant | `_item['json']['ticker']` |
| `_items` | list | Tous les items d'entrée | `_items[0]['json']` |
| `_input` | object | Objet d'entrée complet | `_input.all()` |

### Mode: "Run Once for All Items"

| Variable | Type | Description | Exemple |
|----------|------|-------------|---------|
| `_items` | list | Tous les items d'entrée | `for item in _items: ...` |
| `_input` | object | Objet d'entrée complet | `_input.all()` |

## 🎯 Exemples Pratiques

### Exemple 1: Accéder aux données de l'item courant
```python
# Accéder à l'item courant (mode "Run Once for Each Item")
merged_data = _item['json']

# Extraire des champs spécifiques
stock_id = _item['json']['id']
ticker = _item['json']['ticker']
name = _item['json']['name']
```

### Exemple 2: Accéder aux métadonnées de l'item
```python
# Accéder au JSON de l'item
json_data = _item['json']

# Accéder aux données binaires (si présentes)
binary_data = _item.get('binary', {})

# Accéder aux métadonnées
pairedItem = _item.get('pairedItem')
```

### Exemple 3: Traiter tous les items (mode "All Items")
```python
# Mode "Run Once for All Items"
results = []

for item in _items:
    ticker = item['json']['ticker']
    close_price = item['json']['close']
    results.append({
        'ticker': ticker,
        'price': close_price
    })

return results
```

### Exemple 4: Accéder à l'input complet
```python
# Récupérer tous les items d'entrée
all_items = _input.all()

# Récupérer le premier item
first_item = _input.first()

# Récupérer le dernier item
last_item = _input.last()

# Nombre d'items
item_count = len(_input.all())
```

## 🔄 Comparaison JavaScript vs Python

| Concept | JavaScript | Python |
|---------|------------|--------|
| Item courant | `$input.item` | `_item` |
| Tous les items | `$input.all()` | `_items` |
| Index de l'item | `$itemIndex` | ❌ Non disponible |
| Accès aux nodes | `$node['nom']` | ❌ Non disponible |
| JSON de l'item | `$json` | `_item['json']` |

## ⚠️ Limitations Python dans n8n

### Variables NON disponibles en Python:

1. **`$itemIndex`**: Pas d'accès à l'index de l'item
   ```python
   # ❌ Ne fonctionne pas
   index = $itemIndex  # NameError
   ```

2. **`$node['nom']`**: Pas d'accès direct aux autres nodes
   ```python
   # ❌ Ne fonctionne pas
   stocks = $node['Récupérer les actions']  # NameError
   ```

3. **`$json`**: Pas de raccourci pour le JSON
   ```python
   # ❌ Ne fonctionne pas
   ticker = $json.ticker  # NameError

   # ✅ Utiliser à la place
   ticker = _item['json']['ticker']
   ```

### Solutions de contournement:

**Problème**: Besoin d'accéder à des données d'un node précédent

**Solution**: Utiliser un node **Merge** pour combiner les données
```
Node A → ┐
         ├→ Merge → Code Python (_item contient les deux sources)
Node B → ┘
```

## 📝 Bonnes Pratiques

### ✅ À FAIRE

```python
# 1. Utiliser _item pour l'item courant
data = _item['json']

# 2. Vérifier l'existence des clés avec .get()
ticker = data.get('ticker', 'N/A')

# 3. Gérer les exceptions
try:
    price = data['close']
except KeyError:
    price = None

# 4. Retourner un dictionnaire avec 'json'
return {
    'json': {
        'ticker': ticker,
        'price': price
    }
}
```

### ❌ À ÉVITER

```python
# 1. N'utilisez pas 'item' sans underscore
data = item['json']  # ❌ NameError

# 2. N'assumez pas que les clés existent
ticker = data['ticker']  # ❌ Peut causer KeyError

# 3. N'utilisez pas de variables JavaScript
index = $itemIndex  # ❌ NameError
stocks = $node['Stocks']  # ❌ NameError

# 4. Ne retournez pas de données sans structure
return price  # ❌ n8n attend un dict avec 'json'
```

## 🧪 Test de Vos Variables

Pour déboguer et voir les variables disponibles:

```python
# Afficher le contenu de _item
print("_item:", _item)

# Afficher les clés disponibles
print("Clés de _item:", _item.keys())

# Afficher le JSON
print("JSON:", _item['json'])

# Afficher tous les items (mode All Items)
print("Nombre d'items:", len(_items))
```

Les `print()` s'affichent dans les logs d'exécution de n8n.

## 📚 Documentation Officielle

- [n8n Code Node - Python](https://docs.n8n.io/code-examples/python/)
- [n8n Data Structure](https://docs.n8n.io/data/data-structure/)

## 🔄 Historique de Correction

**Erreur initiale dans la documentation**:
- ❌ Utilisait `item` (sans underscore)
- ❌ Causait `NameError: name 'item' is not defined`

**Correction**:
- ✅ Utilise maintenant `_item` (avec underscore)
- ✅ Code Python fonctionnel dans n8n

---

**Date de création**: 3 janvier 2026
**Dernière mise à jour**: 3 janvier 2026
**Statut**: ✅ Validé et testé
