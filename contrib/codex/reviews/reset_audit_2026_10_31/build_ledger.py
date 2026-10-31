"""Rebuild the disposition register; statuses are review judgments, not inferred from grep."""
import csv, json, re, pathlib, collections
root = pathlib.Path(__file__).resolve().parents[4]
out = pathlib.Path(__file__).resolve().parent
register = root / 'contrib/muse/tools/findings_tests/README.md'
rows = []
for n, line in enumerate(register.read_text().splitlines(), 1):
    m = re.match(r'\| ([A-Z][A-Z0-9]*-\d+) \| (.*?) \| (.*?) \| (.*?) \|$', line)
    if m:
        rows.append(dict(id=m[1], claim=m[2], severity=m[3], muse_status=m[4], register_line=n))
assert len(rows) == 125
tested = {}
for line in (out / 'findings_test_run.txt').read_text().splitlines():
    m = re.match(r'(PASS|FAIL) ([A-Z][A-Z0-9]*-\d+)', line)
    if m: tested[m[2]] = m[1]
# Source checks below were read in their surrounding control flow, rather than
# treating symbol presence or an absent field as proof of runtime behavior.
source = {}
def group(ids, evidence, note, status='SOURCE_SUPPORTED; DESIGN/SEVERITY SEPARATE'):
    for ident in ids.split(): source[ident] = (status, evidence, note)
