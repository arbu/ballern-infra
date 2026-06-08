# Bootstrap Guide

## 1. Purpose

This document describes the expected bootstrap flow for creating the Ballern internal event Kubernetes cluster on Proxmox.

The process is designed to be:

- reproducible
- mostly declarative
- idempotent where practical
- safe to rerun

## 2. Bootstrap layers

The bootstrap process is split into the following layers:

1. **Repository bootstrap**
2. **Secrets/bootstrap configuration**
3. **Proxmox image/template preparation**
4. **VM provisioning**
5. **RKE2 cluster bootstrap**
6. **Argo CD bootstrap**
7. **Cluster add-on reconciliation**

## 3. Repository bootstrap

Initial repository setup should include:

- OpenTofu/Terraform configuration
- provider version pinning
- GitLab CI pipeline configuration
- SOPS configuration
- Argo CD application structure
- base documentation

## 4. Required prerequisites

Before bootstrap begins, the following must exist.

### 4.1 Infrastructure prerequisites
- Proxmox host or cluster
- suitable datastore(s)
- Proxmox API token with appropriate permissions
- bridge and VLAN details
- network address plan

### 4.2 DNS prerequisites
- BIND9 server with RFC2136 dynamic updates enabled
- TSIG key for update authentication
- relevant zones configured
- ability to create records under:
  - `c.ballern.net`
  - user-facing `ballern.net` names as required

### 4.3 Git/GitLab prerequisites
- repository created
- GitLab CI available
- GitLab remote state available
- maintainers identified

### 4.4 Local operator prerequisites
Operators should have:

- `opentofu` or `terraform`
- `kubectl`
- `helm`
- `sops`
- `age`
- `git`

## 5. Secret bootstrap

Secrets should be prepared before the first apply.

Recommended secret categories:

- Proxmox API credentials
- RFC2136 TSIG key material
- ACME DNS challenge credentials, if separate
- RKE2 bootstrap secrets as needed
- Argo CD bootstrap/admin secrets if managed explicitly
- Telegram notification credentials for Alertmanager

Secrets must be:
- encrypted in Git where committed
- injected securely into CI
- never committed in plaintext

## 6. Image and template bootstrap

### 6.1 Image strategy
The preferred image strategy is:

1. use a pinned Ubuntu LTS cloud image
2. download it automatically through the Proxmox provider where possible
3. build or refresh a reusable Proxmox template from that image

### 6.2 Why use a template
A reusable template improves:

- consistency
- provisioning speed
- repeatability
- node lifecycle management

### 6.3 Template responsibilities
The template should provide:

- cloud-init support
- qemu guest compatibility
- baseline package refresh where appropriate
- no node-specific configuration

## 7. VM provisioning bootstrap

OpenTofu/Terraform should provision:

- 1 control-plane node
- 2 worker nodes

Each VM should receive:

- hostname
- CPU and memory settings
- disk settings
- static IP configuration
- SSH keys
- cloud-init user data
- tags and placement settings

## 8. RKE2 bootstrap flow

### 8.1 Control-plane bootstrap
The control-plane node should:

- install RKE2 server
- initialize the cluster
- host embedded etcd
- expose the Kubernetes API

### 8.2 Worker bootstrap
Worker nodes should:

- install RKE2 agent components
- join the cluster using the control-plane endpoint

### 8.3 kubeconfig handling
After cluster creation:

- kubeconfig must be retrieved or generated for operators
- the server endpoint should align with `k8s-api.c.ballern.net` or the current control-plane address

## 9. Argo CD bootstrap flow

Argo CD should be installed immediately after cluster readiness is confirmed.

The bootstrap should:

- install Argo CD into the cluster
- create baseline projects/applications
- establish the GitOps reconciliation root

Recommended approach:
- OpenTofu/Terraform bootstraps Argo CD once
- Argo CD manages the rest of the in-cluster platform stack

## 10. Add-on bootstrap order

Recommended add-on reconciliation order:

1. cert-manager
2. MetalLB
3. Traefik
4. Longhorn
5. monitoring stack
6. Rancher

This order may be adjusted slightly during implementation if chart dependencies require it.

## 11. DNS bootstrap flow

The bootstrap process must create all required DNS names.

### 11.1 Required internal names
At minimum:

- `k8s-api.c.ballern.net`
- `argocd.c.ballern.net`
- `rancher.c.ballern.net`
- `grafana.c.ballern.net`
- `alertmanager.c.ballern.net`
- `longhorn.c.ballern.net` if exposed

### 11.2 DNS automation model
DNS records should be created through:

- RFC2136 dynamic update calls
- authenticated with TSIG

## 12. Certificate bootstrap flow

Certificates should use:

- DNS challenge where required
- cert-manager for in-cluster certificate management

Primary goals:
- trusted TLS for Rancher
- trusted TLS for Argo CD and monitoring endpoints where exposed

## 13. Validation checkpoints

Bootstrap must include clear validation at each stage.

### 13.1 Infrastructure validation
- VMs exist in Proxmox
- cloud-init completed successfully
- SSH works
- qemu-guest-agent is online

### 13.2 Cluster validation
- all nodes are Ready
- core RKE2 services are healthy
- kubeconfig works

### 13.3 GitOps validation
- Argo CD is reachable
- applications sync successfully
- core add-ons become healthy

### 13.4 Platform validation
- Rancher is reachable
- Longhorn is healthy
- monitoring is functional
- DNS names resolve
- TLS certificates are valid

## 14. Re-run behavior

The bootstrap process should be safe to rerun.

Expected behavior:
- OpenTofu/Terraform converges infrastructure state
- Argo CD converges cluster service state
- template refreshes and upgrades happen only when intentionally changed

## 15. Still-required bootstrap inputs

The following inputs must still be provided before the bootstrap can be completed:

- backend subnet and user-facing subnet values
- static node IPs or ranges
- MetalLB address pool
- Proxmox bridge/VLAN details
- SSH public keys
- DNS server IPs
- TSIG key details
- GitLab state/project details
