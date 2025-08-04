#!/bin/bash

# Umbraco Azure Infrastructure Deployment Script
# This script automates the deployment of Umbraco infrastructure using Terraform

set -e  # Exit on any error

# Color codes for output
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if OpenSSL is available (for certificate generation)
    if ! command -v openssl &> /dev/null; then
        print_warning "OpenSSL is not installed. SSL certificate generation may fail."
    fi
    
    print_success "Prerequisites check completed."
}

# Function to setup Terraform backend (optional)
setup_backend() {
    read -p "Do you want to setup remote state backend? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setting up Terraform remote state backend..."
        
        read -p "Enter storage account name for Terraform state: " STORAGE_ACCOUNT
        read -p "Enter resource group name for Terraform state: " STATE_RG
        read -p "Enter container name for Terraform state (default: tfstate): " CONTAINER_NAME
        CONTAINER_NAME=${CONTAINER_NAME:-tfstate}
        
        # Create resource group for state
        az group create --name "$STATE_RG" --location "East US" || true
        
        # Create storage account for state
        az storage account create \
            --resource-group "$STATE_RG" \
            --name "$STORAGE_ACCOUNT" \
            --sku "Standard_LRS" \
            --encryption-services blob || true
        
        # Create container
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT" || true
        
        # Update backend configuration
        cat > terraform/backend.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$STATE_RG"
    storage_account_name = "$STORAGE_ACCOUNT"
    container_name       = "$CONTAINER_NAME"
    key                  = "umbraco.terraform.tfstate"
  }
}
EOF
        
        print_success "Backend configuration created."
    fi
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    if terraform validate; then
        print_success "Terraform configuration is valid."
    else
        print_error "Terraform configuration validation failed."
        exit 1
    fi
    
    cd ..
}

# Function to plan deployment
plan_deployment() {
    print_status "Creating Terraform execution plan..."
    
    cd terraform
    
    # Check if tfvars file exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars file not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values before continuing."
        read -p "Press Enter to continue after editing terraform.tfvars..."
    fi
    
    # Create plan
    terraform plan -out=tfplan
    
    print_success "Terraform plan created successfully."
    
    # Show plan summary
    echo
    print_status "Plan Summary:"
    terraform show -json tfplan | jq -r '.resource_changes[] | "\(.change.actions[0]) \(.address)"' | sort
    
    cd ..
}

# Function to apply deployment
apply_deployment() {
    print_status "Applying Terraform configuration..."
    
    cd terraform
    
    # Apply the plan
    if terraform apply tfplan; then
        print_success "Infrastructure deployed successfully!"
        
        # Show outputs
        echo
        print_status "Deployment Outputs:"
        terraform output
        
        # Save outputs to file
        terraform output -json > ../deployment-outputs.json
        print_success "Outputs saved to deployment-outputs.json"
        
    else
        print_error "Deployment failed!"
        exit 1
    fi
    
    cd ..
}

# Function to destroy infrastructure (optional)
destroy_infrastructure() {
    print_warning "This will destroy all infrastructure resources!"
    read -p "Are you sure you want to destroy the infrastructure? Type 'yes' to confirm: " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        print_status "Destroying infrastructure..."
        
        cd terraform
        terraform destroy -auto-approve
        print_success "Infrastructure destroyed."
        cd ..
    else
        print_status "Destruction cancelled."
    fi
}

# Function to show help
show_help() {
    echo "Umbraco Azure Infrastructure Deployment Script"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  deploy    - Deploy the infrastructure (default)"
    echo "  plan      - Create and show deployment plan only"
    echo "  destroy   - Destroy the infrastructure"
    echo "  validate  - Validate Terraform configuration only"
    echo "  help      - Show this help message"
    echo
    echo "Examples:"
    echo "  $0                # Deploy infrastructure"
    echo "  $0 deploy         # Deploy infrastructure"
    echo "  $0 plan           # Show deployment plan"
    echo "  $0 validate       # Validate configuration"
    echo "  $0 destroy        # Destroy infrastructure"
}

# Main script logic
main() {
    local command=${1:-deploy}
    
    case $command in
        deploy)
            print_status "Starting Umbraco infrastructure deployment..."
            check_prerequisites
            setup_backend
            validate_terraform
            plan_deployment
            
            read -p "Do you want to apply this plan? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                apply_deployment
            else
                print_status "Deployment cancelled."
            fi
            ;;
        plan)
            check_prerequisites
            validate_terraform
            plan_deployment
            ;;
        destroy)
            check_prerequisites
            destroy_infrastructure
            ;;
        validate)
            check_prerequisites
            validate_terraform
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"