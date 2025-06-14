import { expect, test } from '@playwright/test';

test('Login flow', async ({ page }) => {
  await page.goto('/');

  // Navigate to login page
  await page.getByRole('link', { name: 'Login' }).click();
  await expect(page).toHaveTitle(/Login/);

  // Fill login form
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Login' }).click();

  // Verify successful login
  await expect(page.getByText('Welcome back')).toBeVisible();
});
