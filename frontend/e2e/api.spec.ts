import { expect, test } from '@playwright/test';

test.describe('API connectivity', () => {
  test('health check endpoint returns 200', async ({ request }) => {
    // Test the actual health endpoint from backend
    const response = await request.get('http://localhost:8000/health');

    // Check response status
    expect(response.status()).toBe(200);

    // Check response contains expected data
    const data = await response.json();
    expect(data).toHaveProperty('status');
    expect(data.status).toBe('healthy');
  });
});

test.describe('Authentication Flow', () => {
  test('auth API endpoints are accessible', async ({ request }) => {
    // Try to access an auth-protected endpoint without credentials
    // Test the actual auth endpoint structure
    const response = await request.get('http://localhost:8000/auth/me');

    // Should return unauthorized (401) for protected route without auth
    expect(response.status()).toBe(401);
  });
});
