# Grok leg, issue 522 (ideation seat)

Chair header: LANDED Nov 11, 2026. Clean, and the most accurate reading of the blind leg of the two ideation seats: its M1 to M6 judgments match the actual methods and their weaknesses (crop can still polish if taken from a smooth region; inventory can be ignored if the change budget goes elsewhere; colour locks need the crop to carry the palette physically; the escalation step must still protect silhouette and counts). Its added method is adopted: a SECOND crop on a different region, both crops carried as simultaneous same-ship style inputs. In practice the chair applies it as: S10 and E11 get two separate crop edits; E12's crop frame already holds two regions (one arc plus the caged core); G18's crop frame holds the bow lenses and the spine turret together.

---

voidsworn_S10 (Sunward flagship)

Risks in this brief: The source S8 is a clean evenly lit render. Any edit that treats it as something to preserve will keep the smooth drawn look the owner rejected in S9. Colour is fragile: lighter grey and any blue must be locked out, yet the style reference is a different ship under hard light. Counts are exact (seven organ pipes, seven flank barrels, four dome turrets, radiator bank of roughly eleven slits, two engine bells, forked prow with recessed lance, escort). Losing or inventing any of them fails the brief. Gun ports must stay dark.

Specific failure modes the transformation invites: Colour drift toward lighter grey or blue in the prow notch and engine bells, exactly as S9 did. Surface remains illustration-smooth because the source supplies no seams or fittings for the model to amplify. Organ pipes and flank barrels flatten into symbols instead of working machinery with mounts. The escort is dropped or scale is lost. Radiator bank loses its vertical slit count or becomes a single flat panel.

Guard sentences or checks for the chair: Score the full beauty against S8 silhouette and the stated counts first; any missing or altered count is an immediate fail. Confirm no surface is lighter than S8 and that blue is absent from every region, especially prow notch and bells. Verify gun ports remain dark and that the surface reads as many separate dark-iron plates and fittings under one hard light on plain black, not polished illustration. Check the section crop accepted as same-ship style input actually carries plate scale that survives the full edit. If the first two inventory passes stay smooth, escalate to a harder material inventory that accepts limited fitting drift while the prompt still holds silhouette, counts and the dark-iron lock, then re-check shape against S8.

deathless_E11 (Eclipse flagship)

Risks in this brief: The crescent's broad faces are the known failure point from E9. Turning them into layered seamed plate with real thickness at huge scale is the core demand, yet the source E4 is smooth. Colour must stay exactly E4. Turret counts and placement (two large twin, one smaller, one small flak cluster on the spine) are fixed. The model can easily add plate language to the edges while the faces themselves remain single-plane.

Specific failure modes the transformation invites: Broad faces stay smooth or gain only marginal panel lines without layered thickness or seams that read at scale. Colour drifts away from E4. Turrets change form or mounts disappear. The crescent silhouette softens or the faces read as thin rather than built volume. Large flat colour areas survive despite the style line.

Guard sentences or checks for the chair: Require explicit visual evidence that the broad faces are layered plate construction with thickness, seams and fittings small enough to sell the ship's size; edge treatment alone is not enough. Confirm colours match E4 exactly and that the two large twin turrets, smaller turret and flak cluster keep their mounts and relative scale. Score against the style line: many separate plates under hard light on plain black, no large single-colour flats. If the section-crop method leaves the faces smooth after two tries, escalate to a material pass that forces plate inventory on the faces themselves while holding the crescent outline, then verify shape against E4.

deathless_E12 (Eclipse ring cruiser)

Risks in this brief: The ring must stay flat, seven broken arcs on four struts around a caged core, three stern engine bells. E8's dark violet on the arcs is mandatory; grey or slate is the exact failure from E10. Green is restricted to core and razor edges. Nebula is forbidden. The arcs themselves must read as built plate, not smooth bands or a continuous flat ring.

Specific failure modes the transformation invites: Arcs lose dark violet and go grey or slate. The ring collapses into a single flat band instead of seven distinct broken arcs. Struts or core lose definition. Nebula or any painted backdrop appears. Green spreads beyond core and edges. Surface treatment is applied only to the outer silhouette while the arcs remain smooth.

