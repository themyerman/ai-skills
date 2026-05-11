---
name: feature-flags
description: >-
  Feature flag patterns: safe rollout procedure, kill switch design, security
  boundary rules, flag hygiene and lifecycle, metrics to track. Covers both
  release flags and operational kill switches. Triggers: feature flag, feature
  toggle, kill switch, rollout, canary, gradual rollout, flag hygiene,
  LaunchDarkly, flag debt, dark launch.
---

# feature-flags

Feature flags decouple deployment from release. You ship code, then turn features on — gradually, for specific users, or in response to what you observe. Done well, they make deploys safer and rollbacks instant. Done poorly, they accumulate as tech debt and create security blind spots.

---

## Flag types

| Type | Lifespan | Purpose |
|------|----------|---------|
| **Release flag** | Days to weeks | Gate a feature until it's ready to ship broadly |
| **Experiment flag** | Days to weeks | A/B test; removed after the winner is chosen |
| **Operational flag** | Permanent | Kill switch, circuit breaker, rate limiter toggle |
| **Permission flag** | Long-lived | Enable features for specific users/orgs (beta access, paid tier) |

Treat these differently. Release and experiment flags are temporary — schedule their removal. Operational and permission flags may be permanent and need different hygiene.

---

## Safe rollout procedure

The goal: get broad coverage while limiting blast radius if something is wrong.

```
1%  →  5%  →  20%  →  50%  →  100%
```

At each stage:
1. Wait for meaningful traffic (enough requests to see errors or latency change).
2. Check your key metrics: error rate, p99 latency, business metric (conversion, engagement).
3. If metrics are clean, advance to the next stage. If not, kill the flag immediately.

### Rollout targeting order

1. **Internal users first** (your team, your org) — catch obvious breakage with no user impact.
2. **Beta users / early adopters** — users who expect rough edges.
3. **Low-traffic geographies or time windows** — e.g., start in a region that's off-peak.
4. **Percentage rollout** — 1%, 5%, 20%, 50%, 100%.

### Example with LaunchDarkly SDK

```python
import ldclient
from ldclient.config import Config

ldclient.set_config(Config(sdk_key="your-sdk-key"))
client = ldclient.get()

def is_new_checkout_enabled(user_id: str, email: str) -> bool:
    context = ldclient.Context.builder(user_id).set("email", email).build()
    return client.variation("new-checkout-flow", context, default=False)
```

---

## Kill switch design

A kill switch is an operational flag that can immediately disable a feature in production without a deploy. Design these to be:

- **Fast to evaluate** — flag check adds < 1ms. Don't call an external service on every request.
- **Fail-safe** — if the flag service is unavailable, default to the safe state (usually: feature off).
- **Clearly named** — `enable_new_checkout` is a release flag. `kill_new_checkout` or `disable_new_checkout` makes the kill switch intent obvious.

```python
def process_payment(order):
    if not flags.is_enabled("new-payment-processor"):
        return legacy_process_payment(order)
    try:
        return new_process_payment(order)
    except NewProcessorError as e:
        logger.error("new_processor_failed", exc_info=e)
        # Don't fall back silently — surface the error so you know the kill switch is needed
        raise
```

### When to kill immediately (don't wait)

- Error rate rises by more than 1% above baseline.
- p99 latency doubles.
- Any data loss or data corruption signal.
- Payment or auth failures.

Have the kill switch URL / toggle bookmarked before you start a rollout.

---

## Security boundary rules

Flags that control security-relevant behavior need extra care.

### Never use a flag to bypass security controls

```python
# Wrong — flag disables auth check
if flags.is_enabled("skip-auth-for-dev"):
    return serve_request(request)
else:
    require_auth(request)

# Wrong in production even if you intend it for dev only
```

Security controls should not be flag-controlled in production. If you need to disable auth for testing, do it in a separate environment, not via a flag in production.

### Flags that change security posture need review

Any flag that:
- Changes who can access what (authz rules)
- Enables or disables encryption
- Controls audit logging
- Changes rate limiting behavior

...should go through a security review before rollout, and should require explicit approval to enable rather than a percentage rollout.

### Flags are not a substitute for access control

A flag check is a code path. It can be bypassed, misconfigured, or have a bug. Don't rely on a flag to protect sensitive data — use real access control. Flags are for release management, not security enforcement.

---

## Flag hygiene

Flag debt accumulates fast. A 100-flag codebase with no lifecycle process is a maintenance liability.

### Metrics to track

- **Total active flags** — if it's growing without bound, you're not cleaning up.
- **Flag age** — any release or experiment flag older than 30 days needs a decision: ship it or delete it.
- **Flags never evaluated** — flags that haven't been evaluated in production in 14 days are almost certainly dead.
- **Flags with no owner** — owner left, nobody reassigned. These are the ones nobody ever removes.

### Lifecycle rules

1. Every release/experiment flag gets a **removal date** when created. Put it in the description.
2. When a flag is at 100% and has been stable for one week, open a cleanup ticket immediately.
3. Before removing a flag, confirm the default behavior (what happens when the flag is gone) is what you want. Remove the condition from code first, then delete the flag from the service.

```python
# Removing a flag safely
# Step 1: Inline the winning behavior (don't delete the flag check yet)
def process_payment(order):
    # TODO: remove flag — always using new processor as of 2024-01 (flag: new-payment-processor)
    return new_process_payment(order)

# Step 2: Deploy and verify
# Step 3: Delete the flag from the flag service
# Step 4: Remove the TODO comment and any remaining flag SDK calls
```

---

## Related

- Shipping safely: [`ship-checklist`](../ship-checklist/SKILL.md)
- CI/CD pipeline integration: [`ci-cd-pipelines`](../ci-cd-pipelines/SKILL.md)
- Incident response when a flag causes a production issue: [`incident-response`](../incident-response/SKILL.md)
