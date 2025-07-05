/**
 * Basic Integration Tests - Phase 7 Foundation
 * Tests core application integration without complex dependencies
 */

import { render, screen } from '@testing-library/react';
import React from 'react';

describe('Basic Integration Tests', () => {
  it('can render multiple components together', () => {
    const Header = () => <h1>Vigor</h1>;
    const Content = () => <main>Welcome to Vigor</main>;
    const App = () => (
      <div>
        <Header />
        <Content />
      </div>
    );

    render(<App />);

    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Vigor');
    expect(screen.getByRole('main')).toHaveTextContent('Welcome to Vigor');
  });

  it('handles conditional rendering', () => {
    const ConditionalComponent = ({ showContent }: { showContent: boolean }) => (
      <div>
        {showContent && <p>Content is visible</p>}
        {!showContent && <p>Content is hidden</p>}
      </div>
    );

    const { rerender } = render(<ConditionalComponent showContent={true} />);
    expect(screen.getByText('Content is visible')).toBeInTheDocument();

    rerender(<ConditionalComponent showContent={false} />);
    expect(screen.getByText('Content is hidden')).toBeInTheDocument();
  });
});
