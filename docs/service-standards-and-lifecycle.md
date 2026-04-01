---
id: service-standards-and-lifecycle
title: Service Standards & Lifecycle
sidebar_label: Service Standards and Lifecycle
description: Historical compatibility page for an older service standards document that no longer reflects the current repository architecture.
tags: [historical, compatibility, services, architecture]
audience: [Developer, Operations]
doc_type: reference
unlisted: true
---

# Service Standards & Lifecycle

This page is retained only as a compatibility entry point for older links.

It does **not** describe the current `openCenter-gitops-base` architecture.

In particular, the earlier version of this page described a mono-repo `clusters/`, `apps/`, and `infra/` layout and a promotion model that does not match the current repository boundaries.

## Current Canonical Guidance

Use these documents instead:

- [Architecture Explanation](explanation/architecture.md) for current repository boundaries and deployment architecture
- [GitOps Workflow](explanation/gitops-workflow.md) for the current Flux reconciliation model
- [Service Deployment Patterns](how-to/service-deployment-patterns.md) for the cluster-repo and enterprise-repo consumption model
- [Directory Structure Reference](reference/directory-structure.md) for current on-disk layout
- [Directory Structure Reference](reference/directory-structure.md) for current service layout and composition patterns
- [Base, Override, and Enterprise Values](explanation/three-tier-values.md) for the current values ownership model

## Status

Historical and superseded.
