# Kubernetes on Proxmox with Rancher — Implementation Requirements Plan

## 1. Objective

Implement a reproducible, idempotent infrastructure and platform stack that provisions a single **RKE2** Kubernetes cluster on **Proxmox**, installs **Rancher** on that same cluster, and manages most cluster add-ons and workloads through **Argo CD**.

The cluster is intended for an **internal event setup** and should be easy to rebuild from code.

## 2. Confirmed decisions

The following decisions are confirmed based on the current requirements discussion:

- **Environment type:** internal event cluster
- **Cluster count:** one cluster
- **Rancher scope:** one cluster only
- **Initial topology:** 1 control-plane node, 2 worker nodes
- **Future scaling:** worker nodes must be scalable later through infrastructure code
- **Control-plane HA:** not required for initial implementation
- **Kubernetes distribution:** RKE2
- **Rancher placement:** on the same cluster
- **Ingress controller:** Traefik
- **Load balancer for services:** MetalLB
- **GitOps:** Argo CD from day 1
- **Persistent storage:** Longhorn included in phase 1
- **Dynamic DNS:** RFC2136-compatible dynamic updates against BIND9
- **Internal DNS zone:** non-user-facing names must reside under `c.ballern.net`
- **Terraform/OpenTofu state:** GitLab-managed remote state
- **Secrets in Git:** encrypted
- **SSH access:** SSH keys only
- **Password SSH login:** disabled
- **Root SSH login:** disabled
- **Admin access model:** every provided SSH key grants admin access
- **Environment count:** one environment
- **Repository:** new repository
- **CI system:** GitLab CI
- **Multiple commands acceptable:** yes

## 3. Recommended default decisions

The following items were left open earlier; these are the recommended defaults for implementation unless explicitly changed later.

### 3.1 IaC tool
- **OpenTofu** is recommended as the primary IaC CLI.
- Terraform compatibility should be preserved as much as practical.

### 3.2 Operating system
- **Ubuntu LTS cloud image** is recommended for the initial implementation because of the maturity and low-friction workflow around cloud images and cloud-init.
- If Debian must be used later, the implementation should keep OS-specific assumptions minimal.

### 3.3 etcd mode
- Use **embedded etcd** as part of RKE2.
- External datastore is out of scope for the initial implementation.

### 3.4 API access strategy
- Do **not** implement a Kubernetes API VIP or dedicated API load balancer in v1.
- The Kubernetes API should be exposed through the single control-plane node.
- This choice should be documented as a deliberate availability trade-off.

### 3.5 Proxmox storage strategy
- Use **local SSD-backed storage** in the initial implementation.
- Shared storage is **not required** for v1.
- Datastore names and placement should remain configurable for later multi-host operation.

## 4. Scope

### 4.1 In scope
- Proxmox VM provisioning from pinned cloud images
- Automatic image download and reusable template workflow
- Provisioning of 1 control-plane VM and 2 worker VMs
- Static IP configuration
- RKE2 bootstrap with embedded etcd
- Argo CD bootstrap
- Traefik deployment
- MetalLB deployment
- cert-manager deployment
- Longhorn deployment
- Rancher deployment on the same cluster
- RFC2136/BIND9 DNS automation for required records
- ACME DNS challenge where applicable
- GitLab-managed remote state
- Encrypted secret management in Git
- GitLab CI validation and planning workflow
- Documentation for bootstrap, rebuild, recovery, scaling, and upgrades

### 4.2 Out of scope for initial implementation
- Multi-cluster Rancher management
- Highly available control plane
- Automatic VM backup/snapshot strategy in Proxmox
- Multi-environment setup
- Automatic GitLab user lookup for SSH keys
- Production-grade logging stack unless required later
- External datastore for RKE2

## 5. Functional requirements

### 5.1 Infrastructure provisioning
The implementation must:

- Provision VMs on Proxmox declaratively.
- Download a pinned cloud image automatically where supported by the Proxmox provider.
- Support creation or refresh of a reusable VM template.
- Provision cluster nodes from the template.
- Support configurable:
  - CPU
  - memory
  - disk size
  - datastore names
  - node placement
  - Proxmox bridge
  - VLAN tags
  - VM tags
  - startup order
