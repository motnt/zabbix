# Quick Start Guide - Umbraco Azure Infrastructure

This guide will help you deploy a production-ready Umbraco CMS infrastructure on Azure in under 30 minutes.

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

# Make deployment script executable
chmod +x deploy.sh
```

## Step 2: Configure Your Deployment

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration file
nano terraform.tfvars  # or use your preferred editor
```

### Essential Configuration

Update these values in `terraform.tfvars`:

```hcl
# Basic Configuration
resource_group_name = "my-umbraco-rg"
location            = "East US"  # Choose your preferred region

# SQL Server Configuration (IMPORTANT: Change these!)
sql_admin_username = "umbraco_admin"
sql_admin_password = "YourSecurePassword123!"  # Use a strong password

# Optional: Azure AD Configuration
# azure_ad_admin_object_id = "your-azure-ad-object-id"
```

## Step 3: Deploy Infrastructure

### Option A: Using the Deployment Script (Recommended)

```bash
# Run the deployment script
./deploy.sh

# Or run with specific options
./deploy.sh --plan      # Only create plan
./deploy.sh --validate  # Only validate configuration
```

### Option B: Manual Terraform Commands

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply
```

## Step 4: Access Your Application

After successful deployment, you'll see output similar to:

```
app_service_url = "https://umbraco-app-abc123.azurewebsites.net"
umbraco_admin_url = "https://umbraco-app-abc123.azurewebsites.net/umbraco"
```

### Access Points

- **Main Application**: `https://your-app-name.azurewebsites.net`
- **Admin Interface**: `https://your-app-name.azurewebsites.net/umbraco`
- **Azure Portal**: Navigate to your resource group to manage resources

## Step 5: Install Umbraco

### Option A: Using FTP (Quick Setup)

1. **Get FTP Credentials**:
   ```bash
   terraform output app_service_ftp_hostname
   ```

2. **Download Umbraco**:
   - Visit [umbraco.com](https://umbraco.com)
   - Download the latest Umbraco package

3. **Deploy via FTP**:
   - Use an FTP client (FileZilla, WinSCP)
   - Upload Umbraco files to the App Service
   - Navigate to `/install` to run the installer

### Option B: Using Azure DevOps (Recommended for Production)

1. **Create Azure DevOps Pipeline**:
   ```yaml
   # azure-pipelines.yml
   trigger:
   - main
   
   pool:
     vmImage: 'windows-latest'
   
   steps:
   - task: DotNetCoreCLI@2
     inputs:
       command: 'publish'
       publishWebProjects: true
       arguments: '--configuration Release --output $(Build.ArtifactStagingDirectory)'
       zipAfterPublish: true
   
   - task: AzureWebApp@1
     inputs:
       azureSubscription: 'Your-Azure-Subscription'
       appName: '$(appServiceName)'
       package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
   ```

## Step 6: Configure Umbraco

### Database Connection

The database connection is automatically configured via App Service settings. During Umbraco installation:

1. Choose **SQL Server** as database type
2. Use the connection string from App Service Configuration
3. The connection string format is: `Server=your-sql-server.database.windows.net;Database=umbraco-db;User Id=umbraco_admin;Password=your-password;TrustServerCertificate=true;`

### Media Storage

The infrastructure is configured to use Azure Blob Storage for media files. In Umbraco:

1. Install the **Azure Blob Storage** package
2. Configure the connection string from App Service settings
3. Set the container name to `umbraco-media`

### Monitoring

Application Insights is automatically configured. To view metrics:

1. Go to Azure Portal
2. Navigate to your Application Insights resource
3. View Live Metrics, Performance, and Errors

## Step 7: Post-Deployment Tasks

### Security Hardening

1. **Enable Azure AD Authentication**:
   ```bash
   # Get your Azure AD Object ID
   az ad signed-in-user show --query objectId -o tsv
   ```

2. **Configure SSL Certificate**:
   - Purchase or upload your SSL certificate
   - Configure in App Service SSL settings

3. **Set up Backup Policies**:
   - Configure automated backups for SQL Database
   - Set up storage account lifecycle management

### Performance Optimization

1. **Enable CDN**:
   - The CDN is already configured
   - Update your DNS to point to the CDN endpoint

2. **Configure Auto-scaling**:
   ```hcl
   # In terraform.tfvars
   enable_auto_scaling = true
   auto_scaling_min_instances = 1
   auto_scaling_max_instances = 5
   ```

3. **Optimize Database**:
   - Monitor performance metrics
   - Consider upgrading to Premium tier for high-traffic sites

## Troubleshooting

### Common Issues

1. **SQL Connection Errors**:
   ```bash
   # Check if private endpoint is working
   terraform output private_endpoint_ip
   
   # Verify VNet integration
   az webapp vnet-integration list --resource-group your-rg --name your-app
   ```

2. **App Service Not Starting**:
   ```bash
   # Check application logs
   az webapp log tail --resource-group your-rg --name your-app
   
   # Verify .NET version
   az webapp config show --resource-group your-rg --name your-app --query "netFrameworkVersion"
   ```

3. **Storage Access Issues**:
   ```bash
   # Get storage connection string
   terraform output storage_account_connection_string
   
   # Verify container exists
   az storage container list --account-name your-storage --connection-string "your-connection-string"
   ```

### Useful Commands

```bash
# View all outputs
terraform output

# Check resource status
terraform show

# Get App Service logs
az webapp log download --resource-group your-rg --name your-app

# Test database connectivity
az sql db show --resource-group your-rg --server your-sql-server --name umbraco-db

# Monitor costs
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31
```

## Cost Estimation

### Development Environment
- **App Service Plan**: B1 (~$13/month)
- **SQL Database**: Basic (~$5/month)
- **Storage**: Standard LRS (~$2/month)
- **Total**: ~$20/month

### Production Environment
- **App Service Plan**: P1v3 (~$146/month)
- **SQL Database**: Standard S1 (~$30/month)
- **Storage**: Standard LRS (~$5/month)
- **CDN**: ~$10/month
- **Application Insights**: ~$5/month
- **Total**: ~$196/month

*Note: Costs vary by region and usage. Use Azure Pricing Calculator for accurate estimates.*

## Next Steps

1. **Set up CI/CD Pipeline** for automated deployments
2. **Configure Monitoring Alerts** for proactive issue detection
3. **Implement Backup Strategy** for disaster recovery
4. **Set up Development/Staging Environments**
5. **Configure Custom Domain** and SSL certificates
6. **Implement Security Scanning** and vulnerability management

## Support

- **Documentation**: Check the main README.md for detailed information
- **Architecture**: Review ARCHITECTURE.md for design decisions
- **Issues**: Open an issue in the repository
- **Azure Support**: Contact Azure support for platform issues

## Cleanup

To remove all resources (use with caution):

```bash
# Destroy infrastructure
./deploy.sh --destroy

# Or manually
terraform destroy
```

---

**Congratulations!** You now have a production-ready Umbraco infrastructure running on Azure. 🎉