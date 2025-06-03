# Enterprise LLM Orchestration System - Complete Usage Guide

## 🎯 Overview

Your **Enterprise LLM Orchestration Layer** is a production-ready system designed to handle thousands of concurrent users with enterprise-grade features including:

- 🔐 **Secure Key Vault Integration** (Azure, AWS, HashiCorp)
- 💰 **Intelligent Budget Management** 
- ⚡ **High-Performance Caching**
- 🛡️ **Circuit Breaker Protection**
- 🎯 **Context-Aware Intelligent Routing**
- 📊 **Comprehensive Analytics & Monitoring**

## 🚀 Quick Start

### 1. Basic LLM Chat Request

```bash
curl -X POST "http://localhost:8000/api/llm/chat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "prompt": "What is the best workout for building muscle?",
    "task_type": "fitness",
    "metadata": {
      "source": "web_app",
      "user_context": "beginner"
    }
  }'
```

### 2. Streaming Response

```bash
curl -X POST "http://localhost:8000/api/llm/stream" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "prompt": "Create a detailed workout plan for beginners",
    "task_type": "fitness"
  }'
```

### 3. Check System Status

```bash
curl "http://localhost:8000/api/llm/status" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in your backend directory:

```env
# Key Vault Configuration
KEY_VAULT_PROVIDER=azure  # or 'aws', 'hashicorp', 'local'

# Azure Key Vault
AZURE_KEY_VAULT_URL=https://your-vault.vault.azure.net/
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_TENANT_ID=your-tenant-id

# AWS Secrets Manager
AWS_REGION=us-west-2
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# HashiCorp Vault
VAULT_URL=https://vault.example.com:8200
VAULT_TOKEN=your-vault-token

# Budget Configuration
GLOBAL_BUDGET_LIMIT=1000.00
BUDGET_RESET_PERIOD=monthly
BUDGET_WARNING_THRESHOLD=0.8

# Cache Configuration
CACHE_TTL=3600
CACHE_MAX_SIZE=10000

# Rate Limiting
RATE_LIMIT_PER_USER=100
RATE_LIMIT_WINDOW=3600
```

### API Key Management

Instead of storing raw API keys, store **secret references** in your Key Vault:

```python
# In Azure Key Vault, store secrets with names like:
# - openai-api-key
# - gemini-api-key  
# - perplexity-api-key

# In your configuration, reference them like:
{
    "api_key_reference": {
        "provider": "azure",
        "vault_url": "https://your-vault.vault.azure.net/",
        "secret_name": "openai-api-key"
    }
}
```

## 🔐 Security Best Practices

### 1. Key Vault Setup

```python
from core.llm_orchestration.key_vault import SecretReference

# Create secret references (not raw keys!)
secret_ref = SecretReference(
    provider=KeyVaultProvider.AZURE,
    vault_url="https://your-vault.vault.azure.net/",
    secret_name="openai-api-key",
    version="latest"  # Optional
)
```

### 2. Admin Model Configuration

```python
from core.llm_orchestration_init import get_llm_gateway

# Initialize gateway
gateway = get_llm_gateway()

# Add a new model securely
await gateway.admin_add_model(
    model_id="gpt-4-turbo",
    provider="openai",
    model_name="gpt-4-1106-preview",
    api_key_reference=secret_ref,  # Reference, not raw key
    priority=ModelPriority.HIGH,
    max_tokens=4096,
    cost_per_token=0.00003
)
```

## 💰 Budget Management

### 1. Set Budget Limits

```python
from core.llm_orchestration.config_manager import BudgetConfiguration

budget_config = BudgetConfiguration(
    global_limit=1000.00,
    user_limits={"premium": 100.00, "standard": 25.00},
    group_limits={"enterprise": 5000.00},
    reset_period="monthly",
    warning_threshold=0.8,
    auto_disable_on_exceed=True
)

await gateway.config_manager.set_budget_configuration(budget_config)
```

### 2. Monitor Usage

```bash
# Get usage summary
curl "http://localhost:8000/api/llm/usage-summary" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get detailed analytics
curl "http://localhost:8000/api/llm/admin/analytics" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