- Support static IP assignment for all cluster nodes.
- Support later scaling of worker nodes through code changes.

### 5.2 Operating system bootstrap
The implementation must:

- Initialize VMs using cloud-init.
- Accept a list of SSH public keys as input.
- Create admin-capable access for all provided SSH keys.
- Disable password authentication.
- Disable root SSH login.
- Install qemu-guest-agent.
- Configure hostnames, networking, DNS, and baseline packages.
- Keep first-boot configuration deterministic and rerunnable where practical.

### 5.3 Kubernetes bootstrap
The implementation must:

- Install and configure RKE2.
- Initialize a single control-plane node.
- Join two worker nodes.
- Use embedded etcd.
- Expose kubeconfig for operators.
- Support later addition of worker nodes without redesign.

### 5.4 Networking
The implementation must:

- Support separation between backend/management and user-facing network roles.
- Place cluster nodes on the backend/management subnet.
- Support MetalLB address pools for user-facing services.
- Keep bridge, VLAN, gateway, DNS servers, and search domain configurable.
- Reserve and manage static IP ranges for nodes and MetalLB.

### 5.5 DNS and certificates
The implementation must:

- Create all DNS names required for cluster operation.
- Place **non-user-facing names** under `c.ballern.net`.
- Support RFC2136-compatible dynamic DNS updates against BIND9.
- Support ACME DNS challenge for certificate issuance where applicable.
- Ensure Rancher and other ingress endpoints can use valid TLS certificates.

### 5.6 Platform add-ons
The implementation must install, preferably through Argo CD after bootstrap:

- Traefik
- MetalLB
- cert-manager
- Longhorn
- Rancher
- minimal monitoring stack

### 5.7 GitOps
The implementation must:

- Install Argo CD during bootstrap.
- Use Argo CD to manage cluster add-ons after bootstrap.
- Keep application and add-on definitions in Git.
- Clearly document which resources are managed by OpenTofu/Terraform and which are managed by Argo CD.

### 5.8 Secrets and state
The implementation must:

- Store sensitive configuration encrypted in Git.
- Avoid plaintext secrets in committed files.
- Use centralized GitLab-managed remote state.
- Document how state access is configured for team members.

### 5.9 CI/CD
The repository must:

- Run formatting checks.
- Run validation checks.
- Run linting where practical.
- Support plan generation in GitLab CI.
- Document the apply workflow.

## 6. Non-functional requirements

### 6.1 Reproducibility
- All infrastructure and cluster configuration must be represented as code.
- Versions for providers, charts, images, and key components must be pinned.
- The environment must be rebuildable from documented prerequisites.

### 6.2 Idempotency
- Repeated OpenTofu/Terraform applies must converge without creating duplicates.
- Argo CD syncs must be declarative and convergent.
- Bootstrap steps must minimize imperative one-off actions.

### 6.3 Maintainability
- The repository structure must be idiomatic and understandable.
- Modularization should be used where it clearly improves maintainability.
- Variables, secrets, bootstrap assets, and GitOps definitions must be clearly separated.

### 6.4 Operability
- Upgrade procedures must be documented.
- Recovery procedures must be documented.
- Minimal observability must exist from day 1.

## 7. Architecture decisions

### 7.1 Cluster topology
- One cluster only.
- Rancher runs on the same cluster.
- Initial topology:
  - 1 control-plane node
  - 2 worker nodes
- Worker count must be scalable later.

### 7.2 Kubernetes distribution
- RKE2
- Embedded etcd

### 7.3 Ingress and service exposure
- Traefik as ingress controller
- MetalLB for `LoadBalancer` services
- Rancher exposed through ingress
- No Kubernetes API VIP in v1

### 7.4 Operating system
- Ubuntu LTS cloud image as implementation default
- Pinned LTS image version

### 7.5 Storage
- Proxmox local SSD-backed storage in v1
- Datastore names configurable
- Longhorn included in phase 1
- Separate disks for storage workloads may be used if available

