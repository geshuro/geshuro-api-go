#!/bin/bash

# Run script for development
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
PORT=8080
GIN_MODE=debug
USE_AIR=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --mode)
            GIN_MODE="$2"
            shift 2
            ;;
        --air)
            USE_AIR=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --port PORT    Port to run the server on (default: 8080)"
            echo "  --mode MODE    Gin mode: debug or release (default: debug)"
            echo "  --air          Use Air for hot reload (requires air to be installed)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting API server..."
print_status "Port: $PORT"
print_status "Mode: $GIN_MODE"

# Check if port is available
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "Port $PORT is already in use!"
    print_status "Attempting to kill existing process..."
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Set environment variables
export PORT=$PORT
export GIN_MODE=$GIN_MODE

# Check if Air is available and requested
if [ "$USE_AIR" = true ]; then
    if command -v air >/dev/null 2>&1; then
        print_status "Using Air for hot reload..."
        print_status "Install Air with: go install github.com/cosmtrek/air@latest"
        
        # Create .air.toml if it doesn't exist
        if [ ! -f .air.toml ]; then
            print_status "Creating .air.toml configuration..."
            cat > .air.toml << EOF
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ."
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  include_file = []
  kill_delay = "0s"
  log = "build-errors.log"
  poll = false
  poll_interval = 0
  rerun = false
  rerun_delay = 500
  send_interrupt = false
  stop_on_root = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  main_only = false
  time = false

[misc]
  clean_on_exit = false

[screen]
  clear_on_rebuild = false
  keep_scroll = true
EOF
        fi
        
        air
    else
        print_warning "Air not found. Installing Air..."
        print_status "Installing Air for hot reload..."
        go install github.com/cosmtrek/air@latest
        print_success "Air installed! Running with hot reload..."
        air
    fi
else
    print_status "Running with go run..."
    go run main.go
fi 