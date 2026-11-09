# DeepSeek stress-test leg (buildability), issue #270 (verbatim substance from the browser run, Nov 8, 2026; DeepThink on, Search off, gate verified)

Per candidate: (a) Godot theme buildability, (b) first density break, (c) rollout.

D1 Plotting Table. (a) Partial: brass rails as StyleBoxTexture nine-patches, engraved caps via FontVariation; projected-light panels need a reusable GlowPanel custom Control with a CanvasItem shader or baked glow; Godot themes cannot assign shader materials, so not theme-only. (b) Breaks first on overlapping nameplates over bright scenery: projected panels lose BONE text unless backed by opaque dark glass, which fights the holo read. Roster feasible (~34-40 px rows, 760 px at 20 ships). 4K: nine-patch brass needs high-res sources. (c) Good rollout to map and menus; debrief needs a body font, not engraved caps. Medium friction.

D2 Gun Director. (a) Mostly theme: nine-patch riveted steel, stamped tabs, backlit GILT primary via Button variations; arc gauges need a reusable ArcGauge custom Control (_draw). (b) First break: the selected tab "dropped forward" clips in a VBoxContainer; long captain names truncate hard in 250 px tabs. Steel nameplates are opaque and survive bright fields. 4K needs 2x rivet assets; gauges scale cleanly. (c) Strong rollout: menus as steel plates, debrief as war report, map as fire-control plot.

D3 Chart Room. (a) Yes, closest to theme-only: StyleBoxFlat hairlines, monospace FontFile, GridContainer columns, a reusable RuledBar for ticks; no shaders. (b) Breaks first on long captain names (monospace is wide); clustered nameplates need opaque backing, a transparent chart over nebula fails text survival. 4K hairlines need a 2 px floor. (c) Excellent rollout everywhere.

D4 Vector C.I.C. (a) Partial: bezel and telemetry fine; stepped bars need a SegmentedBar control; phosphor bloom and raster need a SubViewport shader pass themes cannot carry. (b) Segmented bars and codes eat the 250 px; 12 px segmented glyphs become illegible, the text floor fights the font concept; 4K scanline moire unless screen-derived. (c) Possible, but a phosphor debrief is fatiguing. High build and readability risk.

D5 Salvaged Console. (a) Poor as a standalone theme: many texture variants, chalk smudge needs shaders, mismatch invites per-screen heroics. (b) Hand-painted labels are variable-width; chalk log is low contrast; 4K raster labels blur. (c) Merge into D2 as an optional Salvaged stylebox and font variant, not a separate direction.

D6 Glass Bridge. (a) Weak: etched glow and parallax are per-panel custom work. (b) The collapsed idle roster conflicts with the locked roster requirement; transparency plus parallax misregistration kills BONE text over bright scenery, and opaque backing breaks the concept. (c) Battle-screen-only trick; debrief and modals fail over glass. High risk.

W1 Admiralty Table. (a) Mostly buildable; route line needs a custom control. (b) Italic serif at small sizes is weak for captain lines and log. (c) Excellent rollout. Merge into D1: same table, rim, brass, diary idea; W1 supplies material and serif, D1 supplies structure.

W2 Living Membrane. Kill: fights the hard-edged brief, per-panel shaders, text contrast fails over bright scenery, not a rollout family.

W3 Signal and Semaphore. Not a theme, a signal language (SignalLamp control, pennants, hoists). Merge into D2/D3 for enemy-phase and Nemesis signalling; kill as a standalone.

DeepSeek ranking (survivors): 1. D3 Chart Room (low risk). 2. D2 Gun Director with D5 skin and W3 language (medium). 3. D1 plus W1 (medium). 4. D4 Vector C.I.C. (high). 5. D6 Glass Bridge (high). Riskiest assumption in D3: that opaque backing on nameplates and roster rows still reads as a warship console rather than flat printed chart UI; if the owner rejects the backing, D3 needs glow or dark plates and collapses toward a generic dark-panel theme.
