data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

locals {
  default_sp_name = "${var.namespace}-${local.geo_code}-sp"
}

resource "azuread_application" "default_sp" {
  display_name = local.default_sp_name
  owners = distinct(concat(
    [data.azuread_service_principal.deploy_app_sp.object_id],
    data.azuread_group.owners.members,
    var.is_infrastructure_developer_environment ? data.azuread_group.infrastructure_developer.members : []
  ))
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "default_sp" {
  client_id                    = azuread_application.default_sp.client_id
  app_role_assignment_required = false
  owners                       = azuread_application.default_sp.owners
}

resource "azuread_application_password" "default_sp_secret" {
  display_name   = "${local.default_sp_name}-tf-managed-secret"
  application_id = azuread_application.default_sp.id

  rotate_when_changed = {
    rotation = time_rotating.default_sp_secret.id
  }
}

resource "time_rotating" "default_sp_secret" {
  rotation_days = 30
}

resource "azurerm_key_vault_secret" "default_sp_secret" {
  name         = "${local.default_sp_name}-tf-managed-secret"
  value        = azuread_application_password.default_sp_secret.value
  key_vault_id = module.default_kv.id
}

# Federated credentials for deployment via GitHub Actions using OIDC for dsaas-etl-pipeline-configs repo
resource "azuread_application_federated_identity_credential" "etl_pipeline_configs_gha_branch_oidc_credential" {
  for_each       = toset(var.etl_pipeline_configs_gh_branches)
  application_id = azuread_application.default_sp.id
  display_name   = "etl_pipeline_configs_gha_${each.key}_oidc_credential"
  description    = "OIDC auth for GitHub Actions workflow dsaas-etl-pipeline-configs repo - ${each.key} branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:OptumInsight-Analytics/dsaas-etl-pipeline-configs:ref:refs/heads/${each.key}"
}

resource "azuread_application_federated_identity_credential" "etl_pipeline_configs_gha_pull_request_oidc_credential" {
  application_id = azuread_application.default_sp.id
  display_name   = "etl_pipeline_configs_gha_pull_request"
  description    = "OIDC auth for GitHub Actions workflow dsaas-etl-pipeline-configs repo - pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:OptumInsight-Analytics/dsaas-etl-pipeline-configs:pull_request"
}

# Federated credentials for deployment via GitHub Actions using OIDC for dsaas-etl-pipeline repo
resource "azuread_application_federated_identity_credential" "etl_pipeline_gha_branch_oidc_credential" {
  for_each       = toset(var.etl_pipeline_gh_branches)
  application_id = azuread_application.default_sp.id
  display_name   = "etl_pipeline_gha_${each.key}_oidc_credential"
  description    = "OIDC auth for GitHub Actions workflow dsaas-etl-pipeline repo - ${each.key} branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:OptumInsight-Analytics/dsaas-etl-pipeline:ref:refs/heads/${each.key}"
}
