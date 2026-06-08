# Recovery Guide

## 1. Purpose

This document defines the recovery strategy for the Ballern internal event Kubernetes platform.

The system is intentionally designed around a **rebuild-first recovery model**.

That means the primary disaster recovery method is:

- recreate infrastructure from code
- rebuild the cluster
- re-bootstrap GitOps
- let platform services reconcile from Git

## 2. Recovery assumptions

The following assumptions are built into the recovery strategy:

- the cluster is internal and event-focused
- Rancher runs on the same cluster it manages
- full rebuild is acceptable in a disaster
- all critical infrastructure and platform definitions are stored in Git
- secrets required for rebuild are recoverable from encrypted storage

## 3. Recovery objectives

The recovery process should restore:

- Proxmox VMs
- RKE2 cluster availability
- Argo CD
- Rancher
- Longhorn
- monitoring
- DNS records required for management endpoints
- ingress and TLS functionality

## 4. Recovery scenarios

### 4.1 Single node failure
Examples:
- worker node lost
- control-plane VM corruption
- accidental VM deletion

Recommended response:
- recreate the node through OpenTofu/Terraform
- allow the cluster to reconcile
- verify workloads reschedule correctly

### 4.2 Full cluster failure
Examples:
- all cluster VMs lost
- unrecoverable Kubernetes state
- bootstrap configuration drift beyond confidence

Recommended response:
- recreate all VMs from code
- rebuild the cluster
- restore GitOps control
- allow applications and platform services to reconcile

### 4.3 DNS or certificate failure
Examples:
- missing dynamic records
- expired or broken TLS
- TSIG credential drift

Recommended response:
- restore encrypted DNS credentials
- re-run DNS automation
- re-run cert-manager reconciliation

## 5. Recovery prerequisites

The following must be available for successful recovery:

- access to the Git repository
- access to GitLab remote state
- access to encrypted secrets
- age private key(s) or equivalent SOPS decryption capability
- Proxmox API access
- DNS/BIND9 access through RFC2136 + TSIG
- operator tooling (`opentofu`, `kubectl`, `sops`, `age`, `git`)

## 6. Recovery strategy by layer

### 6.1 Infrastructure layer
Infrastructure is recovered by:

- restoring access to the repository
- restoring access to remote state or reinitializing if necessary
- running OpenTofu/Terraform to recreate image/template resources and VMs

### 6.2 Cluster layer
The Kubernetes cluster is recovered by:

- rerunning the RKE2 bootstrap process
- recreating the control-plane node
- joining worker nodes
- validating node readiness and cluster health

### 6.3 GitOps layer
GitOps is recovered by:

- reinstalling or reconnecting Argo CD
- restoring Argo CD bootstrap configuration
- re-syncing platform applications from Git

### 6.4 Platform services layer
Platform services are recovered through Argo CD reconciliation:

- Traefik
- MetalLB
- cert-manager
- Longhorn
- Rancher
- monitoring stack

## 7. Recovery sequence

Recommended order:

1. restore repository and secrets access
2. restore or initialize infrastructure state access
3. recreate Proxmox resources and VMs
4. verify VM reachability and cloud-init completion
5. bootstrap RKE2
6. validate kubeconfig and cluster readiness
7. bootstrap Argo CD
8. sync core platform services
9. validate DNS and TLS
10. validate Rancher and monitoring access

## 8. Secrets recovery

Recovery depends on the ability to decrypt required secrets.

At minimum, ensure recoverability of:

- Proxmox API credentials
- DNS TSIG key material
- ACME-related credentials if used
- RKE2 bootstrap secrets as applicable
- Telegram alerting secrets
- any bootstrap admin credentials not regenerated automatically

If encrypted with SOPS + age, the age private key material must itself have a documented backup and recovery process.

## 9. DNS recovery

The following records are expected to be recoverable automatically through DNS automation:

- `k8s-api.c.ballern.net`
- `rancher.c.ballern.net`
- `argocd.c.ballern.net`
- `grafana.c.ballern.net`
- `alertmanager.c.ballern.net`
- `longhorn.c.ballern.net` if exposed

Recovery of DNS depends on:
- BIND9 update availability
- RFC2136 configuration
- valid TSIG credentials

## 10. Certificate recovery

Certificate recovery should be handled through:

- cert-manager reconciliation
- DNS challenge automation

If certificates are missing after rebuild:
- verify DNS records
- verify RFC2136 access
- verify issuer configuration
- verify challenge-specific secrets

## 11. Longhorn recovery notes

Longhorn is included in phase 1, but this environment uses rebuild-first recovery.

Implications:
- persistent volume data durability expectations must be documented separately
- Longhorn may recover platform stateful workloads, but the primary recovery model is still rebuild
- applications requiring strict data retention need explicit backup planning beyond this baseline

## 12. etcd snapshots

etcd snapshots are optional but recommended as convenience recovery.

They are useful for:
- accidental configuration damage
- faster recovery from logical cluster problems

They are not the primary disaster recovery strategy.

If enabled, the recovery documentation must cover:
- snapshot location
- snapshot retention
- restore procedure
- limitations of restoring Rancher-on-self-managed-cluster setups

## 13. Validation checklist after recovery

Recovery is complete only when:

- VMs are running in Proxmox
- all Kubernetes nodes are Ready
- Argo CD is reachable and healthy
- Rancher is reachable and healthy
- Longhorn is healthy
- monitoring is healthy
- required DNS records resolve correctly
- TLS certificates are valid
- user-facing applications can be resynced successfully

## 14. Failure modes that require manual intervention

The following situations may require manual intervention:

- GitLab remote state corruption or loss
- age key loss without backup
- BIND9 dynamic updates misconfigured
- Proxmox bridge/VLAN changes outside code
- incompatible provider or image version changes
- storage-layer issues affecting Longhorn disks

## 15. Recovery drills

Recovery procedures should be tested periodically.

Recommended drills:
- rebuild a worker node
- replace the control-plane node in a controlled test
- re-bootstrap Argo CD from scratch
- validate DNS recreation
- validate certificate reissuance

## 16. Minimum documentation requirement

Before the platform is considered operationally ready, the repository must document:

- exact recovery commands
- required tools
- required secrets
- expected DNS names
- expected validation steps
- known recovery limitations
