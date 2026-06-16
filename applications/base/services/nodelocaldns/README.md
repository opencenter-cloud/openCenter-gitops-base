# NodeLocal DNS Cache – Base Configuration

This directory contains the **base manifests** for deploying [NodeLocal DNS Cache](https://github.com/lablabs/k8s-nodelocaldns-helm), a DNS caching agent that runs on each cluster node to improve DNS performance and reliability.  
It can be consumed directly by cluster repositories or imported by the private enterprise repository for enterprise-specific overrides.

For service overview, use cases, examples, and upstream references, see the [service reference](../../../../docs/reference/services/nodelocaldns.md).

**About NodeLocal DNS Cache:**

- Runs a DNS cache on each node as a DaemonSet, reducing latency for DNS lookups.  
- Avoids conntrack race conditions by using a local link address (`169.254.20.11`) for DNS resolution.  
- Reduces load on the cluster DNS service (CoreDNS / kube-dns).  
- Improves DNS reliability for pods that make frequent DNS queries.  
- Uses CoreDNS as the caching engine with configurable zones and upstream forwarding.  
- Deployed to `kube-system` namespace.  
- Cluster-specific overrides are supplied via the `nodelocaldns-values-override` Secret (optional).  
