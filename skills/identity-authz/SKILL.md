---
name: identity-authz
description: >-
  Identity and authorization design: RBAC vs ABAC, AWS IAM patterns, permission
  boundaries, cross-account access, app-level authz. Covers both cloud IAM and
  application-level authorization patterns. Triggers: IAM, RBAC, ABAC, roles,
  permissions, policy, least privilege, cross-account, permission boundary,
  authorization, access control, AWS IAM, service account.
---

# identity-authz

Authorization is the decision "can this identity do this thing?" It's one of the most common sources of security bugs and one of the most important to get right early — retrofitting authz is painful.

---

## RBAC vs ABAC

### RBAC — Role-Based Access Control

Permissions are attached to roles; users/services are assigned roles.

```
User → Role(s) → Permissions
```

Good for: most applications. Simple to reason about, easy to audit.

```python
# Simple RBAC check
ROLE_PERMISSIONS = {
    "viewer": {"read"},
    "editor": {"read", "write"},
    "admin":  {"read", "write", "delete", "manage_users"},
}

def can(user_role: str, action: str) -> bool:
    return action in ROLE_PERMISSIONS.get(user_role, set())
```

Pitfalls:
- Role explosion: teams create a new role for every edge case instead of refining existing ones.
- Privilege creep: users accumulate roles over time and nobody removes them.

### ABAC — Attribute-Based Access Control

Permissions are derived from attributes of the subject (user), resource, action, and environment.

```
Policy(subject.attrs, resource.attrs, action, environment) → allow/deny
```

Good for: fine-grained access where RBAC roles would become unmanageably numerous. "Can this user edit this specific document?" where ownership matters.

```python
def can_edit_document(user: User, document: Document) -> bool:
    # ABAC: combine user and resource attributes
    if user.role == "admin":
        return True
    if document.owner_id == user.id:
        return True
    if user.department == document.department and user.role == "editor":
        return True
    return False
```

Pitfalls:
- Hard to audit: "who can access X?" requires evaluating every policy against every identity.
- Policy logic becomes complex and hard to test. Keep individual policies small and testable.

### Which to use

Start with RBAC. Move to ABAC when you have a concrete use case that RBAC can't handle without role explosion. Many applications that think they need ABAC actually need better-designed RBAC.

---

## AWS IAM patterns

### Principle: least privilege, always

Give the minimum permissions needed for the task. Start with nothing and add what's required, rather than starting broad and trying to remove.

### Identity types

| Identity | Use case |
|----------|---------|
| IAM User | Human with long-term credentials. Avoid for automation. |
| IAM Role | Assumed by services, Lambda, EC2, ECS tasks, CI/CD. Preferred. |
| Service Account (IRSA) | Kubernetes workloads needing AWS access. |
| OIDC federation | CI/CD systems (GitHub Actions, etc.) assuming roles without stored keys. |

Never create long-lived IAM access keys for automation. Use roles with temporary credentials.

### OIDC federation for CI/CD (no stored secrets)

```yaml
# GitHub Actions — no AWS_ACCESS_KEY_ID stored
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-deploy-role
    aws-region: us-east-1
```

The corresponding trust policy on the role:
```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123456789:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:ref:refs/heads/main"
    }
  }
}
```

Lock down the `sub` condition — without it, any repo in your org can assume this role.

### Permission boundaries

A permission boundary is a policy attached to an IAM role that acts as an outer limit — even if the role has other policies that grant broad access, the boundary restricts what's actually usable.

Use permission boundaries when:
- Delegating role creation to teams (they can create roles, but only within the boundary you define).
- Deploying Lambda or ECS tasks via CI/CD — the deployment role can only create task roles that stay within bounds.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:*", "dynamodb:*"],
    "Resource": "arn:aws:*:*:123456789:*"
  }]
}
```

Attaching this as a permission boundary means the role can only ever do S3 and DynamoDB operations, regardless of what other policies are attached.

### Cross-account access

One account assumes a role in another account. The pattern:

1. Account B creates a role with a trust policy allowing Account A to assume it.
2. Account A's identity calls `sts:AssumeRole` with the Account B role ARN.
3. Account A uses the temporary credentials to act in Account B.

```python
import boto3

def get_cross_account_session(role_arn: str, region: str = "us-east-1"):
    sts = boto3.client("sts")
    creds = sts.assume_role(
        RoleArn=role_arn,
        RoleSessionName="cross-account-session",
        DurationSeconds=3600,
    )["Credentials"]
    return boto3.Session(
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
        region_name=region,
    )
```

Audit cross-account trust relationships regularly. Old trust relationships are a common blind spot.

---

## App-level authorization

### Where to check

Authorization checks belong as close to the data as possible — ideally in the service that owns the data, not at the API gateway or load balancer.

```python
# Wrong: auth check at the route level only
@app.route("/documents/<doc_id>")
@require_role("editor")        # role check only — any editor can read any doc
def get_document(doc_id):
    return Document.get(doc_id)

# Right: check at the resource level
@app.route("/documents/<doc_id>")
@require_login
def get_document(doc_id):
    doc = Document.get(doc_id)
    if not can_access(current_user, doc):   # ownership/role check on the resource
        abort(403)
    return doc
```

### BOLA / IDOR prevention

Broken Object Level Authorization (BOLA) is the most common API security bug. The fix: always verify the requesting user can access the specific object, not just the resource type.

```python
def can_access(user: User, resource) -> bool:
    if user.role == "admin":
        return True
    if hasattr(resource, "owner_id") and resource.owner_id == user.id:
        return True
    if hasattr(resource, "team_id") and resource.team_id in user.team_ids:
        return True
    return False
```

Test this explicitly: write tests that confirm user A cannot access user B's resources by guessing IDs.

### Audit logging for privileged actions

Every privileged action should produce a log entry with: who, what, when, what resource, from where.

```python
import logging

logger = logging.getLogger(__name__)

def delete_user(actor: User, target_user_id: int) -> None:
    if not can(actor.role, "delete_users"):
        logger.warning(
            "unauthorized_delete_attempt",
            extra={"actor_id": actor.id, "target_user_id": target_user_id},
        )
        raise PermissionError("Not authorized")
    # ... perform delete ...
    logger.info(
        "user_deleted",
        extra={"actor_id": actor.id, "target_user_id": target_user_id},
    )
```

---

## Related

- Zero trust architecture and mTLS: [`zero-trust-design`](../zero-trust-design/SKILL.md)
- API auth (OAuth2, JWT): [`api-security`](../api-security/SKILL.md)
- Kubernetes RBAC: [`kubernetes-security`](../kubernetes-security/SKILL.md)
