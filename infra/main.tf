locals {
  tags                         = { azd-env-name : var.environment_name, spring-cloud-azure : true }
  sha                          = base64encode(sha256("${var.environment_name}${var.location}${data.azurerm_client_config.current.subscription_id}"))
  resource_token               = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  psql_custom_username         = "CUSTOM_ROLE"
}
# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "rg_name" {
  name          = var.environment_name
  resource_type = "azurerm_resource_group"
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location

  tags = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy application insights
# ------------------------------------------------------------------------------------------------------
module "applicationinsights" {
  source           = "./modules/applicationinsights"
  location         = var.location
  rg_name          = azurerm_resource_group.rg.name
  environment_name = var.environment_name
  workspace_id     = module.loganalytics.LOGANALYTICS_WORKSPACE_ID
  tags             = azurerm_resource_group.rg.tags
  resource_token   = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy log analytics
# ------------------------------------------------------------------------------------------------------
module "loganalytics" {
  source         = "./modules/loganalytics"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags
  resource_token = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy Azure PostgreSQL
# ------------------------------------------------------------------------------------------------------
module "postgresql" {
  source         = "./modules/postgresql"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = azurerm_resource_group.rg.tags
  resource_token = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy Azure Container Registry
# ------------------------------------------------------------------------------------------------------
module "acr" {
  source         = "./modules/containerregistry"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  resource_token = local.resource_token

  tags               = local.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy Azure Container Environment
# ------------------------------------------------------------------------------------------------------
module "container_env" {
  source         = "./modules/containerenvironment"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name
  resource_token = local.resource_token

  tags               = local.tags

  workspace_id = module.loganalytics.LOGANALYTICS_WORKSPACE_CUSTOMER_ID
  workspace_primary_shared_key = module.loganalytics.LOGANALYTICS_PRIMARY_ID
}

# ------------------------------------------------------------------------------------------------------
# Deploy Azure Container Apps web
# ------------------------------------------------------------------------------------------------------
module "container_app_web" {
  name           = "ca-web-${local.resource_token}"
  source         = "./modules/containerapps"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name

  tags               = merge(local.tags, { azd-service-name : "web" })

  container_env_id = module.container_env.CONTAINER_ENV_ID
  container_registry_pwd = module.acr.CONTAINER_REGISTRY_PASSWORD
  container_registry_name = module.acr.CONTAINER_REGISTRY_NAME

  env = [
    { "name" = "REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = module.applicationinsights.APPLICATIONINSIGHTS_CONNECTION_STRING },
    { "name" = "REACT_APP_API_BASE_URL", "value" = module.container_app_api.CONTAINER_APP_URI },
    { "name" = "APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = module.applicationinsights.APPLICATIONINSIGHTS_CONNECTION_STRING }
  ]
  image_name = var.web_image_name
  target_port = 80

  identity = [{
    type = "SystemAssigned"
  }]
}

# ------------------------------------------------------------------------------------------------------
# Deploy Azure Container Apps api
# ------------------------------------------------------------------------------------------------------
module "container_app_api" {
  name           = "ca-api-${local.resource_token}"
  source         = "./modules/containerapps"
  location       = var.location
  rg_name        = azurerm_resource_group.rg.name

  tags               = merge(local.tags, { azd-service-name : "api" })

  container_env_id = module.container_env.CONTAINER_ENV_ID
  container_registry_pwd = module.acr.CONTAINER_REGISTRY_PASSWORD
  container_registry_name = module.acr.CONTAINER_REGISTRY_NAME

  cpu = 1.0
  memory = "2.0Gi"

  env = [
    { "name" = "APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = module.applicationinsights.APPLICATIONINSIGHTS_CONNECTION_STRING },
    { "name" = "AZURE_POSTGRESQL_URL", "value" = "jdbc:postgresql://${module.postgresql.AZURE_POSTGRESQL_FQDN}:5432/${module.postgresql.AZURE_POSTGRESQL_DATABASE_NAME}?sslmode=require" },
    { "name" = "AZURE_POSTGRESQL_USERNAME", "value" = local.psql_custom_username }
  ]

  image_name = var.api_image_name
  target_port = 3100

  identity = [{
    type = "SystemAssigned"
  }]
}


# ------------------------------------------------------------------------------------------------------
# Enable Passwordless for PostgreSQL
# ------------------------------------------------------------------------------------------------------
module "enable_passwordless" {
  source         = "./modules/passwordless"

  pg_custom_role_name_with_aad_identity = local.psql_custom_username
  pg_aad_admin_user = module.postgresql.AZURE_POSTGRESQL_ADMIN_USERNAME
  pg_database_name = module.postgresql.AZURE_POSTGRESQL_DATABASE_NAME
  pg_server_fqdn = module.postgresql.AZURE_POSTGRESQL_FQDN
  app_identity_principal_id = module.container_app_api.CONTAINER_APP_NAME_IDENTITY_PRINCIPAL_ID
}