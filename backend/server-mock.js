// backend/server-mock.js
// Backend MOCK - sin base de datos, solo para pruebas

const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const JWT_SECRET = 'tu-secreto-aqui';
const REFRESH_SECRET = 'tu-refresh-secreto';

// Usuarios de prueba
const testUsers = {
  'admin@medicontrol.com': {
    id: 1,
    fullName: 'Administrador',
    email: 'admin@medicontrol.com',
    phone: '1234567890',
    role: 'ADMIN',
    password: 'admin123',
    createdAt: new Date().toISOString(),
  },
  'user@medicontrol.com': {
    id: 2,
    fullName: 'Juan García',
    email: 'user@medicontrol.com',
    phone: '9876543210',
    role: 'USER',
    password: 'user123',
    createdAt: new Date().toISOString(),
  },
  'doctor@medicontrol.com': {
    id: 3,
    fullName: 'Dr. María López',
    email: 'doctor@medicontrol.com',
    phone: '5555555555',
    role: 'DOCTOR',
    password: 'doctor123',
    createdAt: new Date().toISOString(),
  },
};

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

// POST /api/auth/login
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  console.log(`🔑 Login attempt: ${email}`);

  const user = testUsers[email];

  if (!user || user.password !== password) {
    return res.status(401).json({ error: 'Credenciales inválidas' });
  }

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

  const { password: _, ...userWithoutPassword } = user;

  console.log(`✅ Login exitoso: ${email} (${user.role})`);

  res.json({
    user: userWithoutPassword,
    token,
    refreshToken,
  });
});

// POST /api/auth/register
app.post('/api/auth/register', (req, res) => {
  const { fullName, email, password, phone } = req.body;

  console.log(`📝 Register attempt: ${email}`);

  if (testUsers[email]) {
    return res.status(400).json({ error: 'Email ya registrado' });
  }

  const newUserId = Math.max(...Object.values(testUsers).map(u => u.id)) + 1;

  const newUser = {
    id: newUserId,
    fullName,
    email,
    phone,
    role: 'USER',
    password,
    createdAt: new Date().toISOString(),
  };

  testUsers[email] = newUser;

  const token = jwt.sign(
    { id: newUser.id, role: newUser.role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );

  const refreshToken = jwt.sign(
    { id: newUser.id },
    REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  const { password: _, ...userWithoutPassword } = newUser;

  console.log(`✅ Registro exitoso: ${email}`);

  res.status(201).json({
    user: userWithoutPassword,
    token,
    refreshToken,
  });
});

// GET /api/profile
app.get('/api/profile', authMiddleware, (req, res) => {
  const user = Object.values(testUsers).find(u => u.id === req.userId);
  if (!user) {
    return res.status(404).json({ error: 'Usuario no encontrado' });
  }
  const { password: _, ...userWithoutPassword } = user;
  res.json(userWithoutPassword);
});

// GET /api/doctors
app.get('/api/doctors', authMiddleware, (req, res) => {
  const doctors = [
    {
      id: 1,
      name: 'Dr. Carlos Rodríguez',
      specialty: 'Cardiología',
      phone: '555-0101',
      email: 'carlos@hospital.com',
      clinic: 'Hospital Central',
    },
    {
      id: 2,
      name: 'Dra. Ana García',
      specialty: 'Pediatría',
      phone: '555-0102',
      email: 'ana@hospital.com',
      clinic: 'Hospital Central',
    },
    {
      id: 3,
      name: 'Dr. Luis Martínez',
      specialty: 'Neurología',
      phone: '555-0103',
      email: 'luis@hospital.com',
      clinic: 'Clínica San Lucas',
    },
  ];
  res.json(doctors);
});

// GET /api/appointments
app.get('/api/appointments', authMiddleware, (req, res) => {
  const appointments = [
    {
      id: 1,
      doctorName: 'Dr. Carlos Rodríguez',
      specialty: 'Cardiología',
      date: new Date(Date.now() + 86400000).toISOString(),
      reason: 'Chequeo general',
      location: 'Hospital Central',
    },
    {
      id: 2,
      doctorName: 'Dra. Ana García',
      specialty: 'Pediatría',
      date: new Date(Date.now() + 172800000).toISOString(),
      reason: 'Vacuna',
      location: 'Hospital Central',
    },
  ];
  res.json(appointments);
});

// GET /api/emergency-contacts
app.get('/api/emergency-contacts', authMiddleware, (req, res) => {
  const contacts = [
    {
      id: 1,
      name: 'María García',
      relation: 'Esposa',
      phone: '555-1234',
      notes: 'Contacto principal',
    },
    {
      id: 2,
      name: 'Carlos García',
      relation: 'Hijo',
      phone: '555-5678',
      notes: 'Contacto secundario',
    },
  ];
  res.json(contacts);
});

// GET /api/medical-records
app.get('/api/medical-records', authMiddleware, (req, res) => {
  const records = [
    {
      id: 1,
      title: 'Presión Arterial',
      description: 'Medición de presión arterial',
      details: ['120/80 mmHg', 'Normal'],
    },
    {
      id: 2,
      title: 'Análisis de Sangre',
      description: 'Resultados de laboratorio',
      details: ['Colesterol: 180 mg/dL', 'Glucosa: 95 mg/dL'],
    },
  ];
  res.json(records);
});

// Admin endpoints
app.get('/api/admin/users', authMiddleware, (req, res) => {
  if (req.userRole !== 'ADMIN') {
    return res.status(403).json({ error: 'Acceso denegado' });
  }
  const users = Object.values(testUsers).map(u => {
    const { password: _, ...user } = u;
    return user;
  });
  res.json(users);
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════╗
║   🏥 MediControl Backend MOCK - Ejecutándose   ║
╚════════════════════════════════════════════════╝

✅ Puerto: ${PORT}
✅ Modo: MOCK (sin base de datos)
✅ URL: http://localhost:${PORT}

📝 USUARIOS DE PRUEBA:
   Admin:  admin@medicontrol.com / admin123
   User:   user@medicontrol.com / user123
   Doctor: doctor@medicontrol.com / doctor123

🔗 Endpoints disponibles:
   POST   /api/auth/login
   POST   /api/auth/register
   GET    /api/profile
   GET    /api/doctors
   GET    /api/appointments
   GET    /api/emergency-contacts
   GET    /api/medical-records
   GET    /api/admin/users
   GET    /api/health

⚠️  NOTA: Este es un backend MOCK para desarrollo.
   No persiste datos. Reinicia para resetear.
  `);
});
