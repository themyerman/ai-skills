---
name: api-security
description: >-
  API security patterns: OWASP API Top 10, BOLA fix pattern, OAuth2/JWT,
  rate limiting, GraphQL security, security headers. Covers both REST and
  GraphQL APIs. Triggers: API security, OWASP API, BOLA, IDOR, OAuth2, JWT,
  rate limiting, GraphQL, security headers, broken auth, API abuse.
---

# api-security

APIs are the attack surface. Most modern security incidents involve an API — either a misconfigured auth flow, a missing object-level check, or an unprotected endpoint. This skill covers the patterns that prevent the most common failures.

---

## OWASP API Top 10 — quick reference

| # | Name | One-line fix |
|---|------|-------------|
| API1 | Broken Object Level Authorization (BOLA) | Check ownership on every resource access, not just resource type |
| API2 | Broken Authentication | Use standard libraries (OAuth2/JWT); don't roll your own |
| API3 | Broken Object Property Level Authorization | Don't expose fields the caller shouldn't see; validate what can be written |
| API4 | Unrestricted Resource Consumption | Rate limit and size-limit every endpoint |
| API5 | Broken Function Level Authorization | Verify callers can invoke admin/privileged endpoints, not just read endpoints |
| API6 | Unrestricted Access to Sensitive Business Flows | Rate limit and monitor high-value flows (checkout, password reset, account creation) |
| API7 | Server-Side Request Forgery (SSRF) | Validate and allowlist outbound URLs; block metadata endpoints |
| API8 | Security Misconfiguration | Review headers, CORS, error verbosity, debug endpoints in production |
| API9 | Improper Inventory Management | Know what APIs you have; retire old versions |
| API10 | Unsafe Consumption of APIs | Validate and sanitize responses from third-party APIs |

---

## BOLA — the most common API bug

Broken Object Level Authorization: the API checks that the user is authenticated, but not that they can access *this specific object*.

```python
# Vulnerable — any authenticated user can read any document
@app.get("/documents/{doc_id}")
def get_document(doc_id: int, user=Depends(get_current_user)):
    return db.query(Document).filter(Document.id == doc_id).first()

# Fixed — check ownership before returning
@app.get("/documents/{doc_id}")
def get_document(doc_id: int, user=Depends(get_current_user)):
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if doc is None:
        raise HTTPException(404)
    if doc.owner_id != user.id and user.role != "admin":
        raise HTTPException(403)
    return doc
```

**Test for BOLA explicitly:** create two test users, have user A create a resource, verify user B cannot access it by ID.

```python
def test_bola_protection(client, user_a_token, user_b_token):
    # User A creates a document
    resp = client.post("/documents", json={"title": "private"}, headers=auth(user_a_token))
    doc_id = resp.json()["id"]

    # User B should NOT be able to read it
    resp = client.get(f"/documents/{doc_id}", headers=auth(user_b_token))
    assert resp.status_code == 403
```

---

## OAuth2 and JWT

### OAuth2 flows — choose the right one

| Flow | Use case |
|------|---------|
| Authorization Code + PKCE | Browser and mobile apps; user-facing login |
| Client Credentials | Machine-to-machine; no user involved |
| Device Code | CLI tools and TV/device apps |

Never use the Implicit flow (deprecated). Never use Resource Owner Password Credentials flow (sends passwords to your server).

### JWT validation — all of these, every time

```python
import jwt

def verify_token(token: str, public_key: str, audience: str) -> dict:
    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],   # explicit algorithm — never "none", never HS256 for public APIs
            audience=audience,       # must match — prevents token reuse across services
            options={"verify_exp": True},  # always check expiry
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise AuthError("Token expired")
    except jwt.InvalidAudienceError:
        raise AuthError("Token not valid for this service")
    except jwt.PyJWTError as e:
        raise AuthError(f"Invalid token: {e}")
```

Common JWT mistakes:
- Accepting `alg: none` (lets anyone forge tokens)
- Not checking `aud` (tokens issued for service A work on service B)
- Not checking `exp` (expired tokens still work)
- Using `HS256` with a weak or shared secret

---

## Rate limiting

Every external API needs rate limiting. Without it, one misconfigured client or attacker can exhaust your resources or enumerate data.

### What to rate limit

- **Per IP** — catch unauthenticated abuse
- **Per user/API key** — catch authenticated abuse
- **Per endpoint** — tighter limits on expensive or sensitive operations
- **Per business flow** — e.g., max 5 password reset requests per hour per account

### Pattern with a token bucket (pseudo-code)

```python
from functools import wraps
from redis import Redis

redis = Redis()

def rate_limit(key_func, limit: int, window_seconds: int):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            key = f"rate:{key_func()}"
            count = redis.incr(key)
            if count == 1:
                redis.expire(key, window_seconds)
            if count > limit:
                raise RateLimitError(f"Rate limit exceeded: {limit} per {window_seconds}s")
            return f(*args, **kwargs)
        return wrapper
    return decorator

@app.post("/password-reset")
@rate_limit(key_func=lambda: request.json.get("email"), limit=5, window_seconds=3600)
def password_reset():
    ...
```

Return `429 Too Many Requests` with a `Retry-After` header.

---

## GraphQL security

GraphQL introduces specific risks that REST doesn't have.

### Depth limiting

A malicious query can nest fields arbitrarily deep, causing exponential backend work:

```graphql
# Malicious: deeply nested query
{ user { friends { friends { friends { friends { name } } } } } }
```

Add a depth limit:
```python
# graphene or strawberry — add validation rule
from graphql import build_ast_schema
from graphql.validation import NoSchemaIntrospectionCustomRule

MAX_DEPTH = 5

def depth_limit_validator(max_depth):
    def validator(validation_context):
        # ... depth counting logic
        pass
    return validator
```

### Introspection in production

Disable introspection in production unless you have a specific reason to keep it. It exposes your full schema to attackers.

```python
# strawberry
schema = strawberry.Schema(
    query=Query,
    extensions=[DisableIntrospection] if not settings.DEBUG else []
)
```

### Query cost limiting

Assign a cost to each field and reject queries that exceed a budget. Prevents expensive queries from being used as a DoS vector.

---

## Security headers

Every HTTP response from an API or web app should include these:

```python
# Flask middleware example
@app.after_request
def add_security_headers(response):
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "0"          # disable legacy XSS filter; use CSP instead
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    # Only add HSTS if you're sure you'll always serve HTTPS
    # response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

For APIs (not serving HTML): also set `Content-Type: application/json` explicitly and never reflect user input in error messages.

### CORS

Only allow the origins you actually need:

```python
from flask_cors import CORS

CORS(app, resources={
    r"/api/*": {
        "origins": ["https://app.yourdomain.com"],  # explicit, not "*"
        "methods": ["GET", "POST"],
        "allow_headers": ["Authorization", "Content-Type"],
    }
})
```

Never use `*` for origins on endpoints that accept credentials.

---

## Related

- Object-level auth in depth: [`identity-authz`](../identity-authz/SKILL.md)
- Pre-PR security scan: [`security-review-advisor`](../security-review-advisor/SKILL.md)
- Zero trust and mTLS for service-to-service: [`zero-trust-design`](../zero-trust-design/SKILL.md)