### 7.6 Secrets management
- Encrypted secrets in Git
- Recommended implementation: **SOPS + age**

### 7.7 State management
- Remote state stored in GitLab-managed backend

## 8. DNS naming plan

The implementation should create and manage all required DNS names.

### 8.1 Internal and management names
All non-user-facing names must live under `c.ballern.net`.

Recommended names:

- `rancher.c.ballern.net` — Rancher ingress
- `argocd.c.ballern.net` — Argo CD ingress
- `grafana.c.ballern.net` — Grafana ingress
- `alertmanager.c.ballern.net` — Alertmanager ingress
- `longhorn.c.ballern.net` — Longhorn UI ingress, if exposed
- `k8s-api.c.ballern.net` — Kubernetes API endpoint DNS name pointing to the control-plane node in v1

### 8.2 User-facing application names
- User-facing applications should live under `ballern.net` or delegated application subdomains as defined later.
- The exact application hostnames are application-specific and should be managed through GitOps where possible.

### 8.3 DNS update mechanism
- DNS automation must use RFC2136 dynamic updates against BIND9.
- TSIG credentials and related secrets must be stored encrypted.

## 9. Network design requirements

The following networking design must be implemented or kept configurable:

- Backend/management services and cluster nodes reside on the backend subnet.
- User-facing ingress/services use the user-facing subnet through MetalLB.
- Proxmox bridge and VLAN settings remain configurable.
- Node static IPs and MetalLB pools are defined explicitly.
- Gateway, DNS servers, and search domain are configurable.

### 9.1 Still-required concrete inputs
The following concrete values are still required before implementation can be completed:

- backend/management subnet CIDR
- user-facing subnet CIDR
- static IP range for nodes
- MetalLB address pool range
- Proxmox bridge name
- VLAN ID(s), if applicable
- gateway(s)
- DNS server IPs

## 10. Suggested VM sizing

For approximately 10 mostly low-resource web applications, the following initial VM sizes are recommended:

### 10.1 Control-plane node
- 2 vCPU
- 4 GB RAM
- 50 GB disk

### 10.2 Worker nodes
- 4 vCPU
- 8 GB RAM
- 80 GB disk

These values should remain configurable.

## 11. Tooling split of responsibilities

### 11.1 OpenTofu/Terraform responsibilities
OpenTofu/Terraform should manage:

- Proxmox infrastructure
- image/template workflow
- VM provisioning
- cloud-init inputs
- bootstrap inputs for RKE2
- Argo CD bootstrap installation
- infrastructure-level DNS records if implemented at this layer
- remote state configuration

### 11.2 Argo CD responsibilities
Argo CD should manage:

- Traefik
- MetalLB
- cert-manager
- Longhorn
- Rancher
- monitoring stack
- future applications and platform add-ons

## 12. Recommended repository structure

```text
repo/
  README.md
  docs/
    requirements.md
    architecture.md
    bootstrap.md
    operations.md
    recovery.md
    upgrades.md
  tofu/
    envs/
      event/
        backend.hcl
        main.tf
        variables.tf
        tofu.tfvars.example
        outputs.tf
    modules/
      image-template/
      proxmox-vm/
      rke2-cluster/
  bootstrap/
    cloud-init/
      common.yaml
      controlplane.yaml
      worker.yaml
  gitops/
    argocd/
      bootstrap/
      apps/
      projects/
    base/
      traefik/
      metallb/
      cert-manager/
      rancher/
      longhorn/
      monitoring/
  .gitlab-ci.yml
  .sops.yaml
```

## 13. Implementation phases

### Phase 1 — Repository and foundations
- Create repository structure
- Configure OpenTofu/Terraform version pinning
- Configure provider pinning
- Configure GitLab remote state
- Configure SOPS + age
- Define variables and secret handling model

### Phase 2 — Image and template workflow
- Implement cloud image download
- Implement template creation/update workflow
- Document Proxmox prerequisites
- Validate cloud-init boot behavior

