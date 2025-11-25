import express from 'express';
import cors from 'cors';
import { register, Counter, Gauge, Histogram } from 'prom-client';
import pg from 'pg';

const { Pool } = pg;

const app = express();
const PORT = process.env.PORT || 8080;
const DB_HOST = process.env.DB_HOST || 'postgres-service';
const DB_PORT = process.env.DB_PORT || 5432;
const DB_NAME = process.env.DB_NAME || 'metricsdb';
const DB_USER = process.env.DB_USER || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || 'postgres';

// Prometheus metrics
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const cpuUsage = new Gauge({
  name: 'cpu_usage_percent',
  help: 'CPU usage percentage'
});

const memoryUsage = new Gauge({
  name: 'memory_usage_percent',
  help: 'Memory usage percentage'
});

const requestsPerSecond = new Gauge({
  name: 'requests_per_second',
  help: 'Requests per second'
});

const latency = new Histogram({
  name: 'request_latency_ms',
  help: 'Request latency in milliseconds',
  buckets: [10, 50, 100, 200, 500, 1000]
});

// Database connection
const pool = new Pool({
  host: DB_HOST,
  port: DB_PORT,
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Initialize database
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS metrics_history (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        cpu DECIMAL(5,2),
        memory DECIMAL(5,2),
        requests INTEGER,
        latency DECIMAL(10,2)
      )
    `);
    console.log('Database initialized');
  } catch (error) {
    console.error('Database initialization error:', error.message);
  }
}

// Metrics generation
let requestCount = 0;
let startTime = Date.now();

function generateMetrics() {
  // Simulate realistic metrics
  const baseCpu = 30;
  const baseMemory = 45;
  const variation = Math.sin(Date.now() / 10000) * 20;
  
  const cpu = Math.max(10, Math.min(90, baseCpu + variation + Math.random() * 10));
  const memory = Math.max(20, Math.min(85, baseMemory + variation + Math.random() * 15));
  const requests = Math.floor(50 + Math.random() * 100 + Math.sin(Date.now() / 5000) * 30);
  const latencyValue = Math.max(10, 100 + Math.random() * 200 + Math.sin(Date.now() / 7000) * 50);

  // Update Prometheus metrics
  cpuUsage.set(cpu);
  memoryUsage.set(memory);
  requestsPerSecond.set(requests);
  latency.observe(latencyValue);

  return { cpu, memory, requests, latency: latencyValue };
}

// Store metrics in database
async function storeMetrics(metrics) {
  try {
    await pool.query(
      'INSERT INTO metrics_history (cpu, memory, requests, latency) VALUES ($1, $2, $3, $4)',
      [metrics.cpu, metrics.memory, metrics.requests, metrics.latency]
    );
    
    // Keep only last 100 records
    await pool.query(
      'DELETE FROM metrics_history WHERE id NOT IN (SELECT id FROM metrics_history ORDER BY timestamp DESC LIMIT 100)'
    );
  } catch (error) {
    console.error('Error storing metrics:', error.message);
  }
}

// Generate metrics every 5 seconds
setInterval(async () => {
  const metrics = generateMetrics();
  await storeMetrics(metrics);
}, 5000);

// Middleware
app.use(cors());
app.use(express.json());

// Request tracking middleware
app.use((req, res, next) => {
  const start = Date.now();
  requestCount++;
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.observe({ method: req.method, route: req.route?.path || req.path, status: res.statusCode }, duration);
    httpRequestTotal.inc({ method: req.method, route: req.route?.path || req.path, status: res.statusCode });
  });
  
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error);
  }
});

// API endpoint for dashboard
app.get('/api/metrics', async (req, res) => {
  try {
    const currentMetrics = generateMetrics();
    
    // Get history from database
    const historyResult = await pool.query(
      'SELECT * FROM metrics_history ORDER BY timestamp DESC LIMIT 20'
    );
    
    const history = historyResult.rows.reverse().map(row => ({
      timestamp: row.timestamp,
      cpu: parseFloat(row.cpu),
      memory: parseFloat(row.memory),
      requests: row.requests,
      latency: parseFloat(row.latency)
    }));

    // Calculate trends (simple comparison with previous value)
    const trends = history.length > 1 ? {
      cpu: currentMetrics.cpu - history[history.length - 2].cpu,
      memory: currentMetrics.memory - history[history.length - 2].memory,
      requests: currentMetrics.requests - history[history.length - 2].requests,
      latency: currentMetrics.latency - history[history.length - 2].latency
    } : { cpu: 0, memory: 0, requests: 0, latency: 0 };

    const uptime = Math.floor((Date.now() - startTime) / 1000);
    const uptimeFormatted = `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${uptime % 60}s`;

    res.json({
      current: currentMetrics,
      history,
      trends,
      system: {
        uptime: uptimeFormatted,
        totalRequests: requestCount,
        version: '1.0.0'
      }
    });
  } catch (error) {
    console.error('Error fetching metrics:', error);
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

// Start server
async function startServer() {
  await initDatabase();
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Metrics endpoint: http://localhost:${PORT}/metrics`);
    console.log(`API endpoint: http://localhost:${PORT}/api/metrics`);
  });
}

startServer().catch(console.error);


