# ChatGPT leg, Fleet calm round (issue 794)

Run Nov 15, 2026, about 10:10 to 10:21 CST. ChatGPT chat (not Work), GPT-6 at High thinking, picker verified before sending and after the answer finished. Chat: https://chatgpt.com/c/6af9d9c4-56d4-83ea-bf2a-fef2105309f5
Pack: design_pack_fleet_calm.txt (this folder's parent calm pack), asking for reference patterns from comparable games, one calmer screen with an explicit element budget, and risks.
Answer below is verbatim. Interface citation chips in the page are not part of the prose and are not reproduced.

---

1. REFERENCE PATTERNS

The most useful lesson from these games is not that their screens look clean. Several are quite busy. It is that they separate choosing a ship from understanding everything about that ship.

The current Fleet screen asks twelve ships to explain themselves simultaneously. Most successful fleet interfaces avoid that.

Sins of a Solar Empire II

At rest: The fleet manager groups ship icons under headings such as Corvettes, Frigates, Cruisers, Capital Ships and Titan. Its capital ship management screen lists ship names, levels and health alongside compact ability and equipment icons.

Hidden or separated: Detailed abilities, ship items and customization are handled through specialized management controls rather than lengthy descriptions repeated in the general fleet overview.

Transferable rule: Group ships by useful distinctions, then reveal customization for the ship being worked on. Do not show twelve equipment inventories simultaneously.

EVE Online

At rest: The fleet hierarchy identifies pilots and their positions within the command structure. The separate watchlist displays selected pilots with shield, armor and hull condition bars.

Hidden or separated: Fleet Composition provides ship types, groups, roles and locations. Detailed fitting information does not sit in the fleet window.

Transferable rule: Condition monitoring and detailed inspection are different jobs. A preparation roster should make damage obvious while leaving fitting detail one deliberate selection away.

Star Citizen

At rest: The ASOP Fleet Manager is a ship list. Entries identify vehicles, their status and location, and available actions.

Hidden or separated: Detailed ship equipment is managed in the Vehicle Loadout Manager, a different interface with component, weapon and attachment controls.

Transferable rule: A ship's availability belongs in the roster. Its internal equipment belongs in a focused editing view.

Stellaris

At rest: The Fleet Manager lists fleets and their overall strength or capacity. Inside a selected fleet, ship classes are represented compactly rather than with full weapon and component specifications.

Hidden or separated: Individual weapons, components and detailed design choices belong in the Ship Designer.

Transferable rule: Keep the fleet's total command budget visible while showing composition in compact form. The player should be able to see what the fleet contains without reading what every ship carries.

Endless Space 2

At rest: The Military screen lists fleets with information including command points, health, movement, status and location. Ships appear within their fleet context rather than as twelve equal specification cards.

Hidden or separated: The equipment area displays the selected ship's 3D model and modules. Editing the design exposes further details for that ship only.

Transferable rule: Use a persistent overview plus a selected-object inspector. Ship models can provide recognition, but they should not carry a full specification at the same time.

Homeworld

At rest: Homeworld primarily presents ships in the tactical scene, supported by compact selection and group controls. Its menus remain limited, and information is tied to selection rather than displayed for every ship.

Hidden or separated: Selection exposes relevant unit commands and status. Grouping allows many ships to be managed as a single choice.

Transferable rule: The player does not need to read a full specification to recognize a ship. A name, recognizable silhouette and limited condition information are enough at rest.

This is a tactical selection pattern rather than a directly equivalent prebattle fleet screen.

Battlestar Galactica Deadlock

At rest: The skirmish fleet editor shows individual ships in a fleet list, with point subtotals and compact statistics. It retains a direct point total while avoiding a separate full specification for each ship.

Hidden or separated: Selecting equipment slots opens choices. The prebattle FTL Insertion interface likewise exposes loadout options only for selected ships.

Transferable rule: Keep the fleet-point total visible and make equipment editing a contextual action. The point of the screen is choosing a fleet, not reading every component.

FTL: Faster Than Light

At rest: FTL is not a twelve-ship roster. Its upgrade screen focuses on one ship and shows systems through large grouped controls rather than long itemized descriptions.

Hidden or separated: Crew and equipment occupy different tabs. Detailed system explanations appear in a contextual information panel.

Transferable rule: Show the current resource tradeoff and the next meaningful choice. Keep unrelated information in separate areas.

The useful lesson is FTL's division of information, not its visual styling.

The combined lesson

I would borrow three behaviors:

1. Stellaris and EVE: Keep the full operational overview available while reducing each entry to essential information.
2. Endless Space 2 and Homeworld: Inspect one ship at a time, with a single selected visual.
3. Star Citizen, Deadlock and FTL: Expose fitting controls only when the player chooses to work on a specific ship or slot.

This is progressive disclosure: retain frequent decision information on the initial screen and reveal detailed information only through a deliberate action.

2. THE SCREEN

Design: The Fleet Manifest

Replace the twelve cards with one quiet, vertical ship manifest.

All twelve ships remain visible, but none is a card. There are no repeated statistic blocks, weapon lists or equipment paragraphs. A ship is one line. Selecting it turns the rest of the screen into its workspace.

The screen has three functional areas: the manifest, the selected ship workspace and a narrow detail sheet. The header and footer remain, but both are quieter.

Element budget

UNDAMAGED SHIP
3
Elements at rest
Deployment, name, CP cost

DAMAGED SHIP
4
Elements at rest
Plus hull condition

At rest, every ship shows:

- SAIL or RESERVE, a text control for its deployment state.
- Its name, in the display face.
- Its command point cost, in mono.
- Only if damaged, a hull percentage.

There is no FULL label on the other ten ships. A missing damage indicator means full hull, as explained by the manifest heading.

On hover or keyboard focus:

A fixed readout in the workspace shows class, mark, exact hull figures, ability name and equipped refit count.

On selection:

The workspace shows one ship visual and its refit slots. The side sheet reveals its full specification.

A full inspector may scroll internally. The manifest does not.

Layout at 1920 x 1080

Layout schematic, scaled to fit. Names, costs and slot counts are placeholders. The two damaged examples are intended to be read as the upper rows of the manifest.

Region A: Header and doctrine

X 88-1850 | Y 56-212

The title FLEET uses the display face at 42 px. A short fleet summary uses the mono face at 20 px: number sailing out of 12, total CP used out of its limit, and total credits.

Below, doctrine becomes one quiet line:

DOCTRINE [NAME] 40 CREDITS CHANGE

The name uses the display face at 28 px. Cost and action use mono at 18 to 20 px.

Do not show the doctrine's full effect sentence here.

Selecting CHANGE replaces the central ship workspace with a doctrine choice list. The focused doctrine shows its full effect sentence. Only one doctrine effect sentence is visible at any time. The rest of the roster stays visible.

Region B: Ship manifest

X 88-758 | Y 246-934 | Width 670

This is the heart of the redesign.

Two plain section headings:

DAMAGED 2
FULL HULL 10

Under them are twelve rows, approximately 50 to 52 px high.

The ship name uses the display face at 28 px. Deployment and command cost use 18 px mono. Damaged hull percentage uses 18 px mono.

Rows are ordered with damaged ships first, then a stable class and name order. Toggling SAIL or RESERVE does not reorder the rows.

No backgrounds, card outlines, divider boxes or status pills. Selection is shown by full-strength text and a small marker. Everything else is dimmed.

Clicking the ship name selects it. Clicking SAIL or RESERVE changes only its deployment state.

The roster is not filtered to sailing ships, because the player needs to compare reserves before choosing who enters battle.

All twelve fit without scrolling.

Region C: Selected ship workspace

X 810-1470 | Y 250-934 | Width 660

When nothing is selected, this region is mostly empty darkened scene with a quiet instruction to select a ship.

When one ship is selected, show one large, still ship model or recognizable silhouette. Use an existing model rather than a new illustration.

Below the visual, show that ship's refit slots only.

An empty slot needs only its slot identity and EMPTY. It does not need a paragraph, explanation or decorative outline.

Selecting a slot or MANAGE REFITS changes this workspace into the refit chooser, without creating a separate modal screen. The chooser lists available refits and identifies their current ship when equipped. Selecting a refit replaces the one in that slot.

The explanatory sentence about free refit movement appears here, at the point of use, rather than above the roster.

Region D: Detail sheet

X 1510-1850 | Y 250-934 | Width 340, 17.7% of screen

The sheet is text on the scene darkening, not a visible panel.

It opens for the selected ship and contains the original data in a readable order:

Ship name, class and mark; exact hull and segmented condition bar; CP cost; shields and regeneration; armor; speed; turns; evasion; ability name and rule sentence; weapons 1 to 3 with arc, damage, range and reload where applicable; captain name and rank; experience 0/30 toward Commander; and captain perks, currently none.

The name uses the display face at 28 px. Sentences use the text face at 18 px with sufficient line spacing.

The information may scroll vertically within this sheet. Weapon rule lines wrap naturally. Nothing is clipped at 1920 x 1080.

Refit editing stays in the central workspace, so the same empty slots are not duplicated here.

Region E: Footer and DONE

X 88-1850 | Y 966-1040

A compact prebattle summary shows the number sailing and, if applicable, how many damaged ships will enter battle. CP use and the remaining limit are shown, so the player does not need to calculate.

DONE remains the only outlined box on the screen, at the lower right, approximately 190 by 64 px.

If command limits or other actual fleet rules are violated, DONE is unavailable with a readable explanation.

Doctrine, damage and color rules

The two damaged ships are the only entries with hull warnings in the manifest. Both are at 30% hull, which the manifest shows directly.

Damage is communicated through words, numbers and ordering. No red is used, since red belongs to the combat warning language.

Ember orange is used only for the currently actionable command and its target. The DONE outline may be ember.

Glacier blue appears only on shield figures and any shield readout. Hull bars remain neutral.

All text respects the three strength levels. Full strength carries names, decisions and important figures. Dimmed text carries secondary information. Dark text belongs to the scene.

Use darkening behind text sufficient to hold at least 4.5:1 contrast. No glows, shadows, pills, decorative outlines or repeated statistic blocks.

Relocation of every current card line

| Current information | New location |
| Ship name | Manifest at rest; selected sheet |
| Mark, such as MK I | Hover readout; selected sheet |
| Ship class | Hover readout; selected sheet |
| Exact current and maximum hull | Hover readout; selected sheet |
| Segmented hull bar | Selected sheet only |
| Hull damage percentage | Manifest, damaged ships only |
| Command point cost | Manifest at rest; selected sheet |
| Shields | Selected sheet, glacier blue |
| Shield regeneration | Selected sheet beside shields |
| Armor | Selected sheet |
| Speed | Selected sheet |
| Turns | Selected sheet |
| Evasion | Selected sheet |
| Ability name | Hover readout; selected sheet |
| Ability rule sentence | Selected sheet |
| Weapon 1 name, arc, damage, range, reload if applicable | Selected sheet |
| Weapon 2, same fields | Selected sheet |
| Weapon 3, if present, same fields | Selected sheet |
| Captain name | Selected sheet |
| Captain rank, Lieutenant | Selected sheet |
| Experience, 0/30 toward Commander | Selected sheet |
| Captain perks, currently none | Selected sheet, with none stated compactly |
| REFITS heading | Selected ship workspace only |
| Each empty refit slot | Selected ship workspace only |
| Rule that refits move freely | Refit chooser |
| Repairs at shipyards and drydocks | Damaged ship inspection, not a global banner |
| Mark upgrades at shipyards | Selected ship mark information |
| Doctrine name | Header at rest |
| Doctrine full effect | Doctrine chooser and detail sheet |
| Doctrine cost, 40 credits | Header and doctrine chooser |
| DONE | Footer, unchanged |

Nothing is deleted. Only the layer at which it appears changes.

Why keep all twelve visible?

There is no paging cost in this design.

A compact manifest can fit all twelve ships because it no longer carries twelve independent specification cards, weapon lists and repeated labels.

The tradeoff is that class and specialized capabilities are not visible for every ship simultaneously. They are available through hover, focus or selection.

The redesign should be judged on whether players can identify damaged ships, understand the CP budget and choose a fleet without losing track of reserves.

3. RISKS

Risk 1: Hiding information makes ship choices harder

Failure:

The manifest is calmer, but a player cannot distinguish two full-health ships that serve different tactical roles. The roster might also conceal a weapon range or speed difference that would change the chosen fleet.

This would be a bad trade. Cleanliness is not the goal if it makes fleet planning worse.

Answer:

Keep CP cost, deployment state and damage visible. Provide class, mark, ability name and refit count through hover or keyboard focus, with the full specification available on selection.

Test this with a concrete task: ask a player to choose a fleet within a CP limit while retaining the fastest ship, then check whether the answer required selection. If several deliberate selections are needed for a routine choice, the manifest is too sparse.

Risk 2: The calmer surface hides preparation problems

Failure:

A player sends a damaged ship into battle unintentionally, overlooks a CP violation, changes doctrine without noticing the 40 credit cost, or assumes repairs can be performed on this screen.

A visually quiet screen can still be operationally dangerous.

Answer:

Keep both damaged ships grouped at the top, show CP use against the limit persistently, and make the footer state how many damaged ships will sail. Keep the doctrine cost attached to the doctrine line and its chooser.

Repairs and mark upgrades are never presented as actions available on this screen. The selected ship sheet states that those changes happen at shipyards and drydocks, while the roster itself shows damage clearly.

These protections remain textual and compact. They do not require additional panels, bright warning colors or a permanent banner.

The strongest acceptance test is simple: from the default Fleet screen, a player must be able to identify both damaged ships, decide which of them can still sail, and say how much fleet capacity remains.

Verdict: Single DONE button
