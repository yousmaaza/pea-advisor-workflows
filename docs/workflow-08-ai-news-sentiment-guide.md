# 🤖 Workflow 08 - AI News Sentiment Analyzer (Llama3.2)

## 📋 Vue d'ensemble

Analyse automatique du sentiment des actualités financières en utilisant **Llama3.2** (modèle open source de Meta) via Ollama.

**Avantages** :
- ✅ **100% gratuit** (pas de coûts API)
- ✅ **Open source** (Llama3.2 par Meta)
- ✅ **Local** (hébergé dans Docker)
- ✅ **Confidentiel** (données restent sur votre serveur)
- ✅ **Illimité** (pas de rate limits)

---

## 🎯 Objectif

Analyser le sentiment (positif/négatif/neutre) et l'impact potentiel de chaque actualité sur le cours des actions pour aider à la prise de décision d'investissement.

---

## 🏗️ Architecture

### Nodes du Workflow (8 nodes - LangChain)

```
1. Déclencheur Quotidien 20h (Schedule Trigger)
   ↓
2. Récupérer news non analysées (PostgreSQL)
   ↓
3. Préparer Prompt + Context (Set)
   ↓
4. AI Agent (LLM Chain) ← connecté à → Ollama Chat Model (Llama3.2)
   ↓
5. Parser Résultat Python (Code Python)
   ↓
6. Filtrer succès (Filter)
   ↓
7. Mettre à jour news (PostgreSQL)
   ↓
8. Log succès (PostgreSQL)
```

**Architecture LangChain** :
- **Ollama Chat Model** : Node de modèle de langage (se connecte via `ai_languageModel`)
- **AI Agent** : LLM Chain qui reçoit le prompt et utilise le modèle Ollama
- Connexion spéciale : Ollama Chat Model → (ai_languageModel) → AI Agent

---

## 🔧 Configuration Technique

### 1. Ollama Configuration

Ollama est déjà installé dans votre environnement Docker :

```yaml
# docker-compose.yml
services:
  ollama-cpu:  # ou ollama-gpu si GPU disponible
    image: ollama/ollama:latest
    container_name: ollama
    networks: ['demo']
    ports:
      - 11434:11434
```

**URL interne** : `http://ollama:11434`
**Modèle** : `llama3.2` (auto-pulled au démarrage)

### 2. Node "Préparer Prompt + Context" (Set)

**Type** : `n8n-nodes-base.set`

Ce node prépare trois variables pour l'AI Agent :
- `prompt_text` : Le prompt complet avec les données de la news
- `news_id` : L'ID de la news pour mise à jour ultérieure
- `stock_id` : L'ID de l'action associée

### 3. Node "Ollama Chat Model" (LangChain)

**Type** : `@n8n/n8n-nodes-langchain.lmChatOllama`

Configuration :
```json
{
  "model": "llama3.2",
  "options": {
    "temperature": 0.3,
    "maxTokens": 500
  }
}
```

**Credentials** : `ollamaApi` (pointe vers `http://ollama:11434`)

### 4. Node "AI Agent" (LLM Chain)

**Type** : `@n8n/n8n-nodes-langchain.chainLlm`

Configuration :
```json
{
  "text": "={{ $json.prompt_text }}"
}
```

**Connexion** : Reçoit le modèle via connexion `ai_languageModel` depuis "Ollama Chat Model"

### 5. Prompt Engineering

Le prompt demande à Llama de retourner un JSON structuré :

```
Tu es un analyste financier expert. Analyse le sentiment de cet article
financier et retourne UNIQUEMENT un JSON valide sans texte supplémentaire.

Titre: [...]
Description: [...]
Contenu: [...]

Retourne UNIQUEMENT ce JSON :
{
  "sentiment_score": [nombre entre -10 et +10],
  "sentiment_label": "negative" ou "neutral" ou "positive",
  "impact_score": [nombre entre 0 et 10],
  "ai_summary": "résumé en 2-3 phrases maximum",
  "ai_key_points": ["point 1", "point 2", "point 3"]
}
```

**Paramètres** :
- `temperature: 0.3` → Réponses plus déterministes (moins créatives)
- `num_predict: 500` → Maximum 500 tokens de réponse

---

## 📊 Données Analysées

### Input (SELECT)

Récupère les news non analysées des 7 derniers jours :

```sql
SELECT
  id,
  stock_id,
  title,
  description,
  content,
  url,
  source,
  published_at
FROM news
WHERE sentiment_score IS NULL
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY published_at DESC
LIMIT 50;
```

### Output (UPDATE)

Met à jour la table `news` avec :

