const request = require('supertest');

const app = require('../app');
const { pool } = require('../config/database');

afterAll(async () => {
  await pool.end();
});

describe('GET /health', () => {
  it('returns the service health payload', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      status: 'ok',
      service: 'vrisharopan-api',
      version: '1.0.0',
    });
    expect(typeof response.body.timestamp).toBe('string');
  });
});