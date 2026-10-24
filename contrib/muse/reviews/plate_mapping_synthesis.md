# Plate-to-Terrain Mapping Synthesis (chair, SINGLE LEG)

Legs: contrib/deepseek/reviews/plate_mapping_deepseek_draft.md (DeepSeek).
Qwen leg PENDING: blocked Oct 24 by the Qwen3.8-Max daily limit, retry
scheduled Sun Oct 25 ~9:45 AM CDT. This synthesis will be updated to two
legs when the Qwen leg lands. Nothing in it is a ruling.

Chair verdict: GO WITH CONDITIONS (single-leg caveat applies throughout:
a second leg may move mappings, roles, or triggers).

## Headline
All 18 plates get exactly one home: the five anchors map to the five code
terrain kinds, the six variants inherit their parent's kind with one
show-instead rule each, and the six specials share a proposed
"anomaly" non-terrain role with one trigger each. The Dead Star call is
the conservative one and the right default: finale role, not a sixth
terrain kind and not a well mechanic, both of which the draft honestly
costs as new engine work rather than a mapping decision. The draft's
best habit is marking even the five anchor name matches PROPOSED, since
the brief never states one-to-one mapping outright.

## The real cost is not the mapping, it is the triggers
The mapping table is adoptable as a decision. The trigger rules are not
yet adoptable as a system, because every one of them presumes state
hooks that are nowhere verified against code or data:
- Variant rules presume faction home belt sectors, a storm rotation
  cycle with a crimson slot, per-sector battle recency (last 3 turns),
  home sectors flagged as ring worlds, home dockyards, and a finale
  boss with a phase 2.
- Special rules presume an anomaly fight/event system, unowned planet
  sectors, a cold rotation slot, destroyed planet markers, a pulse
  timer event, solar flare events, and sectors with no terrain owner
  after a boss fight.
Until Opus checks each hook, these read as a finished system and they
are not. Rules that fail both the code check and a build ruling should
be cut back to TBD placeholders, not shipped as if they work.

## Conditions
1. Opus hook check (the blocker): for each variant and special rule,
   report whether the state hook exists in code or data, or whether
   the rule needs a new system. The mapping table stands regardless;
   the triggers stand or fall on this check.
2. Dead Star role ruling: finale (this draft's recommendation) vs sixth
   terrain kind vs well mechanic. The finale role itself presumes a
   finale structure that is not established in the brief, so the ruling
   needs to cover the finale concept, not just the plate. If the well
   mechanic is chosen instead, Opus owes an estimate first: the draft
   lists well zone or terrain state, movement or pull or visibility
   rules, AI handling, UI and readability, balance, verification.
3. Anchor mechanism: Opus confirms how plates reference terrain kinds
   in code or data today, since even the name-match mappings are
   PROPOSED until that reference is confirmed.
4. "Anomaly" vocabulary: keep PROPOSED attached to the word wherever it
   appears until an anomaly system is ruled or confirmed, or it will
   harden into assumed vocabulary.

## Recommended next step
Opus runs the hook check in condition 1 across all twelve variant and
special rules and reports which are implementable as mapping, which
need new systems, and which should fall back to TBD. That report is
what turns this draft from a table into something shippable.

## Not checked
- The Qwen leg (pending retry) and any mapping, role, or trigger it
  proposes differently.
- Whether plates are referenced from code or data at all today.
- The finale concept, boss phases, and any event system the triggers
  presume.
