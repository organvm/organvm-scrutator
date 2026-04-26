# THE THREE FILTERS — Conversational Prompt Chain
## My Voice, Preserved

---

## THE THREE FILTERS

### Filter 1: RAW ABSTRACTION

**State:** Direct from head to output. No formatting, no domain, no polish.
**My voice, unfiltered:**

"What did we do so far?"

"If there's no data or statistics to prove whichever answer is the best one, then it's an opportunity for studying and figuring it out."

"Plan every single element, every spec, every grain, every micro, every cog. Plan everything out. Make research documents. Make SOPs. Claude is the master, so we just do what we can while he's away. He's going to clean up everything anyway, so we just do our best. Get crazy if you want; be innovative, strange."

"Name each entity's pathos, logos, and ethos: its existence, its failings for improvement. These are all like stats that will live, so like health, your blood pressure, shit like that."

"Provide the prompt chain for session raw, cleaned, elevated; prompts intent to mutiversal metaphysical full knowing before speaking of ideal survey of is was will"

---

### Filter 2: DOMAIN FORMALIZATION

**State:** Translated into current working context. Structured, actionable, domain-specific.

*Example transformation:*

**RAW (Filter 1):**
"what did we do so far?"

**FORMALIZED (Filter 2):**
```
Session History:
- IRF updated with 479 items across 21 domains
- 3 GitHub repos created and pushed
- Entity Vital Signs Registry established

Context loaded from prior sessions:
- Stream Τ: organvm CLIs + pre-commit hooks (in progress)
- Layer Above Hokage design (in progress)
- Stream Ω: 72h subatomic atomization (pending)
```

The formalization maintains the **intent** of the original but structures it for operational use.

---

### Filter 3: PURE IDEA / GENERALIZABLE

**State:** What is the BIGGER IDEA? Extract the universal principle that applies beyond this session, this domain, this moment.

*Example transformation:*

**RAW (Filter 1):**
"get crazy if you want; be innovative, strange"

**FORMALIZED (Filter 2):**
"Build organvm-scrutator with complete architecture"

**PURE IDEA (Filter 3):**
> "Every unknown is a research opportunity. The system must measure its own ignorance."

This principle applies to:
- Governance (what don't we track?)
- Research (what don't we know?)
- Personal knowledge (what gaps exist?)
- System design (what's missing from the model?)

---

## THE CHAIN IN PRACTICE

### Session Start (Filter 1 → 2 → 3)

**My Input (Filter 1 - RAW):**
> "What did we do so far?"

**Context (Filter 2 - Formalized):**
Session summary loaded from prior context. 8 work items in progress. IRF at 951 items. 3 personas seeded.

**Pure Idea (Filter 3):**
> "Continuity requires artifact-level memory, not volume summaries. Session handoff is context injection."

---

### Mid-Session (Filter 1 → 2 → 3)

**My Input (Filter 1 - RAW):**
> "Plan every single element... get crazy if you want"

**Formalized (Filter 2):**
25 files created in organvm-scrutator. Full Python package, 3 SOPs, research doc, CI pipeline.

**Pure Idea (Filter 3):**
> "The acknowledgment of ignorance is the beginning of wisdom. Build the system that measures its own measurement gaps."

---

### Session End (Filter 1 → 2 → 3)

**My Input (Filter 1 - RAW):**
> "all the N/As suggest something imperative; it means there is a vacuum where something should be"

**Formalized (Filter 2):**
- 8 entities tracked with pathos/logos/ethos
- Aggregate scores: Pathos 0.46, Logos 0.79, Ethos 0.69
- IRF-SYS-158, IRF-SYS-159 added
- Done-ID counter → 490

**Pure Idea (Filter 3):**
> "N/A is a vacuum. Research it, plan it, log it. Never a resting state."

---

## MY UNIQUE VOICE — WHAT GETS PRESERVED

### Conversational Markers
- Direct questions ("What did we do?")
- Imperative bursts ("Get crazy if you want")
- Rule statements ("N/A is a vacuum")
- Vulnerability admissions ("we just do our best")
- System-aware meta ("Claude is the master")

### Linguistic Patterns
- Pathos-first: emotional resonance before logic
- Metaphor mixing: governance = body, system = organism
- Rule density: constitutional axioms, operational laws
- Compression: dense abstraction prompting (packed meanings)

### Metadata Preserved
- Session ID (S-2026-04-26-*)
- Timestamp
- DONE-ID claims
- IRF updates
- Git commits

---

## IMPLEMENTATION

To preserve this chain:

```python
# Filter 1 → Filter 2: Formalization
def formalize(raw_text, domain_context):
    """Keep intent, structure for domain"""
    return {
        "raw_preserved": raw_text,
        "domain_context": domain_context,
        "formalized": extract_structure(raw_text),
        "intent": capture_intent(raw_text)
    }

# Filter 2 → Filter 3: Elevation  
def elevate(formalized):
    """Extract pure idea, generalize"""
    return {
        "formalized": formalized,
        "pure_idea": extract_universal_principle(formalized),
        "applications": find_applications(formalized["pure_idea"]),
        "generalizability": assess_broad_applicability(formalized)
    }

# Filter 3 → Filter 1: Re-grounding
def reground(pure_idea, new_context):
    """New raw input inspired by pure idea"""
    return generate_raw_text(pure_idea, new_context)
```

---

## THE THREE FILTERS — SUMMARY

| Filter | Input | Output | Preserves |
|--------|-------|--------|-----------|
| **1. RAW** | My voice direct | Unfiltered abstraction | Intent, emotion, urgency |
| **2. FORMALIZED** | Structured context | Domain-actionable | Structure, dependencies |
| **3. PURE IDEA** | Universal extraction | Generalizable principle | The "why", applicability |

**The chain:** Raw → Formalized → Pure Idea → (reground to new Raw)

Each filter preserves what matters:
- Filter 1: **What I meant**
- Filter 2: **What to do**
- Filter 3: **Why it matters**