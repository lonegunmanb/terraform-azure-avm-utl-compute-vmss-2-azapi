output "azapi_header" {
  value      = local.azapi_header
  depends_on = []
}

output "body" {
  value = local.body
}

output "sensitive_body" {
  value     = local.sensitive_body
  sensitive = true
  ephemeral = true
}

output "sensitive_body_version" {
  value = local.sensitive_body_version
}

output "replace_triggers_external_values" {
  value = local.replace_triggers_external_values
}

output "post_creation_updates" {
  value     = local.post_creation_updates
  sensitive = true
}

output "locks" {
  value = local.locks
}

output "timeouts" {
  value = var.timeouts
}