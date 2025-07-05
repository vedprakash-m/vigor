import { render, screen } from '@testing-library/react';

describe('Basic Test Setup', () => {
  it('can render a simple component', () => {
    const TestComponent = () => <div>Test Content</div>;
    render(<TestComponent />);
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('has working test environment', () => {
    expect(1 + 1).toBe(2);
    expect(typeof window).toBe('object');
  });
});
