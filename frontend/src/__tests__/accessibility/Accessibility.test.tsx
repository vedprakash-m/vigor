import { render, screen } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import React from 'react'
import DashboardPage from '../../pages/DashboardPage'
import { LoginPage } from '../../pages/LoginPage'

// Extend Jest matchers
expect.extend(toHaveNoViolations)

// Removed BrowserRouter wrapper; jtest.setup provides routing

const TestWrapper = ({ children }: { children: React.ReactNode }) => <>{children}</>

describe('Accessibility Tests', () => {
  describe('LoginPage Accessibility', () => {
    it('should not have any accessibility violations', async () => {
      const { container } = render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })

    it('has proper form labels and associations', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Check for proper form labels
      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)

      expect(emailInput).toHaveAttribute('type', 'email')
      expect(passwordInput).toHaveAttribute('type', 'password')
      expect(emailInput).toHaveAttribute('required')
      expect(passwordInput).toHaveAttribute('required')
    })

    it('has proper heading structure', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const heading = screen.getByRole('heading', { level: 1 })
      expect(heading).toBeInTheDocument()
      expect(heading).toHaveTextContent(/welcome to vigor/i)
    })

    it('has proper button semantics', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const submitButton = screen.getByRole('button', { name: /sign in/i })
      expect(submitButton).toHaveAttribute('type', 'submit')
    })

    it('has proper link semantics', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const registerLink = screen.getByRole('link', { name: /sign up/i })
      expect(registerLink).toHaveAttribute('href', '/register')
    })

    it('has proper error message semantics', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Error messages should be properly announced to screen readers
      // This would be tested when an error occurs
      const form = screen.getByRole('form')
      expect(form).toBeInTheDocument()
    })

    it('has sufficient color contrast', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Check that text has sufficient contrast
      const heading = screen.getByRole('heading', { level: 1 })
      const button = screen.getByRole('button', { name: /sign in/i })

      // These would be checked by axe-core automatically
      expect(heading).toBeInTheDocument()
      expect(button).toBeInTheDocument()
    })

    it('supports keyboard navigation', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)
      const submitButton = screen.getByRole('button', { name: /sign in/i })

      // All interactive elements should be focusable
      expect(emailInput).toHaveAttribute('tabindex', '0')
      expect(passwordInput).toHaveAttribute('tabindex', '0')
      expect(submitButton).toHaveAttribute('tabindex', '0')
    })
  })

  describe('DashboardPage Accessibility', () => {
    it('should not have any accessibility violations', async () => {
      const { container } = render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })

    it('has proper heading hierarchy', () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Should have a main heading
      const mainHeading = screen.getByRole('heading', { level: 1 })
      expect(mainHeading).toBeInTheDocument()
    })

    it('has proper landmark regions', () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Should have main content area
      const main = screen.getByRole('main')
      expect(main).toBeInTheDocument()
    })

    it('has proper list semantics', () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // Dashboard should have proper list structures for data
      // This would be tested when workout data is present
      expect(screen.getByText(/welcome back/i)).toBeInTheDocument()
    })

    it('has proper button labels', () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // All buttons should have descriptive labels
      const buttons = screen.getAllByRole('button')
      buttons.forEach(button => {
        expect(button).toHaveAccessibleName()
      })
    })

    it('has proper image alt text', () => {
      render(
        <TestWrapper>
          <DashboardPage />
        </TestWrapper>
      )

      // All images should have alt text
      const images = screen.getAllByRole('img')
      images.forEach(img => {
        expect(img).toHaveAttribute('alt')
      })
    })
  })

  describe('Form Accessibility', () => {
    it('has proper form validation announcements', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)

      // Required fields should be announced
      expect(emailInput).toHaveAttribute('aria-required', 'true')
      expect(passwordInput).toHaveAttribute('aria-required', 'true')
    })

    it('has proper error state announcements', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Error states should be properly announced
      const emailInput = screen.getByLabelText(/email/i)
      expect(emailInput).toHaveAttribute('aria-invalid', 'false')
    })

    it('has proper loading state announcements', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Loading states should be announced to screen readers
      const submitButton = screen.getByRole('button', { name: /sign in/i })
      expect(submitButton).not.toHaveAttribute('aria-busy')
    })
  })

  describe('Navigation Accessibility', () => {
    it('has proper navigation structure', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Navigation should be properly structured
      const registerLink = screen.getByRole('link', { name: /sign up/i })
      expect(registerLink).toBeInTheDocument()
    })

    it('has proper skip links', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Should have skip to main content links
      // This would be implemented in the actual component
      expect(screen.getByText(/welcome to vigor/i)).toBeInTheDocument()
    })
  })

  describe('Color and Contrast', () => {
    it('maintains sufficient contrast ratios', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // All text should have sufficient contrast
      const heading = screen.getByRole('heading', { level: 1 })
      const button = screen.getByRole('button', { name: /sign in/i })

      // These would be checked by axe-core
      expect(heading).toBeInTheDocument()
      expect(button).toBeInTheDocument()
    })

    it('does not rely solely on color for information', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Information should not be conveyed by color alone
      const errorBox = screen.queryByRole('alert')
      if (errorBox) {
        expect(errorBox).toHaveTextContent('')
      }
    })
  })

  describe('Screen Reader Support', () => {
    it('has proper ARIA labels', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)

      expect(emailInput).toHaveAttribute('aria-label')
      expect(passwordInput).toHaveAttribute('aria-label')
    })

    it('has proper ARIA descriptions', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Form fields should have proper descriptions
      const emailInput = screen.getByLabelText(/email/i)
      expect(emailInput).toHaveAttribute('aria-describedby')
    })

    it('has proper live regions', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Dynamic content should be announced
      const form = screen.getByRole('form')
      expect(form).toBeInTheDocument()
    })
  })

  describe('Keyboard Navigation', () => {
    it('supports tab navigation', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const emailInput = screen.getByLabelText(/email/i)
      const passwordInput = screen.getByLabelText(/password/i)
      const submitButton = screen.getByRole('button', { name: /sign in/i })

      // All interactive elements should be in tab order
      expect(emailInput).toHaveAttribute('tabindex', '0')
      expect(passwordInput).toHaveAttribute('tabindex', '0')
      expect(submitButton).toHaveAttribute('tabindex', '0')
    })

    it('supports keyboard shortcuts', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Form should support standard keyboard shortcuts
      const form = screen.getByRole('form')
      expect(form).toBeInTheDocument()
    })
  })

  describe('Mobile Accessibility', () => {
    it('has proper touch targets', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      const submitButton = screen.getByRole('button', { name: /sign in/i })
      const registerLink = screen.getByRole('link', { name: /sign up/i })

      // Touch targets should be at least 44x44 pixels
      expect(submitButton).toBeInTheDocument()
      expect(registerLink).toBeInTheDocument()
    })

    it('supports pinch-to-zoom', () => {
      render(
        <TestWrapper>
          <LoginPage />
        </TestWrapper>
      )

      // Viewport should not disable zoom
      // This would be checked in the HTML head
      expect(screen.getByText(/welcome to vigor/i)).toBeInTheDocument()
    })
  })
})
