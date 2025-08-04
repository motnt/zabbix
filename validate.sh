#!/bin/bash

# Terraform Validation Script
# This script validates the Terraform configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    print_status "Terraform found: $(terraform version)"
}

# Format Terraform files
format_terraform() {
    print_status "Formatting Terraform files..."
    terraform fmt -recursive
    print_status "Terraform files formatted!"
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    # Initialize Terraform
    terraform init -backend=false
    
    # Validate configuration
    if terraform validate; then
        print_status "Terraform configuration is valid!"
    else
        print_error "Terraform configuration validation failed!"
        exit 1
    fi
}

# Check for security issues
security_check() {
    print_status "Running security checks..."
    
    # Check for hardcoded secrets (basic check)
    if grep -r "password\|secret\|key" . --include="*.tf" --include="*.tfvars" | grep -v "var\." | grep -v "#" | grep -v "description"; then
        print_warning "Potential hardcoded secrets found. Please review the configuration."
    else
        print_status "No obvious hardcoded secrets found."
    fi
}

# Main validation function
main() {
    print_status "Starting Terraform validation..."
    
    check_terraform
    format_terraform
    validate_terraform
    security_check
    
    print_status "Validation completed successfully!"
}

# Run main function
main