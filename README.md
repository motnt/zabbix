# Umbraco on Azure - Terraform Infrastructure

This repository contains Terraform configurations to deploy a production-ready Umbraco CMS application on Microsoft Azure following best practices for security, scalability, and monitoring.

## 🏗️ Architecture Overview

The infrastructure includes:

### Core Components
- **Azure App Service** - Linux-based hosting for Umbraco (.NET 8)
- **Azure SQL Database** - Managed database with automated backups
- **Azure Storage Account** - Blob storage for media files and backups
- **Azure Key Vault** - Secure storage for secrets and connection strings

### Networking & Security
- **Virtual Network (VNet)** - Network isolation with multiple subnets
- **Network Security Groups (NSGs)** - Traffic filtering and security rules
- **Private Endpoints** - Secure database connectivity
- **Application Gateway** - WAF protection, SSL termination, and load balancing
- **Managed Identity** - Secure authentication without stored credentials

### Performance & Reliability
- **Azure CDN** - Global content delivery for static assets
- **Auto-scaling** - Automatic scaling based on demand (production)
- **Deployment Slots** - Zero-downtime deployments (production)
- **Zone Redundancy** - High availability across availability zones (production)

### Monitoring & Logging
- **Application Insights** - Application performance monitoring
- **Log Analytics** - Centralized logging and analytics
- **Azure Monitor Alerts** - Proactive alerting on key metrics
- **Availability Tests** - Synthetic monitoring from multiple regions

## 📋 Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform** (>= 1.0) installed
   ```bash
   # On macOS
   brew install terraform
   
   # On Ubuntu
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

3. **OpenSSL** for SSL certificate generation (included in most systems)

4. **jq** for JSON processing (optional, for enhanced script output)
   ```bash
   # On macOS
   brew install jq
   
   # On Ubuntu
   sudo apt install jq
   ```

## 🚀 Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd umbraco-azure-terraform
```

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Environment configuration
environment = "dev"        # Options: dev, staging, prod
location    = "East US"
project_name = "myumbraco"

# Security - Add your IP ranges
allowed_ip_ranges = [
  "203.0.113.0/24"  # Your office IP range
]

# Optional: Custom domain
custom_domain = "myumbracosite.com"
```

### 3. Deploy Infrastructure

Using the deployment script (recommended):
```bash
./scripts/deploy.sh
```

Or manually:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Post-Deployment Setup

After deployment completes:

1. **Update DNS** - Point your domain to the Application Gateway IP
2. **Replace SSL Certificate** - Update with your real SSL certificate
3. **Configure Monitoring** - Update email addresses in alert action groups
4. **Deploy Umbraco Application** - Deploy your Umbraco app to the App Service

## 📁 Project Structure

```
├── terraform/                    # Terraform configuration files
│   ├── main.tf                  # Provider and basic configuration
│   ├── variables.tf             # Variable definitions
│   ├── locals.tf                # Local values and naming
│   ├── outputs.tf               # Output values
│   ├── resource-group.tf        # Resource group
│   ├── storage.tf               # Storage account and containers
│   ├── key-vault.tf             # Key Vault and secrets
│   ├── sql-database.tf          # SQL Server and database
│   ├── app-service.tf           # App Service Plan and App Service
│   ├── networking.tf            # VNet, subnets, NSGs
│   ├── application-gateway.tf   # Application Gateway and WAF
│   ├── cdn.tf                   # Azure CDN configuration
│   ├── monitoring.tf            # Application Insights and alerts
│   └── terraform.tfvars.example # Example variables file
├── scripts/
│   └── deploy.sh                # Deployment automation script
├── templates/                   # Sample Umbraco configuration templates
└── README.md                    # This file
```

## ⚙️ Configuration Options

### Environment-Specific Settings

The infrastructure automatically adjusts based on the `environment` variable:

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| App Service SKU | P1v3 | P1v3 | P2v3+ |
| SQL Database | S2 | S2 | P2+ |
| Zone Redundancy | ❌ | ❌ | ✅ |
| WAF Protection | ❌ | ❌ | ✅ |
| Deployment Slots | ❌ | ❌ | ✅ |
| Auto-scaling | ❌ | ❌ | ✅ |
| Backup Retention | 7 days | 7 days | 30 days |

### Customizable Features

Enable/disable features via variables:

```hcl
enable_application_gateway = true   # Application Gateway with WAF
enable_cdn = true                   # Azure CDN for static content
enable_backup = true                # Automated backups
```

## 🔒 Security Features

### Network Security
- **Private Endpoints** for SQL Database
- **VNet Integration** for App Service
- **Network Security Groups** with restrictive rules
- **Service Endpoints** for secure service communication

### Identity & Access Management
- **Managed Identity** for App Service
- **Azure AD Authentication** for SQL Server
- **Key Vault Integration** for secrets management
- **RBAC** with least privilege principles

### Data Protection
- **Encryption at Rest** for all storage services
- **TLS 1.2 Minimum** for all communications
- **Soft Delete** enabled for Key Vault and Storage
- **Versioning** enabled for blob storage

## 📊 Monitoring & Alerting

### Built-in Alerts
- High CPU/Memory usage
- HTTP 5xx errors
- High response times
- SQL Database DTU usage
- Application availability

### Dashboards
- Azure Portal dashboard with key metrics
- Application Insights application map
- Log Analytics workbooks

### Availability Monitoring
- Synthetic tests from multiple regions
- Health check endpoints
- Uptime monitoring

## 🔧 Umbraco Configuration

### Required NuGet Packages

Add these packages to your Umbraco project:

```xml
<PackageReference Include="Umbraco.Cms" Version="13.0.0" />
<PackageReference Include="Umbraco.Storage.AzureBlob" Version="13.0.0" />
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" Version="2.21.0" />
```

### App Settings Configuration

The infrastructure automatically configures these settings:

```json
{
  "ConnectionStrings": {
    "umbracoDbDSN": "@Microsoft.KeyVault(...)"
  },
  "Umbraco": {
    "CMS": {
      "Hosting": {
        "Debug": false
      }
    },
    "Storage": {
      "AzureBlob": {
        "Media": {
          "ConnectionString": "@Microsoft.KeyVault(...)",
          "ContainerName": "media"
        }
      }
    }
  }
}
```

## 💰 Cost Optimization

### Development Environment
- Basic/Standard tiers for most services
- Single availability zone
- Shorter retention periods
- Lower SKUs where appropriate

### Production Environment
- Premium tiers for performance and features
- Zone redundancy for high availability
- Extended backup and retention periods
- Auto-scaling to optimize costs

### Estimated Monthly Costs

| Environment | Estimated Cost (USD) |
|-------------|---------------------|
| Development | $200-400 |
| Staging | $300-600 |
| Production | $800-1500+ |

*Costs vary based on usage, region, and specific configuration choices.*

## 🔄 CI/CD Integration

### Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Infrastructure
  jobs:
  - job: Terraform
    steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform'
    - script: |
        cd terraform
        terraform init
        terraform plan -out=tfplan
        terraform apply tfplan
      displayName: 'Deploy Infrastructure'
```

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure

