# 🌍 Convention Timezone - Europe/Paris

## 📋 Standard du Projet

**Tous les workflows utilisent le timezone `Europe/Paris` (CET/CEST).**

Cette convention garantit la cohérence des dates et heures dans tout le système, particulièrement important pour un système français (PEA Boursorama).

---

## 🎯 Où Appliquer le Timezone

### 1. Schedule Triggers (n8n)

**Tous les schedule triggers doivent inclure le paramètre `timezone`** :

```json
{
  "parameters": {
    "rule": {
      "interval": [
        {
          "field": "cronExpression",
          "expression": "0 18 * * 1-5"
        }
      ]
    },
    "timezone": "Europe/Paris"  // ← OBLIGATOIRE
  },
  "type": "n8n-nodes-base.scheduleTrigger"
}
```

**Exemples de cron avec timezone** :
- `0 18 * * 1-5` + `timezone: Europe/Paris` = 18h00 Paris, du lundi au vendredi
- `15 19 * * 1-5` + `timezone: Europe/Paris` = 19h15 Paris, du lundi au vendredi
- `0 */4 * * *` + `timezone: Europe/Paris` = Toutes les 4h (heure de Paris)

---

### 2. Python Code Nodes

**Toujours utiliser `ZoneInfo('Europe/Paris')` pour les conversions de dates** :

```python
from datetime import datetime
from zoneinfo import ZoneInfo

# Définir le timezone Paris
paris_tz = ZoneInfo('Europe/Paris')

# Convertir timestamp Unix → date Paris
date = datetime.fromtimestamp(timestamp, tz=paris_tz).strftime('%Y-%m-%d')

# Date/heure actuelle Paris
now = datetime.now(paris_tz)

# Convertir UTC → Paris
utc_date = datetime.strptime('2024-01-03T10:30:00Z', '%Y-%m-%dT%H:%M:%SZ')
utc_date = utc_date.replace(tzinfo=ZoneInfo('UTC'))
paris_date = utc_date.astimezone(paris_tz)
```

**⚠️ NE PAS utiliser** :
- `datetime.now()` sans timezone (utilise le timezone local du serveur)
- `datetime.fromtimestamp(ts)` sans `tz=` (utilise le timezone local)
- `pytz` (bibliothèque obsolète, utiliser `zoneinfo` à la place)

---

### 3. SQL Timestamps

**PostgreSQL doit être configuré avec timezone Europe/Paris** :

```sql
-- Vérifier le timezone PostgreSQL
SHOW timezone;
-- Devrait retourner: Europe/Paris

-- Modifier le timezone (si nécessaire)
ALTER DATABASE pea_advisor SET timezone TO 'Europe/Paris';

-- Dans les requêtes
INSERT INTO table (created_at) VALUES (CURRENT_TIMESTAMP);
-- CURRENT_TIMESTAMP utilisera automatiquement Europe/Paris
```

**Utiliser TIMESTAMPTZ au lieu de TIMESTAMP** :

```sql
-- ✅ CORRECT - TIMESTAMPTZ (WITH TIME ZONE)
CREATE TABLE example (
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ❌ INCORRECT - TIMESTAMP (WITHOUT TIME ZONE)
CREATE TABLE example (
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Migration pour convertir TIMESTAMP → TIMESTAMPTZ** :

Si vous avez des colonnes TIMESTAMP existantes, utilisez :
```sql
-- Convertir une colonne TIMESTAMP en TIMESTAMPTZ
ALTER TABLE table_name
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';
```

Voir : `database/migrations/002_add_timezone_to_timestamps.sql`

---

## 📝 Checklist pour Nouveaux Workflows

Lors de la création d'un nouveau workflow, vérifier :

- [ ] **Schedule Trigger** : paramètre `timezone: "Europe/Paris"` ajouté
- [ ] **Python datetime** : imports `from zoneinfo import ZoneInfo`
- [ ] **Python conversions** : toujours spécifier `tz=ZoneInfo('Europe/Paris')`
- [ ] **Logs/timestamps** : vérifier que les dates sont bien en heure de Paris
- [ ] **Tests** : tester avec des données de différents fuseaux horaires

---

## 🔍 Exemples par Workflow

### Workflow 00: Historical Data Loader
```python
# ✅ CORRECT
from datetime import datetime
from zoneinfo import ZoneInfo

