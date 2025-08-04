# Umbraco Azure Infrastructure with Terraform

This Terraform configuration deploys a complete Umbraco CMS infrastructure in Azure following best practices for security, scalability, and monitoring.

## Architecture Overview

The infrastructure includes:

- **Resource Group**: Centralized resource management
- **Virtual Network**: Network isolation with separate subnets for app and database
- **Application Gateway**: Load balancer with SSL termination
- **App Service**: Windows-based hosting for Umbraco
- **SQL Database**: Managed SQL Server for Umbraco data
- **Storage Account**: Blob storage for media files
- **CDN**: Content delivery network for static assets
- **Key Vault**: Secure storage for secrets and certificates
- **Application Insights**: Application monitoring and logging
- **Log Analytics**: Centralized logging and diagnostics

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** version 1.0 or higher
3. **Azure Subscription** with appropriate permissions

## Quick Start

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd umbraco-azure-terraform
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- Update `admin_ip_address` with your IP address
- Set secure passwords for SQL Server
- Customize project name and location as needed

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Deployment
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

### 6. Review Outputs
```bash
terraform output
```

## Configuration Details

### Network Security

- **App Subnet**: Hosts Application Gateway and App Service
- **Database Subnet**: Hosts SQL Server with restricted access
- **NSG Rules**: 
  - HTTP/HTTPS traffic allowed to app subnet
  - SQL traffic allowed from app to database subnet
  - SSH access restricted to admin IP

### Security Features

- **Key Vault**: Stores sensitive configuration
- **Managed Identity**: SQL Server uses system-assigned identity
- **Network Isolation**: Database in private subnet
- **SSL/TLS**: Application Gateway handles SSL termination

### Monitoring and Logging

- **Application Insights**: Real-time application monitoring
- **Log Analytics**: Centralized logging workspace
- **Diagnostic Settings**: Comprehensive resource monitoring

## Post-Deployment Steps

### 1. Deploy Umbraco Application

After infrastructure deployment, you'll need to deploy your Umbraco application to the App Service:

```bash
# Using Azure CLI
az webapp deployment source config-zip \
  --resource-group rg-umbraco-app \
  --name umbraco-app-app \
  --src path/to/your/umbraco.zip
```

### 2. Configure Umbraco

1. Access your Umbraco application at the App Service URL
2. Complete the Umbraco installation wizard
3. Configure connection strings to use the SQL Database
4. Set up media storage to use Azure Blob Storage

### 3. SSL Certificate (Optional)

For production, consider adding a custom domain and SSL certificate:

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name umbraco-app-app \
  --resource-group rg-umbraco-app \
  --hostname yourdomain.com
```

## Cost Optimization

- **Development**: Use Basic SKUs for App Service Plan and SQL Database
- **Production**: Scale up to Premium SKUs as needed
- **Monitoring**: Review Application Insights usage to optimize costs
- **Storage**: Use lifecycle management for blob storage

## Security Best Practices

1. **Network Security**: All resources are in private subnets where possible
2. **Secrets Management**: Use Key Vault for sensitive configuration
3. **Access Control**: Implement least-privilege access with Azure RBAC
4. **Monitoring**: Enable comprehensive logging and alerting
5. **Updates**: Regularly update dependencies and security patches

## Troubleshooting

### Common Issues

1. **SQL Connection**: Ensure firewall rules allow App Service to SQL Server
2. **SSL Issues**: Check Application Gateway configuration
3. **Performance**: Monitor App Service metrics and scale as needed

### Useful Commands

```bash
# Check App Service logs
az webapp log tail --name umbraco-app-app --resource-group rg-umbraco-app

# Check SQL Server connection
az sql db show --name umbraco-app-db --server umbraco-app-sql --resource-group rg-umbraco-app

# Monitor Application Insights
az monitor app-insights component show --app umbraco-app-ai --resource-group rg-umbraco-app
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Azure documentation
- Open an issue in the repository
