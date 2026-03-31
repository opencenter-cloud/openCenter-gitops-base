---
id: operator-service-onboarding
title: "Operator Service Onboarding"
sidebar_label: Operator Service Onboarding
description: Compatibility page that points readers to the specific OLM and operator custom-resource onboarding guides.
doc_type: how-to
audience: "platform engineers, cluster operators"
tags: [operators, onboarding, navigation]
unlisted: true
---

# Operator Service Onboarding

Use the more specific onboarding guide that matches your deployment model:

- [OLM Service Onboarding](olm-service-onboarding.md)
  Use when the operator is installed through `OperatorGroup` and `Subscription`.
- [Operator CR Service Onboarding](operator-cr-service-onboarding.md)
  Use when the operator is installed with Helm and the cluster overlay repo creates workload custom resources such as `Kafka` or `postgresql`.

---

- [Service Deployment Patterns](service-deployment-patterns.md)
- [Helm Service Onboarding](helm-service-onboarding.md)

## Related Docs

- [Service Deployment Patterns](service-deployment-patterns.md)
- [Helm Service Onboarding](helm-service-onboarding.md)
- [Keycloak Configuration Guide](services/keycloak.md)
- [Manage Secrets with SOPS](manage-secrets.md)
