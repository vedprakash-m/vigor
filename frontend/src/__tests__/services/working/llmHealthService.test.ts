import { llmHealthService } from '../../../services/llmHealthService';

// Mock fetch for tests
global.fetch = jest.fn();

describe('LLM Health Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('can be imported and has expected methods', () => {
    expect(llmHealthService).toBeDefined();
    expect(typeof llmHealthService.getSystemOverview).toBe('function');
    expect(typeof llmHealthService.getAllModels).toBe('function');
  });

  it('handles fetch errors gracefully', async () => {
    (fetch as jest.Mock).mockRejectedValue(new Error('Network error'));

    try {
      await llmHealthService.getSystemOverview();
    } catch (error) {
      expect(error).toBeInstanceOf(Error);
    }
  });
});
