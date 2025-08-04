# Umbraco on Azure via Terraform

This configuration deploys a production-ready Umbraco CMS instance to Microsoft Azure using Terraform, following modern best practices.

## Architecture

1. **Resource Group** – logical container for all resources.
2. **Azure Application Insights** – performance monitoring & logging.
3. **App Service Plan (Linux)** – hosts the Docker-based Umbraco Web App.
4. **Azure SQL Database** – managed SQL backend for Umbraco content.
5. **Azure Linux Web App (Docker)** – runs the official Umbraco container image.
6. **Random suffix** – guarantees globally unique resource names.

```
+------------+       +-----------------+
| Web Browser| <---> |   Web App       |
+------------+       | (Umbraco Docker) |
                     +----+---------+---+
                          | Connection string
                          v
                     +-------------+
                     | Azure SQL DB|
                     +-------------+
```

## Prerequisites

- Terraform >= 1.3
- Azure CLI logged-in account with permission to create resources

## How to Use

1. **Clone the repo & initialize Terraform**

   ```bash
   terraform init
   ```

2. **Optionally override defaults** in `terraform.tfvars` (location, SKU sizes, etc.)

3. **Review the execution plan**

   ```bash
   terraform plan -out tfplan
   ```

4. **Apply**

   ```bash
   terraform apply tfplan
   ```

5. Once complete, Terraform will output the public URL. Open it in your browser to finish the Umbraco onboarding wizard.

## Customisation

- **Docker Image** – change `umbraco_docker_image` to pin a specific Umbraco version.
- **Scaling** – adjust `app_service_plan_sku` to match expected load (e.g., `P1v3`, `P2v3`).
- **Database performance** – tweak `sql_sku_name` & `max_size_gb`.
- **State Backend** – configure a remote backend (e.g., Azure Storage) for production deployments.

## Security Notes

- The SQL admin password is generated randomly and never hard-coded.
- Firewall rule `0.0.0.0` is added to let the Web App connect to SQL Server via Azure backbone only (no external exposure).
- HTTPS-only is enforced on the Web App.

## Clean-up

```bash
terraform destroy
```

## Further Improvements

- Use **Azure Key Vault** & system-assigned managed identity to inject the connection string securely.
- Add **Azure Front Door** or **Azure Application Gateway** for global routing & WAF.
- Automate container image updates with **Azure Container Registry (ACR)** & CI/CD.
