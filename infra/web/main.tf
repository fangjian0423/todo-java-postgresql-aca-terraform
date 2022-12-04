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
          targetPort = 80
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
              { "name" = "REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = var.application_insights_connection_string },
              { "name" = "REACT_APP_API_BASE_URL", "value" = var.api_module_uri },
              { "name" = "APPLICATIONINSIGHTS_CONNECTION_STRING", "value" = var.application_insights_connection_string }
            ]
            image = var.image_name
            name = "main"
            resources = {
              memory = "1.0Gi"
              cpu = 0.5
            }
          }
        ]
      }
    }
  })

}