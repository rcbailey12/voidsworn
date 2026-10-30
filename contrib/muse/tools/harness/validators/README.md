# Voidsworn data validators (chair-built, for Opus to review)

Status: DRAFT for Opus review, Oct 29, 2026. Wave 2 of the savings-pass
program. Plain Node, no dependencies; table_xref loads the shipped tables
through ../game_loader. Neither script changes game code or data.

## table_xref.js

Structural cross-reference checks over data.js: faction rosters and
bosses exist in HULLS and agree on fac; hull and variant weapon ids and
arcs exist; variant bases exist; admiral factions and start hulls check
out (including foreign-hull starts); boon patrons and BOON_NEED keys
resolve; module ability gates name real hull abilities; RELIC_NAMES rows
and keys resolve; FAC_PRICE and FAC_GATES rows are real factions.

Run: `node table_xref.js [repoDir]`. Exit 1 on any dangling reference.

Results at filing (rules code at main 264f441d): 0 failures, 11 warnings.

- The relic display-name coverage warnings independently reproduce the
  corrected counts from the Oct 29 relics audit (Sunward Crusade 0 of 12,
  Hegemony 11, Ashfall Hullbreakers 10, The Chorus 11, The Glasswrights
  8, Eclipse 10), cross-validating the chair pack correction that audit
  produced.
- Four capital-class price gaps: corsair Battle-barge, chorus Bio-titan,
  ithar Ark and deathless Tomb-ark have no FAC_PRICE key while their
  factions' rows price the rest of the line, so those classes fall back
  to x1. Boss hulls are not shop purchases today, so this is latent; it
  is the same mechanism the Oct 29 faction-shape audit caught around the
  ruled Eclipse battleship (a purchasable capital hull pricing at the
  fallback, below the faction's own cruiser). The check exists so the
  next capital hull added to a roster trips it at data time.
- One new id collision beyond the audited cogitator: 'spore' exists in
  both HULLS (the Chorus wing template) and RELICS (the regen relic).
  It follows the same namespace-explicit pattern as cogitator, but the
  chair has not verified every consumer, so it is left as a warning for
  Opus to confirm rather than allowlisted here.

Calibration note: the first run produced a false failure on the Chorus
squadron (FACTIONS.chorus.sq is 'spore'). Reading the launch code showed
F.sq is a HULLS key whose template flies a role from its own sq field
(the spore template flies bomber), so the check now asserts exactly
that. The warning set was likewise narrowed from every unpriced class
(sparse price rows are a design tool) to capital classes only.

## naming_lint.js

Scans prose documents for retired display names, so a stale name in a
living document is caught at edit time. Hard hits (exit 1) are exact
retired strings with one correct replacement: Mending Choir, Discordant
volley, Steelgrin. Label candidates (warnings) are capitalized old
faction labels (Deathless, Ithar, Corsair) in lines with no code or
rename marker; lines carrying such a marker count as historical or id
mentions (info only). 'Voidsworn' is never flagged: it is the game's
title; only the faction display name changed.

Default targets are the current-voice set: the root docs and docs/.
Filed records (contrib reviews, the rename map, the lore bible) are
history and are not default targets. naming_allowlist.json exempts
docs/archive (dated records) from the label patterns; extend it per
file substring when a living document must quote an old name.

Run: `node naming_lint.js [--allow file.json] [target ...]`.

Results at filing (with the shipped allowlist): 1 hard hit (BACKLOG.md
still lists a direction item for the "Mending Choir"; the same
staleness class the naming QA pass found in OPUS_HANDOFF, since
mitigated there by the names addendum), 100 current-voice label
candidates concentrated in PROGRESS.md, BACKLOG.md, HANDOFF.md,
CLAUDE.md, AGENTS.md and docs/ship_pipeline, and 13 historical or id
mentions. The candidates are a triage list for
a human pass, not auto-fixes: several are kit and pipeline shorthand
where the old label names a visual style rather than the faction.
