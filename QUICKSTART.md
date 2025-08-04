# Quick Start Guide - Umbraco Azure Infrastructure

This guide will help you deploy the Umbraco infrastructure in Azure quickly and efficiently.

## Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** installed and authenticated
2. **Terraform** version 1.0+ installed
3. **Azure Subscription** with appropriate permissions
4. **Git** for cloning the repository

## Step 1: Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd umbraco-azure-terraform

# Make scripts executable
chmod +x deploy.sh validate.sh
```

## Step 2: Configure Your Environment

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration file
nano terraform.tfvars
```

**Important**: Update these values in `terraform.tfvars`:

```hcl
# Replace with your actual IP address
admin_ip_address = "YOUR_IP_ADDRESS/32"

# Set a secure password
sql_admin_password = "YourSecurePassword123!"

# Customize project name if needed
project_name = "my-umbraco-app"
```

## Step 3: Validate Configuration

```bash
# Run validation script
./validate.sh
```

This will:
- Check prerequisites
- Format Terraform files
- Validate configuration syntax
- Check for security issues

## Step 4: Deploy Infrastructure

```bash
# Run deployment script
./deploy.sh
```

The script will:
1. Check prerequisites
2. Initialize Terraform
3. Plan the deployment
4. Ask for confirmation
5. Apply the configuration
6. Show deployment outputs

## Step 5: Access Your Application

After successful deployment, you'll see output similar to:

```
app_service_url = "https://umbraco-app-app.azurewebsites.net"
application_gateway_url = "http://XX.XX.XX.XX"
```

## Step 6: Deploy Umbraco Application

### Option A: Using Azure CLI

```bash
# Package your Umbraco application
zip -r umbraco-app.zip ./umbraco-files/

# Deploy to App Service
az webapp deployment source config-zip \
  --resource-group rg-umbraco-app \
  --name umbraco-app-app \
  --src umbraco-app.zip
```

### Option B: Using Azure Portal

1. Go to your App Service in Azure Portal
2. Navigate to "Deployment Center"
3. Choose your deployment method (Git, ZIP, etc.)
4. Upload your Umbraco application

## Step 7: Configure Umbraco

1. **Access the Application**: Visit your App Service URL
2. **Complete Installation**: Follow the Umbraco installation wizard
3. **Database Connection**: Use the SQL Server details from Terraform outputs
4. **Media Storage**: Configure to use Azure Blob Storage

## Step 8: Verify Deployment

```bash
# Check App Service status
az webapp show --name umbraco-app-app --resource-group rg-umbraco-app

# Check SQL Database
az sql db show --name umbraco-app-db --server umbraco-app-sql --resource-group rg-umbraco-app

# View logs
az webapp log tail --name umbraco-app-app --resource-group rg-umbraco-app
```

## Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Resource Name Conflicts**
   - Change `project_name` in `terraform.tfvars`
   - Ensure unique names across Azure

3. **SQL Connection Issues**
   - Check NSG rules allow App Service to SQL Server
   - Verify connection string in App Service settings

4. **SSL Certificate Issues**
   - Application Gateway handles SSL termination
   - For custom domains, add certificates to Key Vault

### Useful Commands

```bash
# View Terraform state
terraform show

# Check specific resource
terraform state show azurerm_windows_web_app.umbraco_app

# View logs
terraform console

# Destroy infrastructure (if needed)
./deploy.sh destroy
```

## Next Steps

1. **Custom Domain**: Add your domain and SSL certificate
2. **Monitoring**: Set up alerts in Application Insights
3. **Backup**: Configure automated backups
4. **Scaling**: Adjust App Service Plan SKU as needed
5. **Security**: Review and enhance security settings

## Cost Estimation

Estimated monthly costs (US East region):

- **App Service Plan (P1v2)**: ~$73/month
- **SQL Database (Basic)**: ~$5/month
- **Application Gateway**: ~$50/month
- **Storage Account**: ~$1/month
- **CDN**: ~$5/month
- **Key Vault**: ~$1/month
- **Application Insights**: ~$10/month

**Total**: ~$145/month

*Note: Costs vary by region and usage*

## Support

- **Documentation**: Check `README.md` and `ARCHITECTURE.md`
- **Issues**: Open an issue in the repository
- **Azure Support**: Use Azure support for platform issues

## Cleanup

To remove all resources and avoid charges:

```bash
./deploy.sh destroy
```

This will completely remove the infrastructure from Azure.