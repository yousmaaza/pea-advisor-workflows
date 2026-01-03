-- ============================================
-- Script: Vider uniquement les tables de données (garder les stocks)
-- Date: 2026-01-03
-- ============================================
-- Ce script vide les données collectées mais garde la liste des actions
-- Utile pour réinitialiser les données sans perdre la configuration
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'ℹ️  Suppression des données (garde les stocks)';
    RAISE NOTICE '============================================';
END $$;

-- ============================================
-- Vider les tables de données (garde stocks et watchlist)
-- ============================================

-- Ordre respectant les contraintes de clés étrangères
-- (enfants d'abord, parents ensuite)

-- Données dérivées et analyses
TRUNCATE TABLE ai_recommendations RESTART IDENTITY CASCADE;
TRUNCATE TABLE trading_signals RESTART IDENTITY CASCADE;
TRUNCATE TABLE technical_indicators RESTART IDENTITY CASCADE;
TRUNCATE TABLE news RESTART IDENTITY CASCADE;
TRUNCATE TABLE stock_fundamentals RESTART IDENTITY CASCADE;
TRUNCATE TABLE stock_prices RESTART IDENTITY CASCADE;

-- Portfolio et transactions
TRUNCATE TABLE transactions RESTART IDENTITY CASCADE;
TRUNCATE TABLE portfolio RESTART IDENTITY CASCADE;
TRUNCATE TABLE portfolio_performance RESTART IDENTITY CASCADE;

-- Alertes et rapports
TRUNCATE TABLE alerts RESTART IDENTITY CASCADE;
TRUNCATE TABLE reports RESTART IDENTITY CASCADE;

-- Logs système
TRUNCATE TABLE system_logs RESTART IDENTITY CASCADE;

-- ============================================
-- Vérification
-- ============================================

SELECT
    'stocks' as table_name,
    COUNT(*) as row_count,
    '✅ Conservé' as status
FROM stocks
UNION ALL
SELECT 'watchlist', COUNT(*), '✅ Conservé' FROM watchlist
UNION ALL
SELECT 'stock_prices', COUNT(*), '🗑️ Vidé' FROM stock_prices
UNION ALL
SELECT 'stock_fundamentals', COUNT(*), '🗑️ Vidé' FROM stock_fundamentals
UNION ALL
SELECT 'technical_indicators', COUNT(*), '🗑️ Vidé' FROM technical_indicators
UNION ALL
SELECT 'news', COUNT(*), '🗑️ Vidé' FROM news
UNION ALL
SELECT 'trading_signals', COUNT(*), '🗑️ Vidé' FROM trading_signals
UNION ALL
SELECT 'portfolio', COUNT(*), '🗑️ Vidé' FROM portfolio
UNION ALL
SELECT 'transactions', COUNT(*), '🗑️ Vidé' FROM transactions
UNION ALL
SELECT 'ai_recommendations', COUNT(*), '🗑️ Vidé' FROM ai_recommendations
UNION ALL
SELECT 'system_logs', COUNT(*), '🗑️ Vidé' FROM system_logs
ORDER BY status DESC, table_name;

SELECT '✅ Tables de données vidées avec succès!' as status;
SELECT 'Les stocks et la watchlist ont été conservés' as note;
