---
id: configure-gateway
sidebar_label: Configure Gateway
description: Step-by-step guide for configuring Gateway API routing, TLS, and HTTPRoute resources.
doc_type: how-to
title: "Configure Gateway API Routing"
audience: "platform engineers"
tags: [gateway-api, routing, ingress, tls]
---

# Configure Gateway API Routing

**Purpose:** For platform engineers, shows how to configure Gateway API routing for services, covering Gateway creation, HTTPRoute configuration, TLS termination, and cross-namespace references.

## Prerequisites

- Gateway API installed in cluster
- Envoy Gateway deployed
- cert-manager configured for TLS
- Service deployed and accessible via ClusterIP

The base repository provides the Gateway API/Envoy Gateway deployment pattern; this guide's `GatewayClass` selection, `Gateway`, `Certificate`, and `HTTPRoute` objects are consumer-owned resources. Select an existing, accepted GatewayClass; do not create or patch a GatewayClass from this guide. The DNS names, issuer, address allocation, TLS Secret, and service port must match the target cluster.

## Steps

The examples below assume a common consumer layout where cluster-local service manifests live under `applications/overlays/<cluster>/services/`. If your cluster repository uses a different root, apply the same resources from the equivalent service overlay path in that repo.

### 1. Verify Gateway API installation

```bash
# Check Gateway API CRDs
kubectl get crd | grep gateway.networking.k8s.io

# Expected CRDs:
# gateways.gateway.networking.k8s.io
# httproutes.gateway.networking.k8s.io
# referencegrants.gateway.networking.k8s.io

# Check Envoy Gateway
kubectl get pods -n envoy-gateway-system

# Select an existing GatewayClass. Continue only when it is accepted by a
# controller; the class name below is an environment-specific example.
kubectl get gatewayclass
GATEWAY_CLASS="<existing-gateway-class>"
kubectl get gatewayclass "$GATEWAY_CLASS" -o yaml
```

### 2. Create Gateway

Create a consumer-owned file such as `applications/overlays/<cluster>/services/gateway-api/gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: platform-gateway
  namespace: envoy-gateway-system
spec:
  gatewayClassName: <existing-gateway-class>
  
  listeners:
    # HTTP listener. Add an HTTPRoute RequestRedirect rule if HTTP-to-HTTPS
    # redirection is required.
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.<environment-domain>"
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              kubernetes.io/metadata.name: my-service
    
    # HTTPS listener with TLS
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.<environment-domain>"
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              kubernetes.io/metadata.name: my-service
      tls:
        mode: Terminate
        certificateRefs:
           - kind: Secret
             name: platform-gateway-tls
```

Apply:

```bash
kubectl apply -f applications/overlays/<cluster>/services/gateway-api/gateway.yaml
```

Verify:

```bash
kubectl get gateway platform-gateway -n envoy-gateway-system
kubectl describe gateway platform-gateway -n envoy-gateway-system
```

### 3. Create TLS certificate

Create a consumer-owned file such as `applications/overlays/<cluster>/services/gateway-api/certificate.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: platform-gateway-tls
  namespace: envoy-gateway-system
spec:
  secretName: platform-gateway-tls
  issuerRef:
    name: <cluster-issuer-name>
    kind: ClusterIssuer
  dnsNames:
    - "*.<environment-domain>"
    - <environment-domain>
   # The referenced ClusterIssuer owns the challenge method. Do not also add
   # a cert-manager annotation to the Gateway for the same Secret.
```

Apply:

```bash
kubectl apply -f applications/overlays/<cluster>/services/gateway-api/certificate.yaml
```

Verify certificate issuance:

```bash
kubectl get certificate platform-gateway-tls -n envoy-gateway-system
kubectl describe certificate platform-gateway-tls -n envoy-gateway-system

# Check secret was created
kubectl get secret platform-gateway-tls -n envoy-gateway-system
```

### 4. Create HTTPRoute for service

In your cluster repo, create an `HTTPRoute` in the service overlay path. In the common layout used in these examples, that file is `applications/overlays/<cluster>/services/my-service/httproute.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
      sectionName: https
  
  hostnames:
    - <service-hostname>
  
  rules:
    # Default route to service
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-service
          port: 8080
          weight: 100
```

Apply:

```bash
kubectl apply -f applications/overlays/<cluster>/services/my-service/httproute.yaml
```

### 5. Allow routes from the service namespace

For an `HTTPRoute` in another namespace to attach to this Gateway, configure the Gateway listener's `allowedRoutes.namespaces` with a namespace selector (as shown above). Do not use `from: All` unless the consumer explicitly accepts routes from every namespace. A `ReferenceGrant` is not required for the route's cross-namespace `parentRef`; it is required when a route references a backend object in another namespace. Keep such a grant narrowly scoped to the required backend namespace and object.

### 6. Verify routing

Check HTTPRoute status:

```bash
kubectl get httproute my-service -n my-service
kubectl describe httproute my-service -n my-service
```

Test endpoint:

