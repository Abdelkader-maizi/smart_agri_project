const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const jwt = require('jsonwebtoken');

// Admin Login
router.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  // Default simple admin credentials (can be moved to .env in production)
  const ADMIN_USER = process.env.ADMIN_USER || 'admin';
  const ADMIN_PASS = process.env.ADMIN_PASS || 'admin';

  if (username === ADMIN_USER && password === ADMIN_PASS) {
    const token = jwt.sign({ role: 'admin' }, process.env.JWT_SECRET || 'secret', { expiresIn: '1d' });
    res.json({ success: true, token });
  } else {
    res.status(401).json({ success: false, message: 'Invalid admin credentials' });
  }
});

// Middleware to protect admin routes
const requireAdmin = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');
    if (decoded.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Get Dashboard Stats
router.get('/stats', requireAdmin, async (req, res) => {
  try {
    const usersCount = await pool.query('SELECT COUNT(*) FROM users');
    const farmsCount = await pool.query('SELECT COUNT(*) FROM farms');
    
    // Total historical alerts from alert logs if we have them, else just standard stat
    let totalLogs = 0;
    try {
      const logs = await pool.query('SELECT COUNT(*) FROM farmer_logs');
      totalLogs = parseInt(logs.rows[0].count);
    } catch(e) {}
    
    res.json({
      success: true,
      stats: {
        total_users: parseInt(usersCount.rows[0].count),
        total_farms: parseInt(farmsCount.rows[0].count),
        total_logs: totalLogs,
      }
    });
  } catch (error) {
    console.error("Admin stats error:", error);
    res.status(500).json({ error: error.message });
  }
});

// Get all users
router.get('/users', requireAdmin, async (req, res) => {
  try {
    // using left join to get count of farms
    const users = await pool.query(`
      SELECT u.id, u.name, u.email, u.phone, u.language, u.created_at, COUNT(f.id) as farms_count
      FROM users u
      LEFT JOIN farms f ON u.id = f.user_id
      GROUP BY u.id
      ORDER BY u.created_at DESC
    `);
    res.json({ success: true, users: users.rows });
  } catch (err) {
    console.error("Admin users error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get all farms
router.get('/farms', requireAdmin, async (req, res) => {
  try {
    const farms = await pool.query(`
      SELECT f.id, f.name, f.location, f.latitude, f.longitude, f.created_at, u.name as owner_name 
      FROM farms f 
      LEFT JOIN users u ON f.user_id = u.id 
      ORDER BY f.created_at DESC
    `);
    res.json({ success: true, farms: farms.rows });
  } catch (err) {
    console.error("Admin farms error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get all alerts
router.get('/alerts', requireAdmin, async (req, res) => {
  try {
    const alerts = await pool.query(`
      SELECT a.id, a.type, a.message, a.alert_date, f.name as farm_name 
      FROM alerts a 
      LEFT JOIN farms f ON a.farm_id = f.id 
      ORDER BY a.alert_date DESC
    `);
    res.json({ success: true, alerts: alerts.rows });
  } catch (err) {
    console.error("Admin alerts error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
