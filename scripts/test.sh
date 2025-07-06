#!/bin/bash

# Test script for the API
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
COVERAGE=false
VERBOSE=false
RACE=false
SHORT=false
BENCHMARK=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --race)
            RACE=true
            shift
            ;;
        --short)
            SHORT=true
            shift
            ;;
        --bench)
            BENCHMARK=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --coverage     Generate coverage report"
            echo "  --verbose      Verbose output"
            echo "  --race         Run tests with race detection"
            echo "  --short        Run only short tests"
            echo "  --bench        Run benchmarks"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting test suite..."

# Create test directories
mkdir -p testdata
mkdir -p coverage

# Build test arguments
TEST_ARGS=""

if [ "$VERBOSE" = true ]; then
    TEST_ARGS="$TEST_ARGS -v"
fi

if [ "$RACE" = true ]; then
    TEST_ARGS="$TEST_ARGS -race"
fi

if [ "$SHORT" = true ]; then
    TEST_ARGS="$TEST_ARGS -short"
fi

if [ "$COVERAGE" = true ]; then
    print_status "Running tests with coverage..."
    go test $TEST_ARGS -coverprofile=coverage/coverage.out -covermode=atomic ./...
    
    if [ $? -eq 0 ]; then
        print_success "Tests passed!"
        
        # Generate coverage report
        print_status "Generating coverage report..."
        go tool cover -html=coverage/coverage.out -o coverage/coverage.html
        
        # Show coverage summary
        COVERAGE_SUMMARY=$(go tool cover -func=coverage/coverage.out | tail -1)
        print_status "Coverage: $COVERAGE_SUMMARY"
        
        print_success "Coverage report generated: coverage/coverage.html"
    else
        print_error "Tests failed!"
        exit 1
    fi
else
    print_status "Running tests..."
    go test $TEST_ARGS ./...
    
    if [ $? -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_error "Tests failed!"
        exit 1
    fi
fi

# Run benchmarks if requested
if [ "$BENCHMARK" = true ]; then
    print_status "Running benchmarks..."
    go test $TEST_ARGS -bench=. -benchmem ./...
fi

# Run linting
print_status "Running linter..."
if command -v golangci-lint >/dev/null 2>&1; then
    golangci-lint run
    if [ $? -eq 0 ]; then
        print_success "Linting passed!"
    else
        print_warning "Linting found issues"
    fi
else
    print_warning "golangci-lint not found. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
fi

print_success "Test suite completed!" 