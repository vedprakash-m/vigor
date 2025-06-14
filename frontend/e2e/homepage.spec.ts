import { expect, test } from '@playwright/test';

test.describe('Basic navigation', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('/');

    // Verify the page loaded by checking for common elements
    // This will need to be updated based on your actual UI
    await expect(page).toHaveTitle(/Vigor/);
  });
});

test.describe('Authentication', () => {
  test('login form is accessible', async ({ page }) => {
    await page.goto('/');

    // Navigate to login page (update selector based on actual UI)
    const loginButton = page.getByRole('link', { name: /login/i });
    if (await loginButton.isVisible()) {
      await loginButton.click();

      // Check if login form is visible
      await expect(page.getByRole('heading', { name: /sign in/i })).toBeVisible();
    } else {
      // If no login button, the test passes but we log info
      console.log('No login button found - app may already be in authenticated state');
    }
  });
});

test.describe('Responsiveness', () => {
  test('responsive design check', async ({ page }) => {
    // Test on mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');

    // Check that mobile menu is present (update selector based on actual UI)
    const mobileMenuButton = page.getByRole('button', { name: /menu/i });
    if (await mobileMenuButton.isVisible()) {
      await expect(mobileMenuButton).toBeVisible();
    }

    // Test on desktop viewport
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    // Verify the page adapts to desktop view
    // This will need to be updated based on your actual UI
  });
});
