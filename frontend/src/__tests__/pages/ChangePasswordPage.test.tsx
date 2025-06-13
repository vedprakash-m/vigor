import { ChakraProvider, defaultSystem } from '@chakra-ui/react'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { ChangePasswordPage } from '../../pages/ChangePasswordPage'

// Mock window.alert
const mockAlert = jest.spyOn(window, 'alert').mockImplementation(() => {})

// Custom render function with ChakraProvider
const renderWithChakra = (component: React.ReactElement) => {
  return render(
    <ChakraProvider value={defaultSystem}>
      {component}
    </ChakraProvider>
  )
}

describe('ChangePasswordPage', () => {
  beforeEach(() => {
    mockAlert.mockClear()
  })

  afterAll(() => {
    mockAlert.mockRestore()
  })

  it('renders change password page with heading', () => {
    renderWithChakra(<ChangePasswordPage />)

    expect(screen.getByRole('heading', { name: /change password/i })).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Enter your current password')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Enter your new password')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Confirm your new password')).toBeInTheDocument()
  })

  it('shows validation error when fields are empty', async () => {
    renderWithChakra(<ChangePasswordPage />)

    // Fill in only one field to trigger validation
    const currentPasswordInput = screen.getByPlaceholderText('Enter your current password')
    fireEvent.change(currentPasswordInput, { target: { value: 'somepassword' } })

    const form = document.querySelector('form')
    if (form) {
      fireEvent.submit(form)
    }

    // Wait for the error message to appear
    await waitFor(() => {
      expect(screen.getByText('All fields are required')).toBeInTheDocument()
    }, { timeout: 2000 })
  })

  it('shows error when passwords do not match', async () => {
    renderWithChakra(<ChangePasswordPage />)

    const currentPasswordInput = screen.getByPlaceholderText('Enter your current password')
    const newPasswordInput = screen.getByPlaceholderText('Enter your new password')
    const confirmPasswordInput = screen.getByPlaceholderText('Confirm your new password')
    const submitButton = screen.getByRole('button', { name: /change password/i })

    fireEvent.change(currentPasswordInput, { target: { value: 'oldpassword' } })
    fireEvent.change(newPasswordInput, { target: { value: 'newpassword123' } })
    fireEvent.change(confirmPasswordInput, { target: { value: 'differentpassword' } })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText('New passwords do not match')).toBeInTheDocument()
    })
  })

  it('shows error when new password is too short', async () => {
    renderWithChakra(<ChangePasswordPage />)

    const currentPasswordInput = screen.getByPlaceholderText('Enter your current password')
    const newPasswordInput = screen.getByPlaceholderText('Enter your new password')
    const confirmPasswordInput = screen.getByPlaceholderText('Confirm your new password')
    const submitButton = screen.getByRole('button', { name: /change password/i })

    fireEvent.change(currentPasswordInput, { target: { value: 'oldpassword' } })
    fireEvent.change(newPasswordInput, { target: { value: 'short' } })
    fireEvent.change(confirmPasswordInput, { target: { value: 'short' } })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText('New password must be at least 8 characters long')).toBeInTheDocument()
    })
  })

  it('successfully changes password with valid input', async () => {
    renderWithChakra(<ChangePasswordPage />)

    const currentPasswordInput = screen.getByPlaceholderText('Enter your current password')
    const newPasswordInput = screen.getByPlaceholderText('Enter your new password')
    const confirmPasswordInput = screen.getByPlaceholderText('Confirm your new password')
    const submitButton = screen.getByRole('button', { name: /change password/i })

    fireEvent.change(currentPasswordInput, { target: { value: 'oldpassword' } })
    fireEvent.change(newPasswordInput, { target: { value: 'newpassword123' } })
    fireEvent.change(confirmPasswordInput, { target: { value: 'newpassword123' } })
    fireEvent.click(submitButton)

    // Wait for the async operation to complete
    await waitFor(() => {
      expect(screen.getByText('Password changed successfully!')).toBeInTheDocument()
    }, { timeout: 2000 })

    // Should show success alert
    expect(mockAlert).toHaveBeenCalledWith('Password changed successfully!')

    // Fields should be cleared
    expect(currentPasswordInput).toHaveValue('')
    expect(newPasswordInput).toHaveValue('')
    expect(confirmPasswordInput).toHaveValue('')
  })

  it('shows password requirements text', () => {
    renderWithChakra(<ChangePasswordPage />)

    expect(screen.getByText('Must be at least 8 characters long')).toBeInTheDocument()
  })

  it('handles form submission with enter key', async () => {
    renderWithChakra(<ChangePasswordPage />)

    const form = document.querySelector('form')
    const currentPasswordInput = screen.getByPlaceholderText('Enter your current password')
    const newPasswordInput = screen.getByPlaceholderText('Enter your new password')
    const confirmPasswordInput = screen.getByPlaceholderText('Confirm your new password')

    fireEvent.change(currentPasswordInput, { target: { value: 'oldpassword' } })
    fireEvent.change(newPasswordInput, { target: { value: 'newpassword123' } })
    fireEvent.change(confirmPasswordInput, { target: { value: 'newpassword123' } })

    if (form) {
      fireEvent.submit(form)
    }

    await waitFor(() => {
      expect(screen.getByText('Password changed successfully!')).toBeInTheDocument()
    }, { timeout: 2000 })
  })
})
