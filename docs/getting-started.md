# Getting Started with Vigor

This guide will help you set up Vigor for development or production use.

## Prerequisites

- **Python 3.9+**
- **Node.js 18+**
- **Git**
- **Azure subscription** (for cloud deployment only)

## Local Development Setup

### Method 1: VS Code Tasks (Recommended)

The easiest way to get started is using VS Code tasks:

1. **Install Dependencies**

   ```
   Task: Install All Dependencies
   ```

2. **Start Services**

   ```
   # Start backend server
   Task: Start Backend Server

   # In a new terminal, start frontend dev server
   Task: Start Frontend Dev Server
   ```

3. **Run Tests**

   ```
   # Run backend tests
   Task: Run Backend Tests

   # Run frontend tests
   Task: Run Frontend Tests
   ```

### Method 2: Manual Setup

#### 1. Clone Repository

```bash
git clone https://github.com/vedprakash-m/vigor.git
cd vigor
```

#### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment (optional - app works without API keys)
export LLM_PROVIDER=fallback  # Use OpenAI, Gemini, Perplexity, or Fallback
export OPENAI_API_KEY=your-api-key-here  # If using OpenAI

# Run database migrations
alembic upgrade head

# Start the server
python main.py
```

#### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

### 4. Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs

#### Default Admin User

- **Email**: admin@vigor.com
- **Password**: admin123!

## AI Provider Configuration

### Option 1: No Configuration (Demo Mode)

Vigor works out of the box with fallback responses - no API keys required for testing.

### Option 2: Configure AI Providers

#### Google Gemini (Recommended - Free Tier Available)

```bash
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your-gemini-key
```

[Get Gemini API Key](https://makersuite.google.com/app/apikey)

#### OpenAI (Premium Features)

```bash
export LLM_PROVIDER=openai
export OPENAI_API_KEY=your-openai-key
```

[Get OpenAI API Key](https://platform.openai.com/api-keys)

#### Perplexity (Balanced Cost/Performance)

```bash
export LLM_PROVIDER=perplexity
export PERPLEXITY_API_KEY=your-perplexity-key
```

[Get Perplexity API Key](https://docs.perplexity.ai/)

## Validation

Run fast validation to ensure everything is working:

```bash
./scripts/lightning-validation.sh
```

## Next Steps

- **[API Documentation](http://localhost:8001/docs)** - Explore the API
- **[Deployment Guide](deployment.md)** - Deploy to production
- **[LLM Setup](../backend/LLM_SETUP.md)** - Advanced AI configuration
- **[Contributing](CONTRIBUTING.md)** - Help improve Vigor

## Troubleshooting

### Common Issues

1. **Backend fails to start**: Check Python version and virtual environment
2. **Frontend build errors**: Ensure Node.js 18+ and run `npm ci` for clean install
3. **Database errors**: Run `alembic upgrade head` to apply migrations
4. **AI responses not working**: Check API keys and provider configuration

### Getting Help

- **[GitHub Issues](https://github.com/vedprakash-m/vigor/issues)** - Report bugs
- **[GitHub Discussions](https://github.com/vedprakash-m/vigor/discussions)** - Ask questions
- **[Documentation](README.md)** - Browse all guides
