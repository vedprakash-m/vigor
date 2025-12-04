import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import React from 'react';

// Mock Chakra UI components
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="box" {...props}>{children}</div>
  ),
  Button: ({ children, onClick, isLoading, isDisabled, ...props }: React.PropsWithChildren<{ onClick?: () => void; isLoading?: boolean; isDisabled?: boolean } & Record<string, unknown>>) => (
    <button onClick={onClick} disabled={isLoading || isDisabled} data-testid="send-button" {...props}>
      {isLoading ? 'Loading...' : children}
    </button>
  ),
  Flex: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="flex" {...props}>{children}</div>
  ),
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <h1 {...props}>{children}</h1>
  ),
  HStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="hstack" {...props}>{children}</div>
  ),
  Input: ({ value, onChange, onKeyPress, ...props }: { value?: string; onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void; onKeyPress?: (e: React.KeyboardEvent) => void } & Record<string, unknown>) => (
    <input
      data-testid="message-input"
      value={value}
      onChange={onChange}
      onKeyPress={onKeyPress}
      {...props}
    />
  ),
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <span {...props}>{children}</span>
  ),
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => (
    <div data-testid="vstack" {...props}>{children}</div>
  ),
}))

// Mock localStorage
const mockLocalStorage = {
  getItem: jest.fn().mockReturnValue('mock-token'),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
}
Object.defineProperty(window, 'localStorage', { value: mockLocalStorage })

// Mock fetch for API calls
const mockFetch = jest.fn()
global.fetch = mockFetch

// Import after mocks
import { CoachPage } from '../../pages/CoachPage';

describe('CoachPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockFetch.mockReset()
  })

  it('renders coach page with heading', () => {
    render(<CoachPage />)

    expect(screen.getByText('AI Coach')).toBeInTheDocument()
  })

  it('displays initial greeting message', () => {
    render(<CoachPage />)

    expect(screen.getByText(/Hello! I'm your AI fitness coach/)).toBeInTheDocument()
  })

  it('renders message input field', () => {
    render(<CoachPage />)

    expect(screen.getByTestId('message-input')).toBeInTheDocument()
  })

  it('renders send button', () => {
    render(<CoachPage />)

    expect(screen.getByTestId('send-button')).toBeInTheDocument()
  })

  it('allows typing in message input', () => {
    render(<CoachPage />)

    const input = screen.getByTestId('message-input') as HTMLInputElement
    fireEvent.change(input, { target: { value: 'Hello coach!' } })

    expect(input.value).toBe('Hello coach!')
  })
})

describe('CoachPage - Message Sending', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockFetch.mockReset()
  })

  it('sends message on button click', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ response: 'Great question!' }),
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    const sendButton = screen.getByTestId('send-button')

    fireEvent.change(input, { target: { value: 'What workout should I do?' } })
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:8001/ai/chat',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
        })
      )
    })
  })

  it('sends message on Enter key press', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ response: 'Here is your workout!' }),
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    fireEvent.change(input, { target: { value: 'Test message' } })
    fireEvent.keyPress(input, { key: 'Enter', code: 'Enter', charCode: 13 })

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalled()
    })
  })

  it('does not send empty messages', async () => {
    render(<CoachPage />)

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('clears input after sending message', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ response: 'Response from coach' }),
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input') as HTMLInputElement
    fireEvent.change(input, { target: { value: 'Test message' } })

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(input.value).toBe('')
    })
  })
})

describe('CoachPage - Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockFetch.mockReset()
    jest.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('displays error message on API failure', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 500,
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    fireEvent.change(input, { target: { value: 'Test message' } })

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(screen.getByText(/Sorry, I'm having trouble responding/)).toBeInTheDocument()
    })
  })

  it('handles network errors gracefully', async () => {
    mockFetch.mockRejectedValueOnce(new Error('Network error'))

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    fireEvent.change(input, { target: { value: 'Test message' } })

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(screen.getByText(/Sorry, I'm having trouble responding/)).toBeInTheDocument()
    })

    expect(console.error).toHaveBeenCalled()
  })
})

describe('CoachPage - Message Display', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockFetch.mockReset()
  })

  it('displays user message after sending', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ response: 'Coach response' }),
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    fireEvent.change(input, { target: { value: 'My question to coach' } })

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(screen.getByText('My question to coach')).toBeInTheDocument()
    })
  })

  it('displays assistant response after API call', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ response: 'Here is my coaching advice!' }),
    })

    render(<CoachPage />)

    const input = screen.getByTestId('message-input')
    fireEvent.change(input, { target: { value: 'Help me with workouts' } })

    const sendButton = screen.getByTestId('send-button')
    fireEvent.click(sendButton)

    await waitFor(() => {
      expect(screen.getByText('Here is my coaching advice!')).toBeInTheDocument()
    })
  })
})
