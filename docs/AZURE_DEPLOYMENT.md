# Azure Container Apps Deployment Guide

This guide explains how to deploy your Go application to Azure Container Apps using GitHub Actions.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure Setup](#azure-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Deployment Process](#deployment-process)
5. [Configuration Files](#configuration-files)
6. [Environment Variables](#environment-variables)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying to Azure Container Apps, ensure you have:

- Azure subscription with Container Apps enabled
- Azure CLI installed and configured
- GitHub repository with the application code
- Docker installed (for local testing)

## Azure Setup

### 1. Create Azure Resources

Run the following Azure CLI commands to create the necessary resources:

```bash
# Set variables
RESOURCE_GROUP="goland-api-rg"
LOCATION="eastus"
CONTAINER_REGISTRY="golandapiregistry"
CONTAINER_APPS_ENVIRONMENT="goland-api-env"
CONTAINER_APP_NAME="goland-api-app"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Container Registry
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY \
    --sku Basic \
    --admin-enabled true

# Create Container Apps Environment
az containerapp env create \
    --name $CONTAINER_APPS_ENVIRONMENT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Create Container App
az containerapp create \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_APPS_ENVIRONMENT \
    --image nginx:latest \
    --target-port 80 \
    --ingress external \
    --min-replicas 0 \
    --max-replicas 1
```

### 2. Create Service Principal

Create a service principal for GitHub Actions authentication:

```bash
# Create service principal
az ad sp create-for-rbac \
    --name "goland-api-sp" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth
```

Save the output JSON - you'll need it for GitHub secrets.

## GitHub Secrets Configuration

Add the following secrets to your GitHub repository (Settings > Secrets and variables > Actions):

### Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS` | Service principal credentials JSON | `{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}` |
| `AZURE_RESOURCE_GROUP` | Azure resource group name | `goland-api-rg` |
| `AZURE_REGISTRY` | Azure Container Registry name | `golandapiregistry` |
| `AZURE_REGISTRY_PASSWORD` | ACR admin password | `password123` |
| `CONTAINER_APP_NAME_STAGING` | Staging container app name | `goland-api-staging` |
| `CONTAINER_APP_NAME_PRODUCTION` | Production container app name | `goland-api-production` |

### Optional Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `JWT_SECRET` | JWT signing secret | `your-secret-key` |
| `API_KEY` | API authentication key | `your-api-key` |

## Deployment Process

### Automatic Deployment

The GitHub Actions workflow automatically deploys:

- **Staging**: When code is pushed to `develop` branch
- **Production**: When code is pushed to `main` branch
- **Manual**: Using workflow dispatch with environment selection

### Manual Deployment

You can also deploy manually using the deployment script:

```bash
# Set environment variables
export AZURE_RESOURCE_GROUP="goland-api-rg"
export AZURE_REGISTRY="golandapiregistry"
export CONTAINER_APP_NAME="goland-api-app"
export IMAGE_TAG="latest"
export AZURE_CONTAINER_APPS_ENVIRONMENT="goland-api-env"

# Run deployment
./scripts/deploy-azure.sh
```

## Configuration Files

### GitHub Actions Workflow

The main workflow file is `.github/workflows/deploy-azure.yml`. It includes:

- **Testing**: Runs Go tests and coverage
- **Building**: Multi-platform Docker image build
- **Pushing**: Pushes to GitHub Container Registry
- **Deploying**: Deploys to Azure Container Apps
- **Health Checks**: Verifies deployment success

### Azure Container Apps Configuration

The `azure-container-apps.yaml` file defines:

- **Ingress**: External access configuration
- **Scaling**: Auto-scaling rules
- **Resources**: CPU and memory limits
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: Application configuration

## Environment Variables

### Application Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PORT` | Application port | `8080` | No |
| `GIN_MODE` | Gin framework mode | `release` | No |
| `DATABASE_URL` | Database connection string | - | Yes |
| `JWT_SECRET` | JWT signing secret | - | Yes |
| `API_KEY` | API authentication key | - | No |
| `ENVIRONMENT` | Deployment environment | `production` | No |
| `LOG_LEVEL` | Logging level | `info` | No |
| `CORS_ORIGIN` | CORS allowed origins | `*` | No |

### Azure Container Apps Environment Variables

These are automatically set by the deployment process:

| Variable | Description |
|----------|-------------|
| `AZURE_CONTAINER_APPS_ENVIRONMENT` | Container Apps environment name |
| `AZURE_RESOURCE_GROUP` | Resource group name |
| `AZURE_REGISTRY` | Container registry name |

## Monitoring and Logging

### Azure Monitor

Enable monitoring in Azure Container Apps:

```bash
# Enable monitoring
az monitor diagnostic-settings create \
    --resource-group $RESOURCE_GROUP \
    --resource-type Microsoft.App/containerApps \
    --resource-name $CONTAINER_APP_NAME \
    --name "container-app-monitoring" \
    --workspace "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}"
```

### Application Logs

View application logs:

```bash
# View logs
az containerapp logs show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --follow
```

### Health Monitoring

The application includes health check endpoints:

- **Health Check**: `GET /api/v1/health`
- **Swagger Docs**: `GET /swagger/index.html`

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

**Problem**: Azure login fails
**Solution**: Verify service principal credentials and permissions

```bash
# Test authentication
az login --service-principal \
    --username $CLIENT_ID \
    --password $CLIENT_SECRET \
    --tenant $TENANT_ID
```

#### 2. Container Registry Access

**Problem**: Cannot push to ACR
**Solution**: Enable admin access and verify credentials

```bash
# Enable admin access
az acr update -n $CONTAINER_REGISTRY --admin-enabled true

# Get credentials
az acr credential show -n $CONTAINER_REGISTRY
```

#### 3. Container App Creation Fails

**Problem**: Container app deployment fails
**Solution**: Check resource limits and environment variables

```bash
# Check container app status
az containerapp show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.provisioningState"
```

#### 4. Health Check Failures

**Problem**: Application doesn't respond to health checks
**Solution**: Verify application startup and port configuration

```bash
# Check container logs
az containerapp logs show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP
```

### Debug Commands

```bash
# Check Azure resources
az resource list --resource-group $RESOURCE_GROUP

# Check Container Apps
az containerapp list --resource-group $RESOURCE_GROUP

# Check Container Registry
az acr repository list --name $CONTAINER_REGISTRY

# Check environment variables
az containerapp show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.template.containers[0].env"
```

### Performance Optimization

#### 1. Resource Optimization

- **CPU**: Start with 0.5 cores, scale based on usage
- **Memory**: Start with 1Gi, monitor memory usage
- **Replicas**: Set min=1, max=10 for auto-scaling

#### 2. Image Optimization

- Use multi-stage Docker builds
- Optimize base images (Alpine Linux)
- Minimize layer count
- Use .dockerignore to exclude unnecessary files

#### 3. Scaling Rules

Configure auto-scaling based on:

- **HTTP Requests**: Scale on concurrent requests
- **CPU Usage**: Scale on CPU utilization > 70%
- **Custom Metrics**: Scale on application-specific metrics

## Security Best Practices

### 1. Secrets Management

- Use Azure Key Vault for sensitive data
- Never commit secrets to source code
- Rotate secrets regularly

### 2. Network Security

- Use private endpoints for database connections
- Configure VNET integration for Container Apps
- Implement proper CORS policies

### 3. Container Security

- Use non-root users in containers
- Scan images for vulnerabilities
- Keep base images updated

## Cost Optimization

### 1. Resource Management

- Use consumption plan for development
- Scale to zero when not in use
- Monitor resource usage

### 2. Image Optimization

- Use smaller base images
- Implement layer caching
- Use multi-platform builds efficiently

### 3. Monitoring Costs

- Set up cost alerts
- Monitor resource usage
- Optimize based on usage patterns

## Support and Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Go on Azure](https://docs.microsoft.com/en-us/azure/developer/go/) 