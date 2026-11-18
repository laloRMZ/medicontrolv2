const { describe, it, before, after } = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const { app, db } = require('../server');

describe('Fase 3: Pruebas de Integración - API REST & SQLite Database', () => {
  let server;
  let baseUrl;
  let createdAppointmentId = null;
  const createdResourceIds = {
    doctor: null,
    contact: null,
    record: null,
  };

  before(async () => {
    // Iniciar servidor en un puerto efímero (0) para evitar colisiones
    await new Promise((resolve) => {
      server = app.listen(0, () => {
        const port = server.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });
  });

  after(async () => {
    // Limpieza posterior y cierre del socket
    if (createdAppointmentId) {
      db.prepare('DELETE FROM appointments WHERE id = ?').run(createdAppointmentId);
    }
    if (createdResourceIds.doctor) {
      db.prepare('DELETE FROM doctors WHERE id = ?').run(createdResourceIds.doctor);
    }
    if (createdResourceIds.contact) {
      db.prepare('DELETE FROM emergency_contacts WHERE id = ?').run(createdResourceIds.contact);
    }
    if (createdResourceIds.record) {
      db.prepare('DELETE FROM medical_records WHERE id = ?').run(createdResourceIds.record);
    }
    await new Promise((resolve) => server.close(resolve));
  });

  // 1. FLUJO CORRECTO: Cliente HTTP -> Controlador Express -> Motor SQLite
  it('Prueba Integración 1 (Flujo Correcto): Inserta vía POST HTTP y comprueba persistencia física en SQLite', async () => {
    const payload = {
      doctorName: 'Dra. Valery Integración',
      specialty: 'Cardiología Pediátrica',
      date: '2026-11-15T09:00:00.000Z',
      location: 'Hospital Ángeles',
      reason: 'Control semestral de seguimiento'
    };

    // 1.1 Ejecutar petición HTTP POST real
    const response = await fetch(`${baseUrl}/api/appointments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    assert.strictEqual(response.status, 201, 'El código de respuesta debe ser 201 Created');
    const responseData = await response.json();
    assert.ok(responseData.id, 'Debe devolver un ID numérico generado');
    createdAppointmentId = responseData.id;

    // 1.2 Verificación física directa en el motor SQLite (sin mocks)
    const rowInDb = db.prepare('SELECT * FROM appointments WHERE id = ?').get(createdAppointmentId);
    assert.ok(rowInDb, 'El registro debe existir físicamente en la tabla SQLite appointments');
    assert.strictEqual(rowInDb.doctorName, payload.doctorName);
    assert.strictEqual(rowInDb.specialty, payload.specialty);
    assert.strictEqual(rowInDb.location, payload.location);
    assert.strictEqual(rowInDb.reason, payload.reason);

    // 1.3 Verificación vía HTTP GET
    const getResponse = await fetch(`${baseUrl}/api/appointments`);
    assert.strictEqual(getResponse.status, 200);
    const appointmentsList = await getResponse.json();
    assert.ok(Array.isArray(appointmentsList), 'Debe devolver un arreglo');
    const found = appointmentsList.find(a => a.id === createdAppointmentId);
    assert.ok(found, 'La cita recién insertada debe figurar en la respuesta GET');
  });

  // 2. MANEJO DE ERRORES E INTEGRIDAD TRANSACCIONAL
  it('Prueba Integración 2 (Manejo de Errores): Rechaza payload incompleto (400) y maneja 404 en borrado inexistente', async () => {
    const initialCount = db.prepare('SELECT COUNT(*) AS count FROM appointments').get().count;

    // 2.1 Enviar payload inválido (sin specialty)
    const invalidPayload = {
      doctorName: 'Dr. Sin Especialidad'
    };

    const badResponse = await fetch(`${baseUrl}/api/appointments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(invalidPayload)
    });

    assert.strictEqual(badResponse.status, 400, 'Debe responder 400 Bad Request');
    const errorBody = await badResponse.json();
    assert.strictEqual(errorBody.message, 'Faltan datos de la cita');

    // Verificar que NO se insertó nada en la base de datos (integridad referencial)
    const countAfterBadPost = db.prepare('SELECT COUNT(*) AS count FROM appointments').get().count;
    assert.strictEqual(countAfterBadPost, initialCount, 'La base de datos no debe alterar su conteo de filas ante un error');

    // 2.2 La validación semántica debe diferenciar fecha inválida de campos ausentes.
    const invalidDateResponse = await fetch(`${baseUrl}/api/appointments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        doctorName: 'Dr. Fecha Inválida',
        specialty: 'Medicina general',
        date: 'no-es-una-fecha',
        reason: 'Prueba',
        location: 'Clínica',
      }),
    });
    assert.strictEqual(invalidDateResponse.status, 422);

    // 2.3 Intentar eliminar un ID inexistente
    const notFoundDelete = await fetch(`${baseUrl}/api/appointments/999999`, {
      method: 'DELETE'
    });
    assert.strictEqual(notFoundDelete.status, 404, 'Debe responder 404 Not Found para IDs inexistentes');

    // 2.4 Borrado exitoso del registro creado
    if (createdAppointmentId) {
      const deleteResponse = await fetch(`${baseUrl}/api/appointments/${createdAppointmentId}`, {
        method: 'DELETE'
      });
      assert.strictEqual(deleteResponse.status, 200, 'Debe responder 200 OK en borrado exitoso');

      // Verificar purgado en SQLite
      const purgedRow = db.prepare('SELECT * FROM appointments WHERE id = ?').get(createdAppointmentId);
      assert.strictEqual(purgedRow, undefined, 'El registro debe ser eliminado físicamente de SQLite');
      createdAppointmentId = null; // ya fue limpiado
    }
  });

  it('Prueba Integración 3: valida y elimina médicos, contactos y registros médicos', async () => {
    const profileResponse = await fetch(`${baseUrl}/api/profile`);
    assert.strictEqual(profileResponse.status, 200);
    assert.ok((await profileResponse.json()).fullName);

    const invalidDoctorResponse = await fetch(`${baseUrl}/api/doctors`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Dra. Sin Especialidad' }),
    });
    assert.strictEqual(invalidDoctorResponse.status, 400);

    const doctorResponse = await fetch(`${baseUrl}/api/doctors`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Dra. Recurso Temporal',
        specialty: 'Neurología',
      }),
    });
    assert.strictEqual(doctorResponse.status, 201);
    createdResourceIds.doctor = (await doctorResponse.json()).id;

    const invalidContactResponse = await fetch(`${baseUrl}/api/emergency-contacts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Contacto sin teléfono' }),
    });
    assert.strictEqual(invalidContactResponse.status, 400);

    const contactResponse = await fetch(`${baseUrl}/api/emergency-contacts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Contacto Temporal',
        relation: 'Amistad',
        phone: '+57 300 000 0000',
      }),
    });
    assert.strictEqual(contactResponse.status, 201);
    createdResourceIds.contact = (await contactResponse.json()).id;

    const invalidRecordResponse = await fetch(`${baseUrl}/api/medical-records`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Registro sin descripción' }),
    });
    assert.strictEqual(invalidRecordResponse.status, 400);

    const recordResponse = await fetch(`${baseUrl}/api/medical-records`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Registro temporal',
        description: 'Creado por una prueba White Box.',
        details: ['Evidencia automatizada'],
      }),
    });
    assert.strictEqual(recordResponse.status, 201);
    createdResourceIds.record = (await recordResponse.json()).id;

    for (const [resource, id] of Object.entries(createdResourceIds)) {
      const deleteResponse = await fetch(`${baseUrl}/api/${resource === 'record' ? 'medical-records' : resource === 'contact' ? 'emergency-contacts' : 'doctors'}/${id}`, {
        method: 'DELETE',
      });
      assert.strictEqual(deleteResponse.status, 200);
      createdResourceIds[resource] = null;
    }
  });
});
