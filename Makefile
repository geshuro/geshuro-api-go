# Makefile for Gin API Project
# This Makefile provides convenient commands for development and deployment

.PHONY: help install build run test clean docker-build docker-run docker-stop docker-logs docker-clean swagger lint format

# Default target
help: ## Show this help message
	@echo "🚀 Gin API - Available Commands"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "📚 For more detailed help on any command, use: make <command> --help"

# Installation and setup
install: ## Install development dependencies and tools
	@echo "🔧 Installing development dependencies..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh --all

install-air: ## Install Air for hot reload
	@echo "🔄 Installing Air for hot reload..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh --air

install-lint: ## Install golangci-lint
	@echo "🔍 Installing golangci-lint..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh --lint

install-swag: ## Install swag for Swagger docs
	@echo "📖 Installing swag for Swagger documentation..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh --swag

# Development commands
run: ## Start development server (requires PostgreSQL)
	@echo "🚀 Starting development server..."
	@chmod +x scripts/run.sh
	@./scripts/run.sh

run-air: ## Start development server with hot reload (requires PostgreSQL)
	@echo "🔄 Starting development server with hot reload..."
	@chmod +x scripts/run.sh
	@./scripts/run.sh --air

run-port: ## Start development server on specific port (usage: make run-port PORT=3000)
	@echo "🚀 Starting development server on port $(PORT)..."
	@chmod +x scripts/run.sh
	@./scripts/run.sh --port $(PORT)

# Build commands
build: ## Build the application
	@echo "🔨 Building application..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh

build-linux: ## Build for Linux
	@echo "🐧 Building for Linux..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh --os linux --arch amd64

build-macos: ## Build for macOS
	@echo "🍎 Building for macOS..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh --os darwin --arch amd64

build-windows: ## Build for Windows
	@echo "🪟 Building for Windows..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh --os windows --arch amd64

# Testing commands
test: ## Run tests
	@echo "🧪 Running tests..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh

test-coverage: ## Run tests with coverage report
	@echo "📊 Running tests with coverage..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --coverage

test-verbose: ## Run tests with verbose output
	@echo "🔍 Running tests with verbose output..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --verbose

test-race: ## Run tests with race detection
	@echo "🏁 Running tests with race detection..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --race

test-bench: ## Run benchmarks
	@echo "⚡ Running benchmarks..."
	@chmod +x scripts/test.sh
	@./scripts/test.sh --bench

# Docker commands
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh build

docker-run: ## Run with Docker Compose (API only)
	@echo "🐳 Starting API with Docker Compose..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh run --prod

docker-run-dev: ## Run with Docker Compose (API + PostgreSQL)
	@echo "🐳 Starting development environment with Docker Compose (API + PostgreSQL)..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh run --dev

docker-stop: ## Stop Docker containers
	@echo "🛑 Stopping Docker containers..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh stop

docker-logs: ## Show Docker container logs
	@echo "📋 Showing Docker container logs..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh logs

docker-shell: ## Open shell in Docker container
	@echo "💻 Opening shell in Docker container..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh shell

docker-clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up Docker resources..."
	@chmod +x scripts/docker.sh
	@./scripts/docker.sh clean

# Code quality commands
lint: ## Run linter
	@echo "🔍 Running linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "⚠️  golangci-lint not found. Install with: make install-lint"; \
	fi

format: ## Format Go code
	@echo "🎨 Formatting Go code..."
	@go fmt ./...

swagger: ## Generate Swagger documentation
	@echo "📖 Generating Swagger documentation..."
	@if command -v swag >/dev/null 2>&1; then \
		swag init -g main.go; \
	else \
		echo "⚠️  swag not found. Install with: make install-swag"; \
	fi

# Utility commands
clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf tmp/
	@rm -rf coverage/
	@rm -f *.log

deps: ## Download and tidy Go dependencies
	@echo "📦 Downloading Go dependencies..."
	@go mod download
	@go mod tidy

# Database commands
db-migrate: ## Run database migrations
	@echo "🗄️  Running database migrations..."
	@go run main.go

db-reset: ## Reset database (delete and recreate)
	@echo "🔄 Resetting database..."
	@echo "⚠️  This will delete all data in PostgreSQL"
	@echo "   For Docker: make docker-stop && make docker-run"
	@echo "   For local: Drop and recreate the database manually"

db-status: ## Check database connection status
	@echo "🔍 Checking database connection..."
	@if command -v psql >/dev/null 2>&1; then \
		psql -h localhost -U api_user -d api -c "SELECT version();" 2>/dev/null || echo "❌ Cannot connect to PostgreSQL"; \
	else \
		echo "⚠️  psql not found. Install PostgreSQL client tools"; \
	fi

# Development workflow
dev: ## Start development environment (install deps, run tests, start server)
	@echo "🚀 Starting development environment..."
	@make deps
	@make test
	@make run

dev-full: ## Full development setup (install tools, deps, tests, server)
	@echo "🚀 Starting full development environment..."
	@make install
	@make deps
	@make test
	@make run-air

# Production commands
prod-build: ## Build for production
	@echo "🏭 Building for production..."
	@GIN_MODE=release make build

prod-run: ## Run in production mode
	@echo "🏭 Running in production mode..."
	@GIN_MODE=release make run

# Health check
health: ## Check API health
	@echo "🏥 Checking API health..."
	@curl -f http://localhost:8080/api/v1/health || echo "❌ API is not responding"

# Show project info
info: ## Show project information
	@echo "📋 Project Information"
	@echo "======================"
	@echo "Go version: $(shell go version)"
	@echo "Go modules: $(shell go list -m all | wc -l) modules"
	@echo "Source files: $(shell find . -name "*.go" | wc -l) files"
	@echo "Lines of code: $(shell find . -name "*.go" -exec wc -l {} + | tail -1 | awk '{print $$1}') lines"
	@echo ""
	@echo "📁 Project structure:"
	@tree -I 'node_modules|vendor|.git|build|tmp|coverage' -L 2 || ls -la

# Default target when no arguments are provided
.DEFAULT_GOAL := help 