-- ============================================
-- Migration: Ajouter timezone Europe/Paris aux colonnes TIMESTAMP
-- Date: 2026-01-03
-- ============================================

-- Configurer le timezone de la base de données
ALTER DATABASE pea_advisor SET timezone TO 'Europe/Paris';

-- Afficher le timezone actuel
SHOW timezone;

-- ============================================
-- Convertir TIMESTAMP en TIMESTAMPTZ (WITH TIME ZONE)
-- ============================================

-- Table: stocks
ALTER TABLE stocks
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Europe/Paris';

-- Table: stock_prices
ALTER TABLE stock_prices
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: stock_fundamentals
ALTER TABLE stock_fundamentals
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: technical_indicators
ALTER TABLE technical_indicators
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at AT TIME ZONE 'Europe/Paris';

-- Table: news
ALTER TABLE news
ALTER COLUMN published_at TYPE TIMESTAMPTZ USING published_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: trading_signals
ALTER TABLE trading_signals
ALTER COLUMN triggered_at TYPE TIMESTAMPTZ USING triggered_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: portfolio
ALTER TABLE portfolio
ALTER COLUMN opened_at TYPE TIMESTAMPTZ USING opened_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN last_updated TYPE TIMESTAMPTZ USING last_updated AT TIME ZONE 'Europe/Paris';

-- Table: transactions
ALTER TABLE transactions
ALTER COLUMN executed_at TYPE TIMESTAMPTZ USING executed_at AT TIME ZONE 'Europe/Paris';

-- Table: portfolio_performance
ALTER TABLE portfolio_performance
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: ai_recommendations
ALTER TABLE ai_recommendations
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: reports
ALTER TABLE reports
ALTER COLUMN sent_at TYPE TIMESTAMPTZ USING sent_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: alerts
ALTER TABLE alerts
ALTER COLUMN notified_at TYPE TIMESTAMPTZ USING notified_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- Table: watchlist
ALTER TABLE watchlist
ALTER COLUMN added_at TYPE TIMESTAMPTZ USING added_at AT TIME ZONE 'Europe/Paris',
ALTER COLUMN last_checked TYPE TIMESTAMPTZ USING last_checked AT TIME ZONE 'Europe/Paris';

-- Table: system_logs
ALTER TABLE system_logs
ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'Europe/Paris';

-- ============================================
-- Mise à jour de la fonction de trigger
-- ============================================

-- La fonction update_updated_at_column() utilise déjà CURRENT_TIMESTAMP
-- qui utilisera maintenant automatiquement le timezone Europe/Paris

-- ============================================
-- Vérification
-- ============================================

-- Afficher toutes les colonnes de type timestamp
SELECT
    table_name,
    column_name,
    data_type,
    CASE
        WHEN data_type = 'timestamp with time zone' THEN '✅ TIMESTAMPTZ'
        WHEN data_type = 'timestamp without time zone' THEN '❌ TIMESTAMP'
        ELSE data_type
    END as status
FROM information_schema.columns
WHERE table_schema = 'public'
    AND data_type LIKE '%timestamp%'
ORDER BY table_name, column_name;

-- Afficher le résultat
SELECT 'Migration timezone terminée avec succès!' as status;
SELECT 'Timezone configuré: ' || current_setting('timezone') as timezone_info;
