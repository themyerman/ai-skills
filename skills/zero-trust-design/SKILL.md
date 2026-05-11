---
name: zero-trust-design
description: >-
  Zero trust architecture: five planes (identity/device/network/app/data),
  maturity model 0-4, mTLS patterns, just-in-time access, never-implicit-trust
  controls. Practical design guidance, not a compliance checklist.
  Triggers: zero trust, ZTA, mTLS, JIT access, implicit trust, network
  segmentation, identity-first security, BeyondCorp, NIST 800-207.
---

# zero-trust-design

Zero trust is a design philosophy, not a product. The core idea: never grant access based on network location alone. Every request is authenticated, authorized, and verified — regardless of where it originates.

This skill covers practical zero trust design: the five planes, a maturity model for gauging where you are, and the key patterns (mTLS, JIT) that make it real in code.

---

## The five planes

Zero trust thinking applies across five layers. Each plane has its own controls:

| Plane | What it governs | Zero trust controls |
|-------|----------------|---------------------|
| **Identity** | Who (or what) is making the request | MFA, phishing-resistant auth, continuous validation, SSO |
| **Device** | What device is making the request | Device health checks, MDM attestation, cert-based device identity |
| **Network** | How the request travels | Micro-segmentation, deny-by-default, mTLS between services |
| **Application** | What the request is trying to do | Per-request authz, least privilege, no implicit session trust |
| **Data** | What data is accessed | Encryption at rest and in transit, data classification, access logging |

Start with identity — it gives you the most leverage earliest. Network is the hardest to retrofit; design for it when building new services.

---

## Maturity model (0–4)

| Level | Description |
|-------|------------|
| **0 — Implicit trust** | Flat network, perimeter-based. "Inside = trusted." Service-to-service calls have no auth. |
| **1 — Network segmentation** | VLANs or security groups limit blast radius. Still mostly perimeter-dependent. |
| **2 — Identity on the perimeter** | Users authenticate at the edge (SSO, MFA). Internal traffic still largely implicit. |
| **3 — Service identity** | Services authenticate to each other (mTLS, workload identity). Per-request authz exists for sensitive operations. |
| **4 — Continuous verification** | All five planes enforced. Access is JIT, logged, and revoked automatically on anomaly. Device posture and data classification drive authorization decisions. |

Most organizations doing real work are between 2 and 3. Getting to 3 is the highest-leverage move for most teams.

---

## mTLS patterns

Mutual TLS: both client and server present a certificate. Neither side is trusted just because it's on the internal network.

### When to use mTLS

- Service-to-service calls in a microservice or distributed system
- Any internal API that handles sensitive data or privileged operations
- Any call crossing a trust boundary (different team, different cluster, different cloud account)

### Basic pattern

```python
import ssl
import httpx

# Client presents its own cert; validates server cert
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.load_cert_chain("client.crt", "client.key")
ctx.load_verify_locations("ca.crt")

client = httpx.Client(verify=ctx)
resp = client.get("https://internal-service/api/resource")
```

### In Kubernetes (via service mesh)

Service meshes (Istio, Linkerd) handle mTLS transparently via sidecar proxies. You don't write mTLS code — you configure policy:

```yaml
# Istio: require mTLS for all services in namespace
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
```

For new services: set STRICT mode from day one. Retrofitting STRICT onto a namespace with mixed services requires a PERMISSIVE transition period.

---

## Just-in-time (JIT) access patterns

JIT means access is granted for a specific purpose, for a bounded time, then revoked automatically. No standing privilege.

### Why JIT

Standing admin access (a person or service that always has elevated permissions) is a persistent attack surface. A compromised credential with standing access can be used indefinitely. A JIT-granted credential expires in hours.

### JIT for humans (privileged access)

1. Engineer requests elevated access for a specific task with a stated reason.
2. Request is approved (automated policy or human approval).
3. Access is granted with a TTL (e.g., 4 hours).
4. Access expires automatically. No manual revocation needed.
5. All actions during the session are logged.

Tools that support this: AWS IAM Identity Center with permission sets, HashiCorp Vault with leased secrets, BeyondCorp-style access proxies.

### JIT for services (secrets and tokens)

Services should fetch short-lived credentials on startup and refresh them before expiry, rather than holding long-lived API keys.

```python
import boto3

def get_short_lived_credentials(role_arn: str, session_name: str) -> dict:
    """Assume a role and get credentials that expire in 1 hour."""
    sts = boto3.client("sts")
    resp = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name,
        DurationSeconds=3600,
    )
    return resp["Credentials"]
```

---

## Design checklist

Starting a new service or reviewing an existing one for zero trust alignment:

- [ ] Does the service authenticate callers per-request, not per-session?
- [ ] Is service-to-service auth in place (mTLS or workload identity)?
- [ ] Are permissions scoped to what this specific service actually needs?
- [ ] Is there no standing admin access? Are elevated actions JIT?
- [ ] Are all access decisions logged (who, what, when, from where)?
- [ ] If the service is compromised, what's the blast radius? Is it acceptable?
- [ ] Is the network path deny-by-default with explicit allow rules?

---

## Related

- IAM patterns and permission design: [`identity-authz`](../identity-authz/SKILL.md)
- Kubernetes security contexts and network policy: [`kubernetes-security`](../kubernetes-security/SKILL.md)
- API auth patterns (OAuth2, JWT): [`api-security`](../api-security/SKILL.md)
