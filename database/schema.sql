-- ============================================
-- Schéma PostgreSQL - Conseiller Intelligent PEA
-- ============================================

-- Note: La base de données doit être créée avant d'exécuter ce script
-- CREATE DATABASE pea_advisor;
-- Puis se connecter : \c pea_advisor ou exécuter avec -d pea_advisor

-- Configurer le timezone Europe/Paris pour toute la base de données
ALTER DATABASE pea_advisor SET timezone TO 'Europe/Paris';

-- ============================================
-- Table: Actions et référentiel
-- ============================================

-- Liste des actions éligibles PEA
CREATE TABLE IF NOT EXISTS stocks (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    isin VARCHAR(12) UNIQUE,
    country VARCHAR(2) NOT NULL, -- Code ISO pays (FR, DE, IT, etc.)
    sector VARCHAR(100),
    industry VARCHAR(100),
    market_cap BIGINT,
    is_pea_eligible BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stocks_ticker ON stocks(ticker);
CREATE INDEX idx_stocks_pea_eligible ON stocks(is_pea_eligible);
CREATE INDEX idx_stocks_sector ON stocks(sector);

-- ============================================
-- Table: Prix historiques
-- ============================================

CREATE TABLE IF NOT EXISTS stock_prices (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    open DECIMAL(10, 2),
    high DECIMAL(10, 2),
    low DECIMAL(10, 2),
    close DECIMAL(10, 2) NOT NULL,
    volume BIGINT,
    adjusted_close DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stock_id, date)
);

CREATE INDEX idx_stock_prices_stock_date ON stock_prices(stock_id, date DESC);
CREATE INDEX idx_stock_prices_date ON stock_prices(date DESC);

-- ============================================
-- Table: Données fondamentales
-- ============================================

CREATE TABLE IF NOT EXISTS stock_fundamentals (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Ratios de valorisation
    pe_ratio DECIMAL(10, 2),
    pb_ratio DECIMAL(10, 2),
    ps_ratio DECIMAL(10, 2),
    peg_ratio DECIMAL(10, 2),

    -- Rentabilité
    roe DECIMAL(10, 2),
    roa DECIMAL(10, 2),
    profit_margin DECIMAL(10, 2),

    -- Dividendes
    dividend_yield DECIMAL(10, 4),
    dividend_per_share DECIMAL(10, 4),
    payout_ratio DECIMAL(10, 2),

    -- Croissance
    revenue_growth DECIMAL(10, 2),
    earnings_growth DECIMAL(10, 2),

    -- Dette
    debt_to_equity DECIMAL(10, 2),
    current_ratio DECIMAL(10, 2),

    -- Autres
    beta DECIMAL(10, 4),
    analyst_rating VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stock_id, date)
);

CREATE INDEX idx_stock_fundamentals_stock_date ON stock_fundamentals(stock_id, date DESC);

-- ============================================
-- Table: Indicateurs techniques
-- ============================================

CREATE TABLE IF NOT EXISTS technical_indicators (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    close_price DECIMAL(10, 4),

    -- RSI
    rsi_14 DECIMAL(10, 2),

    -- MACD
    macd DECIMAL(10, 4),
    macd_signal DECIMAL(10, 4),
    macd_histogram DECIMAL(10, 4),

    -- Moyennes mobiles
    sma_20 DECIMAL(10, 4),
    sma_50 DECIMAL(10, 4),
    sma_200 DECIMAL(10, 4),
    ema_20 DECIMAL(10, 4),

    -- Bandes de Bollinger
    bb_upper DECIMAL(10, 4),
    bb_middle DECIMAL(10, 4),
    bb_lower DECIMAL(10, 4),

    -- Volatilité
    atr_14 DECIMAL(10, 4),

    -- Signaux de trading
    rsi_signal VARCHAR(20),     -- 'oversold', 'overbought', 'neutral'
    trend_signal VARCHAR(20),   -- 'bullish', 'bearish', 'neutral'
    macd_signal_str VARCHAR(20), -- 'bullish', 'bearish', 'neutral' (renamed to avoid conflict with macd_signal value)

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(stock_id, date)
);

