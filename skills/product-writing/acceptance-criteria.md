# Writing acceptance criteria

**Hub:** [SKILL.md](SKILL.md)

Acceptance criteria are done when a tester can run them without asking you what "works correctly" means.

---

## 1. The test: is it binary?

Good AC has a clear pass or fail. If you have to make a judgment call to evaluate it, it's not done yet.

- **Bad:** "The form works correctly."
- **Bad:** "The page loads quickly."
- **Good:** "Submitting the form with a missing required field shows an inline error on that field and does not submit."
- **Good:** "The page loads in under 2 seconds on a 4G connection."

---

## 2. Two formats

**Given / When / Then** — useful for behavior with preconditions:

```
Given [a context or starting state]
When [the user does something]
Then [the observable outcome]
```

Example:
```
Given the user is not logged in
When they visit /account
Then they are redirected to /login with a return URL parameter
```

**Plain statement** — fine for simpler criteria:

```
- Deleting an item asks for confirmation before removing it.
- The confirmation dialog includes the item name.
- Cancelling the dialog leaves the item unchanged.
```

Use whichever is clearer for the specific criterion. Don't force Given/When/Then on simple statements.

---

## 3. What to cover

For each story or feature, write criteria for:

- **The happy path** — the thing working as intended.
- **Edge cases** — empty states, maximums, single items vs. lists.
- **Error states** — what happens when input is invalid, a request fails, or something is missing.
- **Permissions / access** — who can and can't do the thing.

If the error state isn't specified, engineers will invent something and it probably won't match the design.

---

## 4. Common mistakes

**Vague outcomes:**
- Bad: "User sees a success message."
- Good: "User sees 'Changes saved' in the page header for 3 seconds, then it disappears."

**Testing implementation, not behavior:**
- Bad: "The API returns a 200 status code."
- Good: "The user's name updates immediately on screen without a page reload."

**Missing error states:**
Writing only the happy path and leaving error handling undefined is the most common gap. Add at least one error criterion per story.

**Combining multiple behaviors in one criterion:**
Each criterion should test one thing. If your criterion has "and" in it twice, split it.

**Criteria that require a human judgment call:**
- Bad: "The layout looks good on mobile."
- Good: "On viewports narrower than 480px, the two-column layout stacks to a single column."

---

## 5. Where they live

AC can live in the spec, in the ticket, or both (with the ticket as the authoritative source once work starts). What matters: the engineer and tester are looking at the same list.

Don't write AC after the feature is built. If you're writing them to describe what was already shipped, you're writing documentation, not criteria.
