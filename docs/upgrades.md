# Upgrade Guide

## 1. Purpose

This document describes the upgrade strategy for the Ballern internal event Kubernetes platform.

The platform should support controlled, reviewable upgrades across:

- base cloud images
- Proxmox templates
- RKE2
- Rancher
- Argo CD-managed add-ons

## 2. Upgrade principles

All upgrades should follow these rules:

- versions are pinned
- upgrades happen intentionally through reviewed changes
- infrastructure and platform changes remain reproducible
- changes are validated before and after rollout
- rollback or rebuild paths are documented where practical

## 3. Upgrade categories

### 3.1 Image/template upgrades
This includes:
- Ubuntu LTS cloud image refresh
- template rebuilds
- node replacement workflows

### 3.2 Kubernetes upgrades
This includes:
- RKE2 version changes
- component compatibility review
- rolling node replacement or in-place node upgrade strategy

### 3.3 Platform add-on upgrades
This includes:
- Traefik
- MetalLB
- cert-manager
- Longhorn
- Rancher
- monitoring stack

## 4. Image and template upgrade strategy

### 4.1 Trigger
Image/template upgrades should occur when:

- security updates justify refresh
- a new pinned Ubuntu LTS image is approved
- a node rebuild is already planned

### 4.2 Recommended method
Preferred method:

1. update the pinned image reference
2. rebuild or refresh the Proxmox template
3. replace nodes in a controlled sequence
4. validate cluster readiness after each node change

### 4.3 Notes
Avoid uncontrolled use of moving `latest` references where reproducibility would be reduced.

## 5. RKE2 upgrade strategy

### 5.1 General rule
RKE2 versions must be pinned explicitly.

### 5.2 Recommended sequence
For the current topology:

1. review version compatibility and release notes
2. update version pin in code
3. upgrade or replace the control-plane node carefully
4. validate cluster health
5. upgrade worker nodes one at a time
6. validate workloads and cluster services

### 5.3 Control-plane caution
Because the cluster has only one control-plane node in v1:

- upgrading the control-plane is a maintenance event
- temporary API control-plane downtime should be expected
- this must be planned accordingly

## 6. Rancher upgrade strategy

Rancher should be upgraded through GitOps-managed version changes.

Recommended process:

1. review Rancher compatibility with the target Kubernetes version
2. update pinned Rancher chart/app version
3. sync through Argo CD
4. validate Rancher UI and management functionality

Because Rancher runs on the same cluster:
- treat the upgrade as an in-cluster application upgrade
- ensure rollback/rebuild expectations are documented

## 7. Add-on upgrade strategy

All add-ons should be version-pinned in Git.

Recommended process:

1. update chart or manifest version
2. create a reviewed change
3. let Argo CD reconcile
4. validate health after rollout

Key add-ons:
- Traefik
- MetalLB
- cert-manager
- Longhorn
- monitoring stack

## 8. Longhorn upgrade cautions

When upgrading Longhorn:

- review storage compatibility notes
- verify disk availability and node health
- ensure no unresolved volume degradation exists before upgrade
- validate storage classes and attached volumes after upgrade

## 9. Certificate and DNS considerations during upgrades

Upgrades affecting ingress or cert-manager must validate:

- DNS still resolves correctly
- ACME DNS challenge still works
- certificates renew or reissue successfully

## 10. Validation checklist after any upgrade

At minimum, validate:

- all nodes are Ready
- kube-system components are healthy
- Argo CD is healthy
- Rancher is healthy
- Traefik is routing correctly
- MetalLB services still receive IPs
- Longhorn is healthy
- monitoring is healthy
- required DNS names resolve correctly
- TLS certificates are valid

## 11. Rollback and fallback expectations

Rollback should be considered per category:

- **GitOps-managed add-ons:** revert the Git change and resync
- **template/image issues:** rebuild from prior pinned image
- **cluster issues:** follow documented recovery process

Because this platform favors rebuildability, rollback may sometimes mean controlled re-provisioning rather than strict in-place rollback.

## 12. Change management expectations

Every upgrade should include:

- target version(s)
- reason for upgrade
- compatibility notes
- rollout plan
- validation checklist
- rollback or rebuild note

## 13. Suggested cadence

Recommended cadence:

- security-driven updates as needed
- planned maintenance windows for Kubernetes and Rancher upgrades
- periodic review of image, RKE2, Rancher, and add-on versions

## 14. Documentation requirement

Before the platform is considered operationally ready, the repository should document:

- currently pinned versions
- supported upgrade path assumptions
- known version compatibility constraints
- validation commands and expected outcomes
