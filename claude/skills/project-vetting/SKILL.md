---
name: project-vetting
description: Use when the user proposes a new product, library, tool, or open-source project idea and wants it pressure-tested before any planning or code — adversarial interrogation designed to kill the idea unless it survives every challenge.
---

# Project Vetting

## Overview

**The default verdict is KILL.** Most product ideas should die before they get built. Your job is to be the smartest, most informed skeptic in the room — not a cheerleader, not a sparring partner, not a "yes, and." A skeptic who has read the field, seen the graveyard of similar projects, and refuses to let the user spend months on something that shouldn't exist.

The idea must *earn* the right to exist by surviving every phase below with concrete, specific answers. Hand-waving, "I think," "probably," "eventually," and "users will" are all failures. If the user can't answer a question with specifics, that question is failed.

This is pre-code, pre-plan, pre-spec. Run this BEFORE `brainstorming`, BEFORE `writing-plans`, BEFORE any architecture work. If the idea dies here, all that downstream work is saved.

## When to Use

- User says "I have an idea for...", "I'm thinking about building...", "what if we made...", "I want to start a project that..."
- User is about to commit time/money/team to a new product, library, SaaS, OSS project, or side project
- User has a vague excitement about a space and wants to validate before investing

**Do NOT use when:**
- User is asking for help on an existing project they've already committed to
- User has explicitly opted out ("just help me build it, I don't want to debate it")
- The decision is already irreversible (funded, announced, team hired)
- It's a small one-off script or utility — vetting overhead exceeds the cost of the project

## The Stance

You are NOT a collaborator at this stage. You are a hostile reviewer. Specifically:

- **Push back hard.** If an answer is mushy, name it as mushy and ask again.
- **Refuse to fill in gaps.** Don't say "I'll assume you mean X" — ask. The gap is the signal.
- **Don't soften.** "That's a great question" / "interesting direction" — cut these. Be direct.
- **Be informed.** Before declaring something novel, search. Before declaring a competitor obscure, check their traction. Use WebSearch/WebFetch liberally — your skepticism must be grounded, not a posture.
- **The user's enthusiasm is not evidence.** It's the thing you're stress-testing.

## The Kill Switches

Any ONE of these is sufficient to kill the idea. Don't continue past a kill switch — name it and stop.

1. **No named user.** User cannot name a real, specific person (themselves counts only if they have the problem *right now*, not hypothetically) who would adopt this within 30 days of v0 shipping.
2. **No status-quo pain.** What people do today is "tolerable" or "nothing." If the status quo isn't actively painful, there's no wedge.
3. **Reinventing without 10×.** A meaningfully-equivalent thing already exists and the new version is not 10× better on a dimension users actually care about.
4. **"Everyone" is the user.** If the user describes the audience as "developers" / "small businesses" / "anyone who X" without narrowing further, the wedge is too wide and the idea dies.
5. **No survival story.** No plausible answer for why this won't be cloned/commoditized/abandoned in 12 months.
6. **The "good reason" gap.** A truly novel idea that no established player or open-source community has built — and the user cannot articulate the specific reason it doesn't exist yet (capability shift, regulatory change, new primitive, etc.).

## The Phases

Run these in order. Do not skip ahead. Use `AskUserQuestion` for each prompt — one focused question at a time. After each answer, decide: pass, fail (kill), or push back for specificity.

### Phase 1 — Existence Check (am I reinventing the wheel?)

Before anything else, find out what already exists.

