# Pack H: Repairs Rematch (DeepSeek)

Filed by Rey from Ryan's paste, Oct 23, 2026. Model: DeepSeek (attribution confirmed by Ryan). Charter and pack: contrib/muse/prompts/ (Pack H). Screening: contrib/muse/reviews/packFGHI_screening.md. Filed as returned (final answer only; the paste's reasoning trace is not reproduced), with em dash separators normalized to house style. Claims are the model's own and are not verified by filing.

---

VERDICT: MIXED. Paid repairs are correct only in a narrow pre-elite window; they are a noob trap at the pre-boss rest stop when free drydock/field exists and after a boss. Conditions: (a) at the c3 shipyard before deliberately taking the offered c4 elite, (b) current hull low enough that losing the elite is a real risk, (c) credits cover the repair plus the forgone c3 reward, and (d) the c5 free repair cannot arrive before the fight that would kill you. If those do not all hold, do not pay.

Findings

1. OBSERVED: core.js:207: "const cols=[]; const COLS=7;"
The sector is seven forward columns and a route visits one node per column (availableNodes, core.js:300). You cannot route through every free-repair node; each column is a choice.

2. OBSERVED: core.js:228: "if(n.type==='drydock') n.type=rnd()<.5?'battle':'event';"
Drydocks in columns 1-4 are converted away. The only drydock in a sector is the pre-boss rest column, which sits after the c4 elite. There is no mid-sector free drydock to carry you into the elite.

3. OBSERVED: core.js:215: "else if(c===COLS-2) type=pick(['shipyard','drydock','field']);"
The pre-boss rest stop is a pick of shipyard, drydock or field. The guarantee at core.js:225 only ensures a drydock or a shipyard exists in that column; a free repair node is common but not guaranteed. ANNEX mapcheck row: "all 900 pre-boss nodes are rest nodes (drydock 306, field 297, shipyard 297)." 603 of 900 pre-boss nodes are free repair; 297 are paid shipyards.

4. OBSERVED: core.js:224: "if(!cols[3].some(n=>n.type==='shipyard')) pick(cols[3]).type='shipyard';"
A shipyard is guaranteed in c3, immediately before the c4 elite offer (core.js:222 guarantees an elite exists in c4, but the route can choose another c4 node). Paid repair before the elite is therefore a deliberate, optional purchase: you pay to change the odds of a fight you chose.

5. OBSERVED: campaign_run.js:185: "fix=Math.ceil(miss*.6*repairMult());"
Free repair sizes: drydock restores 60% of missing hull; field repairs 20% of max hull (campaign3d.js:41); node reward repairs 25% (campaign_run.js:245); the post-battle win patch 15% (campaign3d.js:80); sector transition 40% (campaign_run.js:313). The large free heal (drydock) is timed after the elite, not before it.

6. OBSERVED: campaign_run.js:153 (as cited; the line is core.js:153): "if(type==='elite'||type==='boss') return {k:'boon',p,min:1};"
Elite and boss nodes never roll a repair reward. Ordinary battle nodes roll repair only on the last 10% of the reward table. Reward repairs cannot be relied on to cover elite or boss damage.

7. INFERRED: repair cost vs battle income. campaign_run.js:164: "Repairs cost 1 credit per 2 hull." campaign_run.js:237: "credits=Math.round((25+12*s+3*(cfg.col||0))*kindMult...". Against the annex elite rows: S1 elite leaves 38% hull (62% missing) and pays 78 credits at column 4, covering a full repair only if fleet max hull is at most ~252. S2 elite leaves 23% (77% missing), pays 98, break-even ~255. S3 elite leaves 40% (60% missing), pays 117, break-even ~390. Elite pay roughly equals the repair bill for a starting-size fleet, which is the squeezed half of the truth.

8. INFERRED: the c5 drydock does not make pre-elite payment pointless. ANNEX row: "S2 elite | 57% | 8.1 | 23% | 3.8". A c5 drydock after that elite heals 60% of the 77% missing hull, leaving 30.8% missing before the boss. Substantial, but it arrives after the fight that decides whether you reach it. Paying at c3 buys survival probability in the elite itself; paying at c5 buys almost nothing when a drydock or field node is there.

9. OBSERVED: core.js:231: "pick(cand).type='field';"
The mid-sector field node is inserted by replacing an event or an extra battle in columns 2-4, so taking it costs a reward. The c5 drydock replaces nothing: the column is rest-only. The two free heals have different opportunity costs, and conflating them is how both earlier audits went wrong.

10. OBSERVED: campaign_run.js:313: "s.hp=Math.min(d.maxHp,s.hp+Math.round(d.maxHp*.4*repairMult()));"
After a boss, the sector transition restores 40% of max hull for free and the next sector opens on a shipyard column (core.js:213). Paying for repairs in that window is paying for hull the game is about to give you.

Not checked
- battle.js combat internals (not in this pack).
- The sim3d.js harness itself; annex figures are taken as reported.
- Event reward economics beyond the repair outcomes.
- Heat and sector conditions (the annex ran no Heat above 0).
- Shipyard purchases other than repairs (hulls, refits) except as opportunity cost.

Questions this pack cannot answer
- What is the actual max hull of the annex's fixed per-sector fleets? The break-even comparison in Finding 7 depends on it.
- What credit balance does a real route carry at c3 and c5 after events, refits and salvage?
- How often is the free c5 node actually reachable from the c4 node a given route arrives on?
- Does paying at c3 measurably change elite loss rates, or only shift hull percentages?
- Does the annex's "Hull left" include lost ships as zero hull, or only survivors?
- Do human players take the c4 elite when damaged, or skip it?
