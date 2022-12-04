locals {
  psql_custom_username         = "CUSTOM_ROLE"
}

resource "azapi_update_resource" "container_apps_web" {
  type        = "Microsoft.App/containerApps@2022-03-01"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-${var.environment_name}/providers/Microsoft.App/containerApps/${var.name}"

  body = jsonencode({
    properties = {
      managedEnvironmentId = var.container_env_id
      configuration = {
        activeRevisionsMode = "Single"
        ingress = {
          external = true
          targetPort = 3100
          transport = "auto"
        }
        secrets = [
          {
            name = "registry-password"
            value = var.container_registry_pwd
          }
        ]
        registries = [
          {
            passwordSecretRef = "registry-password"
            server = "${var.container_registry_name}.azurecr.io"
            username = var.container_registry_name
          }
        ]
      }
      template = {
        containers = [
          {
            env = [
              { "name" = "APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = var.application_insights_connection_string },
              { "name" = "AZURE_POSTGRESQL_URL", "value" = var.psql_url },
              { "name" = "AZURE_POSTGRESQL_USERNAME", "value" = local.psql_custom_username }
            ]
            image = var.image_name
            name = "main"
            resources = {
              memory = "2.0Gi"
              cpu = 1
            }
          }
        ]
      }
    }
  })

}