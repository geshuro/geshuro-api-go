#!/bin/bash

# Docker management script for the API
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
IMAGE_NAME="gin-api"
TAG="latest"
CONTAINER_NAME="gin-api-container"
PORT=8080
COMPOSE_FILE="docker-compose.yml"
MODE="production"

# Parse command line arguments
ACTION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        build)
            ACTION="build"
            shift
            ;;
        run)
            ACTION="run"
            shift
            ;;
        stop)
            ACTION="stop"
            shift
            ;;
        clean)
            ACTION="clean"
            shift
            ;;
        logs)
            ACTION="logs"
            shift
            ;;
        shell)
            ACTION="shell"
            shift
            ;;
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --compose)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --dev)
            MODE="development"
            COMPOSE_FILE="docker-compose.dev.yml"
            shift
            ;;
        --prod)
            MODE="production"
            COMPOSE_FILE="docker-compose.yml"
            shift
            ;;
        --help)
            echo "Usage: $0 [ACTION] [OPTIONS]"
            echo ""
            echo "Actions:"
            echo "  build         Build Docker image"
            echo "  run           Run container with docker-compose"
            echo "  stop          Stop and remove containers"
            echo "  clean         Clean up Docker resources"
            echo "  logs          Show container logs"
            echo "  shell         Open shell in running container"
            echo ""
            echo "Options:"
            echo "  --image NAME  Docker image name (default: gin-api)"
            echo "  --tag TAG     Docker image tag (default: latest)"
            echo "  --container NAME  Container name (default: gin-api-container)"
            echo "  --port PORT   Port to expose (default: 8080)"
            echo "  --compose FILE  Docker compose file (default: docker-compose.yml)"
            echo "  --dev         Use development mode (API + PostgreSQL)"
            echo "  --prod        Use production mode (API only)"
            echo "  --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 build"
            echo "  $0 run --dev                    # Run with PostgreSQL"
            echo "  $0 run --prod                   # Run API only"
            echo "  $0 run --port 3000 --dev        # Run on port 3000 with PostgreSQL"
            echo "  $0 stop"
            echo "  $0 logs"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    print_error "No action specified. Use --help for usage information."
    exit 1
fi

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    print_warning "docker-compose not found, trying 'docker compose'..."
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

case $ACTION in
    build)
        print_status "Building Docker image: $IMAGE_NAME:$TAG"
        
        # Check if Dockerfile exists
        if [ ! -f Dockerfile ]; then
            print_error "Dockerfile not found in current directory"
            exit 1
        fi
        
        # Build the image
        docker build -t "$IMAGE_NAME:$TAG" .
        
        if [ $? -eq 0 ]; then
            print_success "Docker image built successfully!"
            
            # Show image info
            IMAGE_SIZE=$(docker images "$IMAGE_NAME:$TAG" --format "table {{.Size}}" | tail -1)
            print_status "Image size: $IMAGE_SIZE"
        else
            print_error "Failed to build Docker image"
            exit 1
        fi
        ;;
        
    run)
        print_status "Starting services with docker-compose in $MODE mode..."
        
        # Check if docker-compose file exists
        if [ ! -f "$COMPOSE_FILE" ]; then
            print_error "Docker Compose file not found: $COMPOSE_FILE"
            exit 1
        fi
        
        # Stop any existing containers
        print_status "Stopping existing containers..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down 2>/dev/null || true
        
        # Start services
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d
        
        if [ $? -eq 0 ]; then
            print_success "Services started successfully!"
            print_status "API available at: http://localhost:$PORT"
            print_status "Swagger docs at: http://localhost:$PORT/swagger/index.html"
            
            if [ "$MODE" = "development" ]; then
                print_status "PostgreSQL available at: localhost:5432"
            else
                print_status "API only mode - PostgreSQL must be available externally"
            fi
            
            # Wait for services to be ready
            print_status "Waiting for services to be ready..."
            sleep 10
            
            # Check API health
            if curl -f http://localhost:$PORT/api/v1/health >/dev/null 2>&1; then
                print_success "API is healthy!"
            else
                print_warning "API health check failed, but container is running"
            fi
            
            # Check PostgreSQL only in development mode
            if [ "$MODE" = "development" ]; then
                if docker exec api-postgres-dev pg_isready -U api_user >/dev/null 2>&1; then
                    print_success "PostgreSQL is ready!"
                else
                    print_warning "PostgreSQL health check failed, but container is running"
                fi
            fi
        else
            print_error "Failed to start services"
            exit 1
        fi
        ;;
        
    stop)
        print_status "Stopping and removing containers..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down
        
        if [ $? -eq 0 ]; then
            print_success "Containers stopped and removed!"
        else
            print_warning "Some containers may still be running"
        fi
        ;;
        
    clean)
        print_status "Cleaning up Docker resources..."
        
        # Stop containers
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" down 2>/dev/null || true
        
        # Remove images
        docker rmi "$IMAGE_NAME:$TAG" 2>/dev/null || true
        
        # Remove dangling images
        docker image prune -f
        
        # Remove unused volumes
        docker volume prune -f
        
        print_success "Docker resources cleaned up!"
        ;;
        
    logs)
        print_status "Showing container logs..."
        $DOCKER_COMPOSE -f "$COMPOSE_FILE" logs -f
        ;;
        
    shell)
        print_status "Opening shell in container..."
        
        # Check if container is running
        if ! docker ps --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_error "Container $CONTAINER_NAME is not running"
            exit 1
        fi
        
        docker exec -it "$CONTAINER_NAME" /bin/sh
        ;;
        
    *)
        print_error "Unknown action: $ACTION"
        exit 1
        ;;
esac 