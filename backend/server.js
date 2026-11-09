const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');
const path = require('path');

const app = express();
const port = Number(process.env.PORT || 3000);
const databasePath = process.env.SQLITE_PATH || (process.env.VERCEL ? '/tmp/medicontrol.sqlite' : path.join(__dirname, 'medicontrol.sqlite'));
const db = new Database(databasePath);

db.pragma('journal_mode = WAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    fullName TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    bloodType TEXT NOT NULL,
    allergies TEXT NOT NULL,
    address TEXT NOT NULL,
    emergencyContactName TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS app_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS doctors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    clinic TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doctorName TEXT NOT NULL,
    specialty TEXT NOT NULL,
    date TEXT NOT NULL,
    reason TEXT NOT NULL,
    location TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS emergency_contacts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    relation TEXT NOT NULL,
    phone TEXT NOT NULL,
    notes TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS medical_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    details TEXT NOT NULL
  );
`);

const seedData = db.transaction(() => {
  const seeded = db.prepare(
    "SELECT value FROM app_metadata WHERE key = 'demo_data_seeded'",
  ).get();
  if (seeded) return;

  db.prepare(`
    INSERT OR IGNORE INTO profile
      (id, fullName, email, phone, bloodType, allergies, address, emergencyContactName)
    VALUES (1, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    'Eduardo Rodríguez',
    'eduardo@medicontrol.com',
    '+57 320 123 4567',
    'O+',
    'Penicilina, mariscos',
    'Calle 45 #12-34, Medellín',
    'María Rodríguez',
  );

  const seedIfEmpty = (table, insert, rows) => {
    const count = db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).get().count;
    if (count === 0) {
      const statement = db.prepare(insert);
      for (const row of rows) statement.run(...row);
    }
  };

  seedIfEmpty(
    'doctors',
    'INSERT INTO doctors (name, specialty, phone, email, clinic) VALUES (?, ?, ?, ?, ?)',
    [
      ['Dra. Ana López', 'Cardiología', '+57 300 111 2222', 'ana.lopez@clinica.com', 'Clínica del Norte'],
      ['Dr. Camilo Pérez', 'Medicina general', '+57 301 333 4444', 'camilo.perez@consultorio.com', 'Consultorio central'],
    ],
  );
  seedIfEmpty(
    'appointments',
    'INSERT INTO appointments (doctorName, specialty, date, reason, location) VALUES (?, ?, ?, ?, ?)',
    [
      ['Dra. Ana López', 'Cardiología', '2026-09-28T10:30:00.000Z', 'Control de presión arterial', 'Clínica del Norte'],
      ['Dr. Camilo Pérez', 'Medicina general', '2026-10-05T09:00:00.000Z', 'Chequeo general', 'Consultorio central'],
    ],
  );
  seedIfEmpty(
    'emergency_contacts',
    'INSERT INTO emergency_contacts (name, relation, phone, notes) VALUES (?, ?, ?, ?)',
    [
      ['María Rodríguez', 'Madre', '+57 310 987 6543', 'Contacto principal en caso de emergencia.'],
      ['Luis Rodríguez', 'Hermano', '+57 311 222 3344', 'Disponibilidad en la tarde.'],
    ],
  );
  seedIfEmpty(
    'medical_records',
    'INSERT INTO medical_records (title, description, details) VALUES (?, ?, ?)',
    [
      ['Antecedentes', 'Historial médico general y observaciones importantes.', JSON.stringify([
        'Hipertensión controlada',
        'No presenta alergias graves además de las reportadas',
        'Última revisión: mayo 2026',
      ])],
      ['Resumen actual', 'Información relevante para la atención médica.', JSON.stringify([
        'Tipo de sangre: O+',
        'Medicamentos actuales: Vitamina D y Aspirina',
        'Hábitos: ejercicio moderado tres veces por semana',
      ])],
    ],
  );

  db.prepare(
    "INSERT INTO app_metadata (key, value) VALUES ('demo_data_seeded', '1')",
  ).run();
});

seedData();

app.use(cors());
app.use(express.json());

app.get('/api/profile', (req, res) => {
  res.json(db.prepare('SELECT fullName, email, phone, bloodType, allergies, address, emergencyContactName FROM profile WHERE id = 1').get());
});