paris_tz = ZoneInfo('Europe/Paris')
date = datetime.fromtimestamp(timestamps[i], tz=paris_tz).strftime('%Y-%m-%d')
```

### Workflow 01: Daily Market Data Collector
```json
// ✅ CORRECT - Schedule Trigger
{
  "parameters": {
    "rule": {
      "interval": [{"field": "cronExpression", "expression": "0 18 * * 1-5"}]
    },
    "timezone": "Europe/Paris"
  }
}
```

```python
# ✅ CORRECT - Python
from datetime import datetime
from zoneinfo import ZoneInfo

date = datetime.fromtimestamp(timestamp, tz=ZoneInfo('Europe/Paris')).strftime('%Y-%m-%d')
```

### Workflow 02: News Collector
```python
# ✅ CORRECT - Conversion UTC → Paris
from datetime import datetime
from zoneinfo import ZoneInfo

paris_tz = ZoneInfo('Europe/Paris')

# NewsAPI retourne des dates UTC
published_date = datetime.strptime(published_at, '%Y-%m-%dT%H:%M:%SZ')
published_date = published_date.replace(tzinfo=ZoneInfo('UTC'))
published_date = published_date.astimezone(paris_tz)  # Convertir en Paris
published_str = published_date.strftime('%Y-%m-%d %H:%M:%S')
```

### Workflow 03: Technical Indicators Calculator
```json
// ✅ CORRECT - Schedule à 19h15 heure de Paris
{
  "parameters": {
    "rule": {
      "interval": [{"field": "cronExpression", "expression": "15 19 * * 1-5"}]
    },
    "timezone": "Europe/Paris"
  }
}
```

---

## 🐛 Problèmes Courants

### Symptôme: Dates décalées de quelques heures
**Cause** : Timezone non spécifié, utilise UTC ou timezone local du serveur

**Solution** :
```python
# ❌ INCORRECT
date = datetime.fromtimestamp(ts)

# ✅ CORRECT
date = datetime.fromtimestamp(ts, tz=ZoneInfo('Europe/Paris'))
```

### Symptôme: Workflows déclenchés au mauvais moment
**Cause** : `timezone` manquant dans le Schedule Trigger

**Solution** :
```json
// ❌ INCORRECT
{
  "parameters": {
    "rule": {"interval": [{"expression": "0 18 * * 1-5"}]}
  }
}

// ✅ CORRECT
{
  "parameters": {
    "rule": {"interval": [{"expression": "0 18 * * 1-5"}]},
    "timezone": "Europe/Paris"
  }
}
```

### Symptôme: News timestamps incorrects
**Cause** : Conversion UTC → local sans timezone

**Solution** :
```python
# ❌ INCORRECT
published_date = datetime.strptime(published_at, '%Y-%m-%dT%H:%M:%SZ')

# ✅ CORRECT
published_date = datetime.strptime(published_at, '%Y-%m-%dT%H:%M:%SZ')
published_date = published_date.replace(tzinfo=ZoneInfo('UTC'))
published_date = published_date.astimezone(ZoneInfo('Europe/Paris'))
```

---

## 📚 Ressources

- [Python zoneinfo documentation](https://docs.python.org/3/library/zoneinfo.html)
- [PostgreSQL Timezone documentation](https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-TIMEZONES)
- [IANA Time Zone Database](https://www.iana.org/time-zones)

---

## ✅ Workflows Conformes

- ✅ **Workflow 00** : Historical Data Loader (Python timezone corrigé)
- ✅ **Workflow 01** : Daily Market Data Collector (trigger + Python corrigés)
- ✅ **Workflow 02** : News Collector (trigger + Python corrigés)
- ✅ **Workflow 03** : Technical Indicators Calculator (trigger corrigé)

---

**Dernière mise à jour** : 3 janvier 2026
**Version** : 1.0
**Auteur** : PEA Advisor Team
