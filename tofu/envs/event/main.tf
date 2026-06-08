provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_tls_insecure

  # TODO: add SSH and node defaults once concrete environment values are available.
}

locals {
  environment_name = "event"
}

# TODO: add module blocks for image/template workflow, VM provisioning,
# and RKE2 bootstrap once network and Proxmox details are finalized.