| Champ            | Type          | Description                           | Exemple      |
|------------------|---------------|---------------------------------------|--------------|
| `sentiment_score`| DECIMAL(5,2)  | Score -10 (très négatif) à +10 (très positif) | -3.50        |
| `sentiment_label`| VARCHAR(20)   | negative / neutral / positive         | "positive"   |
| `impact_score`   | DECIMAL(5,2)  | Impact estimé 0 (nul) à 10 (majeur)  | 7.20         |
| `ai_summary`     | TEXT          | Résumé en 2-3 phrases                 | "..."        |
| `ai_key_points`  | JSONB         | Points clés extraits                  | ["..."]      |

---

## 🐍 Code Python - Parser Résultat

Le code Python nettoie et parse la réponse de Llama3.2 :

### Étapes du parsing

1. **Nettoyage markdown** :
   ```python
   # Enlever ```json ... ```
   if '```json' in cleaned_response:
       match = re.search(r'```json\s*({.*?})\s*```', cleaned_response, re.DOTALL)
   ```

2. **Extraction JSON** :
   ```python
   # Extraire le JSON s'il est entouré de texte
   json_match = re.search(r'{[^{}]*(?:{[^{}]*}[^{}]*)*}', cleaned_response, re.DOTALL)
   ```

3. **Validation des valeurs** :
   ```python
   # Clamp sentiment_score entre -10 et +10
   sentiment_score = max(-10, min(10, sentiment_score))

   # Clamp impact_score entre 0 et 10
   impact_score = max(0, min(10, impact_score))

   # Valider sentiment_label
   if sentiment_label not in ['negative', 'neutral', 'positive']:
       if sentiment_score < -2:
           sentiment_label = 'negative'
       elif sentiment_score > 2:
           sentiment_label = 'positive'
       else:
           sentiment_label = 'neutral'
   ```

4. **Gestion d'erreur** :
   - En cas d'erreur de parsing, retourne des valeurs neutres
   - Log l'erreur avec les 300 premiers caractères de la réponse

---

## ⏰ Schedule

**Trigger** : Tous les jours à 20h00 (Europe/Paris)
**Fréquence** : 1 fois par jour
**Traitement** : Maximum 50 news par exécution

**Pourquoi 20h00** ?
- Après la collecte des news (Workflow 02 : toutes les 4h)
- Après la fermeture des marchés européens
- Avant le rapport quotidien

---

## 🔍 Exemples de Résultats

### Exemple 1 : Résultat positif

**Article** : "LVMH annonce des résultats record pour Q4 2025"

**Analyse Llama3.2** :
```json
{
  "sentiment_score": 8.5,
  "sentiment_label": "positive",
  "impact_score": 9.0,
  "ai_summary": "LVMH annonce des résultats trimestriels exceptionnels, dépassant les attentes du marché. Forte croissance en Asie et augmentation des marges.",
  "ai_key_points": [
    "Résultats Q4 record",
    "Forte croissance Asie (+15%)",
    "Augmentation des marges"
  ]
}
```

### Exemple 2 : Résultat négatif

**Article** : "TotalEnergies fait face à des sanctions environnementales"

**Analyse Llama3.2** :
```json
{
  "sentiment_score": -6.2,
  "sentiment_label": "negative",
  "impact_score": 7.5,
  "ai_summary": "TotalEnergies pourrait faire face à des amendes importantes suite à des violations environnementales. Impact potentiel sur la rentabilité à court terme.",
  "ai_key_points": [
    "Sanctions environnementales majeures",
    "Amendes potentielles",
    "Impact sur la rentabilité"
  ]
}
```

### Exemple 3 : Résultat neutre

**Article** : "Airbus participe au salon aéronautique de Farnborough"

**Analyse Llama3.2** :
```json
{
  "sentiment_score": 0.5,
  "sentiment_label": "neutral",
  "impact_score": 2.0,
  "ai_summary": "Airbus participe au salon aéronautique de Farnborough pour présenter ses derniers produits. Événement annuel standard de l'industrie.",
  "ai_key_points": [
    "Participation au salon de Farnborough",
    "Présentation de produits",
    "Événement récurrent de l'industrie"
  ]
}
```

---

## 📈 Utilisation des Résultats

### 1. Filtrage des opportunités

```sql
-- News très positives sur actions suivies
SELECT s.ticker, n.title, n.sentiment_score, n.impact_score
FROM news n
JOIN stocks s ON s.id = n.stock_id
WHERE n.sentiment_score > 5
  AND n.impact_score > 7
  AND s.is_pea_eligible = true
ORDER BY n.sentiment_score DESC, n.impact_score DESC
LIMIT 10;
```

### 2. Alertes sur sentiment négatif

```sql
-- News très négatives nécessitant attention
SELECT s.ticker, n.title, n.sentiment_score
FROM news n
JOIN stocks s ON s.id = n.stock_id
JOIN portfolio p ON p.stock_id = s.id
WHERE n.sentiment_score < -5
  AND p.is_open = true
