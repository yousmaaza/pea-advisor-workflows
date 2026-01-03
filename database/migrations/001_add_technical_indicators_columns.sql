-- ============================================
-- Migration: Ajouter colonnes manquantes à technical_indicators
-- Date: 2026-01-03
-- ============================================

-- Ajouter la colonne close_price
ALTER TABLE technical_indicators
ADD COLUMN IF NOT EXISTS close_price DECIMAL(10, 4);

-- Modifier la précision des moyennes mobiles (2 → 4 décimales)
ALTER TABLE technical_indicators
ALTER COLUMN sma_20 TYPE DECIMAL(10, 4),
ALTER COLUMN sma_50 TYPE DECIMAL(10, 4),
ALTER COLUMN sma_200 TYPE DECIMAL(10, 4),
ALTER COLUMN ema_20 TYPE DECIMAL(10, 4);

-- Modifier la précision des bandes de Bollinger (2 → 4 décimales)
ALTER TABLE technical_indicators
ALTER COLUMN bb_upper TYPE DECIMAL(10, 4),
ALTER COLUMN bb_middle TYPE DECIMAL(10, 4),
ALTER COLUMN bb_lower TYPE DECIMAL(10, 4);

-- Ajouter les colonnes de signaux de trading
ALTER TABLE technical_indicators
ADD COLUMN IF NOT EXISTS rsi_signal VARCHAR(20);

ALTER TABLE technical_indicators
ADD COLUMN IF NOT EXISTS trend_signal VARCHAR(20);

ALTER TABLE technical_indicators
ADD COLUMN IF NOT EXISTS macd_signal_str VARCHAR(20);

-- Ajouter colonne updated_at
ALTER TABLE technical_indicators
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Supprimer volume_sma_20 si elle existe (non utilisée)
ALTER TABLE technical_indicators
DROP COLUMN IF EXISTS volume_sma_20;

-- Créer index sur les signaux
CREATE INDEX IF NOT EXISTS idx_technical_indicators_signals
ON technical_indicators(rsi_signal, trend_signal, macd_signal_str);

-- Ajouter des commentaires
COMMENT ON COLUMN technical_indicators.close_price IS 'Prix de clôture du jour (pour référence)';
COMMENT ON COLUMN technical_indicators.rsi_signal IS 'Signal RSI: oversold (<30), overbought (>70), neutral';
COMMENT ON COLUMN technical_indicators.trend_signal IS 'Signal de tendance: bullish, bearish, neutral (basé sur SMA)';
COMMENT ON COLUMN technical_indicators.macd_signal_str IS 'Signal MACD: bullish (MACD > signal), bearish (MACD < signal)';

-- Afficher le résultat
SELECT 'Migration terminée avec succès!' as status;
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'technical_indicators'
ORDER BY ordinal_position;
