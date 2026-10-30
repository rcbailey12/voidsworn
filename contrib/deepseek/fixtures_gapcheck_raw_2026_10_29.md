FIXTURES HAVE GAPS

Missing cases

post-win meta | meta with non-empty stats.wonFacs, wins > 0, multiple fallen entries, and earned unlocks/variants | importer could drop wonFacs, lose earned progression, or confuse earned unlocks with the boot grant.

partial grant | full boot grant plus real earned unlocks, variants, wins, and renown that can support some spend | strip/flag logic may remove legitimately earned unlocks or fail to isolate only the granted portion.

reward-less run | in-progress run with reward: null and nem: null, as in early-sector play | importer may assume reward/nemesis objects always exist and crash or drop the run.

reward stages | valid reward with non-null modOffer, non-empty wrecks / prizes, and stage mod, prize, or promo | importer may only carry the relic/boon mid-choice and re-roll or drop fixed mod/prize/wreck choices.

fleet edge states | fleet at max size, ships with cap.pending > 0, zero/low hp, no captain, or custom names | importer may clamp/drop pending promotions, captains, or hull states at limits.

non-first flagship | flagUid referencing a non-first ship, or a dangling/missing flagUid | importer may assume the first fleet ship is the flagship or fail to preserve the internal reference.

dangling refs repair | run with invalid run.pos / curNode, duplicate ship uid, or map-node/flagUid references that do not resolve | repaired fixture only covers unknown data ids; importer could crash or silently reset map position/flagship.

both-corrupt / half-sound | primary and .bak both unusable, or one parses but fails saneSave while the other half is sound | importer may not implement README fallback/keep-sound-half semantics and lose recoverable meta or run.

settings/options | non-save localStorage keys or persisted user options such as audio/UI/unlockAll | importer may ignore user settings or treat them as save data.

sector boundary | run at sector transition, completed map/boss node, or sector-advance reward pending | importer may mishandle completed-map state or advance state not represented by the mid-sector fixture.

Weak cases

unlocked: it has the all-grant/no-spend signature and a pre-grant .bak, but no earned unlocks/variants in the same profile; it cannot confirm detection distinguishes a granted unlock from an earned one, despite the README claiming the .bak pair lets a test confirm that distinction.

midrun: the Nemesis traits/weaknesses and hull variant are produced by shuffles and "first non-arc" selection, not fixed to the README's named deadeye / regrowth, slow / flank, slow revealed, and vs_harrow_t; the fixture guarantees a valid generated state, not the exact named state.

repaired: it contains no unknown meta ids, so it does not exercise the README's stated asymmetry that meta ids get no repair pass; its silentlyChanged metadata also omits the prize-list emptying that the README calls a silent change.

Not checked

The actual fixture JSON files are not attached, so the README and generator do not let me verify the generated values, the exact 12-entry repair list, the storeAfter / .repaired audit copy, or that the verification pass actually passed.

I cannot check Godot-side parity: whether Godot's defaultMeta, migration stamps, saneSave, and repairRunIds truly match the browser side, nor whether Godot tables accept every id used here.

I cannot verify real-game reachability details from these files alone: max fleet size, full reward-stage enum, whether settings/options exist outside voidsworn.v1, or whether the midrun Nemesis/variant values actually match the README under the current data tables.
