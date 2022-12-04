variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "image_name" {
  description = "Image name apply to Container App"
  type        = string
}

variable "container_registry_pwd" {
  description = "Container Environment password"
  type        = string
}

variable "container_env_id" {
  description = "Identity of Container Environment"
  type        = string
}

variable "api_module_uri" {
  description = "Api Container App ingress exposed URI"
  type        = string
}

variable "application_insights_connection_string" {
  description = "Connection string of Application Insights"
  type        = string
}

variable "name" {
  description = "Name of Container App"
  type        = string
}

variable "environment_name" {
  description = "Container Environment name"
  type        = string
}

variable "container_registry_name" {
  description = "Container Environment name"
  type        = string
}