# Domain docs

How the skills in `.agents/skills/` read this repo's domain documents (issue 1658).

- **`GLOSSARY.md`** at the repo root: the project's words. One context only (no GLOSSARY-MAP.md). Use its terms in issue
  titles, specs, reviews and code names; add a term when a new one is settled.
- **Decisions are not ADRs here.** Every rule in force, with its reason, is in `docs/RULEBOOK.md`; the dated rulings are
  rows in `contrib/opus/FINDINGS.md`. Never create `docs/adr/`. Where a skill says "offer an ADR", propose a RULEBOOK or
  playbook edit with a FINDINGS row instead (R214), and remember only Ryan makes rulings.
- Area playbooks are in `docs/playbooks/` (PROGRAM.md first). Nothing under `docs/archive/` is followed.
