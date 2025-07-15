#!/bin/bash

# Azure Container Apps Deployment Script
# This script deploys the Go application to Azure Container Apps

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Azure CLI login
check_azure_login() {
    if ! az account show >/dev/null 2>&1; then
        print_error "Azure CLI not logged in. Please run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI is logged in"
}

# Function to validate required environment variables
validate_env_vars() {
    local required_vars=(
        "AZURE_RESOURCE_GROUP"
        "AZURE_REGISTRY"
        "CONTAINER_APP_NAME"
        "IMAGE_TAG"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            print_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    print_success "All required environment variables are set"
}

# Function to build and push Docker image
build_and_push_image() {
    local image_name="$AZURE_REGISTRY.azurecr.io/$CONTAINER_APP_NAME:$IMAGE_TAG"
    
    print_status "Building Docker image: $image_name"
    
    # Build the image
    docker build -t "$image_name" .
    
    if [[ $? -eq 0 ]]; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    print_status "Pushing Docker image to Azure Container Registry"
    
    # Push the image
    docker push "$image_name"
    
    if [[ $? -eq 0 ]]; then
        print_success "Docker image pushed successfully"
    else
        print_error "Failed to push Docker image"
        exit 1
    fi
}

# Function to deploy to Azure Container Apps
deploy_to_container_apps() {
    local image_name="$AZURE_REGISTRY.azurecr.io/$CONTAINER_APP_NAME:$IMAGE_TAG"
    
    print_status "Deploying to Azure Container Apps: $CONTAINER_APP_NAME"
    
    # Check if container app exists
    if az containerapp show --name "$CONTAINER_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" >/dev/null 2>&1; then
        print_status "Container app exists, updating..."
        
        # Update existing container app
        az containerapp update \
            --name "$CONTAINER_APP_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --image "$image_name" \
            --set-env-vars \
                PORT=8080 \
                GIN_MODE=release \
                ENVIRONMENT=production \
                LOG_LEVEL=info \
                CORS_ORIGIN="*" \
            --cpu 0.5 \
            --memory 1Gi \
            --min-replicas 1 \
            --max-replicas 10 \
            --target-port 8080 \
            --ingress external \
            --allow-insecure false
        
    else
        print_status "Container app does not exist, creating..."
        
        # Create new container app
        az containerapp create \
            --name "$CONTAINER_APP_NAME" \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --image "$image_name" \
            --environment "$AZURE_CONTAINER_APPS_ENVIRONMENT" \
            --target-port 8080 \
            --ingress external \
            --allow-insecure false \
            --cpu 0.5 \
            --memory 1Gi \
            --min-replicas 1 \
            --max-replicas 10 \
            --env-vars \
                PORT=8080 \
                GIN_MODE=release \
                ENVIRONMENT=production \
                LOG_LEVEL=info \
                CORS_ORIGIN="*"
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "Deployment completed successfully"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Function to get deployment URL
get_deployment_url() {
    print_status "Getting deployment URL..."
    
    local url=$(az containerapp show \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --query "properties.configuration.ingress.fqdn" \
        --output tsv)
    
    if [[ -n "$url" ]]; then
        print_success "Application deployed successfully!"
        print_success "URL: https://$url"
        print_success "Health check: https://$url/api/v1/health"
        print_success "Swagger docs: https://$url/swagger/index.html"
    else
        print_error "Failed to get deployment URL"
        exit 1
    fi
}

# Function to run health check
run_health_check() {
    local url=$(az containerapp show \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --query "properties.configuration.ingress.fqdn" \
        --output tsv)
    
    if [[ -n "$url" ]]; then
        print_status "Running health check..."
        
        # Wait for the application to be ready
        local max_attempts=30
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -f -s "https://$url/api/v1/health" >/dev/null 2>&1; then
                print_success "Health check passed!"
                return 0
            fi
            
            print_status "Health check attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        done
        
        print_warning "Health check failed after $max_attempts attempts"
        return 1
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment status:"
    
    az containerapp show \
        --name "$CONTAINER_APP_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --query "{Name:name, Status:properties.provisioningState, URL:properties.configuration.ingress.fqdn, Replicas:properties.template.scale.minReplicas}" \
        --output table
}

# Main execution
main() {
    print_status "Starting Azure Container Apps deployment..."
    
    # Check prerequisites
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Validate environment
    check_azure_login
    validate_env_vars
    
    # Build and push image
    build_and_push_image
    
    # Deploy to Container Apps
    deploy_to_container_apps
    
    # Get deployment URL
    get_deployment_url
    
    # Run health check
    run_health_check
    
    # Show deployment status
    show_deployment_status
    
    print_success "Deployment process completed!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --help, -h     Show this help message"
            echo "  --skip-build   Skip Docker build and push"
            echo "  --skip-health  Skip health check"
            echo ""
            echo "Environment variables:"
            echo "  AZURE_RESOURCE_GROUP              Azure resource group name"
            echo "  AZURE_REGISTRY                    Azure Container Registry name"
            echo "  CONTAINER_APP_NAME                Container App name"
            echo "  IMAGE_TAG                         Docker image tag"
            echo "  AZURE_CONTAINER_APPS_ENVIRONMENT  Container Apps environment name"
            exit 0
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-health)
            SKIP_HEALTH=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main "$@" 