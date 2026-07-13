# JupyterHub

Multi-user notebook environments for data science and ML experimentation.

This service deploys the [Zero to JupyterHub](https://z2jh.jupyter.org/) Helm chart — the portable, Kubernetes-native alternative to OpenShift ODH Workbenches. It runs on any conformant cluster without OpenShift-specific APIs.

## Key Capabilities

- OIDC authentication (integrate with platform Keycloak via cluster override)
- Custom notebook images with pre-installed libraries and frameworks
- Per-user resource limits (CPU, GPU, memory)
- Persistent storage for user workspaces
- Isolated notebook servers per user with configurable profiles

## Chart Details

| Field | Value |
|-------|-------|
| Chart | `jupyterhub` |
| Version | `4.4.0` |
| AppVersion | `5.5.0` |
| Repository | https://hub.jupyter.org/helm-chart/ |
| Namespace | `jupyterhub` |

## Base Configuration

The base values set minimal, opinionated defaults:

- **Authenticator:** Native authenticator (cluster overrides configure OIDC/Keycloak)
- **Default URL:** `/lab` (JupyterLab interface)
- **User scheduler:** Disabled (the platform uses Kueue for resource scheduling)

## Cluster Override Examples

Configure OIDC authentication with Keycloak:

```yaml
hub:
  config:
    JupyterHub:
      authenticator_class: generic-oauth
    GenericOAuthenticator:
      client_id: jupyterhub
      client_secret: <sealed-secret-ref>
      oauth_callback_url: https://jupyter.example.com/hub/oauth_callback
      authorize_url: https://keycloak.example.com/realms/platform/protocol/openid-connect/auth
      token_url: https://keycloak.example.com/realms/platform/protocol/openid-connect/token
      userdata_url: https://keycloak.example.com/realms/platform/protocol/openid-connect/userinfo
      scope:
        - openid
        - profile
        - email
```

Configure GPU-enabled notebook profiles:

```yaml
singleuser:
  profileList:
    - display_name: "Standard (4 CPU, 8Gi RAM)"
      kubespawner_override:
        cpu_limit: 4
        mem_limit: 8Gi
    - display_name: "GPU (4 CPU, 16Gi RAM, 1 GPU)"
      kubespawner_override:
        cpu_limit: 4
        mem_limit: 16Gi
        extra_resource_limits:
          nvidia.com/gpu: "1"
```

## File Layout

```
jupyterhub/
├── namespace.yaml
├── source.yaml
├── helmrelease.yaml
├── kustomization.yaml
├── helm-values/
│   └── values-4.4.0.yaml
└── README.md
```