CREATE INDEX idx_technical_indicators_stock_date ON technical_indicators(stock_id, date DESC);
CREATE INDEX idx_technical_indicators_signals ON technical_indicators(rsi_signal, trend_signal, macd_signal_str);

-- ============================================
-- Table: Actualités financières
-- ============================================

CREATE TABLE IF NOT EXISTS news (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    content TEXT,
    url TEXT UNIQUE,
    source VARCHAR(100),
    published_at TIMESTAMPTZ NOT NULL,

    -- Analyse de sentiment (rempli par IA)
    sentiment_score DECIMAL(5, 2), -- -10 à +10
    sentiment_label VARCHAR(20), -- negative, neutral, positive

    -- Impact estimé sur le cours
    impact_score DECIMAL(5, 2), -- 0 à 10

    -- IA insights
    ai_summary TEXT,
    ai_key_points JSONB,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_news_stock_published ON news(stock_id, published_at DESC);
CREATE INDEX idx_news_published ON news(published_at DESC);
CREATE INDEX idx_news_sentiment ON news(sentiment_score);

-- ============================================
-- Table: Signaux de trading
-- ============================================

CREATE TABLE IF NOT EXISTS trading_signals (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Type de signal
    signal_type VARCHAR(20) NOT NULL, -- buy, sell, hold

    -- Sources du signal
    technical_score DECIMAL(5, 2), -- 0-100
    fundamental_score DECIMAL(5, 2), -- 0-100
    sentiment_score DECIMAL(5, 2), -- 0-100
    ai_score DECIMAL(5, 2), -- 0-100

    -- Score global
    overall_score DECIMAL(5, 2), -- 0-100
    confidence_level VARCHAR(20), -- low, medium, high

    -- Détails
    reasons JSONB, -- Raisons du signal
    target_price DECIMAL(10, 2),
    stop_loss DECIMAL(10, 2),
    take_profit DECIMAL(10, 2),

    -- Suivi
    is_active BOOLEAN DEFAULT true,
    triggered_at TIMESTAMPTZ,
    outcome VARCHAR(20), -- success, failure, pending

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trading_signals_stock_date ON trading_signals(stock_id, date DESC);
CREATE INDEX idx_trading_signals_type ON trading_signals(signal_type);
CREATE INDEX idx_trading_signals_active ON trading_signals(is_active);

-- ============================================
-- Table: Portefeuille
-- ============================================

CREATE TABLE IF NOT EXISTS portfolio (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,

    -- Position
    quantity INTEGER NOT NULL,
    average_price DECIMAL(10, 2) NOT NULL,
    current_price DECIMAL(10, 2),

    -- Valeurs
    invested_amount DECIMAL(12, 2) NOT NULL,
    current_value DECIMAL(12, 2),
    unrealized_pnl DECIMAL(12, 2),
    unrealized_pnl_percentage DECIMAL(10, 2),

    -- Dates
    opened_at TIMESTAMPTZ NOT NULL,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Statut
    is_open BOOLEAN DEFAULT true
);

CREATE INDEX idx_portfolio_stock ON portfolio(stock_id);
CREATE INDEX idx_portfolio_open ON portfolio(is_open);
CREATE UNIQUE INDEX idx_portfolio_unique_open ON portfolio(stock_id) WHERE is_open = true;

-- ============================================
-- Table: Historique des transactions
-- ============================================

CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,

    -- Type de transaction
    type VARCHAR(10) NOT NULL, -- buy, sell

    -- Détails
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    fees DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(12, 2) NOT NULL,

    -- Contexte
    signal_id INTEGER REFERENCES trading_signals(id) ON DELETE SET NULL,
    notes TEXT,

    -- Date
    executed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Pour le tracking fiscal PEA
    tax_year INTEGER,
    is_pea_contribution BOOLEAN DEFAULT false
);

CREATE INDEX idx_transactions_stock ON transactions(stock_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_date ON transactions(executed_at DESC);

-- ============================================
-- Table: Performance du portefeuille
-- ============================================

CREATE TABLE IF NOT EXISTS portfolio_performance (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,

    -- Valeurs
    total_value DECIMAL(12, 2) NOT NULL,
    invested_amount DECIMAL(12, 2) NOT NULL,
    cash_balance DECIMAL(12, 2) DEFAULT 0,

    -- Performance
    daily_return DECIMAL(10, 4),
    total_return DECIMAL(12, 2),
    total_return_percentage DECIMAL(10, 2),

    -- Comparaison benchmark
    cac40_value DECIMAL(10, 2),
    cac40_return DECIMAL(10, 4),
    alpha DECIMAL(10, 4), -- Performance vs CAC40

    -- Risque
    volatility DECIMAL(10, 4),
    sharpe_ratio DECIMAL(10, 4),
    beta DECIMAL(10, 4),
    max_drawdown DECIMAL(10, 4),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_portfolio_performance_date ON portfolio_performance(date DESC);

-- ============================================
-- Table: Recommandations IA
-- ============================================

CREATE TABLE IF NOT EXISTS ai_recommendations (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Recommandation
    action VARCHAR(20) NOT NULL, -- strong_buy, buy, hold, sell, strong_sell
    confidence DECIMAL(5, 2), -- 0-100

    -- Contenu généré par IA
    summary TEXT,
    reasoning TEXT,
    key_insights JSONB,
    risks JSONB,
    opportunities JSONB,

    -- Prix
    current_price DECIMAL(10, 2),
    target_price DECIMAL(10, 2),
    potential_return DECIMAL(10, 2),

    -- Métadonnées
    model_used VARCHAR(50),
    prompt_version VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_recommendations_stock_date ON ai_recommendations(stock_id, date DESC);
CREATE INDEX idx_ai_recommendations_action ON ai_recommendations(action);

-- ============================================
-- Table: Rapports générés
-- ============================================

CREATE TABLE IF NOT EXISTS reports (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL, -- daily, weekly, monthly
    date DATE NOT NULL,

    -- Contenu
    title VARCHAR(255),
    content TEXT,
    summary TEXT,

    -- Données structurées
    metrics JSONB,
    top_opportunities JSONB,
    alerts JSONB,

    -- Distribution
    sent_at TIMESTAMPTZ,
    recipients JSONB,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reports_type_date ON reports(type, date DESC);

-- ============================================
-- Table: Alertes
-- ============================================

CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE,

    -- Type d'alerte
    type VARCHAR(50) NOT NULL, -- price_target, stop_loss, news, technical, etc.
    severity VARCHAR(20) NOT NULL, -- info, warning, critical

    -- Message
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,

    -- Contexte
    trigger_value DECIMAL(10, 2),
    current_value DECIMAL(10, 2),

    -- Statut
    is_read BOOLEAN DEFAULT false,
    is_dismissed BOOLEAN DEFAULT false,

    -- Notification
    notified_at TIMESTAMPTZ,
    notification_channels JSONB, -- telegram, email, etc.

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_stock ON alerts(stock_id);
CREATE INDEX idx_alerts_read ON alerts(is_read);
CREATE INDEX idx_alerts_created ON alerts(created_at DESC);

-- ============================================
-- Table: Watchlist personnalisée
-- ============================================

CREATE TABLE IF NOT EXISTS watchlist (
    id SERIAL PRIMARY KEY,
    stock_id INTEGER REFERENCES stocks(id) ON DELETE CASCADE UNIQUE,

    -- Raison du suivi
    reason TEXT,

    -- Alertes personnalisées
    alert_price_above DECIMAL(10, 2),
    alert_price_below DECIMAL(10, 2),
    alert_on_news BOOLEAN DEFAULT true,

    -- Priorité
    priority INTEGER DEFAULT 5, -- 1-10

    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_checked TIMESTAMPTZ
);

CREATE INDEX idx_watchlist_priority ON watchlist(priority DESC);

-- ============================================
-- Table: Logs du système
-- ============================================

CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(100),
    execution_id VARCHAR(100),
    level VARCHAR(20), -- debug, info, warning, error
    message TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_logs_workflow ON system_logs(workflow_name);
CREATE INDEX idx_system_logs_level ON system_logs(level);
CREATE INDEX idx_system_logs_created ON system_logs(created_at DESC);

-- ============================================
-- Vues utiles
-- ============================================

-- Vue: Résumé du portefeuille actuel
CREATE OR REPLACE VIEW v_portfolio_summary AS
SELECT
    s.ticker,
    s.name,
    s.sector,
    p.quantity,
    p.average_price,
    p.current_price,
    p.invested_amount,
    p.current_value,
    p.unrealized_pnl,
    p.unrealized_pnl_percentage,
    (p.current_value / NULLIF(SUM(p.current_value) OVER (), 0) * 100) as portfolio_weight,
    p.opened_at,
    p.last_updated
FROM portfolio p
JOIN stocks s ON p.stock_id = s.id
WHERE p.is_open = true
ORDER BY p.current_value DESC;

-- Vue: Meilleures opportunités du jour
CREATE OR REPLACE VIEW v_top_opportunities AS
SELECT
    s.ticker,
    s.name,
    s.sector,
    ts.signal_type,
    ts.overall_score,
    ts.confidence_level,
    ts.target_price,
    sp.close as current_price,
    ((ts.target_price - sp.close) / sp.close * 100) as potential_return,
    ts.created_at
FROM trading_signals ts
JOIN stocks s ON ts.stock_id = s.id
JOIN LATERAL (
    SELECT close
    FROM stock_prices
    WHERE stock_id = ts.stock_id
    ORDER BY date DESC
    LIMIT 1
) sp ON true
WHERE ts.is_active = true
    AND ts.signal_type IN ('buy', 'strong_buy')
    AND ts.overall_score >= 70
ORDER BY ts.overall_score DESC, potential_return DESC
LIMIT 10;

-- ============================================
-- Fonctions utiles
-- ============================================

-- Fonction: Calculer la performance du portefeuille
CREATE OR REPLACE FUNCTION calculate_portfolio_return()
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    total_invested DECIMAL(12, 2);
    total_current DECIMAL(12, 2);
BEGIN
    SELECT
        SUM(invested_amount),
        SUM(current_value)
    INTO total_invested, total_current
    FROM portfolio
    WHERE is_open = true;

    IF total_invested > 0 THEN
        RETURN ((total_current - total_invested) / total_invested * 100);
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction: Mettre à jour le timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update updated_at
CREATE TRIGGER update_stocks_updated_at BEFORE UPDATE ON stocks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Données initiales
-- ============================================

-- Insérer quelques actions CAC40 pour démarrer
INSERT INTO stocks (ticker, name, isin, country, sector, is_pea_eligible) VALUES
('MC.PA', 'LVMH', 'FR0000121014', 'FR', 'Luxe', true),
('OR.PA', 'L''Oréal', 'FR0000120321', 'FR', 'Cosmétiques', true),
('SAN.PA', 'Sanofi', 'FR0000120578', 'FR', 'Pharmacie', true),
('AIR.PA', 'Airbus', 'NL0000235190', 'NL', 'Aéronautique', true),
('TTE.PA', 'TotalEnergies', 'FR0000120271', 'FR', 'Énergie', true),
('BNP.PA', 'BNP Paribas', 'FR0000131104', 'FR', 'Banque', true),
('SAF.PA', 'Safran', 'FR0000073272', 'FR', 'Aéronautique', true),
('SU.PA', 'Schneider Electric', 'FR0000121972', 'FR', 'Industrie', true),
('VIV.PA', 'Vivendi', 'FR0000127771', 'FR', 'Médias', true),
('RMS.PA', 'Hermès', 'FR0000052292', 'FR', 'Luxe', true)
ON CONFLICT (ticker) DO NOTHING;

-- ============================================
-- Permissions (optionnel)
-- ============================================

-- Créer un utilisateur dédié (recommandé pour la prod)
-- CREATE USER pea_advisor_user WITH PASSWORD 'your_secure_password';
-- GRANT ALL PRIVILEGES ON DATABASE pea_advisor TO pea_advisor_user;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pea_advisor_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pea_advisor_user;

-- ============================================
-- Fin du schéma
-- ============================================

-- Afficher un résumé
SELECT 'Base de données créée avec succès!' as status;
SELECT COUNT(*) as nb_tables FROM information_schema.tables WHERE table_schema = 'public';
