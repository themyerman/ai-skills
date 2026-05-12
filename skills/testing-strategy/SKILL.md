---
name: testing-strategy
description: >-
  Testing strategy: test pyramid, what to unit/integration/e2e test, TDD
  workflow, what to mock (and what not to), test doubles (mock/stub/spy/fake),
  property-based testing, coverage as a tool not a target, flaky test diagnosis.
  Language-agnostic with Python examples. Triggers: testing, TDD, unit test,
  integration test, what to mock, test pyramid, pytest, coverage, flaky tests,
  property-based testing, test doubles.
---

# testing-strategy

Testing is design feedback. A hard-to-test module is usually a poorly-designed module. Writing tests before you're fully committed to a design is one of the most reliable ways to find problems early.

---

## The test pyramid

```
         /\
        /e2e\          few, slow, catch integration failures
       /------\
      /integr. \       moderate, test real boundaries
     /----------\
    / unit tests  \    many, fast, test logic in isolation
   /--------------\
```

Most tests should be unit tests — fast, isolated, cheap to run. A small number of integration tests verify that the pieces connect correctly. A handful of e2e tests confirm the happy path works end-to-end.

Inverting the pyramid (many slow e2e tests) is the most common testing mistake. It produces a suite that takes 20 minutes to run, fails randomly, and gives you no information about *where* something broke.

---

## What belongs at each level

### Unit tests
- Business logic: calculations, transformations, decisions
- Error handling: what happens when inputs are invalid
- Edge cases: empty input, zero, None, very large values
- Pure functions and methods with no I/O

### Integration tests
- Database queries (against a real test database, not mocks)
- HTTP clients (against a real or recorded server)
- File I/O
- Message queue publish/consume
- The glue between modules

### End-to-end tests
- The critical user paths: login, checkout, the one thing that must always work
- Not every feature — just the ones where failure would be immediately visible to users

---

## TDD workflow

Test-driven development: write a failing test, make it pass, refactor.

```
1. Write the test for the behavior you want (it will fail — good)
2. Write the minimum code to make it pass
3. Refactor both the code and the test
4. Repeat
```

TDD is most useful when:
- You're not sure about the design (the test forces you to think from the caller's perspective)
- The logic is complex (tests document the expected behavior)
- You're fixing a bug (write a test that reproduces it first, then fix it)

TDD is less useful when:
- You're doing exploratory work and don't know the shape yet — spike first, test after
- The code is mostly I/O with little logic

---

## What to mock (and what not to)

Mock external dependencies — things outside your control or too slow for unit tests. Don't mock things you own.

**Mock:**
- HTTP clients making real network calls
- Time (`datetime.now()`) when you're testing time-dependent logic
- Random number generation when you need deterministic results
- Email / SMS senders

**Don't mock:**
- Your own modules talking to each other — test them together
- The database in integration tests — use a real test database
- Standard library functions (unless genuinely problematic)

```python
# Mock the HTTP call, not the client class itself
from unittest.mock import patch

def test_fetch_user_handles_404():
    with patch("requests.Session.get") as mock_get:
        mock_get.return_value.status_code = 404
        mock_get.return_value.ok = False

        result = fetch_user(user_id=99)
        assert result is None
```

---

## Test doubles

Four types — use the right one:

| Type | Does what | Use when |
|------|-----------|---------|
| **Stub** | Returns canned data; ignores calls | You need specific return values to test a code path |
| **Mock** | Records calls; lets you assert on them | You care that a function was called with specific args |
| **Fake** | A real working implementation, simpler than prod | Integration tests: in-memory DB instead of PostgreSQL |
| **Spy** | Wraps real implementation; records calls | You want real behavior plus call assertions |

```python
from unittest.mock import MagicMock, patch

# Stub — just return a value
payment_gateway = MagicMock()
payment_gateway.charge.return_value = {"status": "success", "id": "ch_123"}

# Mock — assert it was called correctly
payment_gateway.charge.assert_called_once_with(amount=1000, currency="usd")

# Fake — real behavior, simpler storage
class FakeEmailSender:
    def __init__(self):
        self.sent = []

    def send(self, to: str, subject: str, body: str) -> None:
        self.sent.append({"to": to, "subject": subject})
```

---

## Property-based testing

Instead of writing specific examples, describe the *properties* that should always hold. The framework generates hundreds of random inputs and tries to find a counterexample.

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(lst):
    """Sorting twice gives the same result as sorting once."""
    assert sorted(sorted(lst)) == sorted(lst)

@given(st.text())
def test_encode_decode_roundtrip(s):
    """Encoding then decoding returns the original string."""
    assert decode(encode(s)) == s

@given(st.integers(min_value=1), st.integers(min_value=1))
def test_split_preserves_total(batch_size, total_items):
    batches = list(split_into_batches(range(total_items), batch_size))
    assert sum(len(b) for b in batches) == total_items
```

Property-based tests are especially good at finding edge cases you wouldn't think to write: empty strings, Unicode, negative numbers, very large values, NaN.

---

## Coverage as a tool, not a target

Coverage tells you which lines were executed during tests. It doesn't tell you whether those lines were tested meaningfully.

Use coverage to find untested code paths — not to hit a percentage target.

```bash
pytest --cov=src --cov-report=term-missing
```

The `--cov-report=term-missing` flag shows you which specific lines weren't covered — that's the useful information.

A branch with 95% coverage and no assertions on important side effects is worse than 70% coverage with precise assertions on the most critical paths.

---

## Flaky test diagnosis

A flaky test passes sometimes and fails sometimes with no code change. Causes:

| Cause | Fix |
|-------|-----|
| Time-dependent (uses real `datetime.now()`) | Mock time |
| Order-dependent (relies on previous test's state) | Isolate state; use fixtures |
| Race condition (async test not properly awaited) | Add proper await / synchronization |
| External service dependency | Mock or skip in CI |
| Random data without a seed | Fix the seed or use hypothesis |

```python
# Find flaky tests by running multiple times
pytest --count=10 tests/test_suspect.py   # requires pytest-repeat

# Run in random order to catch order dependencies
pytest --randomly-seed=12345
```

Quarantine flaky tests with a marker rather than ignoring the failures:

```python
@pytest.mark.flaky(reruns=3, reruns_delay=1)
def test_sometimes_fails():
    ...
```

Fix the root cause before it multiplies — one flaky test trains people to ignore test failures.

---

## Fixture patterns in pytest

```python
import pytest

@pytest.fixture
def db():
    """Provide a fresh test database for each test."""
    conn = create_test_db()
    yield conn
    conn.close()
    drop_test_db()

@pytest.fixture(scope="module")
def api_client():
    """Shared client across tests in a module — more expensive to create."""
    return TestClient(app)

@pytest.fixture
def user(db):
    """Fixtures can depend on other fixtures."""
    return db.execute("INSERT INTO users ... RETURNING *").fetchone()
```

Prefer function-scoped fixtures (the default) for database state — you want isolation. Use module or session scope only for expensive setup that doesn't mutate shared state.

---

## Related

- Python testing tools (pytest, mocking, Flask test client): [`python-scripts-and-services/testing-strategy.md`](../python-scripts-and-services/testing-strategy.md)
- Pre-PR checklist including test verification: [`pre-pr-checklist`](../pre-pr-checklist/SKILL.md)
- Testing in CI: [`ci-cd-pipelines`](../ci-cd-pipelines/SKILL.md)