on:
  push:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: hashicorp/setup-terraform@v2
    - name: Terraform Init
      run: terraform init
      working-directory: terraform
    - name: Terraform Apply
      run: terraform apply -auto-approve
      working-directory: terraform
```

## 🛠️ Maintenance & Operations

### Regular Tasks
- **Security Updates** - Keep Terraform providers updated
- **Certificate Renewal** - Replace SSL certificates before expiry
- **Backup Verification** - Test restore procedures regularly
- **Cost Review** - Monitor and optimize resource usage
- **Performance Tuning** - Adjust SKUs based on usage patterns

### Scaling Operations
- **Vertical Scaling** - Increase App Service Plan SKU
- **Horizontal Scaling** - Configure auto-scaling rules
- **Database Scaling** - Adjust SQL Database performance tier

### Disaster Recovery
- **Backup Strategy** - Multiple backup types and retention periods
- **Point-in-Time Restore** - SQL Database PITR capability
- **Geo-Redundancy** - Storage replication across regions (production)

## 🐛 Troubleshooting

### Common Issues

1. **Deployment Fails**
   ```bash
   # Check Terraform state
   terraform state list
   terraform state show <resource>
   
   # Force refresh
   terraform refresh
   ```

2. **App Service Won't Start**
   - Check Application Insights logs
   - Verify Key Vault access policies
   - Ensure connection strings are correct

3. **Database Connection Issues**
   - Verify private endpoint configuration
   - Check NSG rules
   - Test from App Service console

4. **SSL Certificate Problems**
   - Regenerate certificate with correct domain
   - Update Application Gateway configuration
   - Verify certificate password

### Useful Commands

```bash
# View Terraform outputs
terraform output

# Show specific resource
terraform state show azurerm_linux_web_app.main

# Import existing resource
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/...

# Refresh state
terraform refresh

# Plan with specific var file
terraform plan -var-file="prod.tfvars"
```

## 📚 Additional Resources

- [Umbraco Documentation](https://docs.umbraco.com/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure and Terraform documentation
3. Create an issue in this repository
4. Contact the development team

---

**Note**: This infrastructure is designed for production use but should be thoroughly tested in a development environment first. Always review and customize the configuration for your specific requirements.
