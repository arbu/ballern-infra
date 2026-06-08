# Kubernetes on Proxmox with Rancher — Architecture Overview

## 1. Purpose

This document describes the target architecture for the Ballern internal event Kubernetes platform running on Proxmox.

The design goals are:

- reproducible infrastructure
- idempotent provisioning
- Git-driven operations
- simple recovery through rebuild
- minimal manual configuration drift

## 2. High-level architecture

The platform consists of the following layers:

1. **Infrastructure layer**
   - Proxmox hosts
   - VM templates built from cloud images
   - Kubernetes node VMs provisioned by OpenTofu/Terraform

2. **Bootstrap layer**
   - cloud-init for guest initialization
   - RKE2 installation and cluster bootstrap

3. **GitOps layer**
   - Argo CD as the cluster add-on and application reconciler

4. **Platform services layer**
   - Traefik ingress controller
   - MetalLB for service IP allocation
   - cert-manager for certificate automation
   - Longhorn for persistent storage
   - Rancher for cluster management
   - kube-prometheus-stack for monitoring and alerting

## 3. Initial topology

Initial cluster layout:

- **1 control-plane node**
- **2 worker nodes**

This is intentionally not highly available.

The initial design optimizes for:
- simplicity
- speed of implementation
- low operational overhead
- rebuildability

## 4. Proxmox design

### 4.1 Initial host model
Initial testing assumes:

- **1 Proxmox host used actively**
- future expansion to **2 Proxmox hosts**

The configuration should keep placement configurable so that workloads can later be spread across hosts.

### 4.2 Storage model
Initial implementation uses:

- **local SSD-backed storage** on Proxmox

Shared storage is not required for v1.

Datastores should remain configurable for:
- VM disks
- downloaded cloud images
- reusable templates
- optional snippet storage

### 4.3 VM image workflow
The preferred workflow is:

1. Download a pinned Ubuntu LTS cloud image
2. Create or refresh a reusable Proxmox VM template
3. Clone the Kubernetes node VMs from the template
4. Inject cloud-init configuration per node

This separates base-image lifecycle from node lifecycle and improves repeatability.

## 5. Node architecture

### 5.1 Node roles
The cluster consists of:

- **Control-plane node**
  - runs RKE2 server
  - hosts embedded etcd
  - serves the Kubernetes API

- **Worker nodes**
  - run application and platform workloads

### 5.2 Initial sizing
Recommended defaults:

#### Control-plane
- 2 vCPU
- 4 GB RAM
- 50 GB disk

#### Workers
- 4 vCPU
- 8 GB RAM
- 80 GB disk

All values should remain configurable.

## 6. Network architecture

## 6.1 Network roles
Two network roles are assumed:

- **backend/management network**
  - Kubernetes nodes
  - Rancher
  - Argo CD
  - monitoring
  - cluster API
  - storage traffic

- **user-facing network**
  - ingress endpoints
  - application service IPs provided through MetalLB

## 6.2 Addressing model
The exact CIDRs are still to be provided, but the architecture assumes:

- static IPs for all Kubernetes nodes
- explicit IP pool(s) for MetalLB
- configurable gateway, DNS servers, domain search settings, bridge, and VLANs

## 6.3 Kubernetes API access
In v1:

- the Kubernetes API is exposed through the **single control-plane node**
- no API VIP or dedicated load balancer is used
- the DNS name `k8s-api.c.ballern.net` should point to that node

This is a deliberate trade-off based on the non-HA control-plane requirement.

## 6.4 Ingress and load balancing
- **Traefik** provides ingress routing
- **MetalLB** assigns service IPs for `LoadBalancer` services

Recommended usage:
- internal/admin endpoints under `c.ballern.net`
- user-facing endpoints under `ballern.net`

## 7. DNS architecture

DNS updates are performed through:

- **RFC2136 dynamic DNS updates**
- **BIND9** as authoritative DNS target
- **TSIG** for authenticated DNS updates

