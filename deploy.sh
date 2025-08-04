#!/bin/bash

# Umbraco Azure Infrastructure Deployment Script
# This script automates the deployment of the Umbraco infrastructure using Terraform

set -e  # Exit on any error

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

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    # Check if Terraform is installed
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check Terraform version
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    print_status "Terraform version: $TF_VERSION"
    
    # Check if Azure CLI is installed
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    # Check if user is logged into Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please edit terraform.tfvars with your configuration values."
            print_warning "Press Enter to continue or Ctrl+C to abort..."
            read -r
        else
            print_error "terraform.tfvars.example not found. Please create terraform.tfvars manually."
            exit 1
        fi
    fi
    
    print_success "Prerequisites validated successfully."
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    if terraform init; then
        print_success "Terraform initialized successfully."
    else
        print_error "Failed to initialize Terraform."
        exit 1
    fi
}

# Function to validate Terraform configuration
validate_configuration() {
    print_status "Validating Terraform configuration..."
    
    if terraform validate; then
        print_success "Terraform configuration is valid."
    else
        print_error "Terraform configuration validation failed."
        exit 1
    fi
}

# Function to plan Terraform deployment
plan_deployment() {
    print_status "Planning Terraform deployment..."
    
    if terraform plan -out=tfplan; then
        print_success "Terraform plan created successfully."
    else
        print_error "Failed to create Terraform plan."
        exit 1
    fi
}

# Function to apply Terraform deployment
apply_deployment() {
    print_status "Applying Terraform deployment..."
    
    if terraform apply tfplan; then
        print_success "Terraform deployment completed successfully."
    else
        print_error "Failed to apply Terraform deployment."
        exit 1
    fi
}

# Function to show deployment outputs
show_outputs() {
    print_status "Deployment outputs:"
    echo ""
    terraform output
    echo ""
    
    # Show deployment summary
    print_status "Deployment Summary:"
    echo "=================================="
    terraform output -json | jq -r '.deployment_summary.value | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || echo "Unable to display deployment summary"
    echo "=================================="
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -f tfplan
    print_success "Cleanup completed."
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --plan     Only create plan, don't apply"
    echo "  -v, --validate Only validate configuration"
    echo "  -i, --init     Only initialize Terraform"
    echo "  -d, --destroy  Destroy the infrastructure"
    echo ""
    echo "Examples:"
    echo "  $0              # Full deployment"
    echo "  $0 --plan       # Only create plan"
    echo "  $0 --validate   # Only validate configuration"
    echo "  $0 --destroy    # Destroy infrastructure"
}

# Main script
main() {
    echo "=================================="
    echo "Umbraco Azure Infrastructure Deployment"
    echo "=================================="
    echo ""
    
    # Parse command line arguments
    PLAN_ONLY=false
    VALIDATE_ONLY=false
    INIT_ONLY=false
    DESTROY_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--plan)
                PLAN_ONLY=true
                shift
                ;;
            -v|--validate)
                VALIDATE_ONLY=true
                shift
                ;;
            -i|--init)
                INIT_ONLY=true
                shift
                ;;
            -d|--destroy)
                DESTROY_MODE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate prerequisites
    validate_prerequisites
    
    # Initialize Terraform
    init_terraform
    
    if [ "$INIT_ONLY" = true ]; then
        print_success "Initialization completed."
        exit 0
    fi
    
    # Validate configuration
    validate_configuration
    
    if [ "$VALIDATE_ONLY" = true ]; then
        print_success "Validation completed."
        exit 0
    fi
    
    # Handle destroy mode
    if [ "$DESTROY_MODE" = true ]; then
        print_warning "You are about to destroy the infrastructure. This action cannot be undone."
        print_warning "Press Enter to continue or Ctrl+C to abort..."
        read -r
        
        print_status "Destroying infrastructure..."
        if terraform destroy -auto-approve; then
            print_success "Infrastructure destroyed successfully."
        else
            print_error "Failed to destroy infrastructure."
            exit 1
        fi
        exit 0
    fi
    
    # Plan deployment
    plan_deployment
    
    if [ "$PLAN_ONLY" = true ]; then
        print_success "Plan created successfully. Review the plan and run '$0' to apply."
        exit 0
    fi
    
    # Confirm deployment
    print_warning "You are about to deploy the Umbraco infrastructure to Azure."
    print_warning "This will create resources that may incur costs."
    print_warning "Press Enter to continue or Ctrl+C to abort..."
    read -r
    
    # Apply deployment
    apply_deployment
    
    # Show outputs
    show_outputs
    
    # Cleanup
    cleanup
    
    echo ""
    print_success "Deployment completed successfully!"
    print_status "Next steps:"
    print_status "1. Deploy your Umbraco application to the App Service"
    print_status "2. Configure Umbraco settings in the Azure Portal"
    print_status "3. Set up monitoring and alerting"
    print_status "4. Configure backup policies"
    echo ""
}

# Run main function
main "$@"