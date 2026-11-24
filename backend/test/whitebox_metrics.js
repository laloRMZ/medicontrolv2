const fs = require('node:fs');
const path = require('node:path');
const { performance } = require('node:perf_hooks');
const { app, db } = require('../server');

const request = async (baseUrl, pathName, options = {}) => {
  const startedAt = performance.now();
  const response = await fetch(`${baseUrl}${pathName}`, options);
  const body = await response.text();
  return {
    status: response.status,
    elapsedMs: Number((performance.now() - startedAt).toFixed(3)),
    responseBytes: Buffer.byteLength(body),
  };
};

const average = (values) =>
  Number((values.reduce((sum, value) => sum + value, 0) / values.length).toFixed(3));

const percentile95 = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(sorted.length * 0.95) - 1];
};

const createAppointment = async (baseUrl, sequence) => {
  const body = JSON.stringify({
    doctorName: `Carga White Box ${sequence}`,
    specialty: 'Medicina general',
    date: '2026-11-15T09:00:00.000Z',
    reason: 'Prueba de carga controlada',
    location: 'Entorno local',
  });
  const startedAt = performance.now();
  const response = await fetch(`${baseUrl}/api/appointments`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  const responseBody = await response.json();
  return {
    id: responseBody.id,
    status: response.status,
    elapsedMs: Number((performance.now() - startedAt).toFixed(3)),
    requestBytes: Buffer.byteLength(body),
  };
};

const runWriteScenario = async (baseUrl, concurrentUsers) => {
  const measurements = [];
  const createdIds = [];
  try {
    for (let sequence = 0; sequence < 20; sequence += concurrentUsers) {
      const batchSize = Math.min(concurrentUsers, 20 - sequence);
      const batch = await Promise.all(
        Array.from(
          { length: batchSize },
          (_, offset) => createAppointment(baseUrl, `${concurrentUsers}-${sequence + offset}`),
        ),
      );
      measurements.push(...batch);
      createdIds.push(...batch.map(({ id }) => id));
    }
    const times = measurements.map(({ elapsedMs }) => elapsedMs);
    return {
      concurrentUsers,
      requests: measurements.length,
      successRate: `${measurements.filter(({ status }) => status === 201).length}/${measurements.length}`,
      averageMs: average(times),
      p95Ms: percentile95(times),
      uploadMbps: Number(
        (
          (measurements[0].requestBytes * 8) /
          (measurements[0].elapsedMs / 1000) /
          1000000
        ).toFixed(3),
      ),
    };
  } finally {
    for (const id of createdIds) {
      await fetch(`${baseUrl}/api/appointments/${id}`, { method: 'DELETE' });
    }
  }
};

const run = async () => {
  const server = await new Promise((resolve) => {
    const instance = app.listen(0, '127.0.0.1', () => resolve(instance));
  });
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  try {
    const requests = [];
    for (let index = 1; index <= 10; index += 1) {
      requests.push({ request: index, ...(await request(baseUrl, '/api/appointments')) });
    }

    const queryStatement = db.prepare(
      'SELECT id, doctorName, specialty, date, reason, location FROM appointments ORDER BY date',
    );
    const queries = [1, 2, 3].map((query) => {
      const startedAt = performance.now();
      const rows = queryStatement.all();
      return {
        query,
        elapsedMs: Number((performance.now() - startedAt).toFixed(3)),
        rows: rows.length,
      };
    });

    const times = requests.map((measurement) => measurement.elapsedMs);
    const writeLoad = [];
    for (const concurrentUsers of [1, 5, 10]) {
      writeLoad.push(await runWriteScenario(baseUrl, concurrentUsers));
    }
    const metrics = {
      executedAt: new Date().toISOString(),
      environment: {
        transport: 'HTTP loopback (127.0.0.1)',
        endpoint: 'GET /api/appointments',
        database: 'SQLite',
      },
      requests,
      httpSummary: {
        averageMs: average(times),
        minMs: Math.min(...times),
        maxMs: Math.max(...times),
        p95Ms: percentile95(times),
        responseBytes: requests[0].responseBytes,
        successRate: `${requests.filter(({ status }) => status === 200).length}/${requests.length}`,
        downloadMbps: Number(
          (
            (requests[0].responseBytes * 8) /
            (requests[0].elapsedMs / 1000) /
            1000000
          ).toFixed(3),
        ),
      },
      database: {
        queries,
        averageMs: average(queries.map((measurement) => measurement.elapsedMs)),
        queryPlan: db
          .prepare(
            'EXPLAIN QUERY PLAN SELECT id, doctorName, specialty, date, reason, location FROM appointments ORDER BY date',
          )
          .all(),
      },
      writeLoad,
    };

    const outputDirectory = path.join(__dirname, '..', 'test-results');
    fs.mkdirSync(outputDirectory, { recursive: true });
    const outputPath = path.join(outputDirectory, 'whitebox-metrics.json');
    fs.writeFileSync(outputPath, `${JSON.stringify(metrics, null, 2)}\n`);
    console.log(JSON.stringify(metrics, null, 2));
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
};

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
