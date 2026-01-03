-- ============================================
-- Script: Vider toutes les tables de la base de données
-- Date: 2026-01-03
-- ============================================
-- ⚠️ ATTENTION: Ce script supprime TOUTES les données !
-- Utilisez-le uniquement en développement ou avec une sauvegarde
-- ============================================

-- Afficher un avertissement
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '⚠️  ATTENTION: Suppression de TOUTES les données!';
    RAISE NOTICE '============================================';
END $$;

-- ============================================
-- MÉTHODE 1: Vider avec CASCADE (rapide)
-- ============================================
-- Désactive temporairement les contraintes et vide tout d'un coup

-- Vider toutes les tables en une seule commande
-- CASCADE supprime aussi les dépendances
TRUNCATE TABLE
    stocks,
    stock_prices,
    stock_fundamentals,
    technical_indicators,
    news,
    trading_signals,
    portfolio,
    transactions,
    portfolio_performance,
    ai_recommendations,
    reports,
    alerts,
    watchlist,
    system_logs
RESTART IDENTITY CASCADE;

-- ============================================
-- Vérification
-- ============================================

-- Compter les lignes dans chaque table
SELECT
    'stocks' as table_name,
    COUNT(*) as row_count
FROM stocks
UNION ALL
SELECT 'stock_prices', COUNT(*) FROM stock_prices
UNION ALL
SELECT 'stock_fundamentals', COUNT(*) FROM stock_fundamentals
UNION ALL
SELECT 'technical_indicators', COUNT(*) FROM technical_indicators
UNION ALL
SELECT 'news', COUNT(*) FROM news
UNION ALL
SELECT 'trading_signals', COUNT(*) FROM trading_signals
UNION ALL
SELECT 'portfolio', COUNT(*) FROM portfolio
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'portfolio_performance', COUNT(*) FROM portfolio_performance
UNION ALL
SELECT 'ai_recommendations', COUNT(*) FROM ai_recommendations
UNION ALL
SELECT 'reports', COUNT(*) FROM reports
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts
UNION ALL
SELECT 'watchlist', COUNT(*) FROM watchlist
UNION ALL
SELECT 'system_logs', COUNT(*) FROM system_logs
ORDER BY table_name;

-- Afficher le résultat
SELECT '✅ Toutes les tables ont été vidées avec succès!' as status;
SELECT 'Les séquences (IDs) ont été réinitialisées à 1' as note;
