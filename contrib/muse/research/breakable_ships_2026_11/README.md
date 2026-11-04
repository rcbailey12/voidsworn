# Breakable ships by design: research pack (issue 171)

Research for FINDINGS R98: how every new or rebuilt Voidsworn hull gets real thickness, a few internal decks and bulkheads, and authored break lines with capped, textured interiors, built in Blender and exported so Godot can swap the pieces in at death. This is the build-side method. The game-side fallback for current hulls is issue #167; the first build job that uses this method is issue #169 (Pyre-Barge, blocked until round 5 picks the hull).

Contents:

- synthesis.md: the chair synthesis. Verdict GO WITH CONDITIONS (owner question 1, the intact-ship thickness reading). Scriptable method in seven stages, Chorus organic variant, triangle and draw-call costs against the R96 ceiling, shipped-game evidence (EVE, Homeworld 3, Sins 2, others), hours per hull, an 11-step list for issue #169, five owner questions with chair picks, screening notes for all four legs, and a Not checked section.
- legs/rey_blind.md: the blind Rey leg, written first from the pack alone.
- legs/deepseek.md: the DeepSeek writer leg (filed raw, punctuation normalized).
- legs/qwen.md: the Qwen writer leg, with a chair gate note at the top; largely screened in the synthesis (non-running code, an EVE account that contradicts the CCP source, variant costs that repeat the parked V3 error).
- legs/argon_review.md: the Argon review, filed with a chair screening header. Its API corrections and source nuances are adopted; its quotation-based cut lists do not match the filed legs and are screened in that header.

Headline: do not Solidify the whole intact hull (it is already at the R96 ceiling). The intact ship carries thickness bands at the break lines plus a decimated dark liner; full interiors live in the broken-piece variants. One .glb per hull, named pieces, centre-of-mass origins, damage painted inside the R96 baked-mask system.
