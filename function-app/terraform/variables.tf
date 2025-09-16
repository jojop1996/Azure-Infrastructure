variable "tenant_id" {}
variable "client_id" {}
variable "subscription_id" {}
variable "client_secret" {}

variable "location" {
  description = "Primary region for all Azure resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-app"
}

variable "app_name" {
  description = "The name for your deployed function app."
  type        = string
  default     = "func-app"
}

variable "app_runtime" {
  description = "Language runtime used by the function app."
  type        = string
  default     = "python"
  validation {
    condition     = contains(["dotnet-isolated", "python", "java", "node", "powerShell"], var.app_runtime)
    error_message = "App runtime must be one of: dotnet-isolated, python, java, node, powerShell."
  }
}

variable "app_runtime_version" {
  description = "Target language version used by the function app."
  type        = string
  default     = "3.13"
  validation {
    condition     = contains(["3.13", "3.10", "3.11", "7.4", "8.0", "9.0", "10", "11", "17", "20"], var.app_runtime_version)
    error_message = "App runtime version must be one of: 3.13, 3.10, 3.11, 7.4, 8.0, 9.0, 10, 11, 17, 20."
  }
}

variable "plan_type" {
  description = "The type of hosting plan to use for the function app."
  type        = string
  default     = "FlexConsumption"
  validation {
    condition     = contains(["FlexConsumption", "Consumption", "Premium"], var.plan_type)
    error_message = "Plan type must be one of: FlexConsumption, Consumption, Premium."
  }
}

variable "maximum_instance_count" {
  description = "The maximum scale-out instance count limit for the app."
  type        = number
  default     = 40
  validation {
    condition     = var.maximum_instance_count >= 40 && var.maximum_instance_count <= 1000
    error_message = "Maximum instance count must be between 40 and 1000."
  }
}

variable "instance_memory_mb" {
  description = "The memory size of instances used by the app."
  type        = number
  default     = 2048
  validation {
    condition     = contains([2048, 4096], var.instance_memory_mb)
    error_message = "Instance memory must be either 2048 or 4096 MB."
  }
}

locals {
  # A unique token used for resource name generation.
  resource_token = lower(substr(sha256("${var.subscription_id}-${var.location}"), 0, 8))
  app_name_token = "${var.app_name}-${local.resource_token}"

  # Generates a unique container name for deployments.
  # Restrained to 63 characters to stay within Azure's naming length limits.
  deployment_storage_container_name = "app-package-${substr(local.app_name_token, 0, 39)}"

  # Sanitize and constrain storage account name to Azure requirements:
  # - lowercase
  # - remove hyphens
  # - max length 24 characters
  # - prefix with 'sta' for a recognizable prefix to meet the 3 character minimum requirement
  storage_account_name_cleaned = replace(lower(local.app_name_token), "-", "")
  storage_account_name = "sta${substr(local.storage_account_name_cleaned, 0, 21)}"

  # Key access to the storage account is disabled by default.
  storage_account_allow_shared_key_access = false

  # Define the IDs of the roles we need to assign to our managed identities.
  storage_blob_data_owner_role_id       = "b7e6dc6d-f1e8-4753-8033-0f276bb0955b"
  storage_blob_data_contributor_role_id = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
  storage_queue_data_contributor_id     = "974c5e8b-45b9-4653-ba55-5f855dd0fb88"
  storage_table_data_contributor_id     = "0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3"
  monitoring_metrics_publisher_id       = "3913510d-42f4-4e42-8a64-420c390055eb"

  # Define SKU configuration based on plan type.
  plan_config = var.plan_type == "FlexConsumption" ? {
    kind = "functionapp"
    sku = {
      tier = "FlexConsumption"
      name = "FC1"
    }
    reserved = true
  } : var.plan_type == "Consumption" ? {
    kind = "functionapp"
    sku = {
      tier = "Dynamic"
      name = "Y1"
    }
    reserved = true
  } : var.plan_type == "Premium" ? {
    kind = "functionapp"
    sku = {
      tier = "ElasticPremium"
      name = "EP1"
    }
    reserved = true
  } : {}
}