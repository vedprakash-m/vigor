export const authService = {
  login: jest.fn(),
  register: jest.fn(),
  getCurrentUser: jest.fn(),
  refreshToken: jest.fn(),
  logout: jest.fn(),
  forgotPassword: jest.fn(),
  resetPassword: jest.fn(),
}

export default authService
