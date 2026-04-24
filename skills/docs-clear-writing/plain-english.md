# Plain English and layman-friendly wording

**Hub:** [SKILL.md](SKILL.md) · **Sister file:** [reference.md](reference.md) (task structure) · **Leadership** tone: [executive-reports](../executive-reports/SKILL.md)

**Plain English** here means: a **literate reader** can get the right idea **on the first pass**, without a glossary for everyday sentences. It does **not** mean chit-chat, jokes, or long-winded “helpful” asides. Stay **professional**, **concrete**, and **calm**.

---

## 1. What this approach is (and is not)

| Aims to | Does not mean |
|--------|----------------|
| **Favor common words** when they carry the same meaning as a rare one | Talking down to **experts**; **dumbing down** **precision** you truly need |
| **Define once**, then re-use a **term of art** (Jira, program security gate, WAF, RPO) | Avoiding **domain terms**; leaving **acronyms** unexpanded |
| **Short sentences** when a thought is **complete** | Staccato one-line **telegraph** in place of a needed **if/then** |
| **Active voice** for who does what (especially in runbooks) | A **chatty** “Hey team!” or **forced** collegiality |
| **Concrete** next steps, names of systems, links | **Cute** metaphors, memes, or “folksy” **fill** that adds **time** to read |

---

## 2. Jargon: when to use it

- **Introduce** a **specialist term** the first time: **“**Security **Planning** (design review before you ship large changes)**”** or **acronym (A B C)**. After that, use the **short** form **consistently** in the doc.  
- If **two** audiences (e.g. **eng** and **ops**) share a page, a **one-line** “**Term:** meaning” in a box at the top can replace scattered definitions.  
- If only **peers** will read it, you may **open** in **jargon**—**still** add a **2-sentence** **abstract** or **“For non-…”** pointer for **triage** and **search** discoverability.  
- **Do not** replace a **defined** program term (your org’s **official** name for a **security** or **SDLC** **gate** **,** and so on) with a **vague** “security review” if the **Jira** **component** or **policy** matters.

---

## 3. Verbs and clutter

- Prefer **run**, **set**, **open**, **turn on**, **apply**, **remove** over **utilize**, **leverage**, **incentivize** when the simple verb works.  
- **Cut** filler: “It is **important to note** that** …**” → “**X** **affects** **Y**.” “In order to” → “**To**” when it is only purpose.  
- **Nominalizations** (long noun phrases) → verb where it helps: “**perform** an **implementation** of” → “**implement**” if that is all you mean.  
- **We / you:** **You** for the reader’s action; **we** only when you mean the **author** **team** or a **process** you **all** run—**don’t** **mix** in one sentence without intent.

---

## 4. Tone: professional, not flippant

- **Avoid:** slang that **dates** fast, **irony** on **safety** or **access** topics, exclamation marks in **procedures** (except **genuine** alerts: “**Do not** **skip** this.”).  
- **Avoid** **jocular** asides in **runbooks**; stress **kills** **focus**. Save **light** **tone** for **blogs** and **onboarding** **tours** if your org does that, not for **P1** steps.  
- **“Loquacious”** in practice: **multiple** subordinate **clauses** in **one** sentence, **repeated** “**which** means** …** which** in** **turn** …”—**split** or use a **list**.

---

## 5. One idea per line of sight

- In **procedures**: **one** **imperative** / **outcome** per **numbered** step. If you need a **sub-step**, use **(a) (b)** or **a** sub-list—**not** a **paragraph** **hiding** **three** actions.  
- In **explanations**: **define** the **phenomenon** before **consequences**; **if** the reader can **skip** **detail**, use **“** **Optional** **:**”** or **an** **appendix**.

---

## 6. Micro before/after (illustrative)

- **Before:** *It is recommended that, prior to executing the bulk action, the operator should take care to ensure that the preview mode has been engaged so as to avoid irreversible state changes to production issues.*  
- **After:** *Before you run **bulk** updates, **turn on** **preview**. Preview **does** **not** write to Jira.*

- **Before:** *We’re super excited to share that the new thing will hopefully make stuff better!*  
- **After:** *This change **adds** **X**. **Result:** **Y** for **Z** **users**.*

---

## 7. Where to apply

| Doc type | Plain-English check |
|----------|---------------------|
| [readmes](readmes.md) | **Quickstart** commands + **one** line **per** **concept** in the **what** / **why** **intro** |
| [installation-guides](installation-guides.md) | **Imperative** **steps**; **name** each **prereq** in **lay** terms the first time |
| [user-instructions-howto](user-instructions-howto.md) | **Symptom** → **action** in **common** words, then **link** to **deep** **tuning** if needed |
| [executive-reports](../executive-reports/SKILL.md) | **BLUF** + **limitations**; plain **headings**; **jargon** **gated** in **body** with **glossary** if needed |

---

## 8. Checklist (before you ship a page)

- [ ] **Key** **nouns** are things a **new** **reader** can **picture** (or are **defined**)  
- [ ] **Average** **sentence** **length** **bears** **rereading** out loud; **cut** or **break** the **rest**  
- [ ] **No** **cute** **or** **snide** on **safety** / **access** / **compliance**  
- [ ] **Acronyms** **and** program terms **on** a **leash** — **glossary** or **first**-use **expansion**  
- [ ] **This** file’s **sibling** [reference](reference.md) for **structure**; **this** file for **wording**

---

*Authored for **ai-skills**. Calibrate to your org’s comms and legal—this is a **default** for internal tools and runbooks, not a compliance-by-itself bar.*
