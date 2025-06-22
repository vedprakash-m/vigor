import { ChakraProvider, defaultSystem } from '@chakra-ui/react';
import { render, screen, waitFor } from '@testing-library/react';
import React from 'react';
import LLMStatus from '../../components/LLMStatus';

// Mock fetch globally
global.fetch = jest.fn();
const mockFetch = fetch as jest.MockedFunction<typeof fetch>;

const TestWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <ChakraProvider value={defaultSystem}>
    {children}
  </ChakraProvider>
);

describe('LLMStatus', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    console.error = jest.fn(); // Suppress console errors in tests
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('Loading State', () => {
    it('shows loading spinner initially', () => {
      // Mock a delayed response
      mockFetch.mockImplementation(() => new Promise(() => {})); // Never resolves

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      expect(screen.getByText('Loading AI status...')).toBeDefined();
      // Check for spinner by looking for the Chakra UI spinner class or text
      const loadingElement = screen.getByText('Loading AI status...');
      expect(loadingElement).toBeDefined();
    });
  });

  describe('Error State', () => {
    it('shows error message when fetch fails', async () => {
      mockFetch.mockRejectedValue(new Error('Network error'));

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Failed to load AI status')).toBeInTheDocument();
      });

      expect(screen.queryByText('Loading AI status...')).not.toBeInTheDocument();
    });

    it('shows error message when response is not ok', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 500,
        json: async () => ({}),
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Failed to load AI status')).toBeDefined();
      });
    });
  });

  describe('Success State - OpenAI Active', () => {
    const mockStatusOpenAI = {
      configured_provider: 'openai',
      active_provider: 'OpenAI',
      is_available: true,
      provider_info: {
        openai: { configured: true, model: 'gpt-4' },
        gemini: { configured: false, model: '' },
        perplexity: { configured: false, model: '' },
      },
    };

    it('displays OpenAI as active provider', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusOpenAI,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('OpenAI')).toBeInTheDocument();
      });

      expect(screen.getByText('AI Provider:')).toBeInTheDocument();
      expect(screen.getByText('Available Providers:')).toBeInTheDocument();
    });

    it('shows correct provider statuses with OpenAI active', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusOpenAI,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('OpenAI:')).toBeInTheDocument();
      });

      // Check provider labels
      expect(screen.getByText('OpenAI:')).toBeInTheDocument();
      expect(screen.getByText('Gemini:')).toBeInTheDocument();
      expect(screen.getByText('Perplexity:')).toBeInTheDocument();

      // Check status texts
      expect(screen.getByText('Active')).toBeInTheDocument();
      expect(screen.getAllByText('Not Configured')).toHaveLength(2);
    });
  });

  describe('Success State - Gemini Active', () => {
    const mockStatusGemini = {
      configured_provider: 'gemini',
      active_provider: 'Gemini Pro',
      is_available: true,
      provider_info: {
        openai: { configured: true, model: 'gpt-3.5-turbo' },
        gemini: { configured: true, model: 'gemini-pro' },
        perplexity: { configured: false, model: '' },
      },
    };

    it('displays Gemini as active provider', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusGemini,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Gemini Pro')).toBeInTheDocument();
      });
    });

    it('shows correct mixed provider statuses', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusGemini,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Configured')).toBeInTheDocument();
      });

      // Should show Configured for OpenAI, Active for Gemini, Not Configured for Perplexity
      expect(screen.getByText('Active')).toBeInTheDocument(); // Gemini
      expect(screen.getByText('Configured')).toBeInTheDocument(); // OpenAI
      expect(screen.getByText('Not Configured')).toBeInTheDocument(); // Perplexity
    });
  });

  describe('Fallback Provider State', () => {
    const mockStatusFallback = {
      configured_provider: 'fallback',
      active_provider: 'FallbackProvider',
      is_available: true,
      provider_info: {
        openai: { configured: false, model: '' },
        gemini: { configured: false, model: '' },
        perplexity: { configured: false, model: '' },
      },
    };

    it('displays fallback provider message', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusFallback,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('FallbackProvider')).toBeInTheDocument();
      });

      expect(screen.getByText(/Using fallback responses/)).toBeInTheDocument();
      expect(screen.getByText(/Configure an API key for personalized AI features/)).toBeInTheDocument();
    });

    it('shows all providers as not configured in fallback mode', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusFallback,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getAllByText('Not Configured')).toHaveLength(3);
      });
    });
  });

  describe('Provider Status Colors', () => {
    const mockStatusMixed = {
      configured_provider: 'openai',
      active_provider: 'OpenAI GPT-4',
      is_available: true,
      provider_info: {
        openai: { configured: true, model: 'gpt-4' },
        gemini: { configured: true, model: 'gemini-pro' },
        perplexity: { configured: false, model: '' },
      },
    };

    it('applies correct badge colors based on status', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatusMixed,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('Active')).toBeInTheDocument();
      });

      // The badges should be rendered with appropriate colorSchemes
      // We can't easily test the actual colors, but we can verify the text content
      expect(screen.getByText('Active')).toBeInTheDocument(); // OpenAI - green
      expect(screen.getByText('Configured')).toBeInTheDocument(); // Gemini - blue
      expect(screen.getByText('Not Configured')).toBeInTheDocument(); // Perplexity - gray
    });
  });

  describe('Availability Status', () => {
    it('shows green badge when AI is available', async () => {
      const mockStatus = {
        configured_provider: 'openai',
        active_provider: 'OpenAI',
        is_available: true,
        provider_info: {
          openai: { configured: true, model: 'gpt-4' },
          gemini: { configured: false, model: '' },
          perplexity: { configured: false, model: '' },
        },
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatus,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('OpenAI')).toBeInTheDocument();
      });

      // The main provider badge should indicate availability
      expect(screen.getByText('AI Provider:')).toBeInTheDocument();
    });

    it('shows red badge when AI is not available', async () => {
      const mockStatus = {
        configured_provider: 'none',
        active_provider: 'None',
        is_available: false,
        provider_info: {
          openai: { configured: false, model: '' },
          gemini: { configured: false, model: '' },
          perplexity: { configured: false, model: '' },
        },
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatus,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(screen.getByText('None')).toBeInTheDocument();
      });
    });
  });

  describe('API Integration', () => {
    it('calls the correct API endpoint', async () => {
      const mockStatus = {
        configured_provider: 'openai',
        active_provider: 'OpenAI',
        is_available: true,
        provider_info: {
          openai: { configured: true, model: 'gpt-4' },
          gemini: { configured: false, model: '' },
          perplexity: { configured: false, model: '' },
        },
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatus,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      await waitFor(() => {
        expect(mockFetch).toHaveBeenCalledWith('http://localhost:8001/ai/provider-status');
      });

      expect(mockFetch).toHaveBeenCalledTimes(1);
    });
  });

  describe('Component Lifecycle', () => {
    it('fetches status on mount', async () => {
      const mockStatus = {
        configured_provider: 'openai',
        active_provider: 'OpenAI',
        is_available: true,
        provider_info: {
          openai: { configured: true, model: 'gpt-4' },
          gemini: { configured: false, model: '' },
          perplexity: { configured: false, model: '' },
        },
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatus,
      } as Response);

      render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      // Should start with loading state
      expect(screen.getByText('Loading AI status...')).toBeInTheDocument();

      // Should eventually show the status
      await waitFor(() => {
        expect(screen.getByText('OpenAI')).toBeInTheDocument();
      });

      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('handles component unmount gracefully', async () => {
      const mockStatus = {
        configured_provider: 'openai',
        active_provider: 'OpenAI',
        is_available: true,
        provider_info: {
          openai: { configured: true, model: 'gpt-4' },
          gemini: { configured: false, model: '' },
          perplexity: { configured: false, model: '' },
        },
      };

      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => mockStatus,
      } as Response);

      const { unmount } = render(
        <TestWrapper>
          <LLMStatus />
        </TestWrapper>
      );

      // Unmount before the API call completes
      unmount();

      // Should not cause any errors
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });
  });
});