```bash
# Get Gateway external IP
GATEWAY_IP=$(kubectl get gateway platform-gateway -n envoy-gateway-system -o jsonpath='{.status.addresses[0].value}')
SERVICE_HOSTNAME="<service-hostname>"

# Test HTTP (redirects only if an HTTPRoute RequestRedirect rule was configured)
curl -v "http://${SERVICE_HOSTNAME}" --resolve "${SERVICE_HOSTNAME}:80:${GATEWAY_IP}"

# Test HTTPS
curl -v "https://${SERVICE_HOSTNAME}" --resolve "${SERVICE_HOSTNAME}:443:${GATEWAY_IP}"
```

## Advanced Routing Patterns

### Path-based routing

Route different paths to different services:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-routes
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
  
  hostnames:
     - <api-hostname>
  
  rules:
    # Route /v1/* to v1 service
    - matches:
        - path:
            type: PathPrefix
            value: /v1
      backendRefs:
        - name: my-service-v1
          port: 8080
    
    # Route /v2/* to v2 service
    - matches:
        - path:
            type: PathPrefix
            value: /v2
      backendRefs:
        - name: my-service-v2
          port: 8080
    
    # Default route
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-service-v1
          port: 8080
```

### Header-based routing

Route based on HTTP headers:

```yaml
rules:
  # Route requests with specific header to canary
  - matches:
      - headers:
          - name: X-Canary
            value: "true"
    backendRefs:
      - name: my-service-canary
        port: 8080
  
  # Default route
  - backendRefs:
      - name: my-service-stable
        port: 8080
```

### Weighted traffic splitting

Canary deployment with traffic split:

```yaml
rules:
  - backendRefs:
      # 90% to stable
      - name: my-service-stable
        port: 8080
        weight: 90
      # 10% to canary
      - name: my-service-canary
        port: 8080
        weight: 10
```

### Request header manipulation

Add or modify headers:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    filters:
      # Add request header
      - type: RequestHeaderModifier
        requestHeaderModifier:
          add:
            - name: X-Custom-Header
              value: "custom-value"
          set:
            - name: X-Forwarded-Proto
              value: "https"
          remove:
            - X-Internal-Header
    backendRefs:
      - name: my-service
        port: 8080
```

### URL rewriting

Rewrite request path:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /api/v1
    filters:
      - type: URLRewrite
        urlRewrite:
          path:
            type: ReplacePrefixMatch
            replacePrefixMatch: /v1
    backendRefs:
      - name: my-service
        port: 8080
```

Request to `/api/v1/users` becomes `/v1/users` at backend.

### Redirects

HTTP to HTTPS redirect:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-redirect
  namespace: my-service
spec:
  parentRefs:
    - name: platform-gateway
      namespace: envoy-gateway-system
      sectionName: http
  
  hostnames:
    - <service-hostname>
  
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
```

### Timeouts and retries

Configure request timeouts:

```yaml
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    timeouts:
      request: 30s
      backendRequest: 25s
    backendRefs:
      - name: my-service
        port: 8080
```

## Troubleshooting

### HTTPRoute not working

Check HTTPRoute status:

```bash
kubectl describe httproute my-service -n my-service
```

Look for conditions:
- `Accepted: True` - Route accepted by Gateway
- `ResolvedRefs: True` - Backend references resolved

### "Backend not found" error

Verify service exists:

```bash
kubectl get service my-service -n my-service
```

Check service port matches HTTPRoute:

```bash
kubectl get service my-service -n my-service -o jsonpath='{.spec.ports[0].port}'
```

### Cross-namespace route attachment denied

Check the Gateway listener allows the HTTPRoute namespace:

```bash
kubectl get gateway platform-gateway -n envoy-gateway-system -o yaml
```

Verify the route's parent namespace and listener:

```bash
kubectl get httproute my-service -n my-service -o jsonpath='{.spec.parentRefs[0].namespace}'
```

If the route's `backendRef` points to a Service in another namespace, inspect the corresponding narrowly scoped `ReferenceGrant` in the backend namespace.

### TLS certificate not ready

Check certificate status:

```bash
kubectl get certificate platform-gateway-tls -n envoy-gateway-system
kubectl describe certificate platform-gateway-tls -n envoy-gateway-system
```

Check cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager
```

### Gateway not getting external IP

Check Gateway status:

```bash
kubectl describe gateway platform-gateway -n envoy-gateway-system
```

Check LoadBalancer service:

```bash
kubectl get service -n envoy-gateway-system
```

For MetalLB, verify IP pool:

```bash
kubectl get ipaddresspool -n metallb-system
```

## Verification

Complete verification checklist:

```bash
# 1. Gateway is ready
kubectl get gateway platform-gateway -n envoy-gateway-system -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}'
# Expected: True

# 2. Certificate is ready
kubectl get certificate platform-gateway-tls -n envoy-gateway-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
# Expected: True

# 3. HTTPRoute is accepted
kubectl get httproute my-service -n my-service -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'
# Expected: True

# 4. Service is accessible
curl -k "https://${SERVICE_HOSTNAME}/health"
# Expected: 200 OK
```

## Next Steps

- Configure rate limiting on Gateway
- Set up observability for Gateway metrics (see [setup-observability.md](setup-observability.md))
- Implement mTLS with Istio for service-to-service communication
- Add WAF policies for security
