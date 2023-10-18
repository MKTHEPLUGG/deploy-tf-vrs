# Terraform Deploy to Azure (via Remote State) Action

This GitHub Action allows you to deploy infrastructure to Azure using Terraform, leveraging Azure Blob Storage for remote state management.

## Prerequisites

- An Azure Storage Account and a container within it for storing Terraform state.
- A Service Principal in Azure with permissions to manage resources in your subscription and to read/write to the aforementioned storage account.

## Usage

To use this action in your GitHub workflow, add the following step:

```yaml
- name: Terraform Deploy to Azure
  uses: [YOUR_GITHUB_USERNAME]/deploy-tf-vrs@v1
  with:
    storage_account_name: 'your-storage-account-name'
    container_name: 'your-container-name'
    key: 'terraform.tfstate'
    resource_group_name: 'your-resource-group-name'
    client_id: ${{ secrets.AZURE_CLIENT_ID }}
    client_secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    tenant_id: ${{ secrets.AZURE_TENANT_ID }}
    subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    working_directory: './path-to-your-terraform-files' # Optional. Default is the root directory.
```

## Inputs

| Input               | Description                                                  | Required |
|---------------------|--------------------------------------------------------------|----------|
| `storage_account_name` | Name of the Azure Storage Account for Terraform State.    | Yes      |
| `container_name`      | Name of the Azure Blob Container for Terraform State.      | Yes      |
| `key`                 | Key for Terraform State in Azure Blob.                      | Yes      |
| `resource_group_name` | Azure Resource Group Name for the Storage Account.         | Yes      |
| `client_id`           | Azure Client ID for Service Principal.                     | Yes      |
| `client_secret`       | Azure Client Secret for Service Principal.                 | Yes      |
| `tenant_id`           | Azure Tenant ID for Service Principal.                     | Yes      |
| `subscription_id`     | Azure Subscription ID for Service Principal.               | Yes      |
| `working_directory`   | Working directory for Terraform files. Default is `.`.     | No       |

## Outputs

None.

## Debugging

Uncomment the debug statements in the `action.yml` file to get more detailed logs during the action's execution. This can help in diagnosing issues related to directory paths, subscription IDs, and more.

---

## Authentication with Azure using `TF_VAR` Environment Variables

In this setup, we leverage Terraform's capability to read environment variables prefixed with `TF_VAR_` for authentication. This allows us to securely pass sensitive credentials from GitHub Secrets to our Terraform configuration without hardcoding them.

### How it Works

1. **GitHub Workflow**: In the GitHub workflow, we set environment variables using the `env` key. These variables are named with the `TF_VAR_` prefix followed by the variable name as defined in the Terraform configuration.

   ```yaml
   env:
     TF_VAR_client_id: ${{ secrets.AZURE_CLIENT_ID }}
     TF_VAR_client_secret: ${{ secrets.AZURE_CLIENT_SECRET }}
     TF_VAR_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
     TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
   ```

2. **Terraform Configuration**: In the Terraform configuration, we define these variables without the `TF_VAR_` prefix. For example:

   ```hcl
   variable "client_id" {}
   variable "client_secret" {}
   variable "tenant_id" {}
   variable "subscription_id" {}
   ```

3. **Azure Provider Authentication**: The `azurerm` provider in the Terraform configuration then uses these variables for authentication:

   ```hcl
   provider "azurerm" {
     client_id       = var.client_id
     client_secret   = var.client_secret
     tenant_id       = var.tenant_id
     subscription_id = var.subscription_id
     features {}
   }
   ```

By using this approach, we achieve the following:

- **Security**: Sensitive credentials are stored securely in GitHub Secrets and are never hardcoded in the Terraform configuration.
- **Flexibility**: This method allows for easy rotation of credentials without modifying the Terraform configuration.
- **Clarity**: The use of `TF_VAR_` prefixed environment variables makes it clear that these are being passed to Terraform.

### Best Practices

- **Separation of Concerns**: While in this setup, the same Service Principal is used for both the storage account authentication and the deployment of resources, it's possible to use different Service Principals for different tasks to adhere to the principle of least privilege.
- **Regularly Rotate Secrets**: It's a good security practice to regularly rotate secrets stored in GitHub and update the corresponding Service Principal credentials in Azure.

---

### Example workflow

```YAML

name: 'Use Terraform Action'
on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v3
      with:
        fetch-depth: 0

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2

    - name: Terraform Deploy to Azure
      uses: MKTHEPLUGG/deploy-tf-vrs@v1
      # these vars are for azurerm providor to auth with azure via SP to deploy
      env:
        TF_VAR_client_id: ${{ secrets.AZURE_CLIENT_ID }}
        TF_VAR_client_secret: ${{ secrets.AZURE_CLIENT_SECRET }}
        TF_VAR_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
        TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      with:
        # these vars are for the storage account authentication with SP
        storage_account_name: 'tfstatestore12345'
        container_name: tfstatecontainer
        key: 'terraform.tfstate'
        resource_group_name: TerraformStateRG
        client_id: ${{ secrets.AZURE_CLIENT_ID }}
        client_secret: ${{ secrets.AZURE_CLIENT_SECRET }}
        tenant_id: ${{ secrets.AZURE_TENANT_ID }}
        subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        working_directory: './vnet'
        # specify working directory to choose where you want to deploy from


```