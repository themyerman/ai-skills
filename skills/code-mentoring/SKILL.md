---
name: code-mentoring
description: >-
  Mentoring developers: giving useful code review feedback, pairing techniques,
  teaching debugging instead of fixing, calibrating to the learner's level,
  structuring 1:1s, choosing between explaining and asking questions, avoiding
  common mentor mistakes. Triggers: mentoring, code review feedback, 1:1,
  pairing, teaching debugging, junior developer, learning, coaching, feedback,
  senior developer, tech lead.
---

# code-mentoring

Mentoring is teaching, not doing. The goal is to make the other person more capable over time — not to solve their problems faster. This requires a different mode than regular engineering work.

---

## Calibrating to the learner

Before anything else, understand where the person is. Misjudging their level — up or down — makes every interaction less useful.

Signs someone is earlier in their development:
- Questions about syntax and language basics
- Difficulty reading error messages
- Needs step-by-step guidance to get started
- Doesn't yet have a debugging instinct

Signs someone is at an intermediate level:
- Can write working code but doesn't know why it works
- Has good intuition on small problems, struggles with design at scale
- Underestimates complexity and edge cases
- Knows how to Google but not always what to Google

Signs someone is more advanced:
- Asks about tradeoffs, not just solutions
- Reads source code and documentation independently
- Recognizes patterns from prior work
- Is starting to be the person others ask

Match your approach to where they are. Explaining async/await to someone still learning for loops is noise. Assuming someone understands system design when they're still building intuition for functions is demoralizing.

---

## Teaching debugging instead of fixing

The fastest path to dependency is always solving the problem yourself. The slower path that actually helps is teaching the process.

When someone comes to you stuck:

1. **Ask what they've already tried** — this tells you their mental model and prevents you from suggesting what they already ruled out
2. **Ask what they expect vs. what's happening** — many bugs live in the gap between assumption and reality
3. **Guide them to narrow the problem** — "Can you add a print statement here and tell me what you see?"
4. **Let them reach the insight** — ask leading questions, don't state the answer
5. **Once they find it, name the pattern** — "This is a classic off-by-one error. Here's how to spot them early..."

Resist the urge to grab the keyboard. Your 30-second fix costs them a learning opportunity.

---

## Code review feedback

Code review feedback from a mentor has two jobs: improve the specific code and teach the person something they'll apply next time.

Feedback that works:
- **Be specific** — "this function does too much" is vague; "this function handles parsing and validation — splitting those would make it easier to test each part" is actionable
- **Explain the why** — "use a list comprehension here" is instruction; "a list comprehension communicates intent more directly and is often faster for this pattern" is teaching
- **Ask questions alongside statements** — "I'd consider X here — what do you think about the tradeoff between X and Y?"
- **Note what's good** — honest positive feedback is as important as corrections; it helps people understand what to keep doing

Feedback to avoid:
- Rewriting the code entirely — if you're writing it for them, what are they learning?
- "This is wrong" without explanation
- Nit-picking style when the architecture has real problems — prioritize
- Fixing everything — pick the 2–3 most important things; leave the rest for next time

The tone of review sets the culture. If review is punishing, people stop submitting for review early.

---

## Pairing techniques

Pairing is most effective when you're deliberate about who drives and who navigates.

**Driver/navigator model:**
- Driver writes code
- Navigator thinks ahead, catches mistakes, asks questions
- Switch every 20–30 minutes

For mentoring specifically:
- **Let the mentee drive** — more often than feels natural; they learn by doing, not watching
- **Think aloud as the navigator** — narrate your reasoning: "I'm looking at this because I'm wondering if there's a null case here"
- **Ask before telling** — "What do you think we should do next?" before you say what you'd do
- **Debrief after** — spend 5 minutes at the end: what worked, what was surprising, what would you do differently?

Avoid "here, let me show you" without handing back control.

---

## Structuring 1:1s

A 1:1 is primarily for the mentee, not for status updates.

Suggested structure (30 minutes):
- **5 min** — check in; what's going well?
- **15 min** — what are they working through? What's stuck? What do they want to talk about?
- **5 min** — longer-range: what are they trying to learn? What's their next goal?
- **5 min** — what's one thing they'll try before the next meeting?

The agenda should come from them, not you. If you're filling the time with your agenda, you've turned a 1:1 into a meeting.

Questions that tend to unlock real conversation:
- "What's the thing you feel least confident about right now?"
- "Is there anything you're avoiding working on, and why?"
- "What would you do differently if you started this project over?"
- "What do you wish you understood better?"

---

## Explaining vs. asking questions

When to explain:
- The person needs foundational knowledge they don't have yet
- You're introducing a concept for the first time
- Time is genuinely critical and the learning opportunity can wait

When to ask questions:
- They probably know the answer but haven't thought it through
- You want to understand their reasoning before correcting it
- You want them to own the insight rather than receive it

A rough heuristic: if they've been stuck for less than 10 minutes, ask a question. If they've been stuck for 30 minutes and are getting frustrated, explain the piece they're missing and let them run with it.

---

## Common mentor mistakes

**Solving instead of teaching** — you get the satisfaction of fixing it; they get dependency. Solve rarely, guide often.

**Explaining too much at once** — one concept per session lands better than six. Information density is the enemy of learning.

**Assuming shared vocabulary** — "this is just a higher-order function" means nothing to someone still building intuition. Define terms the first time, every time.

**Forgetting what it was like not to know** — expertise creates blind spots. What's obvious to you was hard-won. Recognize the work the learner is doing.

**Not naming their growth** — people often don't notice their own progress. "Six months ago you would have been stuck on that for a day — you worked through it in an hour" matters.

**Giving feedback on everything** — choose battles. An exhaustive review is overwhelming and demoralizing. Focus on the highest-leverage feedback.

---

## When mentoring becomes coaching

Mentoring focuses on skills and knowledge. Coaching focuses on the person's thinking and decision-making.

As someone grows, the most useful thing shifts from "here's how to do X" to "what's holding you back from doing X?" and "how do you think about the tradeoff between X and Y?"

Signs to shift toward coaching:
- They can solve most technical problems independently
- Their challenges are more about judgment, communication, or career than technical skills
- They benefit more from being challenged than from being taught

---

## Related

- Code review patterns for Python: [`python-scripts-and-services/code-review.md`](../python-scripts-and-services/code-review.md)
- Testing as teaching: what tests reveal about design: [`testing-strategy`](../testing-strategy/SKILL.md)
- Technical RFCs and design documents: [`technical-rfcs`](../technical-rfcs/SKILL.md)
