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

Initial implementation scaffolding is in place for OpenTofu, GitLab CI, SOPS, and Argo CD/GitOps layout.

## Core goals

- infrastructure as code
- reproducible VM provisioning
- GitOps-managed cluster services
- rebuild-first recovery model
- maintainable operations for a small internal cluster

## Repository layout

```text
.
├── .gitlab-ci.yml
├── .sops.yaml
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
2. implement OpenTofu modules/resources for Proxmox and RKE2
3. replace placeholder SOPS age recipient and encrypted files
4. wire Argo CD applications to the real repository URL and manifests
5. bootstrap Proxmox image/template workflow