app.get('/api/doctors', (req, res) => {
  res.json(db.prepare('SELECT id, name, specialty, phone, email, clinic FROM doctors ORDER BY name COLLATE NOCASE, id').all());
});

app.post('/api/doctors', (req, res) => {
  const doctor = req.body;
  if (!doctor || !doctor.name || !doctor.specialty) {
    return res.status(400).json({ message: 'Faltan datos del médico' });
  }

  const result = db.prepare(
    'INSERT INTO doctors (name, specialty, phone, email, clinic) VALUES (?, ?, ?, ?, ?)',
  ).run(doctor.name, doctor.specialty, doctor.phone || '', doctor.email || '', doctor.clinic || '');
  return res.status(201).json({ id: Number(result.lastInsertRowid), ...doctor });
});

app.delete('/api/doctors/:id', (req, res) => {
  const result = db.prepare('DELETE FROM doctors WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ message: 'Médico no encontrado' });
  return res.sendStatus(200);
});

app.get('/api/appointments', (req, res) => {
  res.json(db.prepare('SELECT id, doctorName, specialty, date, reason, location FROM appointments ORDER BY date').all());
});

app.post('/api/appointments', (req, res) => {
  const appointment = req.body;
  if (!appointment || !appointment.doctorName || !appointment.specialty) {
    return res.status(400).json({ message: 'Faltan datos de la cita' });
  }

  const result = db.prepare(
    'INSERT INTO appointments (doctorName, specialty, date, reason, location) VALUES (?, ?, ?, ?, ?)',
  ).run(
    appointment.doctorName,
    appointment.specialty,
    appointment.date || new Date().toISOString(),
    appointment.reason || '',
    appointment.location || '',
  );
  return res.status(201).json({ id: Number(result.lastInsertRowid), ...appointment });
});

app.delete('/api/appointments/:id', (req, res) => {
  const result = db.prepare('DELETE FROM appointments WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ message: 'Cita no encontrada' });
  return res.sendStatus(200);
});

app.get('/api/emergency-contacts', (req, res) => {
  res.json(db.prepare('SELECT id, name, relation, phone, notes FROM emergency_contacts ORDER BY id').all());
});

app.post('/api/emergency-contacts', (req, res) => {
  const contact = req.body;
  if (!contact || !contact.name || !contact.phone) {
    return res.status(400).json({ message: 'Faltan datos del contacto' });
  }

  const result = db.prepare(
    'INSERT INTO emergency_contacts (name, relation, phone, notes) VALUES (?, ?, ?, ?)',
  ).run(contact.name, contact.relation || '', contact.phone, contact.notes || '');
  return res.status(201).json({ id: Number(result.lastInsertRowid), ...contact });
});

app.delete('/api/emergency-contacts/:id', (req, res) => {
  const result = db.prepare('DELETE FROM emergency_contacts WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ message: 'Contacto no encontrado' });
  return res.sendStatus(200);
});

app.get('/api/medical-records', (req, res) => {
  const records = db.prepare(
    'SELECT id, title, description, details FROM medical_records ORDER BY id',
  ).all();
  res.json(records.map((record) => ({ ...record, details: JSON.parse(record.details) })));
});

app.post('/api/medical-records', (req, res) => {
  const record = req.body;
  if (!record || !record.title || !record.description) {
    return res.status(400).json({ message: 'Faltan datos del registro' });
  }

  const details = Array.isArray(record.details) ? record.details : [];
  const result = db.prepare(
    'INSERT INTO medical_records (title, description, details) VALUES (?, ?, ?)',
  ).run(record.title, record.description, JSON.stringify(details));
  return res.status(201).json({ id: Number(result.lastInsertRowid), ...record, details });
});

app.delete('/api/medical-records/:id', (req, res) => {
  const result = db.prepare('DELETE FROM medical_records WHERE id = ?').run(req.params.id);
  if (result.changes === 0) return res.status(404).json({ message: 'Registro no encontrado' });
  return res.sendStatus(200);
});

let server;
if (require.main === module) {
  server = app.listen(port, '0.0.0.0', () => {
    console.log(`MediControl backend running at http://0.0.0.0:${port} using ${databasePath}`);
  });
}

module.exports = app;