## 🎯 Intelligent Routing

### 1. Context-Aware Routing

The system automatically routes based on task type:

```python
# Different task types route to optimal models
{
    "coding": "gpt-4-turbo",      # Best for code generation
    "chat": "gpt-3.5-turbo",     # Cost-effective for chat
    "analysis": "claude-3-sonnet", # Best for analysis
    "creative": "gemini-pro",     # Good for creative tasks
    "factual": "perplexity-pro"   # Best for factual queries
}
```

### 2. Custom Routing Rules

```python
from core.llm_orchestration.config_manager import RoutingRule

# Route premium users to better models
premium_rule = RoutingRule(
    name="premium_routing",
    condition={"user_tier": "premium"},
    target_models=["gpt-4-turbo", "claude-3-sonnet"],
    weight=1.0,
    is_active=True
)

await gateway.config_manager.add_routing_rule(premium_rule)
```

### 3. A/B Testing

```python
from core.llm_orchestration.config_manager import ABTestConfiguration

ab_test = ABTestConfiguration(
    name="gpt4_vs_claude",
    variant_a={"model_id": "gpt-4-turbo", "weight": 0.5},
    variant_b={"model_id": "claude-3-sonnet", "weight": 0.5},
    traffic_percentage=0.1,  # 10% of traffic
    success_metric="user_satisfaction",
    is_active=True
)

await gateway.config_manager.add_ab_test(ab_test)
```

## ⚡ Performance Optimization

### 1. Caching Configuration

```python
# Responses are automatically cached based on:
# - Prompt similarity (embeddings)
# - User context
# - Model used
# - Custom cache keys

# Cache hits save both cost and latency
cache_stats = await gateway.cache_manager.get_cache_stats()
print(f"Cache hit rate: {cache_stats.hit_rate:.1f}%")
```

### 2. Circuit Breaker Management

```python
# Circuit breakers automatically handle failures
circuit_status = await gateway.circuit_breaker.get_status("openai")

if circuit_status.state == "open":
    print("OpenAI circuit breaker is open - routing to fallback")
```

## 📊 Monitoring & Analytics

### 1. Real-time Monitoring

```bash
# System health check
curl "http://localhost:8000/health"

# LLM-specific status
curl "http://localhost:8000/api/llm/status" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Usage Analytics

```python
from datetime import datetime, timedelta

# Get usage report
report = await gateway.analytics.get_usage_report(
    start_date=datetime.now() - timedelta(days=7),
    end_date=datetime.now(),
    group_by=["model_id", "user_tier"],
    include_costs=True
)

print(f"Total requests: {report.total_requests}")
print(f"Total cost: ${report.total_cost:.2f}")
print(f"Average latency: {report.avg_latency_ms}ms")
```

### 3. Cost Optimization Insights

```python
# Get cost breakdown
cost_breakdown = await gateway.analytics.get_cost_breakdown(
    period="last_30_days",
    group_by=["model_id", "task_type"]
)

# Identify optimization opportunities
for item in cost_breakdown.top_expensive_queries:
    print(f"Query: {item.query_pattern}")
    print(f"Cost: ${item.total_cost:.2f}")
    print(f"Suggestion: {item.optimization_suggestion}")
```

## 🔧 Admin Operations

### 1. Model Management

```python
# List all models
models = await gateway.config_manager.get_all_models()

# Toggle model availability
await gateway.admin_toggle_model("gpt-4-turbo", is_active=False)

# Update model configuration
await gateway.config_manager.update_model_config(
    model_id="gpt-4-turbo",
    updates={"priority": ModelPriority.MEDIUM, "cost_per_token": 0.00002}
)
```

### 2. User Management

```python
# Set user tier
await gateway.config_manager.set_user_tier("user123", "premium")

# Get user usage
usage = await gateway.budget_manager.get_user_usage("user123")
print(f"User usage: ${usage.current_usage:.2f}")
```

### 3. Configuration Export/Import

```python
# Export configuration
config = gateway.config_manager.export_configuration()

