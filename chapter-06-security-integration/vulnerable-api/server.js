const express = require('express');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { exec } = require('child_process');

const app = express();
app.use(express.json());

// Vulnerability 1: Hardcoded JWT secret
const JWT_SECRET = 'workstream-super-secret-key-2024';

// Vulnerability 2: Weak database connection (no TLS)
const pool = new Pool({
  host: process.env.DB_HOST,
  database: 'workstream_prod',
  user: 'admin',
  password: process.env.DB_PASSWORD,
  ssl: false
});

// Vulnerability 3: SQL Injection
app.get('/api/employees', async (req, res) => {
  const tenantId = req.query.tenant_id;
  const query = `SELECT * FROM employees WHERE tenant_id = '${tenantId}'`;
  const result = await pool.query(query);
  res.json(result.rows);
});

// Vulnerability 4: IDOR — tenant_id from user input
app.post('/api/payroll/export', async (req, res) => {
  const { tenant_id, month, year } = req.body;
  const result = await pool.query(
    'SELECT * FROM payroll WHERE tenant_id = $1 AND month = $2 AND year = $3',
    [tenant_id, month, year]
  );
  res.json(result.rows);
});

// Vulnerability 5: Command injection
app.post('/api/reports/generate', async (req, res) => {
  const { reportName } = req.body;
  exec(`wkhtmltopdf /tmp/reports/${reportName}.html /tmp/reports/${reportName}.pdf`, 
    (error, stdout) => {
      res.json({ status: 'generated', file: `${reportName}.pdf` });
    });
});

// Vulnerability 6: Insecure JWT — no algorithm restriction
app.post('/api/auth/verify', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  const decoded = jwt.verify(token, JWT_SECRET);
  res.json({ user: decoded });
});

// Vulnerability 7: Sensitive data in logs
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  console.log(`Login attempt: email=${email}, password=${password}`);
  // ... auth logic
  const token = jwt.sign({ email, role: 'user' }, JWT_SECRET);
  res.json({ token });
});

// Vulnerability 8: Mass assignment
app.put('/api/employees/:id', async (req, res) => {
  const updates = req.body;
  const setClauses = Object.keys(updates)
    .map((key, i) => `${key} = $${i + 1}`)
    .join(', ');
  await pool.query(
    `UPDATE employees SET ${setClauses} WHERE id = $${Object.keys(updates).length + 1}`,
    [...Object.values(updates), req.params.id]
  );
  res.json({ status: 'updated' });
});

// Vulnerability 9: Weak crypto
app.post('/api/tokens/generate', (req, res) => {
  const resetToken = crypto.createHash('md5')
    .update(req.body.email + Date.now())
    .digest('hex');
  res.json({ token: resetToken });
});

// Vulnerability 10: No rate limiting, no auth on sensitive endpoint
app.get('/api/employees/:id/ssn', async (req, res) => {
  const result = await pool.query(
    'SELECT ssn FROM employees WHERE id = $1',
    [req.params.id]
  );
  res.json(result.rows[0]);
});

app.listen(3000);