### Phase 3 — VM provisioning
- Provision 1 control-plane VM and 2 worker VMs
- Configure storage, networking, tags, and startup order
- Validate SSH and qemu-guest-agent operation

### Phase 4 — RKE2 bootstrap
- Install RKE2
- Initialize control-plane node
- Join worker nodes
- Export kubeconfig
- Validate cluster readiness

### Phase 5 — GitOps bootstrap
- Install Argo CD
- Bootstrap Argo CD applications
- Validate sync and reconciliation model

### Phase 6 — Core platform services
- Deploy Traefik
- Deploy MetalLB
- Deploy cert-manager
- Deploy Longhorn
- Deploy Rancher
- Configure DNS and TLS

### Phase 7 — Observability
- Deploy minimal monitoring stack
- Configure Alertmanager
- Configure Telegram notifications

### Phase 8 — Documentation and operations
- Document rebuild procedure
- Document recovery procedure
- Document upgrade strategy
- Document worker scale-out procedure

## 14. Recovery plan requirements

Because Rancher runs on the same cluster and a full rebuild is acceptable, the implementation must include a documented recovery plan covering:

- How to recreate Proxmox VMs from code
- How to rebuild the RKE2 cluster
- How to re-bootstrap Argo CD
- How to re-sync Rancher and add-ons from Git
- How to restore encrypted bootstrap secrets
- How DNS and certificates are re-established
- Optional etcd snapshot restore procedure if snapshots are enabled

## 15. Backup and restore position

- Full-cluster rebuild is the primary disaster recovery strategy.
- Proxmox VM backup automation is out of scope.
- etcd snapshots are recommended as optional convenience recovery, not as the primary disaster recovery mechanism.

## 16. Monitoring and alerting requirements

The implementation must include a minimal observability stack.

Recommended baseline:

- Prometheus
- Alertmanager
- Grafana

Alerting must support **Telegram** notification delivery.

Recommended implementation:
- `kube-prometheus-stack`
- Alertmanager Telegram integration

## 17. Upgrade requirements

The implementation must document upgrade procedures for:

- Cloud image/template refresh
- Proxmox VM replacement or rebuild flow
- RKE2 version upgrades
- Rancher upgrades
- Core add-on upgrades managed through Argo CD

Versions should be pinned and upgraded intentionally through reviewed changes.

## 18. Security requirements

The implementation must:

- Use SSH keys only for node access
- Disable password-based SSH authentication
- Disable root SSH login
- Keep secrets encrypted in Git
- Avoid storing plaintext API tokens, TSIG secrets, or other credentials in committed files
- Document how Proxmox API credentials are created and supplied securely

## 19. Proxmox API access requirement

The implementation documentation must include instructions for creating a Proxmox API token suitable for infrastructure provisioning, including:

- required account context
- token creation steps
- required permissions or role guidance
- secure injection into OpenTofu/Terraform and CI

## 20. CI requirements for GitLab

The GitLab CI pipeline must support:

- formatting checks
- validation checks
- linting where practical
- plan generation
- optional guarded apply workflow

## 21. Acceptance criteria

Implementation is complete when:

- A team member can provision the cluster from the repository and documented prerequisites.
- The system creates 1 control-plane VM and 2 worker VMs on Proxmox.
- RKE2 becomes functional.
- Argo CD becomes functional.
- Traefik, MetalLB, Longhorn, cert-manager, and Rancher are deployed.
- Required DNS names are created.
- Rancher is reachable via ingress with working TLS.
- Monitoring is functional.
- Re-running infrastructure and GitOps reconciliation is safe and convergent.
- Recovery and upgrade procedures are documented.

## 22. Remaining inputs required before implementation

The following concrete values are still required to finalize implementation:

- backend/management subnet CIDR
- user-facing subnet CIDR
- static node IP range
- MetalLB IP range
- Proxmox bridge name
- VLAN ID(s), if applicable
- gateway IP(s)
- DNS server IPs
- list of SSH public keys
- GitLab project details for remote state and CI setup
- certificate/DNS challenge details as needed for ACME