ORDER BY n.published_at DESC;
```

### 3. Agrégation par action

```sql
-- Sentiment moyen par action (7 derniers jours)
SELECT
  s.ticker,
  COUNT(*) as nb_articles,
  ROUND(AVG(n.sentiment_score), 2) as avg_sentiment,
  ROUND(AVG(n.impact_score), 2) as avg_impact
FROM news n
JOIN stocks s ON s.id = n.stock_id
WHERE n.published_at >= CURRENT_DATE - INTERVAL '7 days'
  AND n.sentiment_score IS NOT NULL
GROUP BY s.ticker
HAVING COUNT(*) >= 3
ORDER BY avg_sentiment DESC;
```

---

## 🐛 Troubleshooting

### Problème 1 : Ollama ne répond pas

**Erreur** : `Connection refused to http://ollama:11434`

**Solution** :
```bash
# Vérifier que Ollama est démarré
docker ps | grep ollama

# Redémarrer Ollama
docker restart ollama

# Vérifier les logs
docker logs ollama
```

### Problème 2 : JSON invalide de Llama

**Symptôme** : Toutes les news ont `success: false`

**Solution** :
- Vérifier les logs système : `SELECT * FROM system_logs WHERE workflow_name = 'ai-news-sentiment-analyzer' AND success = false`
- Examiner `raw_response` pour voir ce que Llama retourne
- Ajuster le prompt pour être plus explicite

### Problème 3 : Llama3.2 pas installé

**Erreur** : `model 'llama3.2' not found`

**Solution** :
```bash
# Se connecter au container Ollama
docker exec -it ollama bash

# Pull le modèle manuellement
ollama pull llama3.2

# Vérifier les modèles installés
ollama list
```

### Problème 4 : Timeout (60s dépassé)

**Symptôme** : Certaines news ne sont pas analysées

**Cause** : Llama prend trop de temps pour répondre

**Solution** :
- Augmenter le timeout dans le HTTP Request node : `"timeout": 120000` (2 minutes)
- Réduire la longueur du contenu : `.substring(0, 500)` au lieu de 1000

---

## ⚡ Performance

### Temps d'exécution

- **1 news** : ~2-5 secondes (selon CPU/GPU)
- **50 news** : ~2-5 minutes
- **Dépend de** : Puissance CPU/GPU, longueur des articles

### Optimisations possibles

1. **GPU** : Utiliser `ollama-gpu` au lieu de `ollama-cpu` (10x plus rapide)
2. **Batch** : Analyser plusieurs news en une seule requête (à implémenter)
3. **Cache** : Ne pas réanalyser les news déjà traitées (déjà implémenté)
4. **Modèle léger** : Utiliser `llama3.2:1b` au lieu de la version complète

---

## 🔐 Avantages vs LLM Commerciaux

| Critère             | Llama3.2 (Ollama) | OpenAI GPT-4 | Claude     |
|---------------------|-------------------|--------------|------------|
| **Coût**            | ✅ Gratuit        | 💰 $0.01/req | 💰 $0.015/req |
| **Limite**          | ✅ Illimité       | ⚠️ Rate limits | ⚠️ Rate limits |
| **Confidentialité** | ✅ Local          | ❌ Cloud     | ❌ Cloud   |
| **Latence**         | ✅ Rapide (local) | ⚠️ Réseau    | ⚠️ Réseau  |
| **Qualité**         | ⭐⭐⭐ Bon        | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐⭐ Excellent |

**Estimation coûts mensuel** :
- Llama3.2 : **0€** (gratuit, illimité)
- OpenAI : **~15€** (50 news/jour × 30 jours × $0.01)
- Claude : **~22€** (50 news/jour × 30 jours × $0.015)

---

## 🚀 Prochaines Améliorations

1. **Modèle spécialisé** : Fine-tuner Llama3.2 sur des news financières françaises
2. **Analyse multi-langue** : Détecter et analyser news en anglais
3. **Extraction d'entités** : Identifier automatiquement entreprises, produits, personnes mentionnées
4. **Comparaison historique** : Comparer le sentiment actuel vs historique
5. **Score composite** : Agréger sentiment news + indicateurs techniques

---

## 📚 Ressources

- **Ollama Documentation** : https://ollama.ai/
- **Llama3.2 Model Card** : https://huggingface.co/meta-llama/Llama-3.2
- **n8n Ollama Integration** : https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.lmchatollama/
- **Financial Sentiment Analysis** : https://arxiv.org/abs/2107.08055

---

**Dernière mise à jour** : 3 janvier 2026
**Version** : 1.0
**Auteur** : PEA Advisor Team
