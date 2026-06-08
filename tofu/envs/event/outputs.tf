output "environment" {
  description = "OpenTofu environment name"
  value       = local.environment_name
}

output "cluster_name" {
  description = "Configured logical cluster name"
  value       = var.cluster_name
}

# TODO: add outputs for node addresses, kubeconfig location,
# and bootstrap metadata as modules are implemented.
