# Umbraco Azure Infrastructure with Terraform

This Terraform configuration deploys a production-ready Umbraco CMS application on Azure following best practices for security, scalability, and maintainability.

## Architecture Overview

The infrastructure includes the following Azure resources:

### Core Components
- **App Service Plan** - Hosts the Umbraco web application
- **App Service** - Windows-based web app with .NET 6.0 runtime
- **SQL Database** - Azure SQL Database for Umbraco content and configuration
- **Storage Account** - Azure Blob Storage for media files and static content

### Security & Networking
- **Virtual Network** - Isolated network with separate subnets
- **Private Endpoints** - Secure SQL Server connectivity
- **Key Vault** - Centralized secrets management
- **Network Security** - IP restrictions and VNet integration

### Performance & Monitoring
- **Application Insights** - Application monitoring and telemetry
- **CDN** - Content delivery network for static assets
- **Auto Scaling** - Optional automatic scaling based on demand

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** version 1.0 or later
3. **Azure Subscription** with appropriate permissions
4. **Azure AD** user/group for SQL Server administration (optional)

## Quick Start

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd umbraco-azure-terraform
```

### 2. Configure Variables
Copy the example variables file and customize it:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- Set a secure SQL admin password
- Configure your Azure region
- Update tags and resource names as needed

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan the Deployment
```bash
terraform plan
```

### 5. Deploy the Infrastructure
```bash
terraform apply
```

### 6. Access Your Umbraco Application
After deployment, you can access:
- **Main Application**: `https://<app-service-name>.azurewebsites.net`
- **Admin Interface**: `https://<app-service-name>.azurewebsites.net/umbraco`

## Configuration Options

### Resource Sizing
- **App Service Plan**: Choose from B1, B2, B3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, S1, S2, S3
- **SQL Database**: Basic, Standard, Premium, GeneralPurpose, BusinessCritical, Hyperscale
- **Storage Account**: Standard or Premium tier

### Security Features
- **Private Endpoints**: Isolate SQL Server from public internet
- **Key Vault**: Store sensitive configuration securely
- **Network Restrictions**: Limit access to specific IP ranges or VNet
- **TLS 1.2**: Enforced minimum TLS version

### Performance Features
- **CDN**: Accelerate static content delivery
- **Auto Scaling**: Automatically scale based on CPU/memory usage
- **Application Insights**: Monitor application performance and errors

## Best Practices Implemented

### Security
- ✅ Private endpoints for database connectivity
- ✅ Network isolation with VNet integration
- ✅ Key Vault for secrets management
- ✅ TLS 1.2 enforcement
- ✅ Azure AD authentication for SQL Server
- ✅ IP restrictions and network security groups

### Scalability
- ✅ App Service Plan with multiple SKU options
- ✅ Auto-scaling capabilities
- ✅ CDN for static content
- ✅ Azure Storage for media files
- ✅ Separate subnets for different resource types

### Monitoring & Observability
- ✅ Application Insights integration
- ✅ Health check endpoints
- ✅ Comprehensive logging
- ✅ Performance monitoring

### Maintainability
- ✅ Infrastructure as Code with Terraform
- ✅ Modular configuration with variables
- ✅ Consistent tagging strategy
- ✅ Version control friendly

## Post-Deployment Steps

### 1. Install Umbraco
After deployment, you'll need to install Umbraco on the App Service:

1. Download the latest Umbraco package
2. Deploy to the App Service using FTP or Azure DevOps
3. Run the Umbraco installer at `/install`
4. Configure the database connection using the provided connection string

### 2. Configure Umbraco Settings
Update the following Umbraco settings in the App Service Configuration:

- **Database Connection**: Already configured via app settings
- **Media Storage**: Configured to use Azure Blob Storage
- **Logging**: Configured to use Application Insights
- **CDN**: Configured for static content delivery

### 3. Security Hardening
- Enable Azure AD authentication for Umbraco admin
- Configure SSL certificates
- Set up backup policies
- Enable Azure Security Center monitoring

## Cost Optimization

### Development Environment
- Use `B1` App Service Plan
- Use `Basic` SQL Database
- Disable CDN and Application Insights
- Use `Standard` Storage Account with LRS

### Production Environment
- Use `P1v3` or higher App Service Plan
- Use `Standard` or `Premium` SQL Database
- Enable CDN and Application Insights
- Use `Premium` Storage Account for better performance

## Troubleshooting

### Common Issues

1. **SQL Connection Errors**
   - Verify private endpoint is properly configured
   - Check firewall rules and network security groups
   - Ensure VNet integration is enabled

2. **App Service Not Starting**
   - Check application logs in Azure Portal
   - Verify .NET version compatibility
   - Check app settings configuration

3. **Storage Access Issues**
   - Verify storage account connection string
   - Check container permissions
   - Ensure VNet integration is configured

### Useful Commands

```bash
# View deployment outputs
terraform output

# Check resource status
terraform show

# Destroy infrastructure (use with caution)
terraform destroy

# Refresh state
terraform refresh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the [Terraform documentation](https://www.terraform.io/docs)
- Review [Azure Umbraco documentation](https://docs.microsoft.com/en-us/azure/app-service/overview)
- Open an issue in this repository

## Changelog

### Version 1.0.0
- Initial release
- Complete Umbraco infrastructure
- Security best practices
- Monitoring and observability
- Performance optimization
