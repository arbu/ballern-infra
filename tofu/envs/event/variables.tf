variable "proxmox_api_url" {
  description = "Proxmox API URL, for example https://proxmox.example.com:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Allow insecure TLS for Proxmox API calls"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Logical name for the event cluster"
  type        = string
  default     = "ballern-event"
}

variable "node_count_controlplane" {
  description = "Number of control-plane nodes for this environment"
  type        = number
  default     = 1
}

variable "node_count_workers" {
  description = "Number of worker nodes for this environment"
  type        = number
  default     = 2
}
