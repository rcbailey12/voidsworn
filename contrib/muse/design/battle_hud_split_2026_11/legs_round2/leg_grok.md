# Issue 1006 round 2, Grok leg (KEEL shelf polish review)

Model gate: Grok, free grok.com, Fast mode, verified in the picker before the pack was pasted and again after the answer completed. New chat, pack pasted as text. Run Nov 17, 2026. Filed verbatim below; any en or em dashes in the raw answer were normalized to hyphens per the repo rule.

Verdicts on Ryan's three criticisms
    
    Unpolished bottom row: Agree. The current shelf is a linear string of sentences and bare figures. It reads as a draft readout rather than a finished tactical surface. At a decision cadence measured in seconds this feels unfinished.
    
    Hull and shield treated differently and apart: Agree. Hull is a lone text figure while shields get both a figure and a bar, and they sit in separate visual slots. Players should parse the ship's current toughness as one glance. Splitting the grammar and the placement forces two reads instead of one.
    
    Text where icons should be: Agree in part. Names, the status sentence, the target line, and the damage estimate must stay text; those are the decision anchors. Everything else (weapon state, orders, command actions, log toggle) is currently pure text and should become compact glyphs or bars so the eye can scan without reading every word.
    
    Concrete revised shelf
    
    Shelf remains 216 px tall, full 1920 width, dark gradient veil, no panels. Content zones left to right with approximate widths:
    
    Left status block (approx 420 px): Ship name in large condensed display face. Directly beneath it a single toughness unit: a short horizontal hull bar (ember fill, muted damage colour when below full) paired with its figure, then immediately under that a matching Glacier-blue shield bar and figure. Both bars share the same length and tick marks so they read as one grammar. Class and move remaining sit as a single secondary line under the bars.
    
    Guns column (approx 380 px): Three compact rows. Each row is a small weapon glyph (battery or lance silhouette) + arc letter + range band as mono figures + state. State is either a short mono percentage or a single status word. No full sentences.
    
    Target and odds block (approx 340 px): Target name in red if Nemesis, otherwise normal. Below it the chosen weapon name and hit percentage as mono figures, then one short damage line ("16 dmg: 7 sh / 8 hu"). This stays text because it is the current decision's payoff.
    
    FIRE box (approx 180 px): Unchanged outline box containing the verb phrase for the selected weapon. Remains the only box on the shelf.
    
    Orders and command strip (approx 320 px): Two short rows of icon buttons. Orders row: three glyphs for Brace, Concentrated fire, Turn. Command row: three glyphs for Command, Fire for effect, End ship. Icons sit on the veil with no tile backgrounds; active state is an ember underline or ember fill on the glyph itself.
    
    Right log cluster (approx 280 px): "Log" label plus the two most recent log lines, truncated. A small chevron glyph indicates the log can expand on hover or click.
    
    Fleet strip (full width, 36 px tall along the absolute foot): Compact ship tokens. Each token is ship name (or abbreviated) + small hull bar + hull figure. Acting ship marked by a thin ember underline under its token. At 14 ships the tokens compress to name initials + bar only; hover expands the full name.
    
    Line-by-line disposition of every current item:
    
    Ship name: stays large text.
    Class / move line: stays short text under the toughness unit.
    Hull figure: becomes part of the shared bar + figure unit.
    Shield figure and bar: joins the same unit; no longer separate.
    Guns rows: become glyph + arc + range + state; full sentences cut.
    Status sentence: moves behind hover on the ship name or toughness unit.
    Target name: stays text (red if Nemesis).
    Hit chance and damage estimate: stay short text.
    FIRE box: unchanged.
    Orders and command: become icon glyphs; text labels only on hover.
    Log lines: stay text but shortened; older lines behind hover.
    Fleet strip: becomes bar + figure tokens instead of pure text.
    Reference patterns to borrow and refuse
    
    Borrow from BattleTech: the idea that status is drawn first (bars on a compact unit) and weapons are a short checklist with clear state at the right edge. Borrow the discipline that abilities are icons, not sentences.
    
    Borrow from Gothic Armada 2: stacked hull then shield bars of identical length and weight so toughness is one visual object.
    
    Borrow from Sins 2: every actionable thing is an icon plus a number or state mark; text is reserved for names and the rare sentence that actually carries decision weight.
    
    Refuse: paper-doll diagrams (too much vertical space and too slow to read at fleet scale). Refuse boxed icon tiles or chrome frames (they violate the no-panels rule). Refuse long vertical resource or ability columns (they fight the horizontal decision order and the 216 px height). Refuse any pattern that turns the shelf into a collection of floating panels; everything must sit on the single veil.
    
    Icon set required
    
    Weapon battery: simple crossed-barrel glyph. Ready = solid ember outline. Out of range or unavailable = dim outline. Selected = filled ember.
    
    Weapon lance: single long barrel with a tip mark. Same state rules as battery.
    
    Brace: shield-wall silhouette. Ready = ember outline. Active = filled. Unavailable = dim.
    
    Concentrated fire: three converging chevrons. Same state rules.
    
    Turn: curved arrow. Same state rules.
    
    Command: small star or signal glyph. Same state rules.
    
    Fire for effect: stacked impact marks. Same state rules.
    
    End ship: simple check or stop bar. Same state rules.
    
    Log chevron: small downward triangle. Always present; expands on interaction.
    
    Fleet token underline: thin ember bar under the acting ship only.
    
    State is shown only by fill versus outline and by dimming. No additional colours. Cooldown (if any later) would be a thin ember sweep along the glyph edge, still within the two-colour discipline.
    
    5. Costs and risks
    
    At 1080p the shared hull/shield bars must be at least 8 px tall and the icons at least 24 px to stay legible; anything thinner becomes noise. The fleet strip at 14 ships will force name truncation; the design must accept initials-plus-bar as the default dense mode and rely on hover for full names. Art effort is modest: one set of eight simple vector glyphs plus two bar styles. Build effort is mainly layout and hover wiring; no new systems. The revision does not break the decision order or the single FIRE box. The main risk is over-compressing the guns column so that range bands become hard to parse; keep those as mono figures, never icons.
    
    6. What the current KEEL shelf does better and must keep
    
    It keeps the entire decision path on one continuous horizontal line in the exact order a player must think: identity, toughness, weapons, target, odds, commit, then orders. None of the reference UIs preserve that single-pass reading order as cleanly. The revision must not scatter those steps into vertical stacks or separate panels.