# Import configuration (for staging/prod sync)
await gateway.config_manager.import_configuration(config)
```

## 🎯 Integration Examples

### 1. Python Integration

```python
import asyncio
from core.llm_orchestration_init import get_llm_gateway

async def ask_ai(prompt: str, user_id: str, task_type: str = "chat"):
    gateway = get_llm_gateway()
    
    response = await gateway.process_request(
        prompt=prompt,
        user_id=user_id,
        task_type=task_type,
        metadata={"source": "api", "timestamp": "2024-01-01T12:00:00Z"}
    )
    
    return {
        "content": response.content,
        "model": response.model_used,
        "cost": response.cost_estimate,
        "cached": response.cached
    }

# Usage
result = asyncio.run(ask_ai(
    "What's the best exercise for abs?", 
    "user123", 
    "fitness"
))
```

### 2. FastAPI Integration

```python
from fastapi import APIRouter, Depends
from core.llm_orchestration_init import get_llm_gateway

router = APIRouter()

@router.post("/ask-ai")
async def ask_ai_endpoint(
    request: dict,
    current_user = Depends(get_current_user)
):
    gateway = get_llm_gateway()
    
    response = await gateway.process_request(
        prompt=request["prompt"],
        user_id=current_user.id,
        task_type=request.get("task_type", "chat"),
        metadata={"source": "web_api"}
    )
    
    return response
```

### 3. Frontend Integration

```javascript
// React component example
const useLLMOrchestration = () => {
  const [loading, setLoading] = useState(false);
  
  const sendRequest = async (prompt, taskType = 'chat') => {
    setLoading(true);
    try {
      const response = await fetch('/api/llm/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ prompt, task_type: taskType })
      });
      
      return await response.json();
    } finally {
      setLoading(false);
    }
  };
  
  return { sendRequest, loading };
};
```

## 🚨 Troubleshooting

### Common Issues

1. **"Key vault authentication failed"**
   ```bash
   # Check environment variables
   echo $AZURE_CLIENT_ID
   echo $AZURE_TENANT_ID
   
   # Verify vault permissions
   az keyvault secret show --vault-name your-vault --name openai-api-key
   ```

2. **"Budget exceeded"**
   ```python
   # Check current usage
   usage = await gateway.budget_manager.get_global_usage()
   print(f"Current usage: ${usage.current_usage:.2f}")
   
   # Temporarily increase limit
   await gateway.budget_manager.update_budget_limit(2000.00)
   ```

3. **"Circuit breaker open"**
   ```python
   # Check circuit breaker status
   status = await gateway.circuit_breaker.get_status("openai")
   
   # Manually reset if needed
   if status.state == "open":
       await gateway.circuit_breaker.reset("openai")
   ```

### Performance Tuning

1. **Optimize Cache Hit Rate**
   ```python
   # Analyze cache performance
   stats = await gateway.cache_manager.get_cache_stats()
   
   if stats.hit_rate < 0.3:
       # Increase cache TTL
       await gateway.cache_manager.update_ttl(7200)  # 2 hours
   ```

2. **Monitor Response Times**
   ```python
   # Get latency metrics
   metrics = await gateway.analytics.get_latency_metrics()
   
   # If average latency > 5000ms, consider:
   # - Adding more models for load balancing
   # - Increasing cache TTL
   # - Using faster models for simple queries
   ```

## 📈 Scaling Considerations

### Production Deployment

1. **Load Balancing**
   - Deploy multiple gateway instances
   - Use Redis for shared caching
   - Database connection pooling

2. **Monitoring**
   - Set up health checks: `/health` and `/llm/status`
   - Monitor key metrics: response time, error rate, cost per request
   - Set up alerts for budget thresholds

3. **Security**
   - Use HTTPS in production
   - Implement rate limiting per IP
   - Regular key rotation in Key Vault
   - Audit logs for all admin operations

## 🎯 Next Steps

1. **Test the system** with sample requests
2. **Configure your Key Vault** with API keys
3. **Set up monitoring** and alerting
4. **Train your team** on admin operations
5. **Scale gradually** and monitor performance

Your enterprise LLM orchestration system is now ready to handle production workloads with enterprise-grade security, cost optimization, and operational excellence! 🚀 