Findings

1. BLOCKER, OBSERVED with INFERRED consequence. The Godot cutover drops browser saves entirely. Evidence: "browser saves are not carried over"; "no GDScript in the tree references the browser key voidsworn.v1". Cost: every player loses all META and any in-progress RUN at cutover, including map, fleet, captains and pending rewards. This confirms the claims register save BLOCKER and makes cutover player-data destructive without an importer.

2. BLOCKER, OBSERVED with INFERRED consequence. The unlockAll boot grant persists into saved META and therefore into imported Godot profiles. Evidence: "if META.opts.unlockAll is anything other than false"; "permanent part of the stored profile". Cost: progression integrity is broken, imported browser META usually arrives fully unlocked, and the importer loses its last clean decision point on whether that state should stand.

3. BLOCKER for release gate, OBSERVED. The findings-to-tests ledger at the pin is 8 PASS and 40 FAIL, and the runner "exits 1 while any pinned defect is unfixed"; "a failing test here is a correct regression test". Cost: no release candidate can pass the existing gate, and the 40 failing cases are known unfixed defects rather than test noise. A release-blocking program must treat those 40 as blockers and add importer round-trip and save-repair tests before cutover.

4. FIX, OBSERVED with INFERRED consequence. Silent id drops on load can delete ships, captains, perks and fitted refits. Evidence: "with no per-ship record anywhere except the raw .repaired JSON"; "Id stability is load-bearing for this save format". Cost: a hull id rename or data cleanup silently corrupts a run; the player gets a toast, but no UI reads back the raw repaired copy for per-ship recovery.

5. FIX, OBSERVED with INFERRED consequence. Mid-reward resume can silently skip unclaimed prize, salvage or pick stages after a damaged or id-shifted save. Evidence: "the node is already banked, so the lost rewards are not recoverable". Cost: rewards vanish after the node is already complete, which is an unrecoverable state corruption edge in the strongest part of the save layer.

6. FIX, OBSERVED with INFERRED consequence. Settings writes bypass stamping and the cloud path. Evidence: "never syncs those settings to the cloud mirror". Cost: quality, sound, camera and AI settings can stay device-local until an unrelated save or purchase occurs, so a second device resolves by stamps without seeing them.

7. FIX, OBSERVED. The free-exit guarantee fails on 7 of 33 events, including the ruling's own haven example. Evidence: "it still has no leave option"; "A non-corsair player with under 40 credits has exactly one enabled option, the fight." Cost: forced fight or forced cost events violate the ruling, and the Godot port inherits the same event pool unless the seven failures are fixed.

8. FIX, OBSERVED. The elite guarantee is broken on some generated maps. Evidence: "84 failures, all one kind"; "column 4 offers no elite". Cost: the map promise that the pre-rest column offers an elite is false for roughly 1.9 percent of checked maps, and the port inherits a generator guarantee that is not actually guaranteed.

9. FIX, OBSERVED. A third silent weapon deletion is present in data. Evidence: "b_razor_s (see row)"; "b_razor_s drops bioplasma undisclosed". Cost: content is removed from a hull without disclosure, which is a data integrity defect and another regression case that must not travel into Godot parity as accepted behavior.

10. FIX, OBSERVED with INFERRED consequence. Save versioning is shallow, with no per-version transform chain. Evidence: "There is no chain of per-version transforms"; "a future field rename has nowhere to hook". Cost: the next schema or field rename becomes another silent drop or load-failure risk, and the importer has no migration scaffolding beyond the existing v1 to v2 and default-fill functions.

Verdict

Verdict: Release readiness is blocked; the single most important attack is the Godot cutover destroying all browser progression because no importer exists.

Not checked

I did not run the browser or Godot builds; all findings are code and evidence reads. I could not judge live cloud conflict behavior, Godot battle mid-battle persistence, human-play impact of forced event costs, save size growth across long runs, or whether a second repair event later in a profile's life is left without a raw copy.
