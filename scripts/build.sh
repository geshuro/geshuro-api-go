#!/bin/bash

# Build script for the API
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
BUILD_NAME="api"
BUILD_OS="$(go env GOOS)"
BUILD_ARCH="$(go env GOARCH)"
BUILD_VERSION="1.0.0"
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S_UTC')

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --os)
            BUILD_OS="$2"
            shift 2
            ;;
        --arch)
            BUILD_ARCH="$2"
            shift 2
            ;;
        --name)
            BUILD_NAME="$2"
            shift 2
            ;;
        --version)
            BUILD_VERSION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --os OS        Target operating system (default: current OS)"
            echo "  --arch ARCH    Target architecture (default: current arch)"
            echo "  --name NAME    Output binary name (default: api)"
            echo "  --version VER  Build version (default: 1.0.0)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting build process..."
print_status "Target OS: $BUILD_OS"
print_status "Target Arch: $BUILD_ARCH"
print_status "Build Name: $BUILD_NAME"
print_status "Build Version: $BUILD_VERSION"

# Create build directory
BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

# Set build flags
LDFLAGS="-X main.Version=$BUILD_VERSION -X main.BuildTime=$BUILD_TIME"

# Determine file extension
if [ "$BUILD_OS" = "windows" ]; then
    EXTENSION=".exe"
else
    EXTENSION=""
fi

# Build the application (PostgreSQL doesn't require CGO)
print_status "Building application..."
GOOS=$BUILD_OS GOARCH=$BUILD_ARCH go build \
    -ldflags "$LDFLAGS" \
    -o "$BUILD_DIR/${BUILD_NAME}${EXTENSION}" \
    main.go

if [ $? -eq 0 ]; then
    print_success "Build completed successfully!"
    print_status "Binary location: $BUILD_DIR/${BUILD_NAME}${EXTENSION}"
    
    # Show file size
    FILE_SIZE=$(du -h "$BUILD_DIR/${BUILD_NAME}${EXTENSION}" | cut -f1)
    print_status "File size: $FILE_SIZE"
    
    # Show build info
    if [ "$BUILD_OS" = "$(go env GOOS)" ] && [ "$BUILD_ARCH" = "$(go env GOARCH)" ]; then
        print_status "Testing binary..."
        if "$BUILD_DIR/${BUILD_NAME}${EXTENSION}" --help 2>/dev/null || "$BUILD_DIR/${BUILD_NAME}${EXTENSION}" -h 2>/dev/null; then
            print_success "Binary is executable!"
        else
            print_warning "Could not test binary execution"
        fi
    fi
else
    print_error "Build failed!"
    exit 1
fi 