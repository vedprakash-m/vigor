# LLM Provider Setup Guide

Vigor now supports multiple LLM providers for cost optimization and flexibility. You can choose between OpenAI, Google Gemini, or Perplexity based on your needs and budget.

## Quick Setup

### Option 1: Google Gemini (Recommended for Cost)
```bash
# Set environment variables
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your-gemini-api-key-here
export GEMINI_MODEL=gemini-2.5-flash

# Start the server
cd backend
source venv/bin/activate
python main.py
```

### Option 2: Perplexity (Good Value + Real-time Data)
```bash
# Set environment variables
export LLM_PROVIDER=perplexity
export PERPLEXITY_API_KEY=your-perplexity-api-key-here
export PERPLEXITY_MODEL=llama-3.1-sonar-small-128k-online

# Start the server
cd backend
source venv/bin/activate
python main.py
```

### Option 3: OpenAI (Most Advanced)
```bash
# Set environment variables
export LLM_PROVIDER=openai
export OPENAI_API_KEY=your-openai-api-key-here
export OPENAI_MODEL=gpt-3.5-turbo

# Start the server
cd backend
source venv/bin/activate
python main.py
```

## Getting API Keys

### Google Gemini (Free Tier Available)
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Free tier includes generous usage limits

### Perplexity (Affordable)
1. Go to [Perplexity API](https://docs.perplexity.ai/)
2. Sign up and get your API key
3. Competitive pricing with good performance

### OpenAI (Premium)
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new secret key
3. Most expensive but most capable

## Cost Comparison (Approximate)

| Provider | Model | Input Cost | Output Cost | Best For |
|----------|-------|------------|-------------|----------|
| Gemini | Flash 2.5 | $0.075/1M tokens | $0.30/1M tokens | Development, Budget |
| Perplexity | Llama 3.1 | $0.20/1M tokens | $0.20/1M tokens | Real-time data |
| OpenAI | GPT-3.5-turbo | $0.50/1M tokens | $1.50/1M tokens | Advanced reasoning |

## Configuration Options

### Environment Variables
```bash
# Provider selection
LLM_PROVIDER=gemini  # or openai, perplexity

# Gemini settings
GEMINI_API_KEY=your-key
GEMINI_MODEL=gemini-2.5-flash  # or gemini-2.5-pro

# Perplexity settings
PERPLEXITY_API_KEY=your-key
PERPLEXITY_MODEL=llama-3.1-sonar-small-128k-online

# OpenAI settings
OPENAI_API_KEY=your-key
OPENAI_MODEL=gpt-3.5-turbo  # or gpt-4
```

## Fallback Behavior

If no LLM provider is configured, the app will:
1. Try to use the specified provider
2. Fall back to any available configured provider
3. Use built-in fallback responses for basic functionality

## Testing Your Setup

After configuration, test the setup:

```bash
# Test the health endpoint
curl http://localhost:8000/health

# Check the API docs
open http://localhost:8000/docs
```

The app will automatically detect and use your configured provider. You'll see provider information in the startup logs.

## Recommendations

- **Development**: Start with Gemini Flash 2.5 (free tier)
- **Production**: Consider Perplexity for good value
- **Advanced Features**: Use OpenAI for complex reasoning

## Troubleshooting

1. **Provider not working**: Check API key and network connection
2. **High costs**: Monitor usage and consider switching providers
3. **Rate limits**: Implement caching and request batching
4. **No responses**: Check logs for specific error messages