group('ADM-3 ADM-4', 'data.js:218-221', 'Names promise interdiction/ram/board; absence of a dedicated modifier does not prove an incoherent or broken admiral.', 'DESIGN_JUDGMENT')
group('EVT-1', 'campaign_run.js:218-239; independent_probes.json', 'Picking defector ransom still satisfies a presence-only defector flag requirement.', 'CONFIRMED_RUNTIME')
group('EVT-4', 'data.js EVENTS; price_ladder_synthesis.md:54', 'A no-shipyard-repair ruling does not by itself ban event healing.', 'QUALIFY_SCOPE')
group('TXT-1', 'campaign_meta.js:150-167; main3d.js:11; core.js:258', 'Availability matches browser boot grant; fourth aspect is mastery-unlocked; sector-entry shipyard exists. Legendary omission is real. Rewrite for new progression, not four blanket contradictions.', 'MIXED')
group('TXT-2', 'campaign_run.js:360,369; independent_probes.json', 'Two-ship probe repairs the upgraded ship twice. Re-sorting after healing then selecting index 1 is the bug; no same-name first-match lookup causes it.', 'CONFIRMED_BUG; LEDGER_MECHANISM_WRONG')
group('TXT-3', 'campaign_run.js:171; core.js:217', 'Shop renders raw W[id].n while derived weapons use faction-aware nameWeapons.')
group('TXT-5', 'campaign_run.js:227,411', 'Requirement text and reward promotion notice use RANKS; other promotion paths already use rankName.', 'SOURCE_SUPPORTED_PARTIAL')
group('TXT-7', 'battle.js:575-585; campaign_run.js:303', 'Battle fleeing, rout and narrative early-sector scar escape are different. Never retreats is not automatically false because a destroyed rival escapes in fiction.', 'QUALIFY_SEMANTICS')
group('TXT-8', 'campaign_run.js:174; data.js:544-546', 'NaN is conditional on a genuinely unpriced hull. Ordinary non-Crusade roster hull prices are derived.', 'CONDITIONAL_ONLY')
group('PROG-1', 'main3d.js:11', 'Browser boot grant is real. It does not establish a Godot boot or parity grant.', 'SOURCE_CONFIRMED_BROWSER_ONLY')
group('PROG-2 PROG-3 PROG-6', 'campaign_meta.js:120-144; campaign3d.js:119; core.js:newRun', 'Old purchase/lock flow is incomplete. New leveling rulings govern the replacement; do not restore the old shop just to clear an audit row.')
group('PROG-4 LOOP-1', 'campaign_meta.js:188-214', 'Carried forward already lists renown/mastery. Missing sync delta and generational framing are narrower presentation gaps.', 'QUALIFY_PAYOFF')
group('PROG-5', 'campaign_run.js:398; campaign_meta.js:195', 'Elite contributes 3 XP and boss 6. Arithmetic is confirmed; intended weighting is not established.', 'ARITHMETIC_CONFIRMED; INTENT_UNPROVEN')
group('RWD-1', 'campaign_run.js:447-451', 'Default follows a local heuristic, not globally optimal strategy. Convenience defaults are a design choice.', 'DESIGN_JUDGMENT')
group('RWD-5', 'campaign_run.js:ACT.boonDecline; rollNodeReward', 'Credit node pays five more guaranteed credits. Offer option value does not prove strict dominance; the rebalance ruling remains valid.', 'QUALIFY_DOMINANCE')
group('RWD-6', 'campaign_run.js:ACT.boonReroll; core.js:rollBoonOffer', 'Identities can repeat, but rarity may improve. Not universally a paid no-op.', 'QUALIFY_VALUE')
group('RWD-7', 'campaign_run.js:428-441', 'Fixed salvage priority and ransom ordering are real. Whether deterministic rewards are bad is design.')
group('BF-1', 'battle.js:289-294,343', 'Spawn-clearing mechanism exists; shape-by-shape identity erosion was not measured here.', 'MECHANISM_SUPPORTED; MAGNITUDE_UNVERIFIED')
group('BF-2', 'battle.js:313', 'Each rock has .45 removal probability; a board need not lose exactly 45%.')
group('BF-4', 'battle.js:16,280-284', 'The well is separate from terrainPresent. Godot presentation is a separate check.')
group('BF-5', 'battle.js:deploy', 'Deployment fallback risk is plausible, but no independently reproduced collapse geometry is claimed.', 'INFERRED; NOT_REPRODUCED')
group('BF-7 BF-8', 'battle.js:27-30,231', 'Parallel wall and left/right spawn selection exist. Actual unfair geometry and intended lane orientation remain design/play checks.', 'SOURCE_SUPPORTED_RISK')
group('FGT-2 FGT-3', 'battle.js:61-69; escortsBreak; checkEnd; campaign_run.js:encounterPreview', 'Objectives and escape paths exist. Own boss table is ruled; exact preview thresholds need presentation checks.', 'QUALIFIED_SOURCE')
group('NEM-2', 'campaign_run.js:287-291', 'Adaptation candidate filtering never checks revealed weaknesses. Add the ruled clash predicate.')
group('NEM-3', 'campaign_run.js:287-291,535', 'Cumulative cap and fallback are real; one addition per sector transition is compatible with a cumulative cap.', 'QUALIFY_CADENCE')
group('NEM-4', 'campaign_run.js:276-281; battle.js:546-578', 'Only two immediate map effects; other faction behaviors are implemented in battle, as the synthesis itself notes.', 'FACT_TRUE; MISSING_IMPLEMENTATION_NOT_PROVEN')
group('NEM-5', 'campaign_run.js:268-281', 'Warning samples current credits/hull; later outcomes and event-driven clock fills can change the result.')
group('NEM-6', 'campaign_run.js:303', 'Explicit scar-and-escape branch explains early-sector flagship destruction, including Eclipse in its comment.', 'QUESTION_RESOLVED_BY_SOURCE')
group('NEM-7', 'campaign_run.js:254', 'Ten-field preservation applies to pre-persona legacy saves, not normal current play.', 'SOURCE_SUPPORTED_LEGACY_ONLY')
group('ROS-7 ROS-8', 'data.js:HULLS', 'Launch concentration and kit overlap are table facts; dedicated carriers/boss-exclusive abilities are design choices.')
group('WPN-4', 'battle.js:531-536', 'Comment differs from live ring/range constants. Correct the record deliberately rather than retuning accidentally.')
group('SQ-2 SQ-3 SQ-4', 'battle.js:139-165; WING_SCREEN_TORP; campaign_run.js:wingPerkGrant', 'Carrier seed/generic fill, screen cap, and random perk grants are mechanisms; replacement designs are not correctness fixes.')
group('MOD-1', 'campaign_run.js:128-143', 'Free fitting is explicit. No friction target is ruled.', 'DESIGN_JUDGMENT')
group('MOD-3', 'campaign_run.js:128-140; godot/campaign/campaign.gd:1312-1325', 'Fit guard checks ability only; authoritative equip action needs the same kind/shield validation.', 'SOURCE_SUPPORTED_BOTH_BUILDS')
group('MOD-5', 'data.js:577', 'Unused FIT_SLOTS cannot currently reserve a slot. Resolve design before implementing it.', 'DEAD_SCHEMA; NOT_ACTIVE_COLLISION')
group('AI-1', 'battle.js:1385-1396; godot/rules/rules.gd:3932-3973', 'Both implementations return from mid-move volley before brace decision. Preserve boarding precedence when fixing.', 'SOURCE_SUPPORTED_BOTH_BUILDS')
group('AI-2 AI-3 AI-4 AI-5', 'battle.js:156,1335,1371-1377', 'Ceiling stranding, flat death cliff, approach leash and pre-move ability pass exist. Their desirability needs outcome testing.')
group('BN-4', 'battle.js:909-915; independent_probes.json', 'Both failed/non-capture branches sabotage under boardPct. Successful capture is not a failed boarding. Three branch probes confirm the promise.', 'REFUTED_RUNTIME')
group('ECO-1', 'economy_synthesis_2026_10_29.md:final addendum', 'Accepted as is pending play data. Do not reopen the headline blocker.', 'CLOSED_RULING')
group('ECO-3', 'core.js:192-193; campaign_run.js:203', 'Scrap payout ignores hull condition; runtime probe confirms it. Desired policy is design.')
group('ECO-4', 'campaign_run.js:439-443; core.js:227', 'Prize valuation uses base value while shops apply priceMult; relative purchasing power changes as described.')
group('FR-1 FR-4', 'ui3d.js:654; campaign_run.js:mapScreen,rewardBadge', 'Browser campaign tip coverage and reward-role explanation are missing. Use current approved protocol vocabulary, not obsolete Boon copy.', 'SOURCE_SUPPORTED_BROWSER')
group('FR-2', 'campaign_run.js:298-310; godot/campaign/campaign.gd:1757', 'Loss branch lacks nemReveal in both sources; in-battle triggered discovery still exists.', 'SOURCE_SUPPORTED_BOTH_BUILDS')
group('FR-3', 'ui3d.js:654-661', 'One tipcard at a time is enforced. Cards may appear serially after acknowledgement, not stack simultaneously.', 'QUALIFY_WORDING')
group('FS-1 FS-3', 'battle.js:139-165; data.js:HULLS', 'Generator spends CP and low-class CP is symmetric. Stats per CP are still asymmetric; own stats/price/CP ruling needs measured implementation.')
group('FS-5', 'battle.js:503-511,817,941; godot/rules/rules.gd:1651,2741; independent_probes.json', 'Kill feed heals killer 12 and neighbor 6 in the controlled probe; bite returns 8 on 100 hull damage. Both mechanics already exist.', 'REFUTED_RUNTIME_BOTH_SOURCES')
group('DRIFT-1', 'godot/campaign/test/node/env.js:15; oracle/campaign3d.js:119', 'Loader excludes main3d.js. Existing unlock reference is a handler, never boot invocation. Fresh parity load has unlocked {} and admirals {vex:true}.', 'REFUTED_RUNTIME')
group('DRIFT-2', 'scene3d.js:4; main3d.js:11', 'Browser pointer/window detection can trigger PC overrides. Not a Godot mobile path.', 'SOURCE_SUPPORTED_BROWSER_ONLY')
group('DRIFT-4', 'NEXT.md; PROGRESS.md; BACKLOG.md', 'Historical guidance needs authority/date banners, not deletion.', 'SOURCE_SUPPORTED_DOCUMENTS')
group('DRIFT-5', 'campaign_meta.js:14; independent_probes.json', 'Specific Click to fire replacement precedes generic Click; output is Tap again to fire. Asserted ordering is reversed.', 'REFUTED_RUNTIME')
group('UI-1 UI-2 UI-3 UI-4', 'ui3d.js:selectUnit,rosterPick,onPick,attackMovePlan', 'Browser interaction facts support the usability concerns. Ruled phased activation belongs to Godot, not incidental browser cleanup.', 'SOURCE_SUPPORTED_BROWSER')
group('UI-5', 'ui3d.js:425-426; selectUnit', 'Some cancel paths retain wingSel, but empty-board click and wing toggle also clear it; only order assignment clears it is overbroad.', 'QUALIFIED_SOURCE')
group('UI-6 UI-7 UI-8', 'ui3d.js:161,393,666-669', 'Incomplete help, hint predicate and gun-count-facing behavior are visible in source; usability severity is separate.', 'SOURCE_SUPPORTED_BROWSER')
group('UI-9', 'ui3d.js:boardTip,moveDmgLine', 'Damage line lacks name, but adjacent gun-count line prints st.gunTarget. Inspect rendered context before claiming the preview is untargeted.', 'QUALIFY_CONTEXT')
group('MOD-4', 'data.js:154,164; core.js:215; independent_probes.json', '4% hull regeneration can outperform an upfront buffer under sustained armor-bypassing damage. Test compares prices, not dominance. DeepSeek explicitly separated sustain from burst.', 'REFUTED_DOMINANCE')
group('KIT-3', 'data.js:126; godot/fx/faction_looks.json', 'Browser green fields reproduce; Godot FX uses violet/white-gold data. Current rendered appearance was not certified.', 'BROWSER_DATA_TRUE; GODOT_DIFFERENT')
group('ROS-4', 'battle.js:490,513,938; data.js:HULLS', 'Boss/gun overlap reproduces, but revival is a shared budget, not one per harvester; boss and flagship exclusions are explicit.', 'QUALIFY_MECHANISM')
group('MOD-2', 'data.js:MODULES,PERKS,RELICS; core.js:derive', 'Stat overlap and shared key strings in separate tables are real. No untyped lookup collision was demonstrated; keep stable ids.', 'OBSERVATION_TRUE; DEFECT_UNPROVEN')
group('FS-2', 'data.js:538-546', '370 vs 390 follows if a new cp6 Battleship is added. No such live hull exists yet; proposal fixes its key.', 'HYPOTHETICAL_PRICE_GAP_CONFIRMED')
for row in rows:
    ident = row['id']
    if ident.startswith('HUD-'):
        status, evidence, note = 'UNVERIFIED_VISUAL', 'hud_synthesis_2026_10_27.md', 'Original captures/current rendered build not inspected. Source cannot certify screen composition.'
    elif ident == 'ADM-7':
        status, evidence, note = 'UNVERIFIED_VOICE', 'data.js; lore_bible_r8.md', 'Requires exact speaker/narrator context, not blanket rejection of every singular pronoun.'
    elif ident in source: status, evidence, note = source[ident]
    elif ident in tested:
        status, evidence, note = 'OBSERVATION_REPRODUCED_' + tested[ident], 'findings_test_run.txt', 'Reproduced after portability repairs. Establishes tested fact, not automatically a correctness defect or approved design target.'
    else: status, evidence, note = 'UNVERIFIED', '', 'No independent verification claimed.'
    row.update(codex_status=status, evidence=evidence, disposition=note)
with (out/'claim_ledger.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
counts=collections.Counter(row['codex_status'] for row in rows)
summary={'pin':'cc2d35fd7054458c1e5707561bb9c6a5da2e4227','current_register_rows':len(rows),'statuses':counts}
(out/'coverage_summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