Guard sentences or checks for the chair: First check that the seven arcs remain distinct, broken, and dark violet with no grey or slate anywhere on them. Confirm green is present only at the core and razor edges. Verify the ring lies flat on four struts with a caged core and three engine bells, and that the arcs show plate construction rather than smooth continuous bands. Reject any nebula or non-black background. If colour or band smoothness persists after two inventory passes, change method: force per-arc plate inventory in the crop stage and carry the accepted crop as the dominant same-ship style input, then re-score colour and arc separation against E8.

ithar_G18 (Glasswright flagship)

Risks in this brief: The lens brief changed after round 8. The two bow lenses and the spine turret lens must be solid forms grown from the hull's glass and bright metal, with forward-facing apertures that point forward, not clear bubbles, domes or glowing globes. Flak lenses are small skin apertures. The ship must stay clean and bright; realism comes from ribs, inlay, layered glass and fine metalwork, never rust or wear. G15 anatomy is fixed: two large bow lenses, one large spine turret lens, one small spine gun, rank of small flak lenses, three stern engine cylinders.

Specific failure modes the transformation invites: Lenses revert to the dome or bubble template and lose the forward point, exactly as G17 did. Spine turret loses its turning collar or points the wrong way. Surface becomes either too smooth or acquires unwanted wear. Bright clean palette drifts. Engines or flak rank change count or scale. Geometry language is ignored and the word "lens" alone summons the old template.

Guard sentences or checks for the chair: Score the lenses first from both beauty and sheet views: they must read as solid swellings of the hull's own glass and metal with forward-facing apertures, able to be confirmed as pointing forward in the top view. Prohibit any dome, bubble or globe reading. Confirm the spine turret sits on a grown turning collar and also points forward. Verify the surface is clean and bright with ribs, inlay, layered glass and fine metalwork only; no rust. Hold G15 counts and silhouette. If the geometry-only approach still produces template lenses after two tries, escalate by describing the aperture and mounting geometry in even tighter physical inventory while continuing to ban the template words, then re-check forward orientation on the sheet.

Judgment of the blind leg's method claims M1 to M6

M1 (section first) is the strongest claim. Editing a tight crop forces the model to invent surface at readable scale because the frame is all surface; the accepted crop then becomes a same-ship style anchor that is tighter than a foreign photograph. Weakness: if the crop itself is taken from a region that is already smooth and evenly lit, the crop can still polish rather than transform. The method assumes the chair will reject non-transforming crops early.

M2 (style input first) is reasonable and cheap. Putting the photographic prior ahead of the shape input biases the model toward photographing rather than preserving. Evidence from the prior round is limited, so it should be treated as a useful default rather than a proven fix.

M3 (prompts as inventory) is correct and necessary. Adjectives are satisfied by polish; named parts at stated scales are not. Weakness: inventories can still be ignored if the model's change budget is spent on lighting or colour instead. The inventory must be dense enough that the model cannot satisfy the prompt without adding parts.

M4 (per-surface colour locks) is a direct response to the documented drifts and is stronger than a single global "keep the reference colours" line. Weakness: locks stated only in text can still lose if the model re-renders; the same-ship crop must also carry the correct palette or the lock has nothing physical to anchor to.

M5 (two-pass escalation, then record) is sound process. Continuing to polish a smooth result wastes the round. The planned ladder (inventory with crop, then harder material pass that accepts limited drift, then honest failure record) is practical. Weakness: the second step must still protect silhouette and counts; unrestricted material drift simply recreates the shape loss seen in the escalated Hegemony pass.

M6 (geometry language only for the lenses) correctly identifies the template problem. Naming the solid form, aperture and forward orientation while banning dome/bubble/globe is the right counter. Weakness: if the geometry description is still too abstract the model can invent a new but equally wrong solid shape; the description needs to stay tied to the hull's own glass and metal so the lenses grow from the existing structure rather than being added as separate objects.

Method I would add

After an accepted section crop exists, run a second tight crop on a different region (for S10 a flank barrel group, for E11 one broad face, for E12 a single arc and strut junction, for G18 one bow lens and its seating) and require the full-ship edit to accept both crops as simultaneous same-ship style inputs. This forces consistency of plate scale and material across separated parts of the hull and reduces the chance that only the first cropped region receives the treatment while the rest of the ship reverts to polish. If both crops transform and the full edit still smooths, the failure is then clearly method-level rather than crop-selection error, and the chair can move to the harder material pass with higher confidence.
