import { expect, test } from '@playwright/test';

test.describe('API connectivity', () => {
  test('health check endpoint returns 200', async ({ request }) => {
    // Adjust the URL to match your actual health check endpoint
    const response = await request.get('/api/health');

    // Check response status
    expect(response.status()).toBe(200);

    // Check response contains expected data
    const data = await response.json();
    expect(data).toHaveProperty('status');
  });
});

test.describe('Authentication Flow', () => {
  test('auth API endpoints are accessible', async ({ request }) => {
    // Try to access an auth-protected endpoint without credentials
    // This should redirect or return 401/403
    const response = await request.get('/api/protected-route');

    // Should either redirect (302) or return unauthorized (401) or forbidden (403)
    expect([302, 401, 403]).toContain(response.status());
  });
});
