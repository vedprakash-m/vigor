import { fireEvent, render, screen } from '@testing-library/react'
import { QuickReplies } from './QuickReplies'

describe('QuickReplies', () => {
  const mockOnSelectReply = jest.fn()

  beforeEach(() => {
    mockOnSelectReply.mockClear()
  })

  it('renders quick reply templates', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    expect(screen.getByText('Quick Reply Templates')).toBeInTheDocument()
    expect(screen.getByText('Welcome Message')).toBeInTheDocument()
    expect(screen.getByText('Password Reset Help')).toBeInTheDocument()
    expect(screen.getByText('Tier Upgrade Information')).toBeInTheDocument()
  })

  it('shows category filter dropdown', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    const categorySelect = screen.getByDisplayValue('All Templates')
    expect(categorySelect).toBeInTheDocument()
  })

  it('filters templates by category', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    const categorySelect = screen.getByDisplayValue('All Templates')

    // Change to Technical category
    fireEvent.change(categorySelect, { target: { value: 'technical' } })

    // Should show only technical templates
    expect(screen.getByText('Password Reset Help')).toBeInTheDocument()
    expect(screen.getByText('Technical Issue Support')).toBeInTheDocument()

    // Should not show non-technical templates
    expect(screen.queryByText('Welcome Message')).not.toBeInTheDocument()
    expect(screen.queryByText('Tier Upgrade Information')).not.toBeInTheDocument()
  })

  it('calls onSelectReply when template is clicked', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    const welcomeButton = screen.getByText('Welcome Message')
    fireEvent.click(welcomeButton)

    expect(mockOnSelectReply).toHaveBeenCalledWith(
      'Welcome to Vigor! I\'m here to help you with your fitness journey. How can I assist you today?'
    )
  })

  it('disables buttons when disabled prop is true', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} disabled={true} />)

    const welcomeButton = screen.getByText('Welcome Message').closest('button')
    expect(welcomeButton).toHaveAttribute('disabled')
  })

  it('shows all categories in dropdown', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    const categorySelect = screen.getByDisplayValue('All Templates')
    const options = Array.from(categorySelect.children) as HTMLOptionElement[]

    expect(options).toHaveLength(5)
    expect(options[0].value).toBe('all')
    expect(options[0].text).toBe('All Templates')
    expect(options[1].value).toBe('general')
    expect(options[1].text).toBe('General')
    expect(options[2].value).toBe('technical')
    expect(options[2].text).toBe('Technical')
    expect(options[3].value).toBe('billing')
    expect(options[3].text).toBe('Billing')
    expect(options[4].value).toBe('feature')
    expect(options[4].text).toBe('Feature Requests')
  })

  it('shows correct number of templates for each category', () => {
    render(<QuickReplies onSelectReply={mockOnSelectReply} />)

    // All templates should be visible initially
    expect(screen.getAllByRole('button')).toHaveLength(6)

    // Change to General category
    const categorySelect = screen.getByDisplayValue('All Templates')
    fireEvent.change(categorySelect, { target: { value: 'general' } })

    // Should show 2 general templates
    expect(screen.getAllByRole('button')).toHaveLength(2)
    expect(screen.getByText('Welcome Message')).toBeInTheDocument()
    expect(screen.getByText('Workout Planning Help')).toBeInTheDocument()
  })
})
