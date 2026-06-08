provider "proxmox" {
  # TODO: configure provider authentication and endpoint details.
  # Suggested inputs for future wiring:
  # - var.proxmox_api_url
  # - var.proxmox_api_token
  # - var.proxmox_tls_insecure
}

locals {
  environment_name = "event"
}

# TODO: add module blocks for image/template workflow, VM provisioning,
# and RKE2 bootstrap once network and Proxmox details are finalized.
