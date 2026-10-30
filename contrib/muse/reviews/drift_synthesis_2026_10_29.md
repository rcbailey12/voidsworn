# Drift audit (dead code, outdated instructions, conflicting guidance) - synthesis (Oct 29 program)

Four prongs: DeepSeek ROT, Argon ROT, Rey (blind) ROT, Qwen DRIFTING.

## Verdict: ROT (3 of 4; Qwen grades the same facts milder)

Qwen grades the buy handlers, the dead Rear arc, and the dead evMult as harmless residue; the other three grade them dangerous for one shared reason: the Godot port copies these files as its parity oracle, so browser-era residue is not inert, it is load-bearing in the port.

## Findings that stand

1. The unlockAll boot grant still executes (4 of 4). Ryan confirmed on Oct 28 that the fully-unlocked state began as a testing leftover. The grant still runs at every boot, silently defining shipped progression, with buy handlers fully implemented and no player-facing way to buy or to turn the grant off. The disagreement among the legs is only about remedy (below).

2. The retired mobile layer is live, and it can fire on real PCs (Argon; chair verified; independently found by the blind Rey leg). The mobile flag derives from pointer type and window size, so a coarse-pointer PC in a small window qualifies. At boot, that path forces reduced-flash off when no explicit setting exists and forces quality to medium. This is not residue; it is a live behavior defect for an edge class of desktop players, and it overrides an accessibility default, which makes it the drift item's most serious single finding.

3. The torpedo comment contradicts the constants inside a parity-oracle file (4 of 4; chair verified). The comment promises off-center penalties of 10 and 25 and range 6; the constants are [0,5,15] and range 5. The constants are the live truth (the legs and the chair agree); the comment is what the port's parity work reads.

4. The guidance documents are a stratigraphy (4 of 4): NEXT.md superseded but still carrying phone-era gates; PROGRESS.md still describing a "mobile map" and an old working directory; BACKLOG.md mid-retirement; Pixel counts of 5, 7, and 5 across the three. CLAUDE.md and HANDOFF.md are the live layer. Nobody proposes deleting history; the shared ask is banner-and-archive so a reader (human or model) cannot mistake the retired layer for instructions.

5. Smaller verified residue: touchWords carries regexes that can never match (the generic Click-to-Tap replacement runs before the specific one in the same chain, and the base tip text has moved on; Argon, chair verified); the desktop base wording itself uses "Tap" phrasing in the action-strip hint line, so retiring the rewrite layer alone does not fix the wording (Rey; converges with the battle UI legs); TORP_INSTANT is dead but harmless; the dead Rear arc and dead startorp evMult sit in the shared data file, so they travel to Godot under the shared-data rule whether or not they are cleaned.

6. The flash merge window's live residue is in the record, not the port (Rey; chair concurs). The Godot effects files are internally consistent at 0.12 s today. What still says 0.33 is the audit record's recommendation. Opus settled the number at 0.12 (R49 technical call), so the drift to fix is the stale recommendation text, and Argon's proposal to reconcile the code TO 0.33 is explicitly not carried.

## The two forks (both Opus technical calls, not designer questions)

- The boot grant in the frozen browser: DeepSeek says turn it off in the browser as a break-fix; Argon says keep it there (with no shop UI, turning it off locks content away entirely) and strip unlock state from the Godot oracle only; Qwen is least interventionist (banner and flag for Godot-side exclusion). The chair's ordering note: the freeze rule governs browser behavior changes, and Opus owns that interpretation; all three shapes agree the Godot oracle must not inherit the grant as designed behavior.
- The mobile override: forcing the mobile flag false at boot converges across legs as the smallest change that kills the live defect, but it is a browser behavior change under the freeze. Same routing: Opus decides, Ryan hears failures or vetoes only, per the Oct 24 decision split.

## Cleanup shape (merged candidate for Opus, ordered)

1. Comment and document fixes that change no behavior: torpedo comment to match constants, banners on NEXT.md and PROGRESS.md, the 0.33 recommendation corrected in the record.
2. Godot oracle exclusions: unlock state, the mobile layer, and dead data keys (Rear arc, startorp evMult, TORP_INSTANT) excluded from parity, explicitly, so the port stops inheriting them.
3. Copied-guidance rewrites in the port where browser text was carried over.
4. Browser deletion of the mobile layer and dead handlers deferred until the Godot cutover makes the browser copy disposable.

## Designer questions

None. Every question the legs posed was already answered on the record (testing leftover, Oct 28; PC-only, Oct 24; flash window 0.12, Opus R49) or routes to Opus under the decision split.
