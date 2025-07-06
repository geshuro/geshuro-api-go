#!/bin/bash

# Installation script for development dependencies
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

# Default values
INSTALL_AIR=false
INSTALL_LINT=false
INSTALL_SWAG=false
INSTALL_DOCKER=false
INSTALL_ALL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --air)
            INSTALL_AIR=true
            shift
            ;;
        --lint)
            INSTALL_LINT=true
            shift
            ;;
        --swag)
            INSTALL_SWAG=true
            shift
            ;;
        --docker)
            INSTALL_DOCKER=true
            shift
            ;;
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --air         Install Air for hot reload"
            echo "  --lint        Install golangci-lint"
            echo "  --swag        Install swag for Swagger docs"
            echo "  --docker      Install Docker (if not already installed)"
            echo "  --all         Install all development tools"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting installation of development dependencies..."

# Check if Go is installed
if ! command -v go >/dev/null 2>&1; then
    print_error "Go is not installed. Please install Go first."
    print_status "Download from: https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}')
print_success "Go version: $GO_VERSION"

# Install Go dependencies
print_status "Installing Go dependencies..."
go mod tidy

if [ $? -eq 0 ]; then
    print_success "Go dependencies installed successfully!"
else
    print_error "Failed to install Go dependencies"
    exit 1
fi

# Install Air for hot reload
if [ "$INSTALL_AIR" = true ] || [ "$INSTALL_ALL" = true ]; then
    print_status "Installing Air for hot reload..."
    if command -v air >/dev/null 2>&1; then
        print_warning "Air is already installed"
    else
        go install github.com/cosmtrek/air@latest
        if [ $? -eq 0 ]; then
            print_success "Air installed successfully!"
        else
            print_error "Failed to install Air"
        fi
    fi
fi

# Install golangci-lint
if [ "$INSTALL_LINT" = true ] || [ "$INSTALL_ALL" = true ]; then
    print_status "Installing golangci-lint..."
    if command -v golangci-lint >/dev/null 2>&1; then
        print_warning "golangci-lint is already installed"
    else
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        if [ $? -eq 0 ]; then
            print_success "golangci-lint installed successfully!"
        else
            print_error "Failed to install golangci-lint"
        fi
    fi
fi

# Install swag for Swagger docs
if [ "$INSTALL_SWAG" = true ] || [ "$INSTALL_ALL" = true ]; then
    print_status "Installing swag for Swagger documentation..."
    if command -v swag >/dev/null 2>&1; then
        print_warning "swag is already installed"
    else
        go install github.com/swaggo/swag/cmd/swag@latest
        if [ $? -eq 0 ]; then
            print_success "swag installed successfully!"
        else
            print_error "Failed to install swag"
        fi
    fi
fi

# Install Docker (if requested and not already installed)
if [ "$INSTALL_DOCKER" = true ] || [ "$INSTALL_ALL" = true ]; then
    print_status "Checking Docker installation..."
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker is already installed: $DOCKER_VERSION"
    else
        print_warning "Docker is not installed"
        print_status "Please install Docker manually:"
        print_status "  - macOS: https://docs.docker.com/desktop/mac/install/"
        print_status "  - Linux: https://docs.docker.com/engine/install/"
        print_status "  - Windows: https://docs.docker.com/desktop/windows/install/"
    fi
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x scripts/*.sh

if [ $? -eq 0 ]; then
    print_success "Scripts are now executable!"
else
    print_warning "Failed to make some scripts executable"
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p build
mkdir -p logs
mkdir -p coverage
mkdir -p testdata

print_success "Directories created successfully!"

# Generate Swagger docs if swag is available
if command -v swag >/dev/null 2>&1; then
    print_status "Generating Swagger documentation..."
    swag init -g main.go
    if [ $? -eq 0 ]; then
        print_success "Swagger documentation generated!"
    else
        print_warning "Failed to generate Swagger documentation"
    fi
fi

# Test the installation
print_status "Testing installation..."
if go run main.go --help 2>/dev/null || timeout 5s go run main.go >/dev/null 2>&1; then
    print_success "Application builds and runs successfully!"
else
    print_warning "Application test failed, but installation may still be successful"
fi

print_success "Installation completed!"
print_status ""
print_status "Next steps:"
print_status "1. Copy env.example to .env and configure your environment"
print_status "2. Ensure PostgreSQL is running and accessible"
print_status "3. Run 'make run' to start the development server"
print_status "4. Visit http://localhost:8080 for the API"
print_status "5. Visit http://localhost:8080/swagger/index.html for documentation"
print_status ""
print_status "Available commands:"
print_status "  make run          - Start development server"
print_status "  make build        - Build the application"
print_status "  make test         - Run tests"
print_status "  make docker-build - Build Docker image"
print_status "  make docker-run   - Run with Docker Compose (includes PostgreSQL)"
print_status ""
print_status "Database setup:"
print_status "  - For local development: Install PostgreSQL locally"
print_status "  - For Docker: Use 'make docker-run' to start API + PostgreSQL"
print_status "  - Update .env with your PostgreSQL connection details" 