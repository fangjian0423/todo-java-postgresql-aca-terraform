variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "environment_name" {
  description = "The name of the azd environment to be deployed"
  type        = string
}

variable "principal_id" {
  description = "The Id of the azd service principal to add to deployed keyvault access policies"
  type        = string
  default     = ""
}

variable "web_image_name" {
  description = "Web App Image name"
  type        = string
  default     = "nginx:latest"
}

variable "api_image_name" {
  description = "API App Image name"
  type        = string
  default     = "nginx:latest"
}

variable "client_id" {
  description = "Client id of current account"
  type        = string
  default     = ""
}