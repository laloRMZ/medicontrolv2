// BACKEND EXAMPLE - NODE.JS / EXPRESS
// Archivo: backend/server.js

const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// Configuración de BD
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'medicontrol',
  waitForConnections: true,
  connectionLimit: 10,
});

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'your-refresh-key';

// Middleware de autenticación
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.id;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token inválido' });
  }
};

// Middleware admin
const adminMiddleware = (req, res, next) => {
  if (req.userRole !== 'ADMIN') {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  next();
};

// ========== AUTH ENDPOINTS ==========

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { fullName, email, password, phone } = req.body;
    const conn = await pool.getConnection();

    // Verificar si email existe
    const [users] = await conn.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (users.length > 0) {
      await conn.release();
      return res.status(400).json({ error: 'Email ya registrado' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const [result] = await conn.query(
      'INSERT INTO users (fullName, email, password, phone, role) VALUES (?, ?, ?, ?, ?)',
      [fullName, email, hashedPassword, phone, 'USER']
    );

    const userId = result.insertId;

    // Generar tokens
    const token = jwt.sign(
      { id: userId, role: 'USER' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const refreshToken = jwt.sign(
      { id: userId },
      REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    // Obtener datos del usuario
    const [userRows] = await conn.query(
      'SELECT id, fullName, email, phone, role, createdAt FROM users WHERE id = ?',
      [userId]
    );

    await conn.release();

    res.status(201).json({
      user: userRows[0],
      token,
      refreshToken,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Error en registro' });
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const conn = await pool.getConnection();

    const [users] = await conn.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      await conn.release();
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const user = users[0];

    // Verificar password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      await conn.release();
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    // Generar tokens
    const token = jwt.sign(
      { id: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    const refreshToken = jwt.sign(
      { id: user.id },
      REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    await conn.release();

    res.json({
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profileImage: user.profileImage,
        createdAt: user.createdAt,
      },
      token,
      refreshToken,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Error en login' });
  }
});

// POST /api/auth/refresh
app.post('/api/auth/refresh', (req, res) => {
  try {
    const { refreshToken } = req.body;

    const decoded = jwt.verify(refreshToken, REFRESH_SECRET);

    const newToken = jwt.sign(
      { id: decoded.id },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({ token: newToken });
  } catch (error) {
    res.status(401).json({ error: 'Refresh token inválido' });
  }
});

// ========== USER ENDPOINTS ==========

// GET /api/profile
app.get('/api/profile', authMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [users] = await conn.query(
      'SELECT id, fullName, email, phone FROM users WHERE id = ?',
      [req.userId]
    );

    await conn.release();

    if (users.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.json(users[0]);
  } catch (error) {
    res.status(500).json({ error: 'Error obteniendo perfil' });
  }
});

// PUT /api/profile
app.put('/api/profile', authMiddleware, async (req, res) => {
  try {
    const { fullName, phone } = req.body;
    const conn = await pool.getConnection();

    await conn.query(
      'UPDATE users SET fullName = ?, phone = ? WHERE id = ?',
      [fullName, phone, req.userId]
    );

    const [users] = await conn.query(
      'SELECT id, fullName, email, phone FROM users WHERE id = ?',
      [req.userId]
    );

    await conn.release();

    res.json(users[0]);
  } catch (error) {
    res.status(500).json({ error: 'Error actualizando perfil' });
  }
});

// ========== ADMIN ENDPOINTS ==========

// GET /api/admin/users
app.get('/api/admin/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [users] = await conn.query(
      'SELECT id, fullName, email, phone, role, createdAt FROM users ORDER BY createdAt DESC'
    );

    await conn.release();

    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Error obteniendo usuarios' });
  }
});

// POST /api/admin/users
app.post('/api/admin/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { fullName, email, phone, role } = req.body;
    const conn = await pool.getConnection();

    const defaultPassword = 'TempPass123!';
    const hashedPassword = await bcrypt.hash(defaultPassword, 10);

    const [result] = await conn.query(
      'INSERT INTO users (fullName, email, password, phone, role) VALUES (?, ?, ?, ?, ?)',
      [fullName, email, hashedPassword, phone, role]
    );

    await conn.release();

    res.status(201).json({ id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: 'Error creando usuario' });
  }
});

// PUT /api/admin/users/:id
app.put('/api/admin/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, email, phone, role } = req.body;
    const conn = await pool.getConnection();

    await conn.query(
      'UPDATE users SET fullName = ?, email = ?, phone = ?, role = ? WHERE id = ?',
      [fullName, email, phone, role, id]
    );

    await conn.release();

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Error actualizando usuario' });
  }
});

// DELETE /api/admin/users/:id
app.delete('/api/admin/users/:id', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const conn = await pool.getConnection();

    await conn.query('DELETE FROM users WHERE id = ?', [id]);

    await conn.release();

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Error eliminando usuario' });
  }
});

// ========== DOCTORS ENDPOINTS ==========

// GET /api/doctors
app.get('/api/doctors', authMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [doctors] = await conn.query(
      'SELECT * FROM doctors'
    );

    await conn.release();

    res.json(doctors);
  } catch (error) {
    res.status(500).json({ error: 'Error obteniendo médicos' });
  }
});

