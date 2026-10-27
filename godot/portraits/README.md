# godot/portraits: admiral portraits and crests (owner: music and portraits helper)

R37 and R40: finish the Chorus set first, then one painted poster admiral per remaining faction, crests for every other admiral; Mending Choir as the Living Suture-Hive. Drafts are made with the AI image tools on Ryan's PC (`tools/portraits/`), reviewed on his phone.

## Files

- `crests/<admiral>.svg`: a crest for all 24 admirals (faction frame and colours, glyph for the admiral's Command: barrage, hunt, scramble, iron, surge, restore). No text. Built by `tools/portraits/crests.py`.
- `painted/<admiral>.webp`: the picked painting (1024 px, thin faction-trim frame).
- `alts/<admiral>_altN.webp`: the other candidates, kept for Ryan to swap.
- `index.json`: per painted admiral, the pick and its alternates. To swap, change `pick` to one of the `alts` paths.
- `sheets/*.webp`: contact sheets per faction (for Ryan's phone) and `crests_all.webp`.
- `portraits.gd`: lookup for any screen.

## Painted admirals (Oct 26 picks)

Seven paintings are in: the Chorus pair plus one poster admiral per other faction. Every other admiral shows its crest. Phone sheets: `sheets/<faction>_portraits.webp` (pick, alternates, crests of the rest). Picks, alternates and the reason for each are in `index.json` and `tools/portraits/picks_b1b2.json`.

| Admiral | Pick | Model | Why |
|---|---|---|---|
| The Matriarch | b1 `chorus_matriarch_zit_s51` | Z-Image Turbo | nine uneven throats venting spore swarms, a brood sac full of larvae: Spawning Surge at a glance |
| The Mending Choir | b2 `chorus_mending_b2_zit_s11` | Z-Image Turbo | the Living Suture-Hive: hive flesh sewn shut with bone stitches, amber nursing sacs dripping onto new flesh |
| Castellan Vex | b1 `voidsworn_vex_qie_s11` | Qwen-Image-Edit | oath scars, wax seals, parchment strips, broadside beams through a gothic viewport |
| Ilsa Kassar | b1 `hegemony_kassar_qie_s23` | Qwen-Image-Edit | targeting grid on the face, rows of firing-solution displays |
| Grax Ironjaw | b1 `corsair_grax_qref_s23` | Qwen-Image-Edit (on plate) | iron jaw, red cyber eye, axe, patchwork plates from three fleets |
| Aelith Dawnsail | b2 `ithar_aelith_b_qie_s37` | Qwen-Image-Edit | robed rerun: crested skull, gold light channels, light sails |
| Nekhet the Undying | b2 `deathless_nekhet_b_qie_s23` | Qwen-Image-Edit | broken ring of computation plates round a green core, repair drones, no figure |

Rejected in review (kept on the PC, not in the repo): every batch 1 Mending render (human faces or a skull-headed body), every batch 1 Nekhet (a torso or a face inside the ring), batch 1 Aelith (nude torso, five fingers), Vex on Z-Image (sea-going battleships in the window), Kassar on Z-Image (gun pictograms on the screens), Matriarch s37 (grew a head), and the Voice and Razormaw alternates (shoulders, a fanged jaw). For the non-human admirals the prompts now describe an organism or a machine, never "a portrait of an admiral" (`make_batches.py`, CREATURE style): the portrait framing is what pulled the models toward a person.

Style: humans, Ithar and Deathless use the Qwen renders (close bust, crisp faces); the Chorus pair use Z-Image's oil-paint look, which suits flesh and gives the Chorus its own texture. All seven share the dark faction field, the left key light in the faction glow and the same thin trim frame.

### Calls handed over in R45

**Mending Choir as the Living Suture-Hive: done.** Picked `painted/mending.webp` (above). Alternates: the cracked-shell hive with pink sutures (b2 variant 1, s23 and s51) and the stitched cocoon s51.

**Matriarch v3 verdict: the new painting replaces v3 in the game.** v3 could not be compared directly: it is not on Ryan's PC in any folder this stream can reach (`Downloads\voidsworn_test` and `Downloads\Claude outputs` were searched; the manifest's paths are for Muse's local pack, and none of the 40 manifest images are on the PC or in the repo), and neither is the approved Voice v4. So the verdict rests on the brief and on consistency with what the game will actually show. The new `chorus_matriarch_zit_s51` matches the DeepSeek 1.3 brief point by point (nine throats of different lengths fused into one brood mass, spore swarms venting from the tips, translucent brood sacs with larvae, no face or limbs), and it is painted by the same model, template and lighting as the new Mending, so the two Chorus paintings sit together on the admiral screen; a v3 from a different image tool would not match them or the five Qwen posters. If Ryan prefers v3 when he sees both, save it as `painted/matriarch.webp` (1024 px, any square) and it is used with no code change.

### Manifest reconciliation (FINDINGS D20)

`contrib/muse/design/IMAGE_MANIFEST.md` is Muse's and is not edited here. These rows supersede its portrait rows for the three Chorus admirals:

| Admiral | Status | File used by the game | Bytes | SHA-256 |
|---|---|---|---:|---|
| Voice of the Deep | v4 FINAL (Ryan, Oct 24). The manifest row (403,732 bytes, `a1bfcea0...`) is the superseded v1. v4 is `adm_voice_of_the_deep.webp`, 519,924 bytes, `6790c41e5afcbc416cb23773cf89db9c54b653dd8952932138f024b015b886b6`, in Muse's local pack only. | none yet: the crest shows until v4 is saved as `painted/voice.webp` | | |
| The Matriarch | Manifest row (v2, 688,858 bytes, `bacfaecb...`) superseded. v3 candidate not used (verdict above). | `painted/matriarch.webp` (b1 `chorus_matriarch_zit_s51`) | 109,062 | `7c37f35f533effc87e9dd30ad08a2aad1edc96876ece2022796f19eaa73c572b` |
| The Mending Choir | Manifest row (v2, 750,690 bytes, `3275f6bd...`) superseded by the Living Suture-Hive direction (R37, R45). | `painted/mending.webp` (b2 `chorus_mending_b2_zit_s11`) | 115,362 | `941111a8269c943aa68501a7ed7d3cd2302d2778dcc9f52dbd964ae5a45d7c59` |

Razormaw stays as Muse's final in the local pack (crest in game until the file is saved as `painted/razormaw.webp`).

## For G3 and the story helper

```gdscript
const Portraits := preload("res://portraits/portraits.gd")
var tex := Portraits.face("vex")    # painting when one exists, else the crest
var small := Portraits.crest("vex") # always the crest
```

Where faces belong (Sheet 3 of the decision packs): the admiral pick screen, the rival boss fight intro, the story beat cards, the Career tab. Crests everywhere else (map tokens, lists, the battle HUD). Admiral ids are the `data.js` ADMIRALS keys.

## Nemesis (R42, for stream B)

- Pool: 6 per faction, ids `nem_<faction>_<1..6>` (36 in all), the same painted style as the admirals but lit from below with a red rim light, and a red-black thorned frame (`nemesis/frame_<faction>.png`) so a Nemesis never looks like a named admiral.
- Scars: `scar_<kind>` with kinds `burn` (every faction), `cyber` and `eye` (Voidsworn, Hegemony, Corsair), `carapace` (Chorus), `porcelain` (Ithar), `machine` (Deathless). `nemesis/scars/scars.json` lists which faction takes which kind.
- Call `Portraits.nemesis("corsair", 3, ["burn", "eye"])`: base portrait, then the scars, then the frame. Add one scar each time a Nemesis survives a fight with you; the order of the list is the order earned.
- `Portraits.nemesis_ids("corsair")` lists the pool for a faction.

How the scars are drawn (Oct 26 rework): the pool portraits are bust crops of the picked renders (`tools/portraits/nemesis_crop.py`), and Qwen-Image-Edit paints every scar kind a faction can take onto every one of its Nemesis (`tools/portraits/make_edits.py`, `portrait_edit.py`; about 90 paintings). In `index.json` each Nemesis has `baked` (the whole portrait with one painted scar) and `patch` (just the scarred region of that painting, feathered, with its offset). The first scar shows the baked painting; each later scar pastes that kind's patch on top, so a Nemesis with three scars is still all paint, in its own lighting. The generic overlays in `nemesis/scars/` are only a fallback for a kind with no painting. Judged on the real paintings, the overlays read as stickers (a flat grey plate with a cartoon red dot, a near-invisible burn on the collar, a hairline through the eye), which is why the scars are painted.

Pool review (Oct 26): Voidsworn, Hegemony and Corsair from the first renders, with five fixes painted in (peaked officer caps removed, which the prompt had ruled out; one helmet that read as a film stormtrooper replaced by a scrap faceplate). Chorus, Deathless and Ithar were rerendered: the first Chorus set was eighteen near-identical skull-headed humanoids, most Deathless had human faces or bodies, and the Ithar did not share Aelith's anatomy. Phone sheets: `sheets/nemesis_<faction>.webp`.

### Oct 27 (takeover): pools in the game, looks on hold

- **Published into the game:** `nemesis/pool/` now holds the Voidsworn, Hegemony and Corsair pools (18 bust crops, 54 painted scars, 54 feathered patches; `index.json` "nemesis"), and the Chorus pool once its carapace rerun is picked. Until this commit no Nemesis image was in the repo, so `Portraits.nemesis()` had nothing to show.
- **Chorus Nemesis picks (vetoable):** 2 = n3 s11 (fungus bursting from a husk; s23, s37 and s51 grew clawed hands), 3 = n3 s37 (spiked dome; the other seeds have a fanged face and eyes), 4 = n3 s11 (a brain-backed leviathan; the model drew "the size of a whale" literally, which reads as a space beast, so kept). Scars: burn on every Chorus as painted; carapace v1 painted bright yellow lightning-like cracks running off the body into the background on 5 of 6, so it was rerun with a gentler prompt and two seeds (`batches/n1s_c2.json`).
- **On hold until Ryan signs off the new looks (lore bible round 4):** Ithar and Deathless Nemesis pools are not published (their n2 and n3 renders stay on the PC), and no new portrait is painted for Voidsworn, Hegemony, Corsair, Ithar or Deathless. Round 4 also proposes moving the Chorus off purple (dark olive-brown flesh, ochre chitin, bile yellow-green), so the Chorus paintings may need a recolour too.
- **Drafts ready to run after sign-off:** `tools/portraits/look_drafts.py` writes `batches/drafts/`: fresh poster admirals for the five changing factions, Qwen-Image-Edit restyle passes on the seven current paintings (keep the face and composition, change only the look: the cheapest route), and six new Nemesis subjects per changing faction. The looks follow round 4 (round 3's translucent glass bodies are superseded: Glasswrights are now biological, crystal and mirror-thread clothing).
- **Review note:** Corsair Nemesis 4 still wears a peaked officer cap (the prompt ruled hats out); left as is because the Corsair look is changing anyway.
- **Phone sheets:** `docs/shots/portraits/<sha>/` (made by `tools/portraits/phone_sheets.py`): `01_admirals.webp` and `02_nemesis_<faction>.webp`, 1080 px wide.
