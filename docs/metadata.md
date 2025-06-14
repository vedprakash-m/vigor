# Vigor Project Metadata

This document consolidates key project metadata and information from various source files. It serves as a single source of truth for project configuration, deployment strategies, and development plans.

## Table of Contents

1. [Deployment Status](#deployment-status)
2. [Regional Strategy](#regional-strategy)
3. [Branch Strategy](#branch-strategy)
4. [Auto Merge Process](#auto-merge-process)
5. [Development Roadmap](#development-roadmap)
6. [Security Information](#security-information)
7. [Technical Debt](#technical-debt)

## Deployment Status

Current deployment status information for Vigor services:

- **Production**: Running on Azure infrastructure with bicep templates
- **Staging**: Automated deployment through GitHub Actions
- **Preview**: Available for PRs through preview-environment.yml workflow

### Service Architecture

- **Frontend**: React with Chakra UI, deployed to Azure Static Web Apps
- **Backend**: FastAPI on Python 3.9+, deployed to Azure App Service
- **Functions**: Azure Functions for workout generation and analysis
- **Database**: PostgreSQL managed database in Azure
- **Storage**: Azure Storage for user data and workout media

## Regional Strategy

Vigor follows a multi-region deployment approach for high availability and regional compliance:

- **Primary region**: West US 2
- **Secondary regions**: East US, Europe West
- **Failover strategy**: Active-passive with automated health checks

Azure services are deployed with multi-region support using Bicep templates defined in the infrastructure folder.

## Branch Strategy

The project follows a trunk-based development model with the following branches:

- `main`: Protected production branch, requires PR approval
- `feature/*`: Short-lived feature branches
- `hotfix/*`: Emergency production fixes
- `release/*`: Release preparation branches

Branch protection rules are enforced through GitHub settings and CI/CD workflows.

## Auto Merge Process

PRs can be automatically merged when they meet the following criteria:

1. Pass all required CI tests
2. Receive required approvals
3. Have the "auto-merge" label
4. No merge conflicts

The PR audit trail workflow logs all merge activities and maintains a comprehensive history.

## Development Roadmap

Key upcoming development priorities:

1. Enhanced user experience with responsive mobile design
2. Integration of additional LLM providers
3. Optimized workout recommendation algorithms
4. Expanded analytics dashboard
5. Multi-language support

### LLM Integration

Vigor currently supports multiple LLM providers to optimize cost and performance:

- **OpenAI**: Primary provider for high-quality workout planning
- **Google Gemini**: Alternative provider with lower cost structure
- **Perplexity**: Specialized for research and knowledge-intensive tasks
- **Fallback**: Automatic failover system to maintain availability

The platform includes an LLM orchestration system that can route requests based on cost, performance, or specific capabilities required for different workout-related tasks.

## Security Information

Security measures implemented:

- Secret scanning with gitleaks.yml
- Dependency auditing with dependency-audit.yml
- Azure authentication for backend services
- Regular security reviews
- Data encryption at rest and in transit

## Technical Debt

Areas identified for improvement:

1. Test coverage for frontend components
2. Migration to newer dependency versions
3. Performance optimization for workout generation
4. More comprehensive error handling
5. Infrastructure as code improvements
