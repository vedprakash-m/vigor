# Contributing to Vigor

Thank you for your interest in contributing to Vigor! We welcome contributions from the community and are pleased to have you join us.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Submitting Changes](#submitting-changes)
- [License Agreement](#license-agreement)
- [Community Guidelines](#community-guidelines)

## Code of Conduct

By participating in this project, you agree to abide by our code of conduct:

- **Be Respectful**: Treat everyone with respect and kindness
- **Be Inclusive**: Welcome people of all backgrounds and experience levels
- **Be Collaborative**: Work together towards common goals
- **Be Professional**: Maintain professional communication in all interactions
- **Be Constructive**: Provide helpful feedback and suggestions

## Getting Started

1. **Fork the Repository**: Create a fork of the main repository
2. **Clone Your Fork**: `git clone https://github.com/your-username/vigor.git`
3. **Set Up Development Environment**: Follow the [Development Setup](#development-setup) guide
4. **Pick an Issue**: Browse open issues or propose new features
5. **Start Contributing**: Follow our contribution workflow

## How to Contribute

### Reporting Bugs

Before submitting a bug report:
- Check if the issue already exists in our [issue tracker](https://github.com/vedprakash-m/vigor/issues)
- Test with the latest version to ensure it's still a problem
- Gather relevant information (OS, browser, version, etc.)

When submitting a bug report, include:
- Clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- Screenshots or logs if applicable
- System information and environment details

### Suggesting Features

We welcome feature suggestions! Please:
- Check existing issues and discussions first
- Clearly describe the problem your feature would solve
- Explain how it would benefit users
- Consider implementation complexity and project scope
- Be open to discussion and feedback

### Contributing Code

1. **Create a Branch**: `git checkout -b feature/your-feature-name`
2. **Make Changes**: Follow our coding standards and guidelines
3. **Test Thoroughly**: Ensure all tests pass and add new tests if needed
4. **Document Changes**: Update documentation as necessary
5. **Submit Pull Request**: Follow our PR template and guidelines

## Development Setup

### Prerequisites

- **Node.js** (v18+ recommended)
- **Python** (v3.9+ recommended)
- **Git**
- **Docker** (optional, for containerized development)

### Backend Setup (Python/FastAPI)

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies
```

### Frontend Setup (React/TypeScript)

```bash
cd frontend
npm install
npm run dev  # Start development server
```

### Environment Configuration

1. Copy `.env.example` to `.env` in both frontend and backend directories
2. Configure required environment variables
3. Set up database connections
4. Configure API keys (OpenAI, etc.)

### Running the Application

```bash
# Backend (from backend/ directory)
uvicorn main:app --reload --host 0.0.0.0 --port 8001

# Frontend (from frontend/ directory)
npm run dev
```

## Code Style Guidelines

### Python (Backend)

- **Formatter**: Use `black` for code formatting
- **Linter**: Use `flake8` for linting
- **Import Sorting**: Use `isort` for import organization
- **Type Hints**: Use type hints for all function parameters and return values
- **Docstrings**: Use Google-style docstrings for all functions and classes

```python
def example_function(param1: str, param2: int) -> dict:
    """Example function with proper typing and documentation.
    
    Args:
        param1: Description of parameter 1
        param2: Description of parameter 2
        
    Returns:
        Dictionary containing the result
        
    Raises:
        ValueError: If parameters are invalid
    """
    return {"result": f"{param1}_{param2}"}
```

### TypeScript/React (Frontend)

- **Formatter**: Use `prettier` for code formatting
- **Linter**: Use `eslint` with TypeScript rules
- **Components**: Use functional components with hooks
- **Naming**: Use PascalCase for components, camelCase for functions/variables
- **Props**: Define explicit prop interfaces

```typescript
interface ExampleComponentProps {
  title: string;
  onAction: (value: string) => void;
  isLoading?: boolean;
}

const ExampleComponent: React.FC<ExampleComponentProps> = ({
  title,
  onAction,
  isLoading = false
}) => {
  // Component implementation
};
```

### General Guidelines

- **Comments**: Write clear, concise comments explaining "why", not "what"
- **Naming**: Use descriptive names for variables, functions, and classes
- **Functions**: Keep functions small and focused on a single responsibility
- **Error Handling**: Implement proper error handling and validation
- **Security**: Follow security best practices and validate all inputs

## Testing Requirements

### Backend Testing

- **Unit Tests**: Write unit tests for all business logic
- **Integration Tests**: Test API endpoints and database interactions
- **Coverage**: Maintain minimum 80% test coverage
- **Testing Framework**: Use `pytest` for Python tests

```bash
# Run tests
pytest tests/ -v --cov=.

# Run specific test file
pytest tests/test_example.py -v
```

### Frontend Testing

- **Unit Tests**: Test individual components and utilities
- **Integration Tests**: Test component interactions and API calls
- **E2E Tests**: Use Playwright or Cypress for end-to-end testing
- **Testing Libraries**: Use Jest, React Testing Library

```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Run e2e tests
npm run test:e2e
```

### Test Guidelines

- Write tests before or alongside your code (TDD encouraged)
- Use descriptive test names that explain what is being tested
- Test edge cases and error conditions
- Mock external dependencies appropriately
- Keep tests focused and independent

## Submitting Changes

### Pull Request Process

1. **Update Documentation**: Ensure all documentation is updated
2. **Run All Tests**: Verify all tests pass locally
3. **Code Review**: Be prepared to address feedback
4. **Squash Commits**: Clean up commit history if needed
5. **Merge Requirements**: Ensure CI/CD checks pass

### Pull Request Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests pass

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### Commit Message Format

Use conventional commit format:

```
type(scope): brief description

Longer description if needed

Fixes #issue_number
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(api): add user authentication endpoint`
- `fix(ui): resolve button alignment issue`
- `docs(readme): update installation instructions`

## License Agreement

### Important: AGPLv3 License Requirements

By contributing to Vigor, you agree that:

1. **Your contributions will be licensed under AGPLv3**: All code contributions become part of the AGPLv3-licensed codebase
2. **You have the right to contribute**: You own the copyright to your contributions or have permission to contribute them
3. **You understand the AGPLv3**: You understand the implications of the GNU Affero General Public License v3.0
4. **Network use disclosure**: You understand that AGPLv3 requires source code disclosure for network use

### Developer Certificate of Origin

By making a contribution, you certify that:

- The contribution was created in whole or in part by you and you have the right to submit it under the open source license indicated in the file
- The contribution is based upon previous work that, to the best of your knowledge, is covered under an appropriate open source license
- You understand and agree that this project and the contribution are public

## Community Guidelines

### Communication Channels

- **GitHub Issues**: Bug reports, feature requests, and technical discussions
- **GitHub Discussions**: General questions, ideas, and community chat
- **Pull Requests**: Code review and technical feedback

### Getting Help

If you need help:

1. Check existing documentation and issues
2. Search GitHub Discussions
3. Create a new issue with detailed information
4. Be patient and respectful when asking for help

### Recognition

Contributors will be recognized in:
- `CONTRIBUTORS.md` file
- Release notes for significant contributions
- Project documentation where appropriate

## Development Workflow

### Branching Strategy

- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features and enhancements
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical production fixes

### Release Process

1. Feature development in feature branches
2. Merge to develop for integration testing
3. Create release branch from develop
4. Final testing and bug fixes
5. Merge to main and tag release
6. Deploy to production

## Security

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities. Instead:

1. Email security issues to: [create private email or security contact]
2. Include detailed description of the vulnerability
3. Provide steps to reproduce if possible
4. Allow reasonable time for response before public disclosure

### Security Best Practices

- Never commit secrets, API keys, or credentials
- Use environment variables for sensitive configuration
- Follow OWASP security guidelines
- Validate and sanitize all user inputs
- Use HTTPS for all communications

## Questions?

If you have questions about contributing, please:

- Check this document first
- Search existing issues and discussions
- Create a new discussion for general questions
- Create an issue for specific technical problems

Thank you for contributing to Vigor! 🏋️‍♀️💪

---

*This document is licensed under AGPLv3 along with the rest of the project.* 