import { fireEvent, render, screen } from '@testing-library/react';
import React from 'react';
import { OnboardingPage } from '../../pages/OnboardingPage';

// Mock Chakra UI components
jest.mock('@chakra-ui/react', () => ({
  Box: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Button: ({ children, onClick, disabled, ...props }: React.PropsWithChildren<{ onClick?: () => void; disabled?: boolean } & Record<string, unknown>>) => (
    <button onClick={onClick} disabled={disabled} {...props}>
      {children}
    </button>
  ),
  CloseButton: ({ onClick, ...props }: { onClick?: () => void } & Record<string, unknown>) => (
    <button onClick={onClick} {...props} />
  ),
  Heading: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <h1 {...props}>{children}</h1>,
  HStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
  Input: ({ onChange, value, placeholder, ...props }: { onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void; value?: string; placeholder?: string } & Record<string, unknown>) => (
    <input onChange={onChange} value={value} placeholder={placeholder} {...props} />
  ),
  Text: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <span {...props}>{children}</span>,
  VStack: ({ children, ...props }: React.PropsWithChildren<Record<string, unknown>>) => <div {...props}>{children}</div>,
}));

describe('OnboardingPage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders onboarding page with heading', () => {
    render(<OnboardingPage />);

    expect(screen.getByText('Step 1: Select Your Primary Goal')).toBeInTheDocument();
    expect(screen.getByText('Choose one or more fitness goals. Start typing to search.')).toBeInTheDocument();
  });

  it('renders search input field', () => {
    render(<OnboardingPage />);

    const input = screen.getByPlaceholderText('e.g., Weight Loss');
    expect(input).toBeInTheDocument();
  });

  it('displays initial goal suggestions', () => {
    render(<OnboardingPage />);

    expect(screen.getByText('Weight Loss')).toBeInTheDocument();
    expect(screen.getByText('Muscle Gain')).toBeInTheDocument();
    expect(screen.getByText('Endurance')).toBeInTheDocument();
    expect(screen.getByText('Flexibility')).toBeInTheDocument();
    expect(screen.getByText('General Fitness')).toBeInTheDocument();
  });

  it('filters suggestions based on input', () => {
    render(<OnboardingPage />);

    const input = screen.getByPlaceholderText('e.g., Weight Loss');
    fireEvent.change(input, { target: { value: 'weight' } });

    expect(screen.getByText('Weight Loss')).toBeInTheDocument();
    expect(screen.queryByText('Muscle Gain')).not.toBeInTheDocument();
  });

  it('adds goals when clicked', () => {
    render(<OnboardingPage />);

    // Get the first Weight Loss button (the suggestion button)
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    // Should now have Weight Loss in the selected section
    const selectedSection = screen.getByText('Weight Loss', { selector: 'span' });
    expect(selectedSection).toBeInTheDocument();
  });

  it('removes goals when close button is clicked', () => {
    render(<OnboardingPage />);

    // Add a goal first
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    // Find and click the close button (it's a button with no text)
    const closeButtons = screen.getAllByRole('button');
    const closeButton = closeButtons.find(button => button.textContent === '');
    expect(closeButton).toBeInTheDocument();
    fireEvent.click(closeButton!);

    // Goal should be removed from selected section
    expect(screen.queryByText('Weight Loss', { selector: 'span' })).not.toBeInTheDocument();
  });

  it('enables continue button when goals are selected', () => {
    render(<OnboardingPage />);

    const continueButton = screen.getByRole('button', { name: /continue/i });
    expect(continueButton).toBeDisabled();

    // Add a goal
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    expect(continueButton).toBeEnabled();
  });

  it('shows consent overlay when continue is clicked', () => {
    render(<OnboardingPage />);

    // Add a goal first
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    // Click continue
    const continueButton = screen.getByRole('button', { name: /continue/i });
    fireEvent.click(continueButton);

    // Consent overlay should appear
    expect(screen.getByText('Data Consent')).toBeInTheDocument();
    expect(screen.getByText(/We use your data to personalise your workout plans/)).toBeInTheDocument();
  });

  it('hides consent overlay when decline is clicked', () => {
    render(<OnboardingPage />);

    // Add a goal and show consent
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    const continueButton = screen.getByRole('button', { name: /continue/i });
    fireEvent.click(continueButton);

    // Click decline
    const declineButton = screen.getByRole('button', { name: /decline/i });
    fireEvent.click(declineButton);

    // Consent overlay should be hidden
    expect(screen.queryByText('Data Consent')).not.toBeInTheDocument();
  });

  it('handles accept and continue in consent overlay', () => {
    render(<OnboardingPage />);

    // Add a goal and show consent
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    const continueButton = screen.getByRole('button', { name: /continue/i });
    fireEvent.click(continueButton);

    // Click accept
    const acceptButton = screen.getByRole('button', { name: /accept & continue/i });
    fireEvent.click(acceptButton);

    // Consent overlay should be hidden (TODO: would submit to backend)
    expect(screen.queryByText('Data Consent')).not.toBeInTheDocument();
  });

  it('filters out already selected goals from suggestions', () => {
    render(<OnboardingPage />);

    // Add Weight Loss goal
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    // Weight Loss should not appear in suggestions anymore
    const suggestionButtons = screen.getAllByRole('button');
    const weightLossInSuggestions = suggestionButtons.some(button =>
      button.textContent === 'Weight Loss' && button !== suggestionButton
    );
    expect(weightLossInSuggestions).toBe(false);
  });

  it('has proper heading hierarchy', () => {
    render(<OnboardingPage />);

    const mainHeading = screen.getByRole('heading', { level: 1 });
    expect(mainHeading).toHaveTextContent('Step 1: Select Your Primary Goal');
  });

  it('displays GDPR consent information', () => {
    render(<OnboardingPage />);

    // Add a goal and show consent
    const weightLossButtons = screen.getAllByText('Weight Loss');
    const suggestionButton = weightLossButtons[0];
    fireEvent.click(suggestionButton);

    const continueButton = screen.getByRole('button', { name: /continue/i });
    fireEvent.click(continueButton);

    expect(screen.getByText(/GDPR Article 13/)).toBeInTheDocument();
  });
});
