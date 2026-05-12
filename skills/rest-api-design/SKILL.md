---
name: rest-api-design
description: >-
  REST API design patterns: resource naming, HTTP verbs and status codes,
  versioning strategies, cursor and offset pagination, error response format,
  idempotency, OpenAPI documentation. Covers design decisions separate from
  security. Triggers: API design, REST, resource naming, HTTP status codes,
  versioning, pagination, error format, idempotency, OpenAPI, endpoint design.
---

# rest-api-design

Design decisions that determine whether an API is pleasant to use or a source of perpetual confusion. Covers the choices you make before writing a line of implementation code.

---

## Resource naming

Resources are nouns, not verbs. URLs identify things; HTTP verbs describe what to do with them.

```
# Wrong — verbs in URLs
GET  /getUser/42
POST /createOrder
POST /deleteItem/7

# Right — nouns, plural, hierarchical where natural
GET    /users/42
POST   /orders
DELETE /items/7
```

### Hierarchy vs. query parameters

Use URL path hierarchy for required, identity-defining relationships:

```
GET /users/42/orders          # orders belonging to user 42
GET /users/42/orders/99       # specific order
```

Use query parameters for filtering, sorting, and pagination — things that narrow a collection without changing what resource you're addressing:

```
GET /orders?status=pending&sort=created_at&direction=desc
```

Don't go more than 2–3 levels deep. `/users/42/orders/99/items/7/reviews` is a sign you should use `/reviews?item_id=7` instead.

---

## HTTP verbs

| Verb | Use for | Idempotent? |
|------|---------|------------|
| GET | Fetch a resource or collection | Yes |
| POST | Create a new resource | No |
| PUT | Replace a resource entirely | Yes |
| PATCH | Partially update a resource | Depends on implementation |
| DELETE | Remove a resource | Yes |

**PUT vs PATCH:** PUT replaces the whole resource (client sends the full representation). PATCH updates specific fields. Use PATCH for partial updates — PUT requires clients to send every field, which causes data loss if they don't know about new fields.

---

## Status codes

Use the right code. Clients branch on these.

| Code | Use when |
|------|---------|
| 200 OK | Successful GET, PUT, PATCH |
| 201 Created | Successful POST that created a resource; include `Location` header |
| 204 No Content | Successful DELETE or action with no response body |
| 400 Bad Request | Client sent invalid data (validation error) |
| 401 Unauthorized | Not authenticated (despite the name) |
| 403 Forbidden | Authenticated but not authorized |
| 404 Not Found | Resource doesn't exist |
| 409 Conflict | State conflict (duplicate, version mismatch) |
| 422 Unprocessable Entity | Syntactically valid but semantically wrong |
| 429 Too Many Requests | Rate limited; include `Retry-After` |
| 500 Internal Server Error | Unhandled server error; don't leak stack traces |

---

## Error response format

Pick a format and use it consistently everywhere. Clients should be able to handle errors with one code path.

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Request body contains invalid fields.",
    "details": [
      {
        "field": "email",
        "code": "invalid_format",
        "message": "Must be a valid email address."
      },
      {
        "field": "age",
        "code": "out_of_range",
        "message": "Must be between 18 and 120."
      }
    ],
    "request_id": "req_abc123"
  }
}
```

Rules:
- `code` is a machine-readable string (not a number) — clients can switch on it
- `message` is human-readable — for logs and developer UI
- `request_id` lets clients give you something to look up in your logs
- Never expose stack traces, internal paths, or database errors in production responses

---

## Versioning

Three common approaches:

| Strategy | Example | Tradeoffs |
|----------|---------|-----------|
| URL path | `/v1/users` | Explicit, cacheable, easy to route; pollutes URLs |
| Header | `Accept: application/vnd.api+json;version=2` | Clean URLs; harder to test in browser |
| Query param | `/users?version=2` | Easy to test; often forgotten |

URL path versioning is the most practical for most APIs. Start with `/v1/` from day one — retrofitting versioning onto an unversioned API is painful.

### What warrants a new version

- Removing a field
- Changing a field's type or meaning
- Changing a required field to required when it wasn't before
- Breaking changes to error codes or response structure

Adding optional fields, adding new endpoints, and adding new optional query parameters are non-breaking and don't need a version bump.

---

## Pagination

### Offset pagination

```
GET /orders?limit=20&offset=0    # page 1
GET /orders?limit=20&offset=20   # page 2
```

Simple to implement; degrades on large datasets. Fine for most use cases under a few hundred thousand rows.

Response envelope:

```json
{
  "data": [...],
  "pagination": {
    "total": 1543,
    "limit": 20,
    "offset": 0,
    "next": "/orders?limit=20&offset=20"
  }
}
```

### Cursor pagination

```
GET /orders?limit=20                          # first page
GET /orders?limit=20&cursor=eyJpZCI6MTIzfQ   # next page
```

The cursor is an opaque token (base64-encoded JSON is common). Clients don't parse it — they pass it back as-is.

Response:

```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIzfQ",
    "has_more": true
  }
}
```

Use cursor pagination for feeds, activity streams, or any collection that's frequently updated.

---

## Idempotency

Idempotent requests: sending the same request multiple times produces the same result as sending it once.

GET, PUT, and DELETE are inherently idempotent. POST is not — submitting an order twice creates two orders.

For non-idempotent POST operations, support an idempotency key:

```
POST /payments
Idempotency-Key: client-generated-uuid-here
```

Server stores the key and result. If the same key is received again (network retry), return the stored result without re-executing. Expire keys after 24 hours.

```python
def create_payment(idempotency_key: str, payload: dict):
    # Check cache first
    cached = cache.get(f"idem:{idempotency_key}")
    if cached:
        return cached

    result = process_payment(payload)
    cache.set(f"idem:{idempotency_key}", result, ttl=86400)
    return result
```

---

## Response envelope vs. naked resource

Two schools:

```json
// Naked resource — simple, works well for single-resource responses
{"id": 42, "name": "Tom", "email": "tom@example.com"}

// Envelope — adds metadata, works well for collections and errors
{
  "data": {"id": 42, "name": "Tom"},
  "meta": {"request_id": "req_abc"}
}
```

Pick one and use it consistently. Naked for simple CRUD APIs; envelope when you need pagination metadata, request IDs, or warnings alongside the data.

---

## OpenAPI

Document your API with an OpenAPI spec. It gives you free client generation, documentation, and validation.

```yaml
openapi: "3.1.0"
info:
  title: Orders API
  version: "1.0"
paths:
  /orders:
    get:
      summary: List orders
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, complete, cancelled]
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/OrderList"
```

Write the spec first (design-first), then implement. It forces you to think through the API shape before you're committed to it.

---

## Related

- Security for the APIs you design: [`api-security`](../api-security/SKILL.md)
- Flask implementation patterns: [`python-scripts-and-services/flask-serving.md`](../python-scripts-and-services/flask-serving.md)
- Input validation at the boundary: [`python-scripts-and-services/data-validation.md`](../python-scripts-and-services/data-validation.md)