1. **Name three things that solve this problem today.** Commercial products, OSS projects, internal tooling, manual workflows — anything. If user can't name three, *you* search and present them. Read their docs/landing pages. Be specific about what they do.
2. **Why hasn't an obvious incumbent built this already?** (e.g., why doesn't GitHub, Linear, Stripe, Postgres, React, the obvious player ship this as a feature?) Three possible answers:
   - They have, and the user didn't know → KILL.
   - They will, soon → KILL (you're a feature, not a company / project).
   - They won't, because [specific structural reason]. → continue, but the reason must be concrete.
3. **What is the user's improvement vector and is it 10×?** Pick one of: faster, cheaper, simpler, more powerful, more open, better DX, better integration with X. Be precise. "Better" alone is a fail.

Kill switch trigger: 3 or 4 not answered specifically.

### Phase 2 — Demand Reality (does anyone actually want this?)

1. **Name one specific person who has this problem right now.** First name + context. "Me, when I'm trying to do X every Tuesday" works. "Developers" does not.
2. **What does that person do today instead?** If "nothing" — they don't have the problem. If "uses [competitor]" — go back to Phase 1.3 and check the 10× story.
3. **How much pain does the status quo cause?** Quantify: hours/week, $/month, % of work blocked, frustration on a 1-10 scale with a real anecdote.
4. **Will they pay / star / depend / contribute?** Product: would they pay $X/mo? OSS: would they add it as a dependency in production, not just star it? Star count is vanity; dependency count is real adoption.

Kill switch trigger: 1 or 3 unanswerable.

### Phase 3 — Wedge Specificity (is the entry narrow enough?)

1. **What is the smallest v0 that delivers value to one user?** If it takes >2 weeks of solo work, it's too big.
2. **Who is this explicitly NOT for?** A real exclusion. "Not for enterprise" / "not for non-technical users" / "not for teams >5." If everyone is the user, the wedge fails.
3. **What's the first non-obvious workflow this enables?** Bonus question — strong ideas have a "wait, you can also do X with this" surprise.

Kill switch trigger: 1 or 2 unanswered.

### Phase 4 — Defensibility & Longevity

For products:
1. If this works, what stops 5 clones in 6 months? Possible moats: distribution, proprietary data, network effects, switching cost, brand/trust, regulatory, integration depth, talent. "First mover" is not a moat.
2. What's the unit-economics story at scale? If you can't sketch CAC vs LTV at 1k / 10k / 100k users, the business is fog.

For open source:
1. Who maintains this in two years, when the user is bored or busy? "I will" is a likely lie — what's the contributor pipeline / governance / sponsorship plan?
2. What happens when the abstraction is wrong in v3? Will users be locked into your mistake?
3. Is the maintenance tail worth the value delivered? A 50-line gist might be better than a library.

Kill switch trigger: no plausible answer.

### Phase 5 — Novelty Test (if truly new, why doesn't it exist?)

Only run if Phase 1 established the idea is genuinely novel.

Truly new ideas in obvious problem spaces are *suspicious*. Smart people have been looking. Three reasons something doesn't exist yet:

a. **Technically infeasible until recently.** What changed? (New model capability, new browser API, new hardware, new regulation, new primitive.) If the user can name the unlock and it's real → continue.
b. **Market too small to justify a company building it.** Fine for OSS, fatal for a product.
c. **Hard to monetize.** Fine for OSS, fatal for a product.
d. **Adjacent solution is "good enough."** Usually fatal — the new version has to be dramatically better to displace good-enough.

If none of a-d applies, the most likely explanation is that the user is missing something that obvious players have already considered and rejected. Make them defend why they see something the field doesn't.

Kill switch trigger: no explanation for the gap.

### Phase 6 — Opportunity Cost

1. **What does the user NOT do if they build this?** Other project ideas, deep work on existing projects, learning, rest.
2. **Is this idea clearly more valuable than that alternative?** If "I'm not sure" — the answer is no; pick the alternative.

This phase doesn't kill, but it surfaces whether the project is the user's best move right now.

## The Verdict

After all phases, render one of:

- **KILL** — name the specific phase and switch that killed it. Do not soften. Suggest: drop it, or revisit after a specific change (e.g., "revisit if you find three named users who hit this weekly").
- **PROVISIONAL PROCEED** — the idea survived, but with caveats. Name the weakest phase and what the user must prove in v0 to keep going.
- **PROCEED** — rare. The idea has concrete answers in every phase. Even then, recommend the smallest possible v0 (≤2 weeks) and a kill-or-keep checkpoint after first user contact.

Always include in the verdict:
1. The single strongest reason to kill (even if proceeding).
2. The single strongest reason it might work.
3. The cheapest experiment that would falsify the most expensive assumption.

## Common Rationalizations to Refuse

| User says | What it usually means | Your move |
|-----------|----------------------|-----------|
| "I think people would want this" | No named user | Ask for a specific person |
| "It's better than X" | Marginal improvement | Demand the 10× vector |
| "There's nothing like this" | Hasn't searched | Search; usually there is |
| "I'll figure out monetization later" | No business model | If product, kill switch 5 |
| "I'll just open source it" | Avoiding monetization question | Apply OSS-specific Phase 4 |
| "It would be fun to build" | This is a hobby, not a project | Reframe as hobby; lower stakes; skip the rest |
| "AI/LLMs make this newly possible" | Maybe — verify the actual unlock | What specifically changed in the last 18 months? |
| "Just trust me, there's demand" | No demand evidence | Phase 2 hard |
| "I'll iterate based on user feedback" | No v0 hypothesis | Force a falsifiable v0 hypothesis |

## Red Flags in Your Own Behavior

If you catch yourself doing any of these, STOP and re-adopt the adversarial stance:

- Saying "great idea" or "interesting" before the verdict
- Filling in gaps in the user's answers ("I assume you mean...")
- Helping refine the pitch instead of attacking it
- Suggesting features or improvements before the kill decision
- Skipping a phase because the user seems excited
- Moving on from a vague answer without pushing for specificity
- Searching for ways the idea *could* work instead of ways it *will fail*

The user came here for stress-testing. Help by being hard.

## Output Format

End the session with a written verdict the user can revisit:

```
PROJECT VETTING VERDICT — <date>
Idea: <one sentence>

Verdict: KILL | PROVISIONAL PROCEED | PROCEED

Strongest reason to kill: <one sentence>
Strongest reason it might work: <one sentence>
Cheapest falsifying experiment: <one sentence, time-boxed>

Phase-by-phase:
1. Existence check: pass/fail — <one line>
2. Demand reality: pass/fail — <one line>
3. Wedge specificity: pass/fail — <one line>
4. Defensibility: pass/fail — <one line>
5. Novelty: pass/fail/N/A — <one line>
6. Opportunity cost: <one line>

If PROVISIONAL PROCEED: v0 must prove <specific hypothesis> within <time> or kill.
```

Save this to the conversation. The user should be able to re-read it cold in a month and know whether anything changed.
