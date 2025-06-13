/* eslint-disable @typescript-eslint/no-explicit-any */
import axios from 'axios'
import { authService } from '../../services/authService'

// Mock axios
jest.mock('axios')
const mockedAxios = axios as jest.Mocked<typeof axios>

// Mock localStorage
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
    length: 0,
    key: jest.fn()
  },
  writable: true
})

describe('authService', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('handles successful login', async () => {
    const mockResponse = {
      data: {
        token: 'test-token',
        user: { id: 1, username: 'testuser' }
      }
    }
    const mockApi = {
      post: jest.fn().mockResolvedValue(mockResponse)
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    const result = await authService.login('test@example.com', 'password')

    expect(result).toEqual(mockResponse.data)
    expect(mockApi.post).toHaveBeenCalledWith('/auth/login', {
      email: 'test@example.com',
      password: 'password'
    })
  })

  it('handles successful registration', async () => {
    const mockResponse = {
      data: {
        user: { id: 1, username: 'newuser' }
      }
    }
    const mockApi = {
      post: jest.fn().mockResolvedValue(mockResponse)
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    const result = await authService.register('new@example.com', 'newuser', 'password123')

    expect(result).toEqual(mockResponse.data)
    expect(mockApi.post).toHaveBeenCalledWith('/auth/register', {
      email: 'new@example.com',
      username: 'newuser',
      password: 'password123'
    })
  })

  it('handles token refresh', async () => {
    const mockResponse = {
      data: {
        access_token: 'new-token'
      }
    }
    const mockApi = {
      post: jest.fn().mockResolvedValue(mockResponse)
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    const result = await authService.refreshToken('old-token')

    expect(result).toEqual(mockResponse.data)
    expect(mockApi.post).toHaveBeenCalledWith('/auth/refresh', {
      refresh_token: 'old-token'
    })
  })

  it('handles get current user', async () => {
    const mockResponse = {
      data: {
        id: 1,
        username: 'testuser',
        email: 'test@example.com'
      }
    }
    const mockApi = {
      get: jest.fn().mockResolvedValue(mockResponse)
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    const result = await authService.getCurrentUser()

    expect(result).toEqual(mockResponse.data)
    expect(mockApi.get).toHaveBeenCalledWith('/auth/me')
  })

  it('handles logout', async () => {
    const mockApi = {
      post: jest.fn().mockResolvedValue({})
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    await authService.logout()

    expect(mockApi.post).toHaveBeenCalledWith('/auth/logout')
  })

  it('handles forgot password', async () => {
    const mockResponse = { message: 'Reset email sent' }
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    })

    const result = await authService.forgotPassword('test@example.com')

    expect(result).toEqual(mockResponse)
    expect(fetch).toHaveBeenCalledWith('/api/auth/forgot', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify('test@example.com')
    })
  })

  it('handles reset password', async () => {
    const mockResponse = { message: 'Password reset successfully' }
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    })

    const result = await authService.resetPassword('reset-token', 'newpassword123')

    expect(result).toEqual(mockResponse)
    expect(fetch).toHaveBeenCalledWith('/api/auth/reset', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'reset-token',
        new_password: 'newpassword123'
      })
    })
  })

  it('handles API errors gracefully', async () => {
    const mockApi = {
      post: jest.fn().mockRejectedValue(new Error('Network error'))
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    await expect(
      authService.login('test@example.com', 'password')
    ).rejects.toThrow('Network error')
  })

  it('handles server errors', async () => {
    const mockApi = {
      post: jest.fn().mockRejectedValue({
        response: { status: 500, data: { detail: 'Internal server error' } }
      })
    }
    mockedAxios.create.mockReturnValue(mockApi as any)

    await expect(
      authService.login('test@example.com', 'password')
    ).rejects.toThrow()
  })
})
