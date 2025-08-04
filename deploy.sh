#!/bin/bash

# Umbraco Azure Infrastructure Deployment Script
# This script automates the deployment of the Umbraco infrastructure using Terraform

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if user is logged into Azure
    if ! az account show &> /dev/null; then
        print_error "You are not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_status "Terraform initialized successfully!"
}

# Plan deployment
plan_deployment() {
    print_status "Planning deployment..."
    terraform plan -out=tfplan
    print_status "Deployment plan created successfully!"
}

# Apply deployment
apply_deployment() {
    print_status "Applying deployment..."
    terraform apply tfplan
    print_status "Deployment completed successfully!"
}

# Show outputs
show_outputs() {
    print_status "Deployment outputs:"
    terraform output
}

# Main deployment function
deploy() {
    print_status "Starting Umbraco Azure infrastructure deployment..."
    
    check_prerequisites
    init_terraform
    plan_deployment
    
    echo
    print_warning "Please review the deployment plan above."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_deployment
        show_outputs
        print_status "Deployment completed! Check the outputs above for important information."
    else
        print_warning "Deployment cancelled by user."
        exit 0
    fi
}

# Destroy function
destroy() {
    print_warning "This will destroy all resources created by this Terraform configuration!"
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying infrastructure..."
        terraform destroy
        print_status "Infrastructure destroyed successfully!"
    else
        print_warning "Destroy operation cancelled by user."
        exit 0
    fi
}

# Show help
show_help() {
    echo "Umbraco Azure Infrastructure Deployment Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  deploy    Deploy the Umbraco infrastructure (default)"
    echo "  destroy   Destroy the Umbraco infrastructure"
    echo "  help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 destroy"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    destroy)
        destroy
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac