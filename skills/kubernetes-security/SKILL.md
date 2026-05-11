---
name: kubernetes-security
description: >-
  Kubernetes security: RBAC, default-deny NetworkPolicy, security contexts,
  Pod Security Standards (PSS) enforcement, resource limits, troubleshooting
  common misconfigurations. Practical patterns for securing workloads.
  Triggers: Kubernetes, k8s, RBAC, NetworkPolicy, security context, PSS,
  Pod Security, resource limits, privileged container, seccomp, AppArmor.
---

# kubernetes-security

Kubernetes has good security primitives — they're just not on by default. Most cluster security incidents come from defaults left in place: no resource limits, no network policy, privileged containers, overly broad RBAC. This skill covers the patterns to fix those.

---

## RBAC

RBAC in Kubernetes: Roles (namespace-scoped) and ClusterRoles (cluster-wide) define what verbs can be applied to what resources. RoleBindings and ClusterRoleBindings attach them to subjects (users, service accounts, groups).

### Principle: least privilege for service accounts

Every pod gets a service account. By default it gets the `default` service account, which in many clusters has more permissions than it needs. Create a dedicated service account per workload.

```yaml
# Service account with no extra permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service
  namespace: production
automountServiceAccountToken: false   # don't auto-mount unless the pod actually needs API access
```

```yaml
# If the pod needs to read ConfigMaps in its namespace only
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: payment-service-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
  resourceNames: ["payment-config"]   # specific resource, not all configmaps
```

### Don't use ClusterRoleBinding when RoleBinding is enough

`ClusterRoleBinding` with a ClusterRole grants cluster-wide access. Most workloads only need access within their namespace. Use `RoleBinding` + `ClusterRole` or `RoleBinding` + `Role` instead.

```yaml
# Wrong for most workloads
kind: ClusterRoleBinding   # gives cluster-wide access

# Right
kind: RoleBinding           # namespace-scoped
roleRef:
  kind: ClusterRole
  name: view               # built-in read-only role, scoped to the namespace via RoleBinding
```

### Audit RBAC regularly

```bash
# See what a service account can do
kubectl auth can-i --list --as=system:serviceaccount:production:payment-service

# Find all bindings for a service account
kubectl get rolebindings,clusterrolebindings -A \
  -o json | jq '.items[] | select(.subjects[]?.name=="payment-service")'
```

---

## Default-deny NetworkPolicy

By default, all pods can talk to all other pods. NetworkPolicy lets you restrict this.

### Start with default-deny in every namespace

```yaml
# Deny all ingress and egress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}    # matches all pods
  policyTypes:
  - Ingress
  - Egress
```

Then explicitly allow what's needed:

```yaml
# Allow the payment service to receive traffic from the API service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-payment
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-service
    ports:
    - protocol: TCP
      port: 8080
```

```yaml
# Allow payment service to reach the database and DNS only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - port: 5432
  - ports:           # DNS — always needed
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

---

## Security contexts

Security contexts control what a container can do at the OS level.

### Baseline security context for most workloads

```yaml
spec:
  securityContext:                    # Pod-level
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault            # use the runtime's default seccomp profile
  containers:
  - name: payment-service
    securityContext:                  # Container-level (overrides pod-level where both apply)
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]                 # drop all Linux capabilities
```

### What each setting does

| Setting | Why it matters |
|---------|---------------|
| `runAsNonRoot: true` | Process can't run as root even if the image has it set |
| `allowPrivilegeEscalation: false` | Child processes can't gain more privileges than the parent |
| `readOnlyRootFilesystem: true` | Container can't write to its own filesystem (limits persistence) |
| `capabilities: drop: ["ALL"]` | Removes Linux capabilities like `NET_ADMIN`, `SYS_ADMIN` |
| `seccompProfile: RuntimeDefault` | Restricts system calls to a safe default set |

If `readOnlyRootFilesystem: true` breaks your app (it needs to write temp files), mount a writable `emptyDir` at the specific paths that need writes rather than making the whole filesystem writable.

---

## Pod Security Standards (PSS)

PSS is Kubernetes' built-in policy enforcement. Three levels:

| Level | What it enforces |
|-------|-----------------|
| **Privileged** | No restrictions (equivalent to no policy) |
| **Baseline** | Prevents known privilege escalation; still allows most workloads |
| **Restricted** | Heavily restricted; requires non-root, no privilege escalation, seccomp |

Apply PSS at the namespace level with labels:

```yaml
# Enforce restricted for production, warn on baseline violations
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: baseline
    pod-security.kubernetes.io/warn-version: latest
```

Test before enforcing — `warn` mode lets you see what would be rejected without breaking existing pods:

```bash
# Dry-run: what would be rejected if you applied restricted to this namespace?
kubectl label namespace production pod-security.kubernetes.io/warn=restricted --dry-run=client
```

---

## Resource limits

Without limits, one runaway pod can starve the entire node.

```yaml
resources:
  requests:
    cpu: "100m"       # what the scheduler reserves
    memory: "128Mi"
  limits:
    cpu: "500m"       # hard cap (throttled if exceeded)
    memory: "256Mi"   # hard cap (OOMKilled if exceeded)
```

### Setting limits intelligently

1. Run without limits first, observe actual usage under load.
2. Set requests slightly above typical usage (p95 of what you observed).
3. Set limits at 2–4x requests for CPU (burst allowed), 1.5x for memory (avoid OOMKill under normal variance).
4. Use a LimitRange to enforce defaults for the namespace:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
```

---

## Troubleshooting

### Pod won't start after adding security context

```bash
kubectl describe pod <pod-name> -n production
# Look for: "container has runAsNonRoot and image will run as root"
# Fix: either set a non-root USER in the Dockerfile, or set runAsUser in the security context
```

### NetworkPolicy blocking unexpected traffic

```bash
# Check what policies apply to a pod
kubectl get networkpolicy -n production -o yaml

# Temporarily add a debug pod in the same namespace and test connectivity
kubectl run debug --image=nicolaka/netshoot -it --rm -n production -- bash
# Then from inside: curl http://payment-service:8080/health
```

### Finding overly permissive RBAC

```bash
# Find any role that can do everything (cluster-admin wildcard)
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name == "cluster-admin") | .subjects'

# Find service accounts with wildcard verbs
kubectl get roles,clusterroles -A -o json | \
  jq '.items[] | select(.rules[]?.verbs[]? == "*") | {name: .metadata.name, ns: .metadata.namespace}'
```

---

## Related

- mTLS between services (via service mesh): [`zero-trust-design`](../zero-trust-design/SKILL.md)
- IAM and service account patterns: [`identity-authz`](../identity-authz/SKILL.md)
- CI/CD for deploying to Kubernetes: [`ci-cd-pipelines`](../ci-cd-pipelines/SKILL.md)
