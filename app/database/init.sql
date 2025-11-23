-- Create database if not exists (handled by POSTGRES_DB env var)
-- Create metrics_history table
CREATE TABLE IF NOT EXISTS metrics_history (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cpu DECIMAL(5,2) NOT NULL,
    memory DECIMAL(5,2) NOT NULL,
    requests INTEGER NOT NULL,
    latency DECIMAL(10,2) NOT NULL
);

-- Create index on timestamp for faster queries
CREATE INDEX IF NOT EXISTS idx_metrics_history_timestamp ON metrics_history(timestamp DESC);

-- Create a function to clean old metrics (older than 7 days)
CREATE OR REPLACE FUNCTION clean_old_metrics()
RETURNS void AS $$
BEGIN
    DELETE FROM metrics_history
    WHERE timestamp < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE metricsdb TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

