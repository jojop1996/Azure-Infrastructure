# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "log-${local.app_name_token}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights
resource "azurerm_application_insights" "application_insights" {
  name                = "appi-${local.app_name_token}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics.id
  disable_ip_masking  = false
}

# Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                      = local.storage_account_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  access_tier               = "Hot"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = local.storage_account_allow_shared_key_access
  min_tls_version           = "TLS1_2"
  public_network_access_enabled = false

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

# Storage Container for deployment
resource "azurerm_storage_container" "deployment_container" {
  name                  = local.deployment_storage_container_name
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "private"
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  name                = "uai-data-owner-${local.app_name_token}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Role Assignment: Storage Blob Data Owner
resource "azurerm_role_assignment" "role_assignment_blob_data_owner" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_id   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.storage_blob_data_owner_role_id}"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Blob Data Contributor
resource "azurerm_role_assignment" "role_assignment_blob_data_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_id   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.storage_blob_data_contributor_role_id}"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Queue Data Contributor
resource "azurerm_role_assignment" "role_assignment_queue_data_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_id   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.storage_queue_data_contributor_id}"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Storage Table Data Contributor
resource "azurerm_role_assignment" "role_assignment_table_data_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_id   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.storage_table_data_contributor_id}"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# Role Assignment: Monitoring Metrics Publisher
resource "azurerm_role_assignment" "role_assignment_monitoring_metrics_publisher" {
  scope                = azurerm_application_insights.application_insights.id
  role_definition_id   = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.monitoring_metrics_publisher_id}"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
  principal_type       = "ServicePrincipal"
}

# App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "plan-${local.app_name_token}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = local.plan_config.sku.name
}

# Function App
resource "azurerm_function_app_flex_consumption" "function_app" {
  name                        = "${local.app_name_token}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  service_plan_id             = azurerm_service_plan.app_service_plan.id
  https_only                  = true

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.storage_account.primary_blob_endpoint}${azurerm_storage_container.deployment_container.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.storage_account.primary_access_key
  runtime_name                = var.app_runtime
  runtime_version             = var.app_runtime_version
  maximum_instance_count      = var.maximum_instance_count
  instance_memory_in_mb       = var.instance_memory_mb

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_assigned_identity.id]
  }

  site_config {
    
  }

  app_settings = merge({
    "AzureWebJobsStorage__accountName" = azurerm_storage_account.storage_account.name
    "AzureWebJobsStorage__credential"  = "managedidentity"
    "AzureWebJobsStorage__clientId"    = azurerm_user_assigned_identity.user_assigned_identity.client_id
    "APPINSIGHTS_INSTRUMENTATIONKEY"   = azurerm_application_insights.application_insights.instrumentation_key
    "APPLICATIONINSIGHTS_AUTHENTICATION_STRING" = "ClientId=${azurerm_user_assigned_identity.user_assigned_identity.client_id};Authorization=AAD"
  })
  
  depends_on = [
    azurerm_role_assignment.role_assignment_blob_data_owner,
    azurerm_role_assignment.role_assignment_blob_data_contributor,
    azurerm_role_assignment.role_assignment_queue_data_contributor,
    azurerm_role_assignment.role_assignment_table_data_contributor,
    azurerm_role_assignment.role_assignment_monitoring_metrics_publisher
  ]
}