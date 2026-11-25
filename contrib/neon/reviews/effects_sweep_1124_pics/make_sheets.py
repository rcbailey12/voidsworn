#!/usr/bin/env python3
"""Compose 1280x720 labelled contact cards for contrib/neon/reviews/effects_sweep_1124.md.
Every card stays at or under 1280x720 (RULEBOOK 1.2) and stamps its code name and camera status.
Run from repo root: python contrib/neon/reviews/effects_sweep_1124_pics/make_sheets.py
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent

W, H = 1280, 720
BG = (14, 17, 24)
PANEL_BG = (22, 26, 36)
BORDER = (55, 65, 84)
TEXT = (236, 240, 248)
MUTED = (160, 172, 192)
GOLD = (242, 199, 108)
RED = (232, 92, 82)
AMBER = (240, 172, 68)
GREEN = (98, 206, 138)
BLUE = (106, 178, 248)


def load_font(size: int, bold: bool = False):
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/consolab.ttf" if bold else "C:/Windows/Fonts/consola.ttf",
    ]
    for p in candidates:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


F_TITLE = load_font(22, bold=True)
F_SUB = load_font(14, bold=False)
F_LABEL = load_font(14, bold=True)
F_BADGE = load_font(12, bold=True)
F_SMALL = load_font(12, bold=False)


def badge_color(tag: str):
    t = tag.upper()
    if "SINGLE" in t or "NEEDS" in t or "PLACEHOLDER" in t:
        return RED
    if "PARTIAL" in t:
        return AMBER
    if "AAA" in t or "LAYERED" in t:
        return GREEN
    return BLUE


def new_card(code: str, title: str, subtitle: str, cam_note: str):
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, W, 56], fill=(20, 25, 36))
    draw.line([0, 56, W, 56], fill=GOLD, width=2)
    draw.text((14, 7), f"{code}  |  {title}", fill=GOLD, font=F_TITLE)
    draw.text((14, 34), subtitle, fill=MUTED, font=F_SUB)
    # Camera status pill on top right
    tw = draw.textlength(cam_note, font=F_BADGE)
    px0 = W - int(tw) - 28
    col = RED if "NEEDS" in cam_note.upper() else GREEN
    draw.rounded_rectangle([px0, 14, W - 12, 40], radius=6, fill=(32, 38, 52), outline=col, width=2)
    draw.text((px0 + 10, 20), cam_note, fill=col, font=F_BADGE)
    return img, draw


def crop_rel(rel_path: str, box=None) -> Image.Image:
    im = Image.open(ROOT / rel_path).convert("RGB")
    if box is not None:
        w, h = im.size
        x0, y0, x1, y1 = box
        if x1 <= 1.01 and y1 <= 1.01:
            box = (int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h))
        im = im.crop(box)
    return im


def fit_cover(im: Image.Image, tw: int, th: int) -> Image.Image:
    sw, sh = im.size
    scale = max(tw / sw, th / sh)
    nw, nh = max(1, int(round(sw * scale))), max(1, int(round(sh * scale)))
    im2 = im.resize((nw, nh), Image.Resampling.LANCZOS)
    x0 = (nw - tw) // 2
    y0 = (nh - th) // 2
    return im2.crop((x0, y0, x0 + tw, y0 + th))


def fit_contain(im: Image.Image, tw: int, th: int) -> Image.Image:
    sw, sh = im.size
    scale = min(tw / sw, th / sh)
    nw, nh = max(1, int(round(sw * scale))), max(1, int(round(sh * scale)))
    im2 = im.resize((nw, nh), Image.Resampling.LANCZOS)
    out = Image.new("RGB", (tw, th), (10, 12, 18))
    out.paste(im2, ((tw - nw) // 2, (th - nh) // 2))
    return out


def paste_panel(img: Image.Image, draw: ImageDraw.ImageDraw, rect, src_im: Image.Image,
                label: str, tag: str, note: str = "", mode: str = "cover"):
    x0, y0, x1, y1 = rect
    pw, ph = x1 - x0, y1 - y0
    header_h = 24
    footer_h = 20 if note else 0
    draw.rectangle([x0, y0, x1, y1], fill=PANEL_BG, outline=BORDER, width=1)
    draw.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + header_h], fill=(26, 32, 44))
    draw.text((x0 + 8, y0 + 4), label, fill=TEXT, font=F_LABEL)
    # Tag pill
    tc = badge_color(tag)
    tw = draw.textlength(tag, font=F_BADGE)
    bx0 = x1 - int(tw) - 14
    draw.rounded_rectangle([bx0, y0 + 4, x1 - 4, y0 + header_h - 3], radius=4, fill=(18, 22, 30), outline=tc, width=1)
    draw.text((bx0 + 5, y0 + 5), tag, fill=tc, font=F_BADGE)
    # Image area
    ih = ph - header_h - footer_h - 2
    iw = pw - 2
    if src_im is not None and iw > 4 and ih > 4:
        fitted = fit_cover(src_im, iw, ih) if mode == "cover" else fit_contain(src_im, iw, ih)
        img.paste(fitted, (x0 + 1, y0 + header_h + 1))
    if note:
        draw.rectangle([x0 + 1, y1 - footer_h, x1 - 1, y1 - 1], fill=(18, 22, 30))
        draw.text((x0 + 8, y1 - footer_h + 3), note, fill=MUTED, font=F_SMALL)


def paste_placeholder(draw: ImageDraw.ImageDraw, rect, title: str, tag: str, lines: list[str]):
    x0, y0, x1, y1 = rect
    header_h = 24
    draw.rectangle([x0, y0, x1, y1], fill=(24, 20, 26), outline=RED, width=1)
    draw.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + header_h], fill=(42, 24, 28))
    draw.text((x0 + 8, y0 + 4), title, fill=TEXT, font=F_LABEL)
    tc = badge_color(tag)
    tw = draw.textlength(tag, font=F_BADGE)
    bx0 = x1 - int(tw) - 14
    draw.rounded_rectangle([bx0, y0 + 4, x1 - 4, y0 + header_h - 3], radius=4, fill=(18, 22, 30), outline=tc, width=1)
    draw.text((bx0 + 5, y0 + 5), tag, fill=tc, font=F_BADGE)
    cy = y0 + header_h + 12
    for ln in lines:
        col = GOLD if ln.startswith("NEEDS") else (TEXT if ln.startswith("Today:") else MUTED)
        draw.text((x0 + 12, cy), ln, fill=col, font=F_SMALL)
        cy += 18


def kit_r3_c170(name: str):
    return crop_rel(f"docs/shots/look_bench/kit/round3/{name}.png", (0, 410, 640, 710))


def kit_r3_c60(name: str):
    return crop_rel(f"docs/shots/look_bench/kit/round3/{name}.png", (1040, 410, 1280, 710))


def battle_cell(rel_path: str, row: int, col: int):
    # 3x4 grid inside 1280x720 BATTLE1076 sheets; skip top 24px cell caption bar
    x_edges = [10, 428, 848, 1270]
    y_edges = [44, 186, 329, 472, 616]
    return crop_rel(rel_path, (x_edges[col], y_edges[row] + 24, x_edges[col + 1], y_edges[row + 1]))


def save(img: Image.Image, filename: str):
    p = OUT / filename
    img.save(p, "JPEG", quality=92, optimize=True)
    assert img.size[0] <= 1280 and img.size[1] <= 720, f"Size overflow on {filename}: {img.size}"


def build_all():
    # FX01: Ballistic bolts (macro, auto, scatter, flak)
    img, dr = new_card(
        "FX01_BOLTS_BALLISTIC",
        "Ballistic Shells, Autocannons, Scatter and Flak",
        "Single-layer fx.stk tracers with tiny crumbs at c170 and c60; flak bursts are single flat circles",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 634, 384), kit_r3_c170("macro"), "macro (c170)", "SINGLE-LAYER", "fx_weapons.gd:440 | 1 fx.stk kind-0 stub; tiny dot at c170")
    paste_panel(img, dr, (646, 66, 1268, 384), kit_r3_c170("auto"), "auto / junk (c170)", "SINGLE-LAYER", "fx_weapons.gd:454,464 | 1 fx.stk kind-0 per round; no tracer sheath")
    paste_panel(img, dr, (12, 394, 634, 708), kit_r3_c170("scatter"), "scatter (c170)", "SINGLE-LAYER", "fx_weapons.gd:505 | 6x1 fx.stk kind-0; flat pellets")
    paste_panel(img, dr, (646, 394, 1268, 708), kit_r3_c170("flak"), "flak / pflak / mflak / gflak (c170)", "SINGLE-LAYER", "fx_weapons.gd:1628-1658 | 1 fx.stk + round beige puff; no shrapnel")
    save(img, "FX01_bolts_ballistic.jpg")

    # FX02: Energy, Crystal, Bio and Gauss bolts
    img, dr = new_card(
        "FX02_BOLTS_ENERGY_BIO",
        "Las, Plasma, Prism, Bioplasma and Gauss Slugs",
        "las/prism read as blunt pills/dashes; plasma/bioplasma read as fuzzy ovals; gauss NULL_SLUG is layered",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 424, 384), kit_r3_c170("las"), "las (c170)", "SINGLE-LAYER", "fx_weapons.gd:471 | 1 fx.stk kind-4 blunt pill")
    paste_panel(img, dr, (434, 66, 846, 384), kit_r3_c170("plasma"), "plasma / plasma_cannon (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:479-492 | blurry oval, no wake")
    paste_panel(img, dr, (856, 66, 1268, 384), kit_r3_c170("prism"), "prism (c170)", "SINGLE-LAYER", "fx_weapons.gd:517 | 3 flat white dashes")
    paste_panel(img, dr, (12, 394, 634, 708), kit_r3_c170("bioplasma"), "bioplasma / spine (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:595 | small chartreuse blob, faint drops")
    paste_panel(img, dr, (646, 394, 1268, 708), kit_r3_c170("gauss"), "gauss / Null Slug (c170)", "LAYERED (AAA)", "fx_weapons.gd:628, SH.NULL_SLUG | sharp core + tapered wake")
    save(img, "FX02_bolts_energy_bio.jpg")

    # FX03: Beams across all factions vs Doom AAA reference
    img, dr = new_card(
        "FX03_BEAMS_ALL_FACTIONS",
        "Beams per Faction vs Doom AAA Benchmark",
        "Doom R4 (multi-filament + dark violet sheath) sets the bar; needle/ion/pulsar/lance read as uniform tubes",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 424, 384), kit_r3_c170("lance"), "lance / nlance (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:533 | clean core+sheath; uniform tube at c60")
    paste_panel(img, dr, (434, 66, 846, 384), kit_r3_c170("ion"), "ion beam (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:533 | washed Gaussian tube; weak arcs")
    paste_panel(img, dr, (856, 66, 1268, 384), kit_r3_c170("pulsar"), "pulsar (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:533 | 3 bright beads; no prism dispersion")
    paste_panel(img, dr, (12, 394, 424, 708), kit_r3_c170("needle"), "needle (c170)", "SINGLE-LAYER", "fx_weapons.gd:533 | plain white line; zero dst or shimmer")
    paste_panel(img, dr, (434, 394, 846, 708), kit_r3_c170("tendril"), "tendril -> PR #1904 Thorns (c170)", "SINGLE-LAYER", "fx_weapons.gd:606 | flat wavy noodle (PR #1904 replaces)")
    doom_r4 = crop_rel("docs/shots/look_bench/kit/round4/doom.png", (855, 82, 1275, 318))
    paste_panel(img, dr, (856, 394, 1268, 708), doom_r4, "doom R4 AAA BENCHMARK (c170)", "LAYERED (AAA)", "SH.ECLIPSE_ARC | 3 filaments + dark sheath + shed motes")
    save(img, "FX03_beams_all_factions.jpg")

    # FX04: Muzzle Flashes
    img, dr = new_card(
        "FX04_MUZZLE_FLASHES",
        "Weapon Muzzle Flashes and Barrel Vents",
        "macro/junk use baked Cone-B muzzle blast; las/prism leak ballistic smoke via _muzzle; auto/flak use 1 flash",
        "c170 + c60 + CLOSE | NEEDS FRESH c26",
    )
    cone_b = crop_rel("docs/shots/vent_fx_2026_11/vent_sheet_close.png", (215, 315, 610, 560))
    paste_panel(img, dr, (12, 66, 634, 384), cone_b, "macro muzzle Cone-B (close crop)", "LAYERED (AAA)", "fx_weapons.gd:875 | flash + Mantaflow muzzle gas + light")
    paste_panel(img, dr, (646, 66, 1268, 384), kit_r3_c170("p_las_muzzle"), "p_las_muzzle (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:870 | leaks ballistic Cone-B smoke on laser")
    paste_panel(img, dr, (12, 394, 634, 708), kit_r3_c170("p_prism_muzzle"), "p_prism_muzzle (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:870 | leaks orange vent on crystal weapon")
    paste_panel(img, dr, (646, 394, 1268, 708), kit_r3_c170("p_missile_launch"), "p_missile_launch (c170)", "LAYERED (AAA)", "fx_weapons.gd:966 | tube pop + coast + ignite + smoke")
    save(img, "FX04_muzzle_flashes.jpg")

    # FX05: Torpedoes, Missiles, Star Torp and PD Intercepts
    img, dr = new_card(
        "FX05_TORPEDOES_MISSILES",
        "Torpedoes, Rockets, Star Torp and PD Intercepts",
        "Kit torps/rockets are layered but trails read faint at c170; star torp is a plain white ball",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 424, 384), kit_r3_c170("torp"), "torp kit flight (c170)", "LAYERED (AAA)", "fx_weapons.gd:950 | kit body + DRIVE + short wake")
    paste_panel(img, dr, (434, 66, 846, 384), kit_r3_c170("rockets"), "rockets salvo (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:950 | tiny dots, faint smoke ribbon")
    paste_panel(img, dr, (856, 66, 1268, 384), kit_r3_c170("star"), "star torpedo (c170)", "SINGLE-LAYER", "fx_weapons.gd:1136 | plain white ball; no corona rays")
    paste_panel(img, dr, (12, 394, 424, 708), kit_r3_c170("torp_intercept"), "PD torp intercept (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:1530 | 1 fx.stk tracer + small pop")
    paste_panel(img, dr, (434, 394, 846, 708), kit_r3_c170("rocket_intercept"), "PD rocket intercept (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:1530 | faint PD tracers + dust puff")
    paste_panel(img, dr, (856, 394, 1268, 708), kit_r3_c170("star_intercept"), "PD star intercept (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:1530 | weak flash on solar ordnance")
    save(img, "FX05_torpedoes_missiles.jpg")

    # FX06: Engine Plumes and RCS Thrusters
    img, dr = new_card(
        "FX06_ENGINES_AND_RCS",
        "Engine Plumes, Moving Trails and RCS Thruster Puffs",
        "CRITICAL FINDING: moving_trail shows polka-dot Sprite3D RCS balls + detached rectangular trail box",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 424, 384), kit_r3_c170("ribbon_0"), "Engine plume Sunward (c170)", "PARTIALLY LAYERED", "fx_ship.gd:1169 | core + ribbon; square root edge at c60")
    paste_panel(img, dr, (434, 66, 846, 384), kit_r3_c170("ribbon_3"), "Engine plume Hullbreakers (c170)", "PARTIALLY LAYERED", "fx_ship.gd:1169 | same ribbon template; no embers/mach nodes")
    paste_panel(img, dr, (856, 66, 1268, 384), kit_r3_c60("ribbon_0"), "Engine plume close (c60)", "PARTIALLY LAYERED", "Flat rectangular join at nozzle lip; no outer gas wash")
    paste_panel(img, dr, (12, 394, 634, 708), kit_r3_c170("moving_trail"), "RCS puffs + moving trail (c170)", "SINGLE-LAYER", "ship_view.gd:2068 | white polka-dot balls + detached box strip")
    paste_panel(img, dr, (646, 394, 1268, 708), kit_r3_c60("moving_trail"), "RCS puffs + moving trail (c60)", "SINGLE-LAYER", "Blurry Gaussian dots + hard-cut box floating off stern")
    save(img, "FX06_engines_and_rcs.jpg")

    # FX07: Shields (Hits and Breaks, c170 + c26)
    img, dr = new_card(
        "FX07_SHIELDS_HIT_BREAK",
        "Shield Hits, Ripple, Crackle and Collapse (One Pool, R450)",
        "Layered hex skin + crackle; c170 impact glare over-washes egg, collapse needs crisp edge dissipation",
        "c170 + c26 CURRENT ON DISK",
    )
    paste_panel(img, dr, (12, 66, 634, 384), kit_r3_c170("shield_torp_hegemony"), "Shield torp hit Hegemony (c170)", "LAYERED (AAA)", "fx_ship.gd:1875 | hex shell + flash; heavy full-egg white wash")
    col_after = crop_rel("docs/shots/look_bench/shields_r297/C15s_23_collapse_before_after_c170.png", (0.0, 0.45, 1.0, 0.72))
    paste_panel(img, dr, (646, 66, 1268, 384), col_after, "Shield collapse strip Hullbreakers (c170)", "LAYERED (AAA)", "fx_ship.gd:1994 | clean fade + rim shards; needs edge tear")
    a16_sh = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 0, 0)
    a16_brk = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 0, 2)
    im5_brk = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_IM5_c26_standard.jpg", 0, 2)
    paste_panel(img, dr, (12, 394, 424, 708), a16_sh, "Fitted shield hit A16 (c26)", "LAYERED (AAA)", "BATTLE1076_A16_c26 | tight surface glow + hex cells")
    paste_panel(img, dr, (434, 394, 846, 708), a16_brk, "Shield failure A16 (c26)", "LAYERED (AAA)", "BATTLE1076_A16_c26 | honeycomb break; flat uniform fade")
    paste_panel(img, dr, (856, 394, 1268, 708), im5_brk, "Shield failure IM5 (c26)", "LAYERED (AAA)", "BATTLE1076_IM5_c26 | hex grid + top arc; needs local ripple")
    save(img, "FX07_shields_hit_and_break.jpg")

    # FX08: Hull Hits and Sparks (noting #2018)
    img, dr = new_card(
        "FX08_HULL_HITS_SPARKS",
        "Hull Impacts, Crits, Fragments and Sparks (Issue #2018)",
        "Layered fireball + fragments + hull light; straight stick sparks being replaced by #2018; crit leaks orange",
        "c170 + c26 CURRENT ON DISK",
    )
    torp_after = crop_rel("docs/shots/look_bench/hull_hit_r303/C15s_23_torpedo_before_after_c170.png", (0.0, 0.44, 1.0, 0.80))
    paste_panel(img, dr, (12, 66, 846, 384), torp_after, "Torpedo hull hit R303 AFTER (c170) - note +0.3s stick sparks (#2018)", "LAYERED (AAA)", "fx_weapons.gd:2045 | fireball + light + debris; flat sticks -> #2018")
    paste_panel(img, dr, (856, 66, 1268, 384), kit_r3_c170("p_crit"), "Crit hit on Eclipse (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:2270 | orange fire leaks on Eclipse hull")
    frag_c26 = crop_rel("docs/shots/hit_fragments/H9_23_torpedo_fragments_c26.png", (0.0, 0.42, 1.0, 0.86))
    paste_panel(img, dr, (12, 394, 634, 708), frag_c26, "Torpedo hull fragments H9 (c26)", "LAYERED (AAA)", "hit_fragments/H9_23_torpedo_fragments_c26 | plates + flash")
    a16_mac = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 1, 0)
    a16_lan = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 1, 1)
    paste_panel(img, dr, (646, 394, 952, 708), a16_mac, "Macro hull hit A16 (c26)", "PARTIALLY LAYERED", "Fire + fragment; stick sparks -> #2018")
    paste_panel(img, dr, (962, 394, 1268, 708), a16_lan, "Lance hull burn A16 (c26)", "LAYERED (AAA)", "Molten cut + halo + cooling glow")
    save(img, "FX08_hull_hits_and_sparks.jpg")

    # FX09: Fires, Vents and Damage Stages 1-4
    img, dr = new_card(
        "FX09_FIRES_VENTS_WOUNDS",
        "Hull Fires, Vents, Wisps and Damage Stages 1 to 4",
        "CRITICAL FINDING: E11 & IM5 c26 show beaded polka-dot fire/vent strings and nearly invisible Stage 1-4 fires",
        "c170 + c26 CURRENT ON DISK",
    )
    a16_170 = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c170_standard.jpg", 2, 2)
    e11_170 = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_E11_c170_standard.jpg", 2, 2)
    paste_panel(img, dr, (12, 66, 634, 384), a16_170, "Stage 4 / 20% HP Hullbreakers A16 (c170)", "SINGLE-LAYER", "fx_ship.gd:2468 | 8 looping fbm quads; faint at battle zoom")
    paste_panel(img, dr, (646, 66, 1268, 384), e11_170, "Stage 4 / 20% HP Eclipse E11 (c170)", "SINGLE-LAYER", "fx_ship.gd:2468 | breaches/fires barely visible at c170")
    e11_s1 = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_E11_c26_standard.jpg", 1, 2)
    im5_s1 = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_IM5_c26_standard.jpg", 1, 2)
    im5_s4 = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_IM5_c26_standard.jpg", 2, 2)
    paste_panel(img, dr, (12, 394, 424, 708), e11_s1, "Stage 1 / 80% E11 (c26) - BEADED DOTS", "SINGLE-LAYER", "6 evenly spaced orange sprite dots leaking on Eclipse!")
    paste_panel(img, dr, (434, 394, 846, 708), im5_s1, "Stage 1 / 80% IM5 (c26) - BEADED DOTS", "SINGLE-LAYER", "3 blurry orange balls; no dark smoke sheath or hull light")
    paste_panel(img, dr, (856, 394, 1268, 708), im5_s4, "Stage 4 / 20% IM5 (c26)", "PARTIALLY LAYERED", "Wounds V2 PR #1755/#1997 pending; flat spark square visible")
    save(img, "FX09_fires_vents_damage_stages.jpg")

    # FX10: Deaths and Breakups (Small, Wing, Capital)
    img, dr = new_card(
        "FX10_DEATHS_BREAKUPS",
        "Ship Deaths: Wings, Frigates, Cruisers and Capitals",
        "Strong layered 3-beat system (tear -> break -> baked core flash -> secondaries); small bow vent reads as white ball",
        "c170 + c26 CURRENT ON DISK",
    )
    cap_after = crop_rel("docs/shots/look_bench/deaths/capital_death_beats.jpg", (0.0, 0.36, 1.0, 0.67))
    paste_panel(img, dr, (12, 66, 846, 384), cap_after, "Capital 3-beat death AFTER (c170)", "LAYERED (AAA)", "fx_death.gd:2500 | drive flare -> tear + 5 blasts -> 3-piece break -> core flash")
    frig_170 = crop_rel("docs/shots/look_bench/deaths_small/frigate_c170.jpg", (0.0, 0.50, 1.0, 0.98))
    paste_panel(img, dr, (856, 66, 1268, 384), frig_170, "Frigate death AFTER (c170)", "LAYERED (AAA)", "fx_death.gd:2637 | spin trail -> baked pop -> drift")
    frig_26 = crop_rel("docs/shots/look_bench/deaths_small/frigate_c26.jpg", (0.0, 0.50, 1.0, 0.98))
    paste_panel(img, dr, (12, 394, 634, 708), frig_26, "Frigate death AFTER (c26)", "LAYERED (AAA)", "0.017s bow puff reads round/flat; 0.733s core flash + pieces strong")
    a16_sep = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 3, 1)
    e11_sep = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_E11_c26_standard.jpg", 3, 1)
    paste_panel(img, dr, (646, 394, 952, 708), a16_sep, "Hull separation A16 (c26)", "LAYERED (AAA)", "Real cut steel bulkheads + glowing cracks")
    paste_panel(img, dr, (962, 394, 1268, 708), e11_sep, "Hull separation E11 (c26)", "PARTIALLY LAYERED", "Orange slag sparks on Eclipse (note R367 update)")
    save(img, "FX10_deaths_small_and_capital.jpg")

    # FX11: Wrecks, Slag Caps and Cooling Coals
    img, dr = new_card(
        "FX11_WRECKS_COOLING",
        "Wrecks, Torn Bulkheads, Slag Caps and Drifting Debris",
        "Strong layered 3D cut pieces + SLAG heat veins + cooling coals; hulk vent is single-layer sprite loop",
        "c170 + c26 CURRENT ON DISK",
    )
    cap_wk = crop_rel("docs/shots/look_bench/deaths/capital_wreck.jpg", (0.0, 0.12, 1.0, 0.96))
    cru_wk = crop_rel("docs/shots/look_bench/deaths/cruiser_wreck.jpg", (0.0, 0.12, 1.0, 0.96))
    paste_panel(img, dr, (12, 66, 634, 384), cap_wk, "Capital cooling wreck (c170)", "LAYERED (AAA)", "fx_death.gd:3757 | 3 pieces + torn slag caps + debris plates")
    paste_panel(img, dr, (646, 66, 1268, 384), cru_wk, "Cruiser cooling wreck (c170)", "LAYERED (AAA)", "fx_death.gd:3757 | 2-3 pieces anchored to hex + cooling coals")
    a16_wk = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_A16_c26_standard.jpg", 3, 2)
    e11_wk = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_E11_c26_standard.jpg", 3, 2)
    im5_wk = battle_cell("docs/shots/battle_baseline_1118/BATTLE1076_IM5_c26_standard.jpg", 3, 2)
    paste_panel(img, dr, (12, 394, 424, 708), a16_wk, "Cooling wreck A16 (c26)", "LAYERED (AAA)", "Rich interior decks + glowing rim veins")
    paste_panel(img, dr, (434, 394, 846, 708), e11_wk, "Cooling wreck E11 (c26)", "LAYERED (AAA)", "Clean cut faces + plates; dark hulk vent is 1 layer")
    paste_panel(img, dr, (856, 394, 1268, 708), im5_wk, "Cooling wreck IM5 (c26)", "LAYERED (AAA)", "Cracked slag heat + Jolt debris plates")
    save(img, "FX11_wrecks_and_cooling.jpg")

    # FX12: Strike Craft Trails, Bay Launch and Ordnance
    img, dr = new_card(
        "FX12_STRIKE_CRAFT_BAY",
        "Strike Craft Trails, Carrier Bay Launch and Craft Ordnance",
        "Craft trails use SH.CRAFT_TRAIL; carrier bay launch is a single white Gaussian blob; bombs/spores are tiny dots",
        "c170 + c60 ON DISK | NEEDS FRESH c26",
    )
    paste_panel(img, dr, (12, 66, 634, 384), kit_r3_c170("bay"), "Carrier bay launch (c170)", "SINGLE-LAYER", "fx_weapons.gd:2788 | 1 kind-18 white Gaussian blob + light on deck")
    paste_panel(img, dr, (646, 66, 1268, 384), kit_r3_c170("bombs"), "Bomber run + bomb drops (c170)", "PARTIALLY LAYERED", "fx_weapons.gd:1714 | craft flares good; bombs reuse 1 kind-23 dot")
    paste_panel(img, dr, (12, 394, 634, 708), kit_r3_c170("guns"), "Fighter dogfight / strafe guns (c170)", "SINGLE-LAYER", "fx_weapons.gd:1719 | 1 fx.stk kind-0 tracer; no muzzle sparkles")
    paste_panel(img, dr, (646, 394, 1268, 708), kit_r3_c170("spores"), "Chorus spore wing attack (c170)", "SINGLE-LAYER", "fx_weapons.gd:1638 | 1 fx.spr kind-15 dot; no mist ribbon")
    save(img, "FX12_strike_craft_and_bay.jpg")

    # FX13: Terrain - Calm Nebula and Ion Storms
    img, dr = new_card(
        "FX13_TERRAIN_NEBULA_STORM",
        "Terrain: Calm Nebula, Ion Storms and Storm Lightning",
        "Layered world-noise cards + FogVolume + 3D hex-tube lightning forks; bolts blink static (PR #1986 baked lightning)",
        "c170 + c26 CURRENT ON DISK",
    )
    neb_170 = crop_rel("docs/shots/look_bench/nebula/N368_nebula_c170.jpg", (0.333, 0.14, 0.666, 0.50))
    storm_170 = crop_rel("docs/shots/look_bench/nebula/N368A_R6_lightning_c170.jpg", (0.333, 0.11, 0.666, 0.44))
    bolt_crop = crop_rel("docs/shots/look_bench/nebula/N368A_R6_lightning_c170.jpg", (0.333, 0.50, 0.666, 0.76))
    paste_panel(img, dr, (12, 66, 424, 384), neb_170, "Calm nebula Option A (c170)", "LAYERED (AAA)", "world_living.gd | 4-band GAS_SHADER cards + FogVolume")
    paste_panel(img, dr, (434, 66, 846, 384), storm_170, "Ion storm R6 (c170)", "LAYERED (AAA)", "ion_storm.gd | storm fog + cloud flash + omni light")
    paste_panel(img, dr, (856, 66, 1268, 384), bolt_crop, "Ion storm lightning fork (1080p crop)", "PARTIALLY LAYERED", "BOLT_SHADER static mesh; PR #1986 replaces with animated bake")
    neb_26 = crop_rel("docs/shots/look_bench/nebula/N368_nebula_c26.jpg", (0.333, 0.14, 0.666, 0.50))
    storm_26 = crop_rel("docs/shots/look_bench/nebula/N368_storm_c26.jpg", (0.333, 0.14, 0.666, 0.50))
    paste_panel(img, dr, (12, 394, 634, 708), neb_26, "Calm nebula on hull (c26)", "LAYERED (AAA)", "N368_nebula_c26 | clean depth haze; nebula_wake default OFF")
    paste_panel(img, dr, (646, 394, 1268, 708), storm_26, "Ion storm on hull (c26)", "LAYERED (AAA)", "N368_storm_c26 | volumetric fog + sparks; needs ship-arc hit")
    save(img, "FX13_terrain_nebula_and_storms.jpg")

    # FX14: Terrain - Dead Star, Comets, Asteroids, Debris
    img, dr = new_card(
        "FX14_TERRAIN_DEADSTAR_COMETS",
        "Terrain: Dead Star Black Hole, Ice Comets, Asteroids and Graveyard",
        "Dead Star is AAA multi-layer; comets have layered nucleus+tail; infall motes, scorch decals & dust are single-layer",
        "c170 + c26 CURRENT ON DISK",
    )
    ds_after = crop_rel("docs/shots/terrain_fx_2/deadstar.jpg", (0.50, 0.05, 1.0, 0.55))
    paste_panel(img, dr, (12, 66, 634, 384), ds_after, "Dead Star core + disc + lens (c170)", "LAYERED (AAA)", "world.gd:766 | black core + 2 discs + 2 haze + lens + omni; INFALL motes 1-layer")
    paste_panel(img, dr, (646, 66, 1268, 384), crop_rel("docs/shots/1361/AC1361_comets_wide.jpg"), "Ice comets + gas tails (wide c170)", "LAYERED (AAA)", "world.gd:1183 | comet nucleus + anti-sun TAIL_SHADER ribbon")
    paste_panel(img, dr, (12, 394, 424, 708), crop_rel("docs/shots/1361/AC1361_comets_c26.jpg"), "Ice comet nucleus + debris (c26)", "LAYERED (AAA)", "AC1361_comets_c26 | detailed rock + hull hulk + soft tail")
    rocks_26 = crop_rel("docs/shots/issue-1264/BD1264_rocks_r26_05_before_after.jpg", (0.50, 0.08, 1.0, 0.92))
    paste_panel(img, dr, (434, 394, 846, 708), rocks_26, "Asteroid blockers (c26)", "LAYERED (AAA)", "world_rocks.gd | batched PBR rocks; terrain_scorch.gd is 64px circle")
    gy_after = crop_rel("docs/shots/terrain_fx_2/graveyard.jpg", (0.50, 0.05, 1.0, 0.55))
    paste_panel(img, dr, (856, 394, 1268, 708), gy_after, "Debris field & graveyard (c170)", "PARTIALLY LAYERED", "world_living.gd | ship debris + rocks; DUST_SHADER is plain dots")
    save(img, "FX14_terrain_deadstar_comets_rocks.jpg")

    # FX15: Missing-Capture High-Priority Effects (Nova, Warp/Arrivals, Boarding, Status, Abilities, Idle)
    img, dr = new_card(
        "FX15_ARRIVALS_NOVA_STATUS",
        "Arrivals, Warp, Nova, Boarding, Status & Abilities",
        "HIGHEST SINGLE-LAYER GAP CLUSTER: zero current c170/c26 look bench rows for these 6 systems",
        "NEEDS FRESH PC CAPTURE (c170 + c26)",
    )
    arr_crop = crop_rel("docs/shots/f1/0354234/5_enemy_reinforcements_banner.jpg", (0.28, 0.16, 0.84, 0.62))
    paste_panel(img, dr, (12, 66, 634, 384), arr_crop, "Reinforcement Arrival (battle frame)", "SINGLE-LAYER", "battle.gd:5755 | instant spawn + 1 fx.pop circle + 'Arrived' text; NO warp-in")
    paste_placeholder(dr, (646, 66, 1268, 384), "Nova Cannon + Blink / Phase / Jump-Out", "SINGLE-LAYER", [
        "NEEDS FRESH PC CAPTURE: c170 + c26 (zero look bench shots)",
        "Today: Nova uses RETIRED fx_stub.gd Sprite3D bolt + 1 flat orange flash!",
        "Today: Blink & Phase (battle.gd:2148,2231) = 1 fx.pop Gaussian dot + snap.",
        "Today: Jump-out (fx_ship.gd:3048) = 1 flash + 1 streak + 1 ring + instant hide.",
        "AAA fix: Charge-up barrel + distortion beam/shell + shockwave (Nova);",
        "faction warp-in/out rift with hull stretch, dst lens, wake and afterimage.",
    ])
    paste_placeholder(dr, (12, 394, 424, 708), "Boarding Breach & Tethers", "PARTIALLY LAYERED", [
        "NEEDS FRESH PC CAPTURE: c170 + c26",
        "Today: fx.gd:1997 hatch mark + burst + 14 vents",
        "+ ring + sparks (#2018) + 3 flat amber line_style",
        "arcs (hardcoded orange for ALL 6 factions).",
        "AAA fix: Faction breach (bio-tendrils / teleporter",
        "arcs / assault pods) + glowing plasma-cutter ring.",
    ])
    paste_placeholder(dr, (434, 394, 846, 708), "Ion & Acid Status (Ticks + Persistent)", "SINGLE-LAYER", [
        "NEEDS FRESH PC CAPTURE: c170 + c26 (PR #2021 WIP)",
        "Today: fx_ship.gd:3024 fire=8 orange quads, acid=6",
        "mist puffs, tidal=20 blue sticks, storm=shield_hit",
        "ONLY (draws NOTHING on unshielded ships!).",
        "Persistent: ion=1px shield line (gone at 0 sh);",
        "acid=single mist pool. AAA: 3D arcs + wet etch.",
    ])
    paste_placeholder(dr, (856, 394, 1268, 708), "Ability / Command Pulses & Idle Motion", "SINGLE-LAYER", [
        "NEEDS FRESH PC CAPTURE: c170 + c26",
        "Today: fx_ship.gd:3012 ability/command = 2-item",
        "stand-in (1 ring + 1 soft dot) identical for all 6",
        "factions! API.md:129 literally calls it 'stand-in'.",
        "Today: fx_idle.gd (default OFF) = single layer of",
        "soft sine Gaussian dots for all 6 factions.",
    ])
    save(img, "FX15_arrivals_warp_nova_status_boarding.jpg")
    print("Generated 15 cards in", OUT)


if __name__ == "__main__":
    build_all()
