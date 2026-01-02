#!/bin/bash

# ============================================
# Script de test de connexion PostgreSQL
# ============================================

echo "🔍 Test de connexion à PostgreSQL..."
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Vérifier que le conteneur PostgreSQL est actif
echo "1️⃣  Vérification du conteneur PostgreSQL..."
if docker ps | grep -q "self-hosted-ai-starter-kit-postgres-1"; then
    echo -e "${GREEN}✅ Conteneur PostgreSQL actif${NC}"
else
    echo -e "${RED}❌ Conteneur PostgreSQL non trouvé${NC}"
    exit 1
fi
echo ""

# Test 2: Vérifier la connexion
echo "2️⃣  Test de connexion..."
if docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connexion réussie${NC}"
else
    echo -e "${RED}❌ Échec de connexion${NC}"
    exit 1
fi
echo ""

# Test 3: Lister les bases de données
echo "3️⃣  Bases de données disponibles:"
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "\l" | grep -E "pea_advisor|n8n"
echo ""

# Test 4: Compter les tables
echo "4️⃣  Tables dans pea_advisor:"
TABLE_COUNT=$(docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")
echo -e "   ${GREEN}${TABLE_COUNT} tables trouvées${NC}"
echo ""

# Test 5: Lister les tables
echo "5️⃣  Liste des tables:"
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "\dt" | tail -n +4 | head -n -2 | awk '{print "   - " $3}'
echo ""

# Test 6: Vérifier les données initiales
echo "6️⃣  Vérification des données initiales:"
STOCK_COUNT=$(docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -t -c "SELECT COUNT(*) FROM stocks;")
echo -e "   ${GREEN}${STOCK_COUNT} actions dans la table stocks${NC}"
echo ""

# Test 7: Afficher quelques actions
echo "7️⃣  Exemple d'actions en base:"
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "SELECT ticker, name, sector FROM stocks LIMIT 5;" | tail -n +3 | head -n -2 | sed 's/^/   /'
echo ""

# Test 8: Vérifier les vues
echo "8️⃣  Vues SQL disponibles:"
VIEW_COUNT=$(docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -t -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public';")
echo -e "   ${GREEN}${VIEW_COUNT} vues trouvées${NC}"
docker exec self-hosted-ai-starter-kit-postgres-1 psql -U root -d pea_advisor -c "\dv" | tail -n +4 | head -n -2 | awk '{print "   - " $3}'
echo ""

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Tous les tests ont réussi!${NC}"
echo ""
echo "📊 Résumé:"
echo "   - Conteneur: self-hosted-ai-starter-kit-postgres-1"
echo "   - Base de données: pea_advisor"
echo "   - Utilisateur: root"
echo "   - Tables: ${TABLE_COUNT}"
echo "   - Vues: ${VIEW_COUNT}"
echo "   - Actions: ${STOCK_COUNT}"
echo ""
echo "🚀 Vous pouvez maintenant commencer à créer les workflows!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
