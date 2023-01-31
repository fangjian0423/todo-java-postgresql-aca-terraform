terraform {
  required_providers {
    azurerm = {
      version = "~>3.33.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.15"
    }
  }
}

locals {
  test = pathexpand("~/${path.module}/main.tf")
  command_map = substr(local.test,0,1) == "/"? {
    command = "./scripts/pg-create-aad-role.sh ${var.pg_server_fqdn} ${var.app_identity_principal_id} ${var.pg_database_name} ${var.pg_aad_admin_user} ${var.pg_custom_role_name_with_aad_identity}",
    interpreter = []
  }:{
    command = "./scripts/pg-create-aad-role.ps1 ${var.pg_server_fqdn} ${var.app_identity_principal_id} ${var.pg_database_name} ${var.pg_aad_admin_user} ${var.pg_custom_role_name_with_aad_identity}",
    interpreter = ["powershell"]
  }
}

resource "azurecaf_name" "app_umi" {
  resource_type       = "azurerm_user_assigned_identity"
  name                = "pqsl-script"

  provisioner "local-exec" {
    command = local.command_map.command
    interpreter = local.command_map.interpreter
    working_dir = path.module
    when = create
  }
}