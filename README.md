# ballern-infra

Infrastructure and platform repository for the Ballern internal event Kubernetes cluster on Proxmox.

## Purpose

This repository is intended to define and operate a reproducible, idempotent Kubernetes platform based on:

- Proxmox
- RKE2
- Rancher
- Argo CD
- Traefik
- MetalLB
- Longhorn

## Status

Planning and documentation repository.

## Core goals

- infrastructure as code
- reproducible VM provisioning
- GitOps-managed cluster services
- rebuild-first recovery model
- maintainable operations for a small internal cluster

## Planned repository layout

```text
.
├── docs/
├── tofu/
├── bootstrap/
└── gitops/
```

## Documentation

- `docs/requirements.md` — implementation requirements plan
- `docs/architecture.md` — target architecture overview
- `docs/bootstrap.md` — bootstrap process guidance
- `docs/recovery.md` — rebuild and recovery strategy
- `docs/upgrades.md` — upgrade strategy

## Still needed before implementation

- network CIDRs and IP ranges
- Proxmox bridge/VLAN details
- SSH public keys
- DNS server IPs
- GitLab project/state details
- certificate challenge details

## Next steps

1. finalize missing infrastructure inputs
2. create OpenTofu/Terraform skeleton
3. add SOPS and GitLab CI scaffolding
4. bootstrap Proxmox image/template workflow
5. implement RKE2 and Argo CD bootstrap