### 7.1 Internal DNS names
Non-user-facing names must reside under `c.ballern.net`.

Planned names:

- `k8s-api.c.ballern.net`
- `rancher.c.ballern.net`
- `argocd.c.ballern.net`
- `grafana.c.ballern.net`
- `alertmanager.c.ballern.net`
- `longhorn.c.ballern.net`

### 7.2 User-facing names
Application hostnames are expected under `ballern.net` or delegated subdomains.
These are ideally managed through GitOps along with the applications.

## 8. Kubernetes architecture

### 8.1 Distribution
The cluster uses:

- **RKE2**
- **embedded etcd**

This is the simplest and most appropriate model for the cluster size and requirements.

### 8.2 Cluster management
Rancher runs on the same cluster it manages.

This is acceptable because:
- the environment is internal
- full-cluster rebuild is considered acceptable
- operational simplicity is prioritized over full management-plane isolation

### 8.3 Trade-offs
This design means:
- Rancher is unavailable when the cluster is unavailable
- recovery depends on cluster rebuild procedures and GitOps re-bootstrap

These trade-offs are intentional and must be documented operationally.

## 9. Storage architecture

### 9.1 Proxmox storage
- VM disks live on Proxmox SSD-backed storage
- optional separate disks can be attached later for storage-heavy components

### 9.2 Kubernetes persistent storage
- **Longhorn** is included in phase 1
- Longhorn provides persistent volume support for stateful workloads

Longhorn is chosen because it fits small on-prem clusters better than more complex systems such as Ceph for this use case.

## 10. GitOps architecture

Argo CD is the central reconciliation engine for cluster services and applications.

### 10.1 Managed by OpenTofu/Terraform
Infrastructure code manages:

- Proxmox resources
- VM lifecycle
- template/image workflow
- cloud-init inputs
- bootstrap configuration
- initial Argo CD installation
- selected infrastructure-level DNS records if implemented here

### 10.2 Managed by Argo CD
Argo CD manages:

- Traefik
- MetalLB
- cert-manager
- Longhorn
- Rancher
- monitoring stack
- future applications

This split keeps infrastructure provisioning separate from in-cluster service reconciliation.

## 11. Security architecture

### 11.1 Access model
- SSH keys only
- no password login
- no root SSH login
- all provided SSH keys grant admin-capable access

### 11.2 Secrets model
Secrets are stored:

- encrypted in Git
- preferably using **SOPS + age**

This includes:
- Proxmox credentials where appropriate
- DNS TSIG credentials
- ACME credentials if needed
- bootstrap secrets
- application secrets intended for GitOps workflows

### 11.3 State management
Infrastructure state is stored centrally in:

- **GitLab-managed remote state**

This supports collaborative operations and reduces local-state drift.

## 12. Observability architecture

The initial observability stack should include:

- Prometheus
- Alertmanager
- Grafana

Recommended packaging:
- **kube-prometheus-stack**

Alerting should support Telegram delivery through Alertmanager.

## 13. Recovery architecture

The primary disaster recovery model is:

- **rebuild from code**

Recovery depends on:
- reproducible VM provisioning
- repeatable RKE2 bootstrap
- Argo CD re-bootstrap
- re-sync of cluster services and applications from Git
- re-creation of DNS records and certificates

Optional etcd snapshots may be used as convenience recovery but are not the primary strategy.

## 14. Upgrade strategy overview

The architecture should support controlled upgrades of:

- cloud image/template version
- Kubernetes/RKE2 version
- Rancher version
- add-on Helm/chart versions

All major versions should be pinned and advanced intentionally through reviewed changes.

## 15. Open architecture inputs still required

The following values must still be provided before implementation can be finalized:

- backend/management subnet CIDR
- user-facing subnet CIDR
- static node IP range
- MetalLB address range
- Proxmox bridge name
- VLAN IDs, if applicable
- gateway values
- DNS server IPs
- final GitLab project details for CI/state integration
