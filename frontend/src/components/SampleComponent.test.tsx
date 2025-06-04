import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';

const SampleComponent = () => <div>Hello, World!</div>;

test('renders SampleComponent', () => {
  render(<SampleComponent />);
  expect(screen.getByText('Hello, World!')).toBeInTheDocument();
});