// POST /api/doctors
app.post('/api/doctors', authMiddleware, async (req, res) => {
  try {
    const { name, specialty, phone, email, clinic } = req.body;
    const conn = await pool.getConnection();

    const [result] = await conn.query(
      'INSERT INTO doctors (name, specialty, phone, email, clinic) VALUES (?, ?, ?, ?, ?)',
      [name, specialty, phone, email, clinic]
    );

    await conn.release();

    res.status(201).json({ id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: 'Error creando médico' });
  }
});

// ========== APPOINTMENTS ENDPOINTS ==========

// GET /api/appointments
app.get('/api/appointments', authMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [appointments] = await conn.query(
      `SELECT a.*, d.name as doctorName, d.specialty
       FROM appointments a
       LEFT JOIN doctors d ON a.doctorId = d.id
       WHERE a.userId = ?
       ORDER BY a.date DESC`,
      [req.userId]
    );

    await conn.release();

    res.json(appointments);
  } catch (error) {
    res.status(500).json({ error: 'Error obteniendo citas' });
  }
});

// POST /api/appointments
app.post('/api/appointments', authMiddleware, async (req, res) => {
  try {
    const { doctorId, date, reason, location } = req.body;
    const conn = await pool.getConnection();

    const [result] = await conn.query(
      'INSERT INTO appointments (userId, doctorId, date, reason, location, status) VALUES (?, ?, ?, ?, ?, ?)',
      [req.userId, doctorId, date, reason, location, 'PENDING']
    );

    await conn.release();

    res.status(201).json({ id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: 'Error creando cita' });
  }
});

// DELETE /api/appointments/:id
app.delete('/api/appointments/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const conn = await pool.getConnection();

    await conn.query('DELETE FROM appointments WHERE id = ? AND userId = ?', [id, req.userId]);

    await conn.release();

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Error eliminando cita' });
  }
});

// ========== REPORTS ENDPOINTS (ADMIN) ==========

// GET /api/admin/reports/users
app.get('/api/admin/reports/users', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [stats] = await conn.query(`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN role = 'USER' THEN 1 ELSE 0 END) as users,
        SUM(CASE WHEN role = 'DOCTOR' THEN 1 ELSE 0 END) as doctors,
        SUM(CASE WHEN role = 'ADMIN' THEN 1 ELSE 0 END) as admins
      FROM users
    `);

    await conn.release();

    res.json(stats[0]);
  } catch (error) {
    res.status(500).json({ error: 'Error en reporte' });
  }
});

// GET /api/admin/reports/appointments
app.get('/api/admin/reports/appointments', authMiddleware, adminMiddleware, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    const [stats] = await conn.query(`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'PENDING' THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN status = 'CONFIRMED' THEN 1 ELSE 0 END) as confirmed,
        SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) as cancelled,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed
      FROM appointments
    `);

    await conn.release();

    res.json(stats[0]);
  } catch (error) {
    res.status(500).json({ error: 'Error en reporte' });
  }
});

// ========== ERROR HANDLER ==========

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor MediControl ejecutándose en puerto ${PORT}`);
});

// ========== NOTAS ==========
/*
DEPENDENCIAS NECESARIAS:
npm install express jsonwebtoken bcryptjs mysql2 cors dotenv

.env REQUERIDO:
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=medicontrol
JWT_SECRET=tu_clave_secreta_aqui
REFRESH_SECRET=tu_refresh_secret_aqui
PORT=3000

EJECUTAR:
node server.js
*/
