---
id: contributing-index
title: "Contributing Documentation and Services"
sidebar_label: Contributing
description: Practical conventions for contributing service manifests, service-local documentation, and curated docs pages to openCenter-gitops-base.
doc_type: how-to
audience: "contributors, platform engineers, operators"
tags: [contributing, documentation, services, templates]
---

# Contributing Documentation and Services

**Purpose:** For contributors, platform engineers, and operators, shows how to add or update service documentation and base service content while keeping repository and consumer responsibilities separate.

## Choose the right owner first

- **This repository:** reusable base manifests under `applications/base/services/`, descriptive catalog metadata beside those manifests, and documentation that explains the base.
- **Cluster consumer repositories:** cluster-specific activation, values, secrets, ingress, storage choices, and operator-managed custom resources. Use the [service deployment patterns](../operations/service-deployment-patterns.md) and the relevant onboarding guide before adding a base change.
- **Private enterprise repository:** private chart or image sources, enterprise values, and enterprise-component rewrites. The base README documents this relationship; do not add private material to a public service directory.

The presence of a service directory means that a base manifest set exists here. It does not by itself mean that every consumer can render or enable it. The root [service inventory](../../README.md#service-inventory) and the catalog metadata record the current boundary.

## Adding or changing a service

For a new Helm service, follow [Add a Helm Service to the Community Repo](../operations/add-helm-service-to-community-repo.md). That guide records the repository-supported file pattern:

- service directory under `applications/base/services/<service>/`
- `kustomization.yaml`, namespace, source, and `helmrelease.yaml` as applicable
- versioned base values under `helm-values/`
- a service-local `README.md`
- a `catalog.yaml` fragment for every new service

Do not infer that every service has the same shape. Existing services also use OLM resources, remote Kustomize bases, Git sources, split CRD releases, and composite directories. Inspect the service's manifests and catalog fragment before copying a sibling.

### Service catalog metadata checklist

For a new or changed service, contributors should:

1. Update the service-local `catalog.yaml` fragment with metadata supported by the service manifests and the catalog schema.
2. Regenerate and commit `applications/catalog.lock.yaml`; do not edit the generated aggregate by hand.
3. Update blueprint membership when the service belongs in, leaves, or changes tier within a blueprint.
4. Reconcile affected service reference or operations pages and README inventories or indexes when catalog-backed facts change.
5. Run the catalog validation and gate checks before opening the change.

Catalog fragment metadata and documentation-page frontmatter are separate concerns. The fragment describes the service inventory; frontmatter describes a Markdown page's identity, navigation, audience, and document type. Updating one does not replace or validate the other.

For changes to an existing service, keep shared, upstream-backed defaults in this repository. Put cluster-specific overrides and secrets in the consuming cluster repository. For operator-managed services, the operator installation may be in this base while the workload custom resources remain consumer-owned; see [Operator CR Service Onboarding](../operations/operator-cr-service-onboarding.md).

## Writing service-local documentation

Use the [service README template](templates/service-readme-template.md) when creating or substantially rewriting `applications/base/services/<service>/README.md`. Replace every placeholder with evidence from the manifests and upstream references. Keep the README focused on:

- what the base directory contains;
- base components, custom resources, storage, and dependencies;
- required versus optional consumer overrides;
- verification and troubleshooting commands; and
- links to the matching reference or configuration guide when one exists.

Service-local READMEs are part of the service directory and are distinct from curated pages under `docs/`. Do not claim that a service is enabled, supported by a particular consumer, or production-ready unless the repository evidence supports that claim.

Use the [service configuration guide template](templates/service-config-guide-template.md) for a `docs/operations/services/<service>.md` page that explains configuration choices, pitfalls, secrets, verification, and usage examples. Use the [service standards template](templates/service-standards-template.md) only when a service needs a lifecycle, risk, architecture, production-requirements, or validation checklist.

## Writing curated `docs/` pages

Every reader-facing Markdown page under `docs/` must start with frontmatter containing:

`id`, `title`, `sidebar_label`, `description`, `doc_type`, `audience`, and `tags`.

The repository audit accepts these `doc_type` values: `tutorial`, `how-to`, `reference`, and `explanation`. Keep the page in the directory matching its purpose:

- `getting-started/` for first-deployment tutorials;
- `operations/` for procedures and troubleshooting;
- `reference/` for stable lookup information; and
- `concepts/` for architecture and explanatory material.

Add the page to the nearest relevant index, and update the root README only when it is an entry-point link or an inventory claim. Use repository-relative Markdown links and verify that their targets exist.

## Existing checks and maintenance scripts

These checks require no docs-site tool or new dependency in the repository:

```bash
python3 hack/scripts/audit_doc_frontmatter.py
python3 hack/scripts/refresh_docs.py --dry-run
python3 hack/scripts/add_purpose_line.py --dry-run
```

For service catalog changes, use the existing catalog tooling from the repository root:

```bash
python3 hack/scripts/catalog.py validate
python3 hack/scripts/catalog.py generate
python3 hack/scripts/catalog.py generate --check
python3 hack/scripts/catalog.py gate
```

`generate` refreshes `applications/catalog.lock.yaml`; `generate --check` verifies that the committed aggregate is current. `validate` checks every fragment against the schema, and `gate` checks manifest coverage, version consistency, orphaned values, aggregate freshness, and blueprint membership. The pre-commit configuration also provides the combined `python3 hack/scripts/catalog.py all` check for catalog changes.

At this revision, all 47 service directories have catalog fragments, the generated lock contains 47 service entries, and the catalog gates pass.

- `audit_doc_frontmatter.py` checks required frontmatter and allowed `doc_type` values for `docs/**/*.md`.
- `refresh_docs.py` repairs known migration path patterns and reports links that still do not resolve. Use its normal mode only when you intend to apply those deterministic repairs.
- `add_purpose_line.py` derives a `**Purpose:**` line from frontmatter; review its dry-run output before applying it.

The script details and the normal invocation list are in [`hack/scripts/README.md`](../../hack/scripts/README.md). Existing templates provide structure; they do not replace checking claims against the repository.

## Before opening a change

1. Check that links point to files or directories that exist.
2. Check that the page frontmatter is complete and its `doc_type` is allowed.
3. Check that service names, paths, versions, and deployment boundaries agree with the manifests and catalog metadata.
4. Run the focused scripts above when they apply.
5. Keep changes within the owning repository: do not add cluster secrets, enterprise-only values, or consumer custom resources to this base.
