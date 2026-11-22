// ======================= DATA =======================
const W = {
  autocannon:{n:'Autocannon',k:'battery',shots:3,dmg:5,r:4,opt:2,acc:80,fall:8,crit:5},
  flak:{n:'Flak battery',k:'flak',shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6},
  battery:{n:'Gun battery',k:'battery',shots:4,dmg:6,r:5,opt:3,acc:72,fall:8,crit:5},
  hbattery:{n:'Heavy gun battery',k:'battery',shots:5,dmg:7,r:5,opt:3,acc:72,fall:8,crit:6},
  lance:{n:'Lance array',k:'lance',shots:1,dmg:20,r:7,opt:6,acc:82,fall:6,pierce:.6,crit:10},
  torp:{n:'Torpedo salvo',k:'torp',shots:1,dmg:42,r:6,opt:6,acc:64,fall:0,pierce:.3,crit:15,cd:2,evMult:2},
  turret:{n:'Dorsal turret',k:'battery',shots:2,dmg:8,r:5,opt:3,acc:74,fall:8,crit:5},
  laser:{n:'Laser cannon',k:'battery',shots:2,dmg:7,r:4,opt:3,acc:80,fall:8,crit:5},
  turbo:{n:'Pulse laser',k:'battery',shots:2,dmg:9,r:5,opt:3,acc:74,fall:8,crit:5},
  hturbo:{n:'Heavy pulse laser',k:'battery',shots:3,dmg:9,r:6,opt:4,acc:72,fall:7,crit:6},
  ion:{n:'Ion cannon',k:'lance',shots:1,dmg:12,r:6,opt:5,acc:80,fall:6,ion:2.7,crit:4},
  scatter:{n:'Scatter cannons',k:'battery',shots:5,dmg:5,r:3,opt:2,acc:78,fall:10,crit:6},
  htorp:{n:'Heavy torpedoes',k:'torp',shots:2,dmg:34,r:6,opt:6,acc:60,fall:0,pierce:.3,crit:15,cd:2,evMult:2},
  tendril:{n:'Boarding tendrils',k:'bio',shots:2,dmg:11,r:1,opt:1,acc:85,fall:0,pierce:.5,crit:12},
  bioplasma:{n:'Bile spray',k:'bio',shots:2,dmg:10,r:4,opt:3,acc:74,fall:8,pierce:.2,crit:8},
  spores:{n:'Spore drifts',k:'flak',shots:3,dmg:4,r:2,opt:2,acc:78,fall:8,vsSq:3,vsCap:.6},
  pulsar:{n:'Prism lance',k:'lance',shots:2,dmg:12,r:6,opt:5,acc:80,fall:6,pierce:.6,crit:10},
  startorp:{n:'Star torpedo',k:'torp',shots:1,dmg:38,r:5,opt:5,acc:66,fall:0,pierce:.4,crit:15,cd:2,evMult:2},
  gauss:{n:'Null cannon',k:'gauss',shots:3,dmg:6,r:5,opt:3,acc:74,fall:8,pierce:0.6,crit:5},
  nlance:{n:'Null lance',k:'gauss',shots:3,dmg:15,r:6,opt:4,acc:74,fall:8,pierce:0.6,crit:5}, // issue 784 (R256): the Eclipse flare's one forward gun, a glass cannon: heavier and longer than a null cannon, forward only
  gsentry:{n:'Null sentries',k:'flak',shots:2,dmg:4,r:3,opt:3,acc:80,fall:10,vsSq:3,vsCap:.6}, // R1 (Nov 1, WPN-1): no longer a copy of flak: one fewer shot, a heavier hit and one hex more reach
  doom:{n:'Corona arc',k:'lance',shots:1,dmg:40,r:5,opt:4,acc:78,fall:6,pierce:.6,crit:12,cd:2},
  shard:{n:'Shard cannon',k:'battery',shots:3,dmg:6,r:4,opt:2,acc:80,fall:8,crit:6,vsSq:1.6},
  guns:{n:'Interceptor guns',k:'sq',shots:3,dmg:4,r:1,opt:1,acc:82,fall:0,vsSq:2.2,vsCap:.5},
  bombs:{n:'Bomb payload',k:'sq',shots:2,dmg:9,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.2,crit:10},
  sporeb:{n:'Spore burst',k:'sq',shots:2,dmg:10,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.3,crit:8},
};
const ARC_NAME = {F:'Fore',P:'Port flank',S:'Starboard flank',T:'Turret (all arcs)',R:'Aft'};
// usage.fire keys: fixed per arc (the pre-rename labels) so saved careers and story reads never move with display words (issue 1551)
const ARC_USAGE_KEY = {F:'Prow',P:'Port broadside',S:'Starboard broadside',T:'Turret (all arcs)',R:'Rear'};
const KIND_NAME = {battery:'Battery',lance:'Lance',torp:'Torpedo',flak:'Point defense',bio:'Bio-weapon',gauss:'Null',sq:'Squadron'};

// Ship templates. size = draw scale; cp = command points.
// v46: each faction names (and draws) its guns its own way; the numbers underneath are unchanged until the v47 mechanics pass
const FAC_WNAMES={
  voidsworn:{autocannon:'Sear repeater',battery:'Sear battery',hbattery:'Heavy sear flank battery',turret:'Sear turret',lance:'Oath lance',torp:'Cinder torpedo',flak:'Spark flak'},
  hegemony:{laser:'Plasma cannon',turbo:'Plasma battery',hturbo:'Heavy plasma battery',ion:'Ion cannon',flak:'Picket lasers'},
  corsair:{autocannon:'Autocannon',scatter:'Scrap scatter gun',turret:'Junk turret',torp:'Rattle-rocket pod',htorp:'Heavy rocket pod',flak:'Chaff guns'},
  chorus:{bioplasma:'Spine volley',tendril:'Boarding tendrils',spores:'Spore cloud',sporeb:'Acid sacs'},
  ithar:{shard:'Prism shards',pulsar:'Prism lance',startorp:'Star torpedo',turret:'Needle beam',flak:'Mirror veil'},
  deathless:{gauss:'Null cannon',doom:'Corona arc',gsentry:'Null spire',flak:'Null shredder'}};
function wName(fac,id){ return (FAC_WNAMES[fac]&&FAC_WNAMES[fac][id])||(W[id]&&W[id].n)||id; }
// v48 faction weapon traits: same hulls and budgets, but each faction's guns behave differently
const WTRAITS={
  las:{d:'+4 aim, half the long-range aim falloff',f:w=>{ w.fall=Math.ceil(w.fall/2); w.acc+=4; }},
  hellfire:{d:'hull hits ignite ships: 6 damage a turn for 2 turns',f:w=>{ w.ignite=1; }},
  plasma:{d:'a quarter burns through shields, +1 damage',f:w=>{ w.pierce=Math.max(w.pierce||0,.25); w.dmg+=1; }},
  scrap:{d:'an extra shot, -12 aim, +3% crit',f:w=>{ w.shots+=1; w.acc-=12; w.crit=(w.crit||0)+3; }},
  rockets:{d:'a rocket salvo: hard to dodge, but point defense can shoot rockets down',f:w=>{ w.shots*=3; w.dmg=Math.round(w.dmg/2.9); w.acc+=2; w.evMult=1.5; w.rockets=1; }},
  spines:{d:'hull hits strip 3 armor points, up to 15',f:w=>{ w.shred=.03; }},
  acid:{d:'hull hits leave acid: 4 hull a turn for 2 turns, through shields and armor',f:w=>{ w.acid=1; }},
  needle:{d:'precise: +6 aim, +8% crit',f:w=>{ w.acc+=6; w.crit=(w.crit||0)+8; }},
  star:{d:'fast: hard to dodge',f:w=>{ w.evMult=1.2; }},
  gauss:{d:'ignores half of armor',f:w=>{ w.armorPierce=.5; }}};
const FAC_WTRAIT={voidsworn:{autocannon:'las',battery:'las',hbattery:'las',turret:'las',torp:'hellfire'},hegemony:{laser:'plasma',turbo:'plasma',hturbo:'plasma'},
  corsair:{autocannon:'scrap',scatter:'scrap',turret:'scrap',torp:'rockets',htorp:'rockets'},chorus:{bioplasma:'spines',tendril:'acid',sporeb:'acid'},
  ithar:{shard:'needle',turret:'needle',startorp:'star'},deathless:{gauss:'gauss',nlance:'gauss',doom:'gauss'}};
function nameWeapons(fac,list){ for(const w of list){ w.n=wName(fac,w.id); const tk=!(typeof process!=='undefined'&&process.env&&process.env.NOTRAITS)&&FAC_WTRAIT[fac]&&FAC_WTRAIT[fac][w.id]; if(tk&&WTRAITS[tk]&&!w.trait){ w.trait=tk; WTRAITS[tk].f(w); } } return list; }

// Ship class display names (lore round 8, rename map row 4.0): cls values stay as lookup keys (models, sizes, fx); show a class through clsName().
const CLS_NAME={'Battle-barge':'War-barge','Bio-titan':'Colossus','Ark':'Lattice-ship','Tomb-ark':'Archive-ship'}; function clsName(c){ return CLS_NAME[c]||c; }
// Shield model (R246, issue 371): one shield pool per ship instead of four side strengths.
// The pool holds shMax = sh * SHIELD_POOL_MULT points; each side catches up to pool * coverage of a hit;
// when a side is hit the ship routes power to it (coverage +SHIELD_ROUTE_BOOST) but routed absorption
// drains (1 + SHIELD_ROUTE_LOSS) pool per point, so reinforcing the struck side burns the pool.
// When the pool empties (under 1 point), shields drop on every side at once. Coverage: [prow, starboard, rear, port].
// The pool regenerates rg * SHIELD_REGEN_MULT a turn. Every number here is the Board's tuning value (issue 371), not an owner rule:
// pool x2 and regen x1.25 put the share of damage shields stop back at main's level (balance pack in the issue 371 pull request).
const SHIELD_POOL_MULT=2;
const SHIELD_REGEN_MULT=1.25;
const SHIELD_POOL_FAC={ithar:.5}; // the Glasswrights' prism refills the whole pool, so their pool is one old facing's worth (x1): glass, not a wall
const SHIELD_ROUTE_LOSS=.3;
const SHIELD_ROUTE_BOOST=.2;
const SHIELD_COV_MAX=.95;
const SHIELD_COV_MIN=.2;
const SHIELD_COV={Frigate:[.85,.55,.40,.55],Destroyer:[.85,.60,.45,.60],Cruiser:[.90,.65,.50,.65],Carrier:[.80,.60,.50,.60],Battleship:[.90,.70,.55,.70],Dreadnought:[.90,.70,.60,.70]};
const SHIELD_COV_FAC={voidsworn:[.05,0,0,0],hegemony:[0,.05,.05,.05],corsair:[-.05,0,-.05,0],ithar:[.05,.05,.10,.05]};
const HULLS = {
  // ---- player: Voidsworn gothic fleet
  warden:{n:'Warden-class frigate',cls:'Frigate',fac:'voidsworn',size:.5,cp:1,hp:50,sh:10,rg:5,ar:.1,sp:5,tn:3,ev:20,w:[['autocannon','F'],['flak','T']],ab:'evasive',slots:1,cost:70},
  harrow:{n:'Harrow-class destroyer',cls:'Destroyer',fac:'voidsworn',size:.6,cp:2,hp:85,sh:14,rg:6,ar:.15,sp:4,tn:2,ev:12,w:[['torp','F'],['turret','T']],ab:'reload',slots:1,cost:130},
  penitent:{n:'Vigil-class cruiser',cls:'Cruiser',fac:'voidsworn',size:.76,cp:3,hp:135,sh:20,rg:8,ar:.2,sp:3,tn:2,ev:5,w:[['battery','P'],['battery','S'],['lance','F']],ab:'focus',slots:2,cost:200},
  reliquary:{n:'Hearth-class carrier',cls:'Carrier',fac:'voidsworn',size:.84,cp:4,hp:130,sh:22,rg:9,ar:.15,sp:2,tn:1,ev:0,w:[['turret','T'],['flak','T']],ab:'launch',hangar:2,slots:2,cost:260},
  cathedral:{n:'Bastion-class battleship',cls:'Battleship',fac:'voidsworn',size:.95,cp:5,hp:220,sh:30,rg:12,ar:.3,sp:2,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['lance','F'],['flak','T']],ab:'surge',slots:3,cost:340},
  ascendant:{n:'Daybreak-class dreadnought',cls:'Dreadnought',fac:'voidsworn',size:1.18,cp:8,hp:370,sh:32,rg:15,ar:.35,sp:2,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']],ab:'nova',slots:3,cost:520,unique:true},
  // ---- squadrons (shared)
  fighter:{n:'Fighter wing',cls:'Squadron',size:.34,cp:0,hp:18,sh:0,rg:0,ar:0,sp:6,tn:9,ev:35,w:[['guns','T']],sq:'fighter'},
  bomber:{n:'Bomber wing',cls:'Squadron',size:.34,cp:0,hp:28,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['bombs','T']],sq:'bomber'},
  spore:{n:'Spore swarm',cls:'Squadron',fac:'chorus',size:.34,cp:0,hp:26,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['sporeb','T']],sq:'bomber'},
  // ---- Meridian Directorate
  h_picket:{n:'Directorate picket',cls:'Frigate',fac:'hegemony',size:.5,cp:1,hp:40,sh:10,rg:5,ar:.1,sp:5,tn:3,ev:18,w:[['laser','F'],['flak','T']],ab:'evasive'},
  h_interdictor:{n:'Cordon destroyer',cls:'Destroyer',fac:'hegemony',size:.6,cp:2,hp:74,sh:18,rg:7,ar:.15,sp:4,tn:2,ev:10,w:[['ion','F'],['turbo','T']],ab:'ionpulse'},
  h_vanguard:{n:'Vector cruiser',cls:'Cruiser',fac:'hegemony',size:.78,cp:4,hp:140,sh:24,rg:10,ar:.2,sp:3,tn:1,ev:4,w:[['turbo','T'],['turbo','T'],['ion','F']],ab:'launch',hangar:1},
  h_dominion:{n:'Dominion dreadnought',cls:'Battleship',fac:'hegemony',size:.98,cp:6,hp:230,sh:32,rg:12,ar:.25,sp:2,tn:1,ev:0,w:[['hturbo','P'],['hturbo','S'],['ion','F'],['flak','T']],ab:'launch',hangar:1},
  h_boss:{n:'The Iron Mandate',cls:'Super-dreadnought',fac:'hegemony',size:1.3,cp:12,hp:560,sh:40,rg:10,ar:.3,sp:1,tn:1,ev:0,w:[['hturbo','P'],['hturbo','S'],['turbo','T'],['ion','F'],['flak','T']],ab:'nova',boss:true},
  // ---- Ashfall Corsairs
  c_raider:{n:'Hullbreaker raider',cls:'Frigate',fac:'corsair',size:.48,cp:1,hp:46,sh:8,rg:4,ar:.05,sp:6,tn:3,ev:28,w:[['autocannon','T']],ab:'overburn'},
  c_reaver:{n:'Hullbreaker gutship',cls:'Destroyer',fac:'corsair',size:.6,cp:2,hp:68,sh:10,rg:5,ar:.1,sp:5,tn:2,ev:15,w:[['torp','F'],['scatter','S']],ab:'reload'},
  c_marauder:{n:'Hullbreaker wrecker',cls:'Cruiser',fac:'corsair',size:.74,cp:3,hp:120,sh:16,rg:7,ar:.15,sp:4,tn:2,ev:6,w:[['scatter','P'],['scatter','S'],['torp','F'],['flak','T']],ab:'overburn'},
  c_hulk:{n:'Hullbreaker hulk-carrier',cls:'Carrier',fac:'corsair',size:.86,cp:4,hp:170,sh:16,rg:6,ar:.2,sp:2,tn:1,ev:0,w:[['turret','T'],['turret','T']],ab:'launch',hangar:2},
  c_boss:{n:"Warlord's Pyre-Barge",cls:'Battle-barge',fac:'corsair',size:1.22,cp:10,hp:600,sh:30,rg:8,ar:.25,sp:2,tn:1,ev:0,w:[['scatter','P'],['scatter','S'],['htorp','F'],['flak','T']],ab:'launch',hangar:2,boss:true},
  // ---- The Chorus (bio-swarm)
  b_drone:{n:'Chorus drone-spawn',cls:'Frigate',fac:'chorus',size:.48,cp:1,hp:46,sh:0,rg:0,ar:.05,sp:5,tn:3,ev:15,w:[['bioplasma','F'],['tendril','T']],ab:'regrow',regen:3},
  b_spitter:{n:'Chorus spitter',cls:'Destroyer',fac:'chorus',size:.6,cp:2,hp:82,sh:0,rg:0,ar:.1,sp:4,tn:2,ev:8,w:[['bioplasma','T'],['bioplasma','F']],ab:'regrow',regen:4},
  b_razor:{n:'Chorus bladeback',cls:'Cruiser',fac:'chorus',size:.76,cp:3,hp:135,sh:0,rg:0,ar:.2,sp:4,tn:2,ev:4,w:[['tendril','T'],['bioplasma','F']],ab:'frenzy',regen:6},
  b_brood:{n:'Chorus brood-sac',cls:'Carrier',fac:'chorus',size:.9,cp:5,hp:180,sh:0,rg:0,ar:.2,sp:2,tn:1,ev:0,w:[['bioplasma','F'],['spores','T']],ab:'launch',hangar:3,regen:6},
  b_boss:{n:'The Ninefold Maw',cls:'Bio-titan',fac:'chorus',size:1.3,cp:12,hp:650,sh:0,rg:0,ar:.25,sp:2,tn:1,ev:0,w:[['bioplasma','F'],['bioplasma','F'],['tendril','T'],['spores','T']],ab:'launch',hangar:3,regen:20,boss:true},
  // ---- The Ithar (elder race)
  i_wisp:{n:'Glasswright sliver',cls:'Frigate',fac:'ithar',size:.46,cp:1,hp:36,sh:12,rg:6,ar:0,sp:7,tn:3,ev:28,w:[['shard','F']],ab:'blink'},
  i_blade:{n:'Glasswright lancet',cls:'Destroyer',fac:'ithar',size:.58,cp:2,hp:68,sh:15,rg:8,ar:0,sp:6,tn:3,ev:24,w:[['shard','F'],['startorp','F']],ab:'blink'},
  i_song:{n:'Glasswright prism',cls:'Cruiser',fac:'ithar',size:.74,cp:4,hp:108,sh:26,rg:10,ar:.05,sp:5,tn:2,ev:16,w:[['pulsar','F'],['pulsar','F'],['turret','T']],ab:'surge'},
  i_carrier:{n:'Glasswright aperture',cls:'Carrier',fac:'ithar',size:.84,cp:5,hp:168,sh:28,rg:10,ar:.05,sp:4,tn:2,ev:12,w:[['pulsar','F'],['turret','T']],ab:'launch',hangar:2},
  i_boss:{n:'The Unfinished',cls:'Ark',fac:'ithar',size:1.26,cp:11,hp:470,sh:34,rg:14,ar:.2,sp:3,tn:2,ev:6,w:[['pulsar','F'],['pulsar','F'],['pulsar','T'],['turret','T'],['flak','T']],ab:'surge',boss:true},
  // ---- The Deathless Dynasty
  d_scythe:{n:'Eclipse mote',cls:'Frigate',fac:'deathless',size:.5,cp:1,hp:56,sh:0,rg:0,ar:.2,sp:4,tn:2,ev:14,w:[['gauss','T']],ab:'phase',regen:2,reanimate:true},
  d_jackal:{n:'Eclipse flare',cls:'Destroyer',fac:'deathless',size:.62,cp:2,hp:100,sh:0,rg:0,ar:.25,sp:3,tn:2,ev:6,w:[['nlance','F']],ab:'phase',regen:2,reanimate:true},
  d_harvester:{n:'Eclipse zenith',cls:'Cruiser',fac:'deathless',size:.82,cp:4,hp:145,sh:0,rg:0,ar:.3,sp:2,tn:1,ev:0,w:[['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T']],ab:'reclaim',regen:3,reanimate:true},
  d_boss:{n:'The Unsetting',cls:'Tomb-ark',fac:'deathless',size:1.3,cp:12,hp:480,sh:0,rg:0,ar:.35,sp:1,tn:1,ev:0,w:[['gauss','T'],['gauss','T'],['doom','F'],['flak','T']],ab:'nova',regen:8,boss:true},
};

// v50 drives: how each faction bends the thruster rules (battle.js MOVE_BASE). n/d show in the ship panel and codex.
const MOVE_RULES={
  voidsworn:{rake:.45,n:'Flanking burn',d:'Port and starboard flank guns hit 45% harder after moving 2+ hexes (others get 10%).'}, // pass 3 tuning: .3 to .4 (pass 2: .2 to .3)
  hegemony:{rev:1,n:'Retro thrusters',d:'Backing off one hex costs 1 movement instead of 2.'},
  corsair:{slip:1,n:'Bolted burners',d:'Sideslips cost 1 movement instead of 2.'},
  chorus:{pivot:1,n:'Living hull',d:'The first turn each round costs no movement.'},
  ithar:{evadeAt:2,evade:18,n:'Crystal vanes',d:'After moving 2+ hexes, enemies get \u221218 to hit it (others need 3 hexes for \u22125).'}, // pass 3 tuning: 14 to 18 (pass 2: 10 to 14)
  deathless:{over:0,n:'Fold drive',d:'Passes through rocks, wrecks and enemy ships at no extra cost.'}};
const FACTIONS = {
  voidsworn:{n:'Sunward Crusade',boss:'ascendant',roster:['warden','harrow','penitent','reliquary','cathedral'],hull:'#4a4440',trim:'#c8501f',glow:'#ff7a2a',style:'gothic',sq:'fighter',blurb:"Frontier secessionists from the dying Vesper Reach, flying unlinked iron warships to smash Eclipse's siphons. Heavy armor, long lances, and flank batteries that hit harder on a burn."},
  hegemony:{n:'Meridian Directorate',hull:'#c4ccd5',trim:'#3a78d0',glow:'#5fa0ff',style:'wedge',
    blurb:"The core-world fleet of the Meridian Directorate: clean wedge hulls, linked crews, and drone screens. Ion cannons strip shields while carriers control the flight lanes.",
    roster:['h_picket','h_interdictor','h_vanguard','h_dominion'],boss:'h_boss',sq:'fighter'},
  corsair:{n:'Ashfall Hullbreakers',hull:'#6a2c22',trim:'#b8402a',glow:'#e0402c',style:'junk',
    blurb:"Hunched, plate-faced alien raiders who hunt by thermal spike and ion wake, bolting stripped enemy armor onto dark hulls. Fast, light on shields, and loaded with rockets.",
    roster:['c_raider','c_reaver','c_marauder','c_hulk'],boss:'c_boss',sq:'bomber'},
  chorus:{n:'The Chorus',hull:'#57364c',trim:'#a4913a',glow:'#d6d24a',style:'bio',
    blurb:"A living bio-weapon that consumed its Fleshwright makers. Zero shields, raw hull regrowth every round, acid weapons, and relentless spore swarms.",
    roster:['b_drone','b_spitter','b_razor','b_brood'],boss:'b_boss',sq:'spore'},
  ithar:{n:'The Glasswrights',hull:'#eef3f1',trim:'#d7c88a',glow:'#9fffd2',style:'sail',
    blurb:"Long-lived optical engineers flying faceted crystal hulls that split starlight into razor beams. Blindingly fast with strong shields, yet fragile the moment those shields fail.",
    roster:['i_wisp','i_blade','i_song','i_carrier'],boss:'i_boss',sq:'fighter'},
  deathless:{n:'Eclipse',hull:'#291f36',trim:'#994dff',glow:'#b385ff',style:'tomb',
    blurb:"Uploaded Starwright minds in violet-black sunshade frames, siphoning neighbor stars to build a new sun. Armor-piercing null weapons, fold drives, and wrecks that rebuild themselves.",
    roster:['d_scythe','d_jackal','d_harvester'],boss:'d_boss',sq:null},
};
const SECTOR_POOL = [['corsair','hegemony'],['chorus','ithar','hegemony'],['deathless','chorus','ithar']];

const ABILITIES = {
  evasive:{n:'Evasive burn',d:'+25 evasion until your next turn and +2 movement now.',cd:3},
  reload:{n:'Reload torpedoes',d:'Torpedo tubes are ready to fire again immediately.',cd:3},
  focus:{n:'Concentrated fire',d:'All of this ship\u2019s weapons deal +30% damage this turn.',cd:3},
  launch:{n:'Automatic wings',d:'Carriers start with wings in flight. Wings move and fight on their own each round. At round start, each ready carrier automatically replaces one lost wing if an adjacent hex is open and spares remain. Replacements fight from next round; one spare per hangar slot.',cd:1},
  surge:{n:'Shield surge',d:'The shield pool is restored to full strength.',cd:4},
  nova:{n:'Spinal cannon',d:'Spinal shell: base 40 damage in a fore hex 3 to 9 away, 20 adjacent. Hits friends too.',cd:3,target:true},
  // faction abilities: every faction's line ships get something to press besides fire and brace
  ionpulse:{n:'Ion pulse',d:'Every enemy ship within 4 hexes loses half of its shield pool.',cd:3},
  overburn:{n:'Overburn',d:'+3 movement now, and a ram this turn hits 50% harder.',cd:3},
  frenzy:{n:'Blood frenzy',d:'All of this ship\u2019s weapons deal +30% damage this turn.',cd:3},
  regrow:{n:'Rapid regrowth',d:'Regrow 25% of this ship\u2019s hull right now.',cd:3},
  blink:{n:'Phase jump',d:'Jump to any open hex within 3, straight past rocks and ships. Tap the hex.',cd:3,target:true},
  phase:{n:'Fold skip',d:'+25 evasion until your next turn and +2 movement now.',cd:3},
  reclaim:{n:'Repair swarm',d:'Restore 20% hull to your most damaged ship within 3 hexes (this one included).',cd:3},
};
const ORDERS = {
  brace:{n:'Brace for impact',d:'Instead of firing: hull damage \u221240% until your next turn. The ship can move first, but can\u2019t brace after it has fired, and bracing ends its turn.'},
};

// fx keys: hpPct shPct regenPct armor speed turns ev aim crit dmgPct broadPct lancePct torpPct sqPct sqHp battShots flakPlus torpCd hangar hullRegen cdMod lastStand rearPct huntPct bracePlus longAim
const MODULES = {
  prow:{n:'Reinforced fore plating',d:'+15% hull, +5% armor.',fx:{hpPct:.15,armor:.05},cost:70},
  auspex:{n:'Scanner array',d:'+10 aim for every weapon.',fx:{aim:10},cost:80},
  drive:{n:'Plasma drive',d:'+1 speed.',fx:{speed:1},cost:75},
  gyro:{n:'Gyro-stabilizers',d:'+1 turn allowance, +5 evasion.',fx:{turns:1,ev:5},cost:60},
  capacitor:{n:'Screen capacitor',d:'+30% shield strength.',fx:{shPct:.3},cost:80},
  regen:{n:'Shield regenerator',d:'+50% shield regeneration.',fx:{regenPct:.5},cost:70},
  loaders:{n:'Battery loaders',d:'Battery weapons fire +1 shot.',fx:{battShots:1},cost:90},
  crystal:{n:'Lance focusing crystal',d:'Lance damage +25%.',fx:{lancePct:.25},cost:80},
  magazine:{n:'Torpedo magazine',d:'Torpedo reload time \u22121 turn, +15% torpedo damage.',fx:{torpCd:1,torpPct:.15},cost:85},
  flakplus:{n:'Flak batteries',d:'Point defense +2 shots and +1 range.',fx:{flakPlus:1},cost:55},
  damcon:{n:'Damage control crews',d:'Repair 4% hull at the start of each of your turns.',fx:{hullRegenPct:.04},cost:85},
  hangar:{n:'Hangar expansion',d:'Launch ships only: +1 squadron in flight.',fx:{hangar:1},cost:90,only:'launch'},
  cogitator:{n:'Targeting reckoner',d:'+10% critical chance.',fx:{crit:10},cost:75},
};

const PERKS = {
  gunnery:{n:'Gunnery master',d:'+10 aim.',fx:{aim:10}},
  killer:{n:'Killer instinct',d:'+10% critical chance.',fx:{crit:10}},
  deflector:{n:'Shield savant',d:'+40% shield regeneration.',fx:{regenPct:.4}},
  ironhull:{n:'Iron hull',d:'+15% max hull.',fx:{hpPct:.15}},
  helm:{n:'Born helmsman',d:'+1 speed.',fx:{speed:1}},
  steady:{n:'Steady hand',d:'Ignore the first 2 hexes of long-range penalty.',fx:{longAim:2}},
  broad:{n:'Flank gunnery',d:'Port and starboard flank weapons deal +15% damage.',fx:{broadPct:.15}},
  lanceadept:{n:'Lance savant',d:'Lance and torpedo damage +15%.',fx:{lancePct:.15,torpPct:.15}},
  stubborn:{n:'Stubborn',d:'Brace for impact blocks an extra 15%.',fx:{bracePlus:.15}},
  rapid:{n:'Rapid cycling',d:'Ability cooldowns \u22121.',fx:{cdMod:1}},
  wing:{n:'Wing commander',d:'Squadrons launched by this ship deal +30% damage.',fx:{sqPct:.3}},
  hunter:{n:'Hunter',d:'+20% damage against ships below half hull.',fx:{huntPct:.2}},
  laststand:{n:'Last stand',d:'Once per battle, survive a killing blow at 1 hull.',fx:{lastStand:1}},
  flanker:{n:'Flanker',d:'+20% damage on rear-arc hits.',fx:{rearPct:.2}},
};
const RANKS = ['Lieutenant','Commander','Captain','Commodore','Fleet captain'];
const RANK_XP = [0,30,80,160,280];

const RELICS = {
  martyr:{n:'The Chalked Roll',d:'When one of your ships is destroyed, every other ship repairs 15% of its hull.',run:{avenge:.15}},
  cogitator:{n:'Founders’ rangefinder',d:'Each ship\u2019s first weapon attack hits at 95% (75% against Full burn).',run:{firstSure:1}},
  lattice:{n:'Alien shield matrix',d:'Shields +15% across the fleet.',fx:{shPct:.15}},
  spore:{n:'Tamed spore culture',d:'Every ship regenerates 3 hull per turn.',fx:{hullRegen:3}},
  phylactery:{n:'Backup frame',d:'The first of your ships destroyed each battle restarts at 25% hull.',run:{revive:1}},
  ledger:{n:'Smuggler\u2019s ledger',d:'+25% credits from battles.',run:{credPct:.25}},
  compass:{n:'Founders’ compass',d:'+1 speed across the fleet.',fx:{speed:1}},
  banner:{n:'Captured war banner',d:'Destroying an enemy ship grants +15% ship damage, up to +45%. Wing kills grant it to their launch ship; downed wings do not count.',run:{bloodied:.15}},
  salvage:{n:'Scrap rig',d:'After each battle, gain 15 credits and repair 8% hull.',run:{salvage:1}},
  coils:{n:'Hand-wound plasma coils',d:'Ability cooldowns \u22121 across the fleet.',fx:{cdMod:1}},
  logbook:{n:'Log of Admiral Rhel',d:'+30% experience per ship.',run:{xpPct:.3}},
  armourweave:{n:'Tempered hullweave',d:'+6% armor across the fleet.',fx:{armor:.06}},
};

// Admiral band (stream B, Oct 27): Kassar, Reyes, Maren, Grax, Matriarch, Mending, Nekhet, then Malek, Ashgrove, Sable (and Mending's fleet) retuned so every admiral sits about 55 to 85% against a sector 1 flagship (bossmatrix); see port_notes.md.
const ADMIRALS = {
  vex:{n:'Admiral Roderic Vex',doc:'Line of battle',d:'Port and starboard flank weapons deal +15% damage.',fx:{broadPct:.15},start:['penitent','harrow','warden'],cost:0},
  malek:{n:'Oath-Captain Torben Hark',doc:'Hunter-killer',d:'Torpedoes reload a turn faster. +50% damage on rear-arc hits.',fx:{torpCd:1,rearPct:.5},start:['harrow','harrow','warden','warden'],cost:30},
  ashgrove:{n:'Commodore Sera Ashgrove',doc:'Carrier doctrine',d:'Squadrons deal +40% damage and launch ships hold +1 wing. Squadron hull +25%.',fx:{sqPct:.4,hangar:1,sqHp:.25},start:['reliquary','harrow','warden','warden'],cost:45},
  thale:{n:'High Admiral Oryn Thale',doc:'Iron doctrine',d:'All ships +10% hull and +10% shields.',fx:{hpPct:.1,shPct:.1},start:['penitent','warden','warden'],cost:80},
};

// ---------- faction admirals: four per faction, own ships, own Command ----------
Object.assign(ADMIRALS.vex,{fac:'voidsworn',cmd:{id:'barrage',n:'Fire for effect',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}});
Object.assign(ADMIRALS.malek,{fac:'voidsworn',cmd:{id:'hunt',n:"Hunter's salvo",d:'Torpedoes reload at once and every ship deals +30% damage this round.'}});
Object.assign(ADMIRALS.ashgrove,{fac:'voidsworn',cmd:{id:'scramble',n:'Scramble all wings',d:'Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round.'}});
Object.assign(ADMIRALS.thale,{fac:'voidsworn',cmd:{id:'iron',n:'Iron wall',d:'All shields refill and your ships take 40% less hull damage this round.'}});
Object.assign(ADMIRALS,{
  kassar:{fac:'hegemony',n:'First Admiral Ilsa Kassar',doc:'Fire discipline',d:'Batteries fire one extra shot per volley, but every gun hits 5% lighter.',fx:{battShots:1,dmgPct:-.05},start:['h_vanguard','h_picket'],cost:0,cmd:{id:'barrage',n:'Synchronized volley',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  vorn:{fac:'hegemony',n:'Commodore Dace Vorn',doc:'Precision fire',d:'+10 aim and +10% critical-hit chance.',fx:{aim:10,crit:10},start:['h_interdictor','h_interdictor','h_picket','h_picket'],cost:30,cmd:{id:'hunt',n:'Interdiction strike',d:'Every ship deals +30% damage this round.'}},
  reyes:{fac:'hegemony',n:'Fleet Marshal Corin Reyes',doc:'Strike group',d:'Squadrons deal +10% damage and launch ships hold +1 wing. Squadron hull +25%.',fx:{sqPct:.1,hangar:1,sqHp:.25},start:['h_vanguard','h_picket','h_picket'],cost:45,cmd:{id:'scramble',n:'Launch the strike group',d:'Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round.'}},
  maren:{fac:'hegemony',n:'Line Admiral Oskar Maren',doc:'Armored column',d:'All ships +15% hull and +10% shields.',fx:{hpPct:.15,shPct:.1},start:['h_dominion','h_picket'],cost:80,cmd:{id:'iron',n:'Shield wall order',d:'All shields refill and your ships take 40% less hull damage this round.'}},
  grax:{fac:'corsair',n:'Warlord Grax Ironmaw',doc:'Fast assault',d:'+1 speed for every ship and +10% damage.',fx:{speed:1,dmgPct:.1},start:['c_marauder','c_reaver','c_reaver'],cost:0,cmd:{id:'surge',n:'Full burn',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  sable:{fac:'corsair',n:'Sable the Smiling Knife',doc:'Knife work',d:'+50% damage on rear-arc hits and +10% crit chance.',fx:{rearPct:.5,crit:10},start:['c_reaver','c_reaver','c_raider','c_raider'],cost:30,cmd:{id:'hunt',n:'Knife in the dark',d:'Torpedoes reload at once and every ship deals +30% damage this round.'}},
  mott:{fac:'corsair',n:'Old Mott',doc:'Junkyard carriers',d:'Squadrons deal +25% damage and hulks hold +1 wing. Squadron hull +25%.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['c_hulk','c_reaver'],cost:45,cmd:{id:'scramble',n:'Release the swarm',d:'Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round.'}},
  vesh:{fac:'corsair',n:'Vesh the Collector',doc:'Scrap armor',d:'Ships patch 5% of their hull each round and have +10% armor.',fx:{hullRegenPct:.05,armor:.1},start:['c_hulk','c_reaver'],cost:80,cmd:{id:'restore',n:'Patch and weld',d:'Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones.'}},
  matriarch:{fac:'chorus',n:'The Matriarch of Nine Throats',doc:'Brood swarm',d:'Spore swarms deal +25% damage and broods hold +1 swarm. Swarm hull +25%.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['b_brood','b_drone','b_drone'],cost:0,cmd:{id:'scramble',n:'Spawning surge',d:'Every brood releases an extra swarm (even past its limit), then all swarms strike again at once with +50% damage this round.'}},
  razormaw:{fac:'chorus',n:'Red Undertow',doc:'Hunter pack',d:'+1 speed and +15% damage on rear-arc hits.',fx:{speed:1,rearPct:.15},start:['b_razor','b_spitter','b_drone'],cost:30,cmd:{id:'surge',n:'Blood frenzy',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  mending:{fac:'chorus',n:'Mending Throng',doc:'Regrowth',d:'Ships regrow 4% of their hull each round.',fx:{hullRegenPct:.04},start:['b_razor','b_drone'],cost:45,cmd:{id:'restore',n:'Regrowth tide',d:'Every ship regrows 25% of its hull and heals damaged sections, even destroyed ones.'}},
  voice:{fac:'chorus',n:'Voice of the Deep',doc:'Acid tide',d:'+15% damage with every weapon.',fx:{dmgPct:.15},start:['b_razor','b_spitter','b_drone'],cost:80,cmd:{id:'barrage',n:'Spitting volley',d:'Every ship spits a free volley at the best target it can reach, right now.'}},
  aelith:{fac:'ithar',n:'Tamsa of the Clear Aperture',doc:'Wing-mistress',d:'Squadrons deal +25% damage and launch ships hold +1 wing. Squadron hull +25%.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['i_carrier','i_wisp'],cost:0,cmd:{id:'scramble',n:'Starling flight',d:'Every launch ship sends out an extra wing if there is room, then all squadrons strike again with +50% damage this round.'}},
  vaelen:{fac:'ithar',n:'Saro of Long Focus',doc:'Focused lances',d:'Lances deal +20% damage; every weapon gains +10 aim.',fx:{lancePct:.2,aim:10},start:['i_song','i_blade'],cost:30,cmd:{id:'barrage',n:'Burning glass',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  thorne:{fac:'ithar',n:'Vell of the Third Mirror',doc:'Refraction tactics',d:'+8 evasion for every ship.',fx:{ev:8},start:['i_blade','i_blade','i_wisp','i_wisp'],cost:45,cmd:{id:'surge',n:'Scatter the light',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  mirelle:{fac:'ithar',n:'Brin of the Fourth Lens',doc:'Prism hulls',d:'All ships +15% shields, and shields recharge 20% faster.',fx:{shPct:.15,regenPct:.2},start:['i_song','i_wisp','i_wisp'],cost:80,cmd:{id:'iron',n:'Prism ward',d:'All shields refill and your ships take 40% less hull damage this round.'}},
  nekhet:{fac:'deathless',n:'Nadir Aurex, Ninth Frame',doc:'Endless restoration',d:'Ships rebuild 4% of their hull each round.',fx:{hullRegenPct:.04},start:['d_harvester','d_jackal'],cost:0,cmd:{id:'restore',n:'Release the repair swarms',d:'Every ship rebuilds 25% of its hull and mends damaged sections, even destroyed ones.'}},
  sekhmar:{fac:'deathless',n:'Umbra Vessane, Third-Housed',doc:'Corona strikes',d:'Corona arcs deal +20% damage and every weapon +10%.',fx:{lancePct:.2,dmgPct:.1},start:['d_harvester','d_scythe','d_scythe'],cost:30,cmd:{id:'barrage',n:'Noon volley',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  anuket:{fac:'deathless',n:'Ostrel of the Long Copy',doc:'Silent hunters',d:'+20% damage on rear-arc hits and +10 evasion.',fx:{rearPct:.2,ev:10},start:['d_jackal','d_jackal','d_scythe','d_scythe'],cost:45,cmd:{id:'hunt',n:'Out of the shadow',d:'Every ship deals +30% damage this round. Any ships carrying torpedoes reload them at once.'}},
  khepra:{fac:'deathless',n:'Seveth, Twice-Restored',doc:'Layered plates',d:'All ships +20% hull.',fx:{hpPct:.2},start:['d_jackal','d_jackal','d_jackal'],cost:80,cmd:{id:'iron',n:'Sunshade wall',d:'Your ships take 50% less hull damage this round. Gets stronger each round you hold it.'}},
});

const LEGACY = {
  u_carrier:{n:'Carrier hulls',d:'Carrier hulls appear in shipyards.',cost:30,group:'Shipyards'},
  u_battleship:{n:'Battleship hulls',d:'Battleship-class hulls appear in shipyards.',cost:60,group:'Shipyards'},
  u_dread:{n:'Dreadnought hulls',d:'Sunward Crusade fleets may take one Daybreak-class dreadnought.',cost:120,group:'Shipyards',req:'u_battleship'},
  chest1:{n:'War chest I',d:'+75 starting credits.',cost:20,group:'Supply'},
  chest2:{n:'War chest II',d:'+75 more starting credits.',cost:40,group:'Supply',req:'chest1'},
  chest3:{n:'War chest III',d:'+75 more starting credits.',cost:65,group:'Supply',req:'chest2'},
  cmd1:{n:'Command authority I',d:'+2 fleet command points.',cost:35,group:'Command'},
  cmd2:{n:'Command authority II',d:'+2 more fleet command points.',cost:70,group:'Command',req:'cmd1'},
  vets:{n:'Veteran officers',d:'Starting captains begin at Commander rank with a perk.',cost:50,group:'Command'},
  founder:{n:'Founders\u2019 cache',d:'Begin each run with a random piece of salvage.',cost:60,group:'Supply'},
  wrights:{n:'Master shipwrights',d:'Shipyard prices \u221215%.',cost:45,group:'Supply'},
  salvagers:{n:'Recovery crews',d:'+20% credits from battles.',cost:40,group:'Supply'},
};

const SHIP_NAMES = ['Unyielding Oath','Wrath of Vesper','Ashen Vigil','Long Watch','Bright Censure','Banked Fire','Cold Watch','Merciless Frost','Cinder Vow','Pale Sentinel','Everwatch','Debt of Vesper','Cold Fury','Iron Dusk','Dawn of Cinders','Resolve of the Reach','Judgment Bell','Oath Flame','Edge of Winter','Unpaid Debt','Relentless Ember','Obsidian Brand','Black Anvil','Debt Paid','Burning Spire','Cold Reckoning','Thorn of the Reach','Vigilant Ash'];
const CAP_FIRST = ['Ilse','Corvin','Mathilde','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Sabine','Emeric','Helka','Brannoc','Rosalind','Garrick','Margery','Dagan','Thessaly','Rourke','Elsbeth','Aldous','Yara','Osric','Ninette','Hadrian','Clemence','Lysander','Calla'];
const CAP_LAST = ['Varrow','Kade','Morrow','Ashdown','Quell','Harrowgate','Vane','Stroud','Rennick','Draeger','Holloway','Sedley','Wyndham','Corvane','Ostrava','Marchetti','Blackwood','Ferro','Vashti','Kellan','Maddox','Serrano','Ivers','Lachance','Okonkwo','Ashby','Salo','Teague'];

// ---------- faction names: same effects, each faction's own words ----------
const MOD_NEED={loaders:'batt',crystal:'lance',magazine:'torp',flakplus:'flak',capacitor:'shields',regen:'shields',hangar:'carrier'};
const MOD_NAMES={
  hegemony:{prow:'Reinforced bow plating',auspex:'Fire-control computer',drive:'Ion drive upgrade',gyro:'Attitude thrusters',capacitor:'Deflector capacitor',regen:'Deflector regenerator',loaders:'Pulse cyclers',crystal:'Ion focus lens',magazine:'Fusion magazine',flakplus:'Point-defense array',damcon:'Damage control teams',hangar:'Expanded hangar bay',cogitator:'Targeting computer'},
  corsair:{prow:'Scrap ram plating',auspex:'Stolen gun sights',drive:'Overbored thrusters',gyro:'Jury-rigged gyros',capacitor:'Salvaged shield cells',regen:'Hot-wired regenerator',loaders:'Ammo hoppers',crystal:'Cracked lens array',magazine:'Extra rocket racks',flakplus:'Bolted-on flak',damcon:'Welding gangs',hangar:'Welded-on hangar',cogitator:'Gunner’s lucky charm'},
  chorus:{prow:'Chitin layers',auspex:'Tasting pores',drive:'Propulsion sacs',gyro:'Fin clusters',capacitor:'Thickened membrane',regen:'Membrane regrowth',loaders:'Spine glands',crystal:'Venom lens',magazine:'Spore bladders',flakplus:'Stinger pores',damcon:'Mending tissue',hangar:'Brood chamber',cogitator:'Predator instinct'},
  ithar:{prow:'Waveguide spine',auspex:'Interferometer lens',drive:'Crystal drive extension',gyro:'Crystal vanes',capacitor:'Prism capacitor',regen:'Stored-light reservoir',loaders:'Shard hoppers',crystal:'Starlight focus',magazine:'Star torpedo cradle',flakplus:'Shard screen',damcon:'Annealing kilns',hangar:'Wing cradle',cogitator:'Clear aperture'},
  deathless:{prow:'Sunshade plating',auspex:'Long-memory sight',drive:'Fold engine',gyro:'Gravitic stabilizers',capacitor:'Corona-ward node',regen:'Corona-ward regenerator',loaders:'Null accelerators',crystal:'Corona-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair drones',hangar:'Drone bay',cogitator:'Long-count reckoner'}};
const RELIC_NAMES={
  hegemony:{martyr:'Medal of the Grand Fleet',cogitator:'Registry targeting array',lattice:'Deflector matrix prototype',spore:'Captured Chorus culture',ledger:'Smuggler’s ledger',compass:'Jump-drive regulator',banner:'Captured war banner',salvage:'Scrap rig',coils:'Overclocked reactors',logbook:'Admiralty logbook',armourweave:'Hardsteel weave'},
  corsair:{martyr:'Dead captain’s harness',cogitator:'Stolen Directorate rangefinder',lattice:'Glasswright shield shard',ledger:'Smuggler’s ledger',compass:'Wake-tracker',banner:'Trophy war banner',salvage:'Scrap rig',coils:'Hot-rodded reactor',logbook:'Warlord’s kill tally',armourweave:'Scrap armor weave'},
  chorus:{martyr:'Heart of the first brood',cogitator:'Heat-tasting pits',lattice:'Swallowed shield cells',spore:'Ancestral spore culture',ledger:'Hoard of the deep',compass:'Migration current',banner:'Prey’s war banner',salvage:'Scavenger gut',coils:'Quickening gland',logbook:'Taste of old prey',armourweave:'Carapace weave'},
  ithar:{martyr:'Tear of the dying star',cogitator:'Ancestral lens',lattice:'Prism matrix',ledger:'Manifest of Exiles',banner:'Banner of Ardent',coils:'Starlight coils',logbook:'Log of the last voyage',armourweave:'Sunstone weave'},
  deathless:{martyr:'Last image of Ardent',cogitator:'Calculus engine',phylactery:'Second Ignition',ledger:'Siphon tally',compass:'Gravitic compass',banner:'Standard of the conquered',salvage:'Reclamation swarm',coils:'Long clock',logbook:'Archive extract',armourweave:'Sunshade weave'}};
// what a run is called, by faction
const RUN_WORD={voidsworn:'crusade',hegemony:'campaign',corsair:'raid',chorus:'hunt',ithar:'voyage',deathless:'Homecoming'};

const EVENTS = [
  {
    "id": "derelict",
    "t": "Derelict on dark scopes",
    "b": "Long-range sensors pick up an unpowered warship tumbling slowly off the lane, its outer hull scored with Starwright script nobody has translated in a millennium.",
    "o": [
      {
        "l": "Send breach teams aboard",
        "s": "Risky. Could hold founders' hardware, or something still powered.",
        "r": "derelictBoard"
      },
      {
        "l": "Strip outer plating from range",
        "s": "+35 credits, zero risk.",
        "r": {
          "cred": 35
        }
      },
      {
        "k": "cut",
        "l": "Core the vault cleanly with lances",
        "s": "Clean extraction: a refit and 40 credits, nothing wakes.",
        "need": {
          "kind": "lance"
        },
        "r": {
          "mod": 1,
          "cred": 40
        }
      },
      {
        "l": "Leave it drifting",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "beacon",
    "not": [
      "hegemony"
    ],
    "t": "Directorate distress beacon",
    "b": "A Directorate supply tender limps along the outer jump lane with a shattered drive ring, broadcasting an automated distress ping on every band.",
    "o": [
      {
        "l": "Patch their drive",
        "s": "Grateful crew transfers 50 credits and shares local flight logs (+10 XP).",
        "r": {
          "cred": 50,
          "xp": 10
        }
      },
      {
        "k": "tow",
        "l": "Tow them clear with a carrier",
        "s": "+70 credits and a Nemesis weakness revealed from their sensor logs.",
        "need": {
          "carrier": 1
        },
        "r": {
          "cred": 70,
          "nemIntel": 1
        },
        "fl": {
          "mercy": 1
        }
      },
      {
        "l": "Crack their cargo hold",
        "s": "+100 credits. Expect an elite Directorate ambush; Nemesis clock moves on 1.",
        "r": {
          "cred": 100,
          "ambush": true,
          "nemClock": 1
        },
        "fl": {
          "greed": 1
        }
      },
      {
        "l": "Pass wide",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "astropath",
    "t": "Signal in the static",
    "b": "Your signals officer isolates a clean founders' transponder pulsing from inside a jump rift. Real hardware sits on the far side, though crossing the shear will punish your hulls.",
    "v": {
      "hegemony": {
        "t": "Ghost transponder",
        "b": "Your telemetry officer decoded an old Directorate supply beacon broadcasting from inside an unstable jump rift."
      },
      "corsair": {
        "t": "Hot trace past the rift",
        "b": "Your best wake-tracker swears she's reading a rich alloy cache humming on the far side of a jump rift. She's right more often than not."
      },
      "chorus": {
        "t": "Warm pulse beyond the tear",
        "b": "Our sensory pits catch a bright thermal spike pulsing steadily on the far side of a spatial rift."
      },
      "ithar": {
        "t": "Glint beyond the rift",
        "b": "Your primary mirrors catch an unmistakable Starwright optical flash coming from beyond a jump rift."
      },
      "deathless": {
        "t": "Pre-collapse Archive ping",
        "b": "An encrypted Archive transponder from before Ardent's fall pulses steadily beyond a rift."
      }
    },
    "o": [
      {
        "l": "Push through the shear",
        "s": "Gain salvage. One random ship takes 30% hull damage.",
        "r": {
          "relic": 1,
          "dmgOne": 0.3
        }
      },
      {
        "k": "shield",
        "l": "Burn a spare refit as ablative shielding",
        "s": "Gain salvage. Uses one refit from the hold instead of hull damage.",
        "need": {
          "mod": 1
        },
        "r": {
          "relic": 1,
          "payMod": 1
        }
      },
      {
        "l": "Bypass the rift",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "merc",
    "t": "Independent destroyer for hire",
    "b": "A battered destroyer drops out of jump matching your vector. Her captain says her last contract went bust and she'd rather fly with a real fleet than starve in the belt.",
    "o": [
      {
        "l": "Hire her (80 credits)",
        "s": "A faction destroyer with a veteran captain joins your fleet.",
        "r": {
          "cost": 80,
          "ship": "harrow",
          "vet": 1
        }
      },
      {
        "k": "oath",
        "l": "Offer her a slot in the Crusade line, no pay",
        "s": "She takes the oath. A faction destroyer joins with veteran experience.",
        "need": {
          "fac": "voidsworn"
        },
        "r": {
          "ship": "harrow",
          "vet": 1
        }
      },
      {
        "l": "Wave her off",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "storm",
    "t": "Rift storm",
    "b": "A wall of crackling spatial shear sweeps straight across your jump lane, tearing blue-red arcs off passing dust.",
    "o": [
      {
        "l": "Burn straight through",
        "s": "Every ship takes 10% hull damage.",
        "r": {
          "dmgAll": 0.1
        }
      },
      {
        "k": "shields",
        "l": "Angle full shields forward and push",
        "s": "No damage. +10 XP per ship.",
        "need": {
          "shields": 1
        },
        "r": {
          "xp": 10
        }
      },
      {
        "l": "Plot a wide detour (40 credits)",
        "s": "Spend extra reaction mass to go around cleanly.",
        "r": {
          "cost": 40
        }
      }
    ]
  },
  {
    "id": "seer",
    "t": "Glasswright trader",
    "b": "A lone crystal cruiser glides parallel to your course and pulses a quiet trade offer: one of your fitted ship refits for a rare piece of Starwright hardware.",
    "o": [
      {
        "l": "Trade an installed refit for salvage",
        "s": "Lose one random installed refit. Gain salvage.",
        "r": {
          "loseMod": 1,
          "relic": 1
        }
      },
      {
        "k": "song",
        "l": "Answer in formal optical code",
        "s": "The keeper pulses warm amber and gifts the salvage outright. No refit lost.",
        "need": {
          "fac": "ithar"
        },
        "r": {
          "relic": 1
        }
      },
      {
        "l": "Decline and keep course",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "wright",
    "t": "Belt refit yard",
    "b": "An eccentric master fabricator running a hollowed-out asteroid foundry hails your bridge. He'll overhaul your roughest hull for free if your tactical officer lets him copy your combat logs.",
    "o": [
      {
        "l": "Dock and share your logs",
        "s": "Your most damaged ship is fully repaired and upgraded one Mark.",
        "r": {
          "upgradeOne": 1
        }
      },
      {
        "k": "pay",
        "l": "Add a spare refit to the deal",
        "s": "Your most damaged ship is repaired and upgraded, plus a second ship is fully repaired.",
        "need": {
          "mod": 1
        },
        "r": {
          "upgradeOne": 1,
          "repairOne": 1,
          "payMod": 1
        }
      },
      {
        "l": "Keep moving",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "moon",
    "not": [
      "chorus"
    ],
    "t": "Overrun mining moon",
    "b": "Chorus spores have blanketed an automated ore moon. Miners are blinking laser distress signals from the deep bore shafts while a brood-cluster swells in low orbit.",
    "o": [
      {
        "l": "Clear orbit and break the brood",
        "s": "Fight an elite Chorus battle. Win salvage.",
        "r": {
          "fight": "chorus"
        }
      },
      {
        "k": "flak",
        "l": "Sweep the orbital spore cloud with point defense",
        "s": "Pull the miners out before the brood hatches. +60 credits and +15 XP per ship.",
        "need": {
          "kind": "flak"
        },
        "r": {
          "cred": 60,
          "xp": 15
        },
        "fl": {
          "mercy": 1
        }
      },
      {
        "l": "Sterilize the shafts from orbit and leave",
        "s": "+20 XP per ship.",
        "r": {
          "xp": 20
        }
      }
    ]
  },
  {
    "id": "shrine",
    "not": [
      "chorus",
      "deathless"
    ],
    "t": "Wall of Names",
    "b": "A cold memorial beacon orbits a dead mining rock, its outer plating covered in chalked crew names from an earlier Vesper expedition. Your crews ask to pause and leave supplies for the next fleet.",
    "v": {
      "hegemony": {
        "b": "An old frontier memorial station orbits a dead rock. Even linked spacers get superstitious this far out, and your crews request a brief tribute stop."
      },
      "corsair": {
        "b": "An old memorial station hangs in dead orbit, bolted over with scorched trophy plates from rival packs. Your captains want to weld a mark of their own on the hull."
      },
      "ithar": {
        "t": "Mirror of the Old World",
        "b": "A pre-collapse optical beacon still turns slowly over a dead moon. Your captains request time to align mirrors in tribute."
      }
    },
    "o": [
      {
        "k": "offer",
        "l": "Leave 50 credits in repair stock",
        "s": "Morale jumps; crews patch 30% hull across every ship.",
        "r": {
          "cost": 50,
          "healAll": 0.3
        }
      },
      {
        "k": "chalk",
        "l": "Chalk your fleet's names and move on",
        "s": "Even odds: +30% hull patched across the fleet, or nothing.",
        "r": {
          "gamble": true
        }
      },
      {
        "k": "relic",
        "l": "Leave a piece of salvage in tribute",
        "s": "Every ship is fully repaired and every captain gains 20 XP.",
        "need": {
          "relic": 1
        },
        "r": {
          "payRelic": 1,
          "healAll": 1,
          "xp": 20
        }
      },
      {
        "k": "leave",
        "l": "Hold schedule and jump",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "deserters",
    "not": [
      "hegemony"
    ],
    "t": "Directorate defectors",
    "b": "A battered Directorate lifeboat drops out of stealth with its transponder wiped. Three junior officers aboard claim they cut their own Registry links and will share fleet firing tables for asylum.",
    "o": [
      {
        "l": "Bring them aboard",
        "s": "Your least experienced captain gains 60 XP from their tactical drills.",
        "r": {
          "xpLow": 60
        }
      },
      {
        "k": "question",
        "l": "Debrief them on the enemy commander",
        "s": "Least experienced captain gains 30 XP and a Nemesis weakness is revealed.",
        "need": {
          "vet": 2
        },
        "r": {
          "xpLow": 30,
          "nemIntel": 1
        }
      },
      {
        "l": "Transmit their coordinates for the bounty",
        "s": "+60 credits.",
        "r": {
          "cred": 60
        }
      }
    ]
  },
  {
    "id": "cache",
    "not": [
      "corsair"
    ],
    "t": "Raider supply stash",
    "b": "Sensors pick up a Hullbreaker hardware pod tethered inside a gas giant's dust ring, locked with clumsy mechanical seals.",
    "o": [
      {
        "l": "Pry the hardware bay",
        "s": "Gain a random refit.",
        "r": {
          "mod": 1
        }
      },
      {
        "k": "both",
        "l": "Crack the seals with a torpedo and drain the fuel tanks",
        "s": "Gain a random refit plus 45 credits.",
        "need": {
          "kind": "torp"
        },
        "r": {
          "mod": 1,
          "cred": 45
        }
      },
      {
        "l": "Siphon the fuel and credits",
        "s": "+45 credits.",
        "r": {
          "cred": 45
        }
      }
    ]
  },
  {
    "id": "tithe",
    "t": "Dead toll station",
    "b": "An abandoned sector customs station tumbles on reserve batteries, its hard-currency vault still sealed. The tamper relays are ancient, yet their status lamps still blink green.",
    "o": [
      {
        "k": "crack",
        "l": "Blow the vault hatches",
        "s": "+70 credits. The distress ping carries: Nemesis clock advances 1.",
        "r": {
          "cred": 70,
          "nemClock": 1
        },
        "fl": {
          "greed": 1,
          "loud": 1
        }
      },
      {
        "k": "lance",
        "l": "Burn through the lock cleanly with a lance",
        "s": "+70 credits, no alarm tripped.",
        "need": {
          "kind": "lance"
        },
        "r": {
          "cred": 70
        },
        "fl": {
          "greed": 1
        }
      },
      {
        "k": "leave",
        "l": "Leave it sealed",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "pilot",
    "t": "Stranded wing leader",
    "b": "Your picket pulls a drifting ejection pod out of a debris lane. Inside, a battered squadron pilot clutches a cracked flight recorder from a carrier that went down two sectors back.",
    "o": [
      {
        "k": "take",
        "l": "Take her onto the bridge crew",
        "s": "Your least experienced captain gains 40 XP from her combat footage.",
        "r": {
          "xpLow": 40
        },
        "fl": {
          "mercy": 1
        }
      },
      {
        "k": "wing",
        "l": "Assign her to your carrier's flight ops",
        "s": "Your best carrier's squadrons gain a veteran perk.",
        "need": {
          "carrier": 1
        },
        "r": {
          "wingPerk": 1
        },
        "fl": {
          "mercy": 1
        }
      },
      {
        "k": "leave",
        "l": "Tag her pod for automated pickup",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "reactor",
    "t": "Hairline reactor fracture",
    "b": "Engineering flags a stress crack along your heaviest ship's primary containment ring. It'll survive one more engagement, maybe two, before blowing.",
    "o": [
      {
        "k": "vent",
        "l": "Vent the core and weld it cold",
        "s": "Your largest ship takes 20% hull damage.",
        "r": {
          "dmgBig": 0.2
        }
      },
      {
        "k": "refit",
        "l": "Cannibalize a spare refit for containment plating",
        "s": "Uses one refit from the hold. Zero hull damage.",
        "need": {
          "mod": 1
        },
        "r": {
          "payMod": 1
        }
      },
      {
        "k": "metal",
        "l": "Let Eclipse repair drones knit the seam",
        "s": "Zero cost.",
        "need": {
          "fac": "deathless"
        },
        "r": {}
      },
      {
        "k": "pay",
        "l": "Buy replacement rings from a passing freighter (45 credits)",
        "s": "Zero hull damage.",
        "r": {
          "cost": 45
        }
      }
    ]
  },
  {
    "id": "squall",
    "t": "Ion squall",
    "b": "A fast-moving front of charged solar particles sweeps across your route, scrambling unshielded optics and scouring bare armor.",
    "o": [
      {
        "k": "ride",
        "l": "Ride it out on bare plating",
        "s": "Every ship takes 8% hull damage.",
        "r": {
          "dmgAll": 0.08
        }
      },
      {
        "k": "shield",
        "l": "Raise shields and burn straight through",
        "s": "Zero damage. +10 XP per ship.",
        "need": {
          "shields": 1
        },
        "r": {
          "xp": 10
        }
      },
      {
        "k": "round",
        "l": "Burn wide around the front (35 credits)",
        "s": "Zero hull damage.",
        "r": {
          "cost": 35
        }
      }
    ]
  },
  {
    "id": "broker",
    "t": "Data broker",
    "b": "A sleek stealth courier matches your orbit and opens an encrypted voice link. The broker claims she's been logging your Nemesis's supply transfers and knows a real vulnerability.",
    "o": [
      {
        "k": "buy",
        "l": "Pay for the dossier (60 credits)",
        "s": "A Nemesis weakness is revealed.",
        "r": {
          "cost": 60,
          "nemIntel": 1
        },
        "fl": {
          "intel": 1
        }
      },
      {
        "k": "debt",
        "l": "Remind her which pack kept her courier intact last year",
        "s": "She pays off the favor: a Nemesis weakness revealed for free.",
        "need": {
          "fac": "corsair"
        },
        "r": {
          "nemIntel": 1
        },
        "fl": {
          "intel": 1
        }
      },
      {
        "k": "leave",
        "l": "Close the channel",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "bait",
    "t": "Looping distress call",
    "b": "A cargo hauler's emergency band is screaming for help, except the static crackle repeats down to the exact millisecond every twelve seconds.",
    "o": [
      {
        "k": "loud",
        "l": "Burn in hot and grab the cargo anyway",
        "s": "+80 credits, though your next fight starts as an ambush.",
        "r": {
          "cred": 80,
          "ambush": true
        },
        "fl": {
          "greed": 1,
          "loud": 1
        }
      },
      {
        "k": "sweep",
        "l": "Clear the approach mines with point defense first",
        "s": "Disarm the trap and clear the hold: +80 credits.",
        "need": {
          "kind": "flak"
        },
        "r": {
          "cred": 80
        },
        "fl": {
          "greed": 1
        }
      },
      {
        "k": "ignore",
        "l": "Leave the bait sitting",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "spawn",
    "t": "Drifting spore belt",
    "b": "Thousands of translucent Chorus egg-sacs hang in the lagrange pocket between two moons, pulsing in slow thermal waves.",
    "o": [
      {
        "k": "burn",
        "l": "Sterilize the pocket with weapons fire",
        "s": "+20 XP per ship.",
        "r": {
          "xp": 20
        },
        "fl": {
          "purge": 1
        }
      },
      {
        "k": "harvest",
        "l": "Sample the self-sealing membranes",
        "s": "Gain a damage-control refit.",
        "r": {
          "modId": "damcon"
        }
      },
      {
        "k": "feed",
        "l": "Open the sacs and absorb the biomass",
        "s": "Every ship regrows 30% hull.",
        "need": {
          "fac": "chorus"
        },
        "r": {
          "healAll": 0.3
        },
        "fl": {
          "fed": 1
        }
      }
    ]
  },
  {
    "id": "lament",
    "t": "Fading optical tone",
    "b": "A shattered Glasswright prism drifts near a dust reef, broadcasting one clean, fading optical pulse that carries old jump-route telemetry inside its harmonics.",
    "o": [
      {
        "k": "listen",
        "l": "Record the navigation harmonics",
        "s": "+15 XP per ship.",
        "r": {
          "xp": 15
        }
      },
      {
        "k": "join",
        "l": "Answer the pulse in kind",
        "s": "Gain salvage, and the charts expose your rival's lane: Nemesis clock back 1.",
        "need": {
          "fac": "ithar"
        },
        "r": {
          "relic": 1,
          "nemClock": -1
        }
      },
      {
        "k": "archive",
        "l": "Trade a piece of salvage for the full sector charts",
        "s": "Lose salvage. Reveal a Nemesis weakness and gain 120 credits.",
        "need": {
          "relic": 1
        },
        "r": {
          "payRelic": 1,
          "nemIntel": 1,
          "cred": 120
        },
        "fl": {
          "intel": 1
        }
      }
    ]
  },
  {
    "id": "tomb",
    "not": [
      "deathless"
    ],
    "t": "Active siphon array",
    "b": "A black ring of Eclipse collector dishes orbits a graying star, channeling stolen plasma straight toward a jump relay. Defense frames are already powering up.",
    "o": [
      {
        "k": "wake",
        "l": "Smash the array and loot its core bay",
        "s": "Fight an elite Eclipse battle. Win salvage.",
        "r": {
          "fight": "deathless"
        },
        "fl": {
          "loud": 1
        }
      },
      {
        "k": "map",
        "l": "Log its jump coordinates and leave",
        "s": "+30 credits for the survey data.",
        "r": {
          "cred": 30
        }
      }
    ]
  },
  {
    "id": "tombhome",
    "not": [
      "hegemony",
      "voidsworn",
      "corsair",
      "chorus",
      "ithar"
    ],
    "t": "Pre-collapse reserve berth",
    "b": "An Eclipse storage berth from before Ardent's fall hangs dormant in deep shadow, holding an intact mote chassis and a single unassigned veteran mind-core sealed in cold sleep.",
    "o": [
      {
        "k": "wake",
        "l": "Wake the sleeping core into the mote",
        "s": "An Eclipse mote joins your fleet at full hull (lawful wake; no duplicate mind).",
        "need": {
          "fac": "deathless"
        },
        "r": {
          "shipRaw": "d_scythe"
        }
      },
      {
        "k": "tithe",
        "l": "Strip the spare alloys instead",
        "s": "+60 credits.",
        "r": {
          "cred": 60
        }
      }
    ]
  },
  {
    "id": "mutiny",
    "t": "Unrest in the fleet",
    "b": "Morale on one of your escorts has turned sour after three straight jumps under fire. Its captain sends a private hail asking how hard you want the line enforced.",
    "o": [
      {
        "k": "pay",
        "l": "Authorize hazard bonuses (50 credits)",
        "s": "Grumbling stops and the watch resets.",
        "r": {
          "cost": 50
        }
      },
      {
        "k": "discipline",
        "l": "Make a hard example",
        "s": "Flagship captain loses 20 XP; discipline holds.",
        "r": {
          "payXp": 20
        }
      },
      {
        "k": "talk",
        "l": "Send your senior captain over to talk it down",
        "s": "Zero cost, and that captain gains 15 XP.",
        "need": {
          "vet": 2
        },
        "r": {
          "xpTop": 15
        },
        "fl": {
          "mercy": 1
        }
      }
    ]
  },
  {
    "id": "convoy",
    "t": "Civilian ore convoy",
    "b": "A slow line of battered bulk ore haulers pings your bridge, offering hard credits for armed escort across the next jump corridor.",
    "o": [
      {
        "k": "escort",
        "l": "Screen their jump transit",
        "s": "+45 credits from the grateful masters.",
        "r": {
          "cred": 45
        },
        "fl": {
          "mercy": 1
        }
      },
      {
        "k": "trade",
        "l": "Buy a spare hardware crate (60 credits)",
        "s": "Gain a random refit.",
        "r": {
          "cost": 60,
          "mod": 1
        }
      },
      {
        "k": "shake",
        "l": "Clamp onto their lead freighter and collect a toll",
        "s": "+100 credits. Word spreads fast: Nemesis clock moves on 1.",
        "need": {
          "fac": "corsair"
        },
        "r": {
          "cred": 100,
          "nemClock": 1
        },
        "fl": {
          "greed": 1,
          "loud": 1
        }
      }
    ]
  },
  {
    "id": "battlefield",
    "t": "Old debris ring",
    "b": "Torn hull halves from a forgotten engagement orbit a burnt rock, still bristling with live proximity mines.",
    "o": [
      {
        "k": "salvage",
        "l": "Thread the mines for hardware",
        "s": "Gain a random refit. One ship takes 12% hull damage.",
        "r": {
          "mod": 1,
          "dmgOne": 0.12
        }
      },
      {
        "k": "wings",
        "l": "Send squadrons ahead to clear the mines",
        "s": "Clean sweep: gain a random refit with zero damage.",
        "need": {
          "carrier": 1
        },
        "r": {
          "mod": 1
        }
      },
      {
        "k": "leave",
        "l": "Keep clear of the debris",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "scout",
    "t": "Picket on your wake",
    "b": "Passive sensors pick up a nimble scout riding the exact edge of your scanner cone, running your Nemesis's transponder signature.",
    "o": [
      {
        "k": "hunt",
        "l": "Burn hard and run it down",
        "s": "Every ship takes 5% hull strain. Nemesis clock back 1 and a weakness revealed.",
        "r": {
          "dmgAll": 0.05,
          "nemClock": -1,
          "nemIntel": 1
        }
      },
      {
        "k": "torp",
        "l": "Kill it at range with a torpedo spread",
        "s": "Nemesis clock back 1 and a weakness revealed. Zero hull damage.",
        "need": {
          "kind": "torp"
        },
        "r": {
          "nemClock": -1,
          "nemIntel": 1
        }
      },
      {
        "k": "ignore",
        "l": "Let it shadow you",
        "s": "The Nemesis clock moves on 1.",
        "r": {
          "nemClock": 1
        }
      }
    ]
  },
  {
    "id": "defector",
    "t": "Rival defector",
    "b": "A fast escape pod breaks away from your Nemesis's picket screen on an open distress channel. The pilot offers encrypted tactical plots in exchange for safe berth.",
    "o": [
      {
        "k": "question",
        "l": "Extract the tactical plots",
        "s": "A Nemesis weakness is revealed.",
        "r": {
          "nemIntel": 1
        },
        "fl": {
          "intel": 1
        }
      },
      {
        "k": "ransom",
        "l": "Sell the pod back on an open channel",
        "s": "+70 credits. Nemesis clock moves on 1.",
        "r": {
          "cred": 70,
          "nemClock": 1
        },
        "fl": {
          "greed": 1
        }
      },
      {
        "k": "enlist",
        "l": "Commission the officer into the Directorate",
        "s": "Least experienced ship gains 50 XP and a Nemesis weakness is revealed.",
        "need": {
          "fac": "hegemony"
        },
        "r": {
          "xpLow": 50,
          "nemIntel": 1
        },
        "fl": {
          "intel": 1
        }
      }
    ]
  },
  {
    "id": "dock",
    "t": "Adrift repair berth",
    "b": "An automated orbital service gantry still runs on fading solar cells, its robotic weld arms twitching as your fleet pulls into range.",
    "o": [
      {
        "k": "use",
        "l": "Feed the power bus (30 credits)",
        "s": "Your most damaged ship is fully repaired.",
        "r": {
          "cost": 30,
          "repairOne": 1
        }
      },
      {
        "k": "frame",
        "l": "Pull its last structural upgrade frame (100 credits)",
        "s": "Your most damaged ship is repaired and upgraded one Mark.",
        "need": {
          "cred": 100
        },
        "r": {
          "cost": 100,
          "upgradeOne": 1
        }
      },
      {
        "k": "leave",
        "l": "Leave it idling",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "well",
    "t": "Gravity slingshot",
    "b": "A collapsed dwarf star bends the direct lane ahead. Skimming its orbital trough will save serious fuel if your bulkheads hold under the shear.",
    "o": [
      {
        "k": "sling",
        "l": "Take the tight slingshot",
        "s": "Every ship takes 5% hull stress; save 35 credits of fuel.",
        "r": {
          "dmgAll": 0.05,
          "cred": 35
        }
      },
      {
        "k": "sails",
        "l": "Ride the gravity trough on crystal vanes",
        "s": "Zero stress, +35 credits saved.",
        "need": {
          "fac": "ithar"
        },
        "r": {
          "cred": 35
        }
      },
      {
        "k": "round",
        "l": "Fly the slow safe arc",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "auction",
    "t": "Black-market salvage bid",
    "b": "A neutral deep-space depot is running a live comms auction on hardware pulled from an older expedition. Bidding is tense and every buyer has weapons hot.",
    "o": [
      {
        "k": "bid",
        "l": "Outbid the room (120 credits)",
        "s": "Gain salvage.",
        "r": {
          "cost": 120,
          "relic": 1
        }
      },
      {
        "k": "swap",
        "l": "Trade a piece of your salvage for theirs",
        "s": "Lose one piece of salvage, gain a different one plus 40 credits.",
        "need": {
          "relic": 1
        },
        "r": {
          "payRelic": 1,
          "relic": 1,
          "cred": 40
        }
      },
      {
        "k": "leave",
        "l": "Listen and jump out",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "saboteur",
    "t": "Sabotage aboard",
    "b": "Three separate power relays have tripped mid-transit on one of your hulls, always right before a jump calculation. Somebody aboard is feeding coordinates to your Nemesis.",
    "o": [
      {
        "k": "search",
        "l": "Sweep the ship deck by deck",
        "s": "Short firefight causes 10% hull damage, yet the saboteur's pad reveals a Nemesis weakness.",
        "r": {
          "dmgOne": 0.1,
          "nemIntel": 1
        }
      },
      {
        "k": "face",
        "l": "Pull the name the defector gave you",
        "s": "Caught quietly before a shot fires: Nemesis clock back 1 and a weakness revealed.",
        "need": {
          "flag": "defector",
          "flagK": [
            "question",
            "enlist"
          ]
        },
        "r": {
          "nemClock": -1,
          "nemIntel": 1
        }
      },
      {
        "k": "ignore",
        "l": "Lock down bridge access and keep burning",
        "s": "Nemesis clock moves on 2.",
        "r": {
          "nemClock": 2
        }
      }
    ]
  },
  {
    "id": "veterans",
    "t": "Retired fleet tactician",
    "b": "A scarred veteran admiral living out her retirement on a cramped listening station offers to run live combat drills with your captains for a modest supply fee.",
    "o": [
      {
        "k": "pay",
        "l": "Transfer 50 credits in supplies",
        "s": "Every captain gains 25 XP.",
        "r": {
          "cost": 50,
          "xp": 25
        }
      },
      {
        "k": "oath",
        "l": "Give her the Vesper dawn-watch salute",
        "s": "She refuses your credits and runs the drills for free: +25 XP each.",
        "need": {
          "fac": "voidsworn"
        },
        "r": {
          "xp": 25
        }
      },
      {
        "k": "leave",
        "l": "Thank her and break orbit",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "haven",
    "t": "Raider den",
    "b": "A hollowed-out iron asteroid honeycombed with docking tunnels and makeshift gun ports. Half the sector's stolen alloy moves through its bays.",
    "o": [
      {
        "k": "raid",
        "l": "Crack the den open",
        "s": "Fight an elite Hullbreaker battle. Win salvage.",
        "r": {
          "fight": "corsair"
        },
        "fl": {
          "loud": 1
        }
      },
      {
        "k": "tribute",
        "l": "Pay them to scramble your jump wake (40 credits)",
        "s": "Nemesis clock back 1.",
        "r": {
          "cost": 40,
          "nemClock": -1
        }
      },
      {
        "k": "recruit",
        "l": "Challenge a young raider crew to fly with you",
        "s": "A veteran Hullbreaker raider joins your pack.",
        "need": {
          "fac": "corsair"
        },
        "r": {
          "shipRaw": "c_raider",
          "vet": 1
        }
      },
      {
        "k": "leave",
        "l": "Give the rock a wide berth",
        "s": "Nothing happens.",
        "r": {}
      }
    ]
  },
  {
    "id": "quiet",
    "t": "Clear void",
    "b": "Clean scopes for six light-hours in every direction. For the first time in weeks, no transponder is shadowing your wake.",
    "o": [
      {
        "k": "rest",
        "l": "Stand down and patch hulls",
        "s": "Every ship repairs 10% hull.",
        "r": {
          "healAll": 0.1
        }
      },
      {
        "k": "drill",
        "l": "Run live formation drills",
        "s": "+10 XP per ship.",
        "r": {
          "xp": 10
        }
      }
    ]
  }
];
// Faction voices only. Option copy is keyed by the saved choice key (or its existing index).
const eventVoices = {
  "merc": {
    "chorus": {
      "t": "Severed hunter-brood",
      "b": "A scarred Chorus destroyer cut off from a dead cluster answers our thermal pulse. It will graft into our swarm if we shed 80 credits' worth of refined alloy to feed its bonding sacs.",
      "o": {
        "0": {
          "l": "Feed the bonding sacs (80 credits)",
          "s": "A veteran Chorus destroyer grafts into the swarm."
        },
        "2": {
          "l": "Leave it drifting",
          "s": "Nothing happens."
        }
      }
    },
    "deathless": {
      "t": "Unlinked Eclipse flare",
      "b": "A lone Eclipse destroyer from an older expedition drifts dark along the lane, its local mind intact though its uplink relay is burned out. Rebuilding the bridge takes 80 credits in rare alloys.",
      "o": {
        "0": {
          "l": "Rebuild its relay (80 credits)",
          "s": "A veteran Eclipse destroyer rejoins the line."
        },
        "2": {
          "l": "Leave it dormant",
          "s": "Nothing happens."
        }
      }
    },
    "corsair": {
      "t": "Packless gutship",
      "b": "A beat-up Hullbreaker gutship swings across your bow with its weapons powered down. Its captain just lost a den challenge and wants fuel, rockets, and a stronger warlord to fly under.",
      "o": {
        "0": {
          "l": "Pay their dock tab (80 credits)",
          "s": "A veteran Hullbreaker gutship joins your pack."
        },
        "2": {
          "l": "Tell them to find another den",
          "s": "Nothing happens."
        }
      }
    },
    "ithar": {
      "t": "Stranded lancet",
      "b": "A lone Glasswright lancet emerges from dust cover, its primary mirror pitted from an old ambush. Its captain offers to join your formation if you fund the kiln-glass needed to seal her hull.",
      "o": {
        "0": {
          "l": "Supply the crystal stock (80 credits)",
          "s": "A veteran Glasswright lancet joins your fleet."
        },
        "2": {
          "l": "Wish her clear lanes",
          "s": "Nothing happens."
        }
      }
    }
  },
  "mutiny": {
    "chorus": {
      "t": "Divergent hunger-pulse",
      "b": "One hull stops tracking the swarm's turn vector, curling inward and pulsing frantic starvation signals across the brood.",
      "o": {
        "pay": {
          "l": "Dump refined mineral stock into its sacs (50 credits)",
          "s": "The hull feeds and locks back into formation."
        },
        "discipline": {
          "l": "Purge the noisy neural cluster",
          "s": "Flagship loses 20 XP; the rest of the swarm snaps back into step."
        },
        "talk": {
          "l": "Let our oldest brood-mind override the pulse",
          "s": "Zero cost, and your senior hull gains 15 XP."
        }
      }
    },
    "deathless": {
      "t": "Clock drift in the line",
      "b": "A damaged optical bus on one hull has knocked its fire-control clock half a second out of sync with the Archive net, causing erratic course corrections.",
      "o": {
        "pay": {
          "l": "Replace the bus with fresh parts (50 credits)",
          "s": "Timing locks clean across the fleet."
        },
        "discipline": {
          "l": "Roll back the flagship's local command buffer",
          "s": "Flagship loses 20 XP; timing stabilizes."
        },
        "talk": {
          "l": "Have your senior mind recalibrate it manually",
          "s": "Zero cost, and your senior hull gains 15 XP."
        }
      }
    },
    "corsair": {
      "t": "Challenge on the open band",
      "b": "One of your junior captains is mouthing off over fleet comms about getting short-changed on scrap shares. Half the pack is listening to see how you answer.",
      "o": {
        "pay": {
          "l": "Toss them a fat cut of alloy (50 credits)",
          "s": "The grumbling turns into loud bragging."
        },
        "discipline": {
          "l": "Put a warning shot across their bridge",
          "s": "Flagship loses 20 XP in wasted ammo and pride; the band goes quiet."
        },
        "talk": {
          "l": "Let your meanest veteran shut them down",
          "s": "Zero cost, and that captain gains 15 XP."
        }
      }
    },
    "ithar": {
      "t": "Fractured consensus",
      "b": "A younger mirror-captain is pulsing sharp dissent across the optical link, arguing that pushing closer to Ardent repeats the exact hubris that killed your star.",
      "o": {
        "pay": {
          "l": "Allocate extra shielding crystals to her vessel (50 credits)",
          "s": "Her inlays steady and the formation holds."
        },
        "discipline": {
          "l": "Pull rank and seal the open channel",
          "s": "Flagship loses 20 XP; order holds, though coldly."
        },
        "talk": {
          "l": "Let your eldest Mirror answer her",
          "s": "Zero cost, and your senior captain gains 15 XP."
        }
      }
    }
  },
  "pilot": {
    "chorus": {
      "t": "Orphan spore-wing",
      "b": "A lone strike organism clings to a tumbling slab of hull metal, pulsing the dying hunt-pattern of a brood wiped out two jumps back.",
      "o": {
        "take": {
          "l": "Absorb its hunt-memory",
          "s": "Your least experienced hull gains 40 XP."
        },
        "wing": {
          "l": "Graft it into your largest brood-sac",
          "s": "Your best carrier's swarms gain a veteran perk."
        },
        "leave": {
          "l": "Let it freeze",
          "s": "Nothing happens."
        }
      }
    },
    "deathless": {
      "t": "Intact drone flight core",
      "b": "A crippled interceptor drone pings weakly from a shattered launch rack. Its chassis is slag, though its combat flight logs remain uncorrupted.",
      "o": {
        "take": {
          "l": "Stream the logs to a junior frame",
          "s": "Your least experienced ship gains 40 XP."
        },
        "wing": {
          "l": "Upload the maneuvers into your largest carrier",
          "s": "Your best carrier's wings gain a veteran perk."
        },
        "leave": {
          "l": "Leave it pinging",
          "s": "Nothing happens."
        }
      }
    },
    "corsair": {
      "t": "Adrift scrap-jockey",
      "b": "Your pickets haul in a scorched ejection pod belonging to a lunatic fighter jockey whose carrier got cored last week. Still clutching her kill-tally drive.",
      "o": {
        "take": {
          "l": "Put her on a junior gunnery bridge",
          "s": "Your least experienced captain gains 40 XP."
        },
        "wing": {
          "l": "Give her a bay on your best hulk-carrier",
          "s": "That carrier's wings gain a veteran perk."
        },
        "leave": {
          "l": "Toss the pod toward a neutral beacon",
          "s": "Nothing happens."
        }
      }
    },
    "ithar": {
      "t": "Stranded starling pilot",
      "b": "Sensors pick up a fading amber pulse from a crippled starling canopy drifting near an asteroid. Its pilot has kept the wing's optical telemetry alive on reserve power.",
      "o": {
        "take": {
          "l": "Bring the pilot onto a young cruiser",
          "s": "Your least experienced captain gains 40 XP."
        },
        "wing": {
          "l": "Assign the pilot to your senior aperture",
          "s": "Your best carrier's wings gain a veteran perk."
        },
        "leave": {
          "l": "Mark the beacon for passing kin",
          "s": "Nothing happens."
        }
      }
    }
  },
  "deserters": {
    "chorus": {
      "t": "Adrift Directorate escape pod",
      "b": "A Directorate lifeboat drifts off-lane with its drive dead, still broadcasting compressed tactical logs on emergency loop.",
      "o": {
        "0": {
          "l": "Consume the pod and read the combat traces",
          "s": "Your least experienced hull gains 60 XP."
        },
        "question": {
          "l": "Have a senior brood-mind dissect the command codes",
          "s": "Least experienced hull gains 30 XP and reveals a Nemesis weakness."
        },
        "2": {
          "l": "Strip its high-grade alloy shell",
          "s": "+60 credits."
        }
      }
    },
    "deathless": {
      "t": "Directorate lifeboat requesting berth",
      "b": "A Directorate escape pod pings your lead ships with an asylum request, offering stolen fleet formation data in trade.",
      "o": {
        "0": {
          "l": "Scan their combat logs and release the pod",
          "s": "Your least experienced ship gains 60 XP."
        },
        "question": {
          "l": "Cross-reference their logs against the Archive",
          "s": "Least experienced ship gains 30 XP and reveals a Nemesis weakness."
        },
        "2": {
          "l": "Broadcast their beacon to Meridian for salvage credit",
          "s": "+60 credits."
        }
      }
    }
  },
  "veterans": {
    "chorus": {
      "t": "Dormant Fleshwright vat",
      "b": "An old Fleshwright growth station drifts dark in the belt, its neural tissue frozen in stasis. Feeding it 50 credits' worth of refined minerals will wake its ancestral hunt instincts.",
      "o": {
        "pay": {
          "l": "Feed the vat (50 credits)",
          "s": "+25 XP per hull."
        },
        "leave": {
          "l": "Leave the tissue frozen",
          "s": "Nothing happens."
        }
      }
    },
    "deathless": {
      "t": "Unpowered Archive relay",
      "b": "A pre-collapse tactical relay drifts outside the main net, its power capacitors dead. Spending 50 credits in stabilizer isotopes will wake it long enough to pull its combat drills.",
      "o": {
        "pay": {
          "l": "Power the relay (50 credits)",
          "s": "+25 XP per ship."
        },
        "leave": {
          "l": "Leave it dark",
          "s": "Nothing happens."
        }
      }
    },
    "corsair": {
      "t": "One-armed den veteran",
      "b": "An ancient retired Hullbreaker warlord squats inside a welded rock-bar, offering to teach your green captains how to crack heavy cruisers if you drop off 50 credits in parts and booze.",
      "o": {
        "pay": {
          "l": "Drop off the parts (50 credits)",
          "s": "+25 XP per captain."
        },
        "leave": {
          "l": "Tell him to keep his stories",
          "s": "Nothing happens."
        }
      }
    },
    "ithar": {
      "t": "Retired Lens-keeper",
      "b": "An elder Glasswright tending a quiet outer observatory offers to review your captains' firing optics in exchange for 50 credits in raw optical quartz.",
      "o": {
        "pay": {
          "l": "Deliver the quartz (50 credits)",
          "s": "+25 XP per captain."
        },
        "leave": {
          "l": "Salute and continue",
          "s": "Nothing happens."
        }
      }
    }
  },
  "reactor": {
    "chorus": {
      "t": "Rupturing thermal sac",
      "b": "Our largest hull spasms as its primary heat-sac splits along an old scar. Outer chitin holds for now, though one hard burn could tear it open.",
      "o": {
        "vent": {
          "l": "Bleed the sac and force raw regrowth",
          "s": "Your largest hull takes 20% damage."
        },
        "refit": {
          "l": "Graft a spare refit over the rupture",
          "s": "Uses one refit from the hold. Zero hull damage."
        },
        "pay": {
          "l": "Shed 45 credits of dense minerals to calcify the seam",
          "s": "Zero hull damage."
        }
      }
    },
    "deathless": {
      "t": "Core containment crack",
      "b": "Telemetry flags a micro-fracture in the containment band around your largest hull's trapped starlight core.",
      "o": {
        "vent": {
          "l": "Bleed excess output and re-weld",
          "s": "Your largest ship takes 20% hull damage."
        },
        "refit": {
          "l": "Bridge the casing with a spare refit",
          "s": "Uses one refit from the hold. Zero damage."
        },
        "metal": {
          "l": "Route repair drones straight to the seam",
          "s": "Zero cost."
        },
        "pay": {
          "l": "Synthesize a fresh containment band (45 credits)",
          "s": "Zero damage."
        }
      }
    }
  },
  "convoy": {
    "chorus": {
      "t": "Heavy ore barges crossing the lane",
      "b": "Fat, slow bulk haulers lumber along the jump gate, shedding warm slag pods as distraction bait to keep our swarm off their main hulls.",
      "o": {
        "escort": {
          "l": "Swallow the dropped alloy pods and let them pass",
          "s": "+45 credits in refined metal."
        },
        "trade": {
          "l": "Tear a hardware pod off their flank (60 credits in biomass/alloy spent)",
          "s": "Gain a random refit."
        }
      }
    },
    "deathless": {
      "t": "Automated freighter transit",
      "b": "Uncrewed core-world ore drones request lane clearance through your formation, transmitting standard transit compensation.",
      "o": {
        "escort": {
          "l": "Clear their vector",
          "s": "+45 credits."
        },
        "trade": {
          "l": "Requisition a hardware crate (60 credits)",
          "s": "Gain a random refit."
        }
      }
    }
  },
  "auction": {
    "chorus": {
      "t": "Contested wreck-field cache",
      "b": "Three rival scavenger cutters orbit an armed neutral depot holding a rare founders' artifact. Pushing past their point defense will cost heavy biomass and alloy.",
      "o": {
        "bid": {
          "l": "Absorb the outer flak and seize the artifact (120 credits)",
          "s": "Gain salvage."
        },
        "swap": {
          "l": "Drop an older artifact as bait and snatch the prize",
          "s": "Swap one piece of salvage and gain 40 credits in stripped alloy."
        },
        "leave": {
          "l": "Drift past into the dark",
          "s": "Nothing happens."
        }
      }
    },
    "deathless": {
      "t": "Open salvage exchange",
      "b": "A neutral brokerage station is liquidating founders' hardware from a shattered expedition. Every ship holding orbit has shields raised.",
      "o": {
        "bid": {
          "l": "Acquire the lot outright (120 credits)",
          "s": "Gain salvage."
        },
        "swap": {
          "l": "Submit a hardware swap",
          "s": "Swap one piece of salvage and gain 40 credits."
        },
        "leave": {
          "l": "Close the channel",
          "s": "Nothing happens."
        }
      }
    }
  },
  "saboteur": {
    "chorus": {
      "t": "Foreign transponder in the hide",
      "b": "One of our hulls twitches on every turn; a hostile tracking spike has been buried inside its outer chitin, pinging our coordinates to your Nemesis.",
      "o": {
        "search": {
          "l": "Burn the spike out with acid",
          "s": "One hull takes 10% damage; reading its burst frequency reveals a Nemesis weakness."
        },
        "face": {
          "l": "Match the captured Directorate frequency to extract it cleanly",
          "s": "Zero damage; Nemesis clock back 1 and a weakness revealed."
        }
      }
    },
    "deathless": {
      "t": "Compromised uplink subroutine",
      "b": "One hull drops packet frames at fixed intervals; an injected beacon routine has been leaking jump vectors to your Nemesis.",
      "o": {
        "search": {
          "l": "Purge the affected bus under load",
          "s": "One ship takes 10% hull damage; tracing the return header reveals a Nemesis weakness."
        },
        "face": {
          "l": "Cross-check the defector's cipher to trap it quietly",
          "s": "Zero damage; Nemesis clock back 1 and a weakness revealed."
        }
      }
    }
  },
  "wright": {
    "chorus": {
      "t": "Thermal vent asteroid",
      "b": "A fractured volcanic rock vents dense mineral vapor along the jump lane, rich enough to calcify our heaviest hull into a tougher strain.",
      "o": {
        "0": {
          "l": "Bathe the most damaged hull in the plume",
          "s": "Your most damaged hull heals fully and evolves one Mark."
        },
        "pay": {
          "l": "Dissolve a spare refit into the vent",
          "s": "Your most damaged hull heals and evolves, plus a second hull heals fully."
        },
        "2": {
          "l": "Move on",
          "s": "Nothing happens."
        }
      }
    }
  },
  "broker": {
    "chorus": {
      "t": "Drifting relay buoy",
      "b": "A cloaked intelligence relay hangs silent behind a rock, holding encrypted fleet logs on your Nemesis. Cracking its armored shell without frying the memory core takes care.",
      "o": {
        "buy": {
          "l": "Spend 60 credits in alloy/biomass to peel the casing slowly",
          "s": "A Nemesis weakness is revealed."
        },
        "leave": {
          "l": "Leave the cold metal",
          "s": "Nothing happens."
        }
      }
    }
  },
  "dock": {
    "chorus": {
      "t": "Mineral-rich slag barge",
      "b": "A derelict ore refinery tumbles along the lane, its heated furnaces still holding pools of molten iron and silicon ideal for rapid regrowth.",
      "o": {
        "use": {
          "l": "Crack the outer vat (30 credits)",
          "s": "Your most damaged hull regrows to full."
        },
        "frame": {
          "l": "Consume the primary core smelter (100 credits)",
          "s": "Your most damaged hull regrows fully and evolves one Mark."
        },
        "leave": {
          "l": "Drift past",
          "s": "Nothing happens."
        }
      }
    }
  },
  "haven": {
    "chorus": {
      "t": "Raider rock-den",
      "b": "A Hullbreaker asteroid fortress bristles with docking tunnels and scrap cannons, reeking of hot drive fuel and unshielded reactors.",
      "o": {
        "raid": {
          "l": "Swarm the docking tunnels",
          "s": "Fight an elite Hullbreaker battle. Win salvage."
        },
        "tribute": {
          "l": "Seed decoy spore clouds to mask our wake (40 credits)",
          "s": "Nemesis clock back 1."
        },
        "leave": {
          "l": "Give the rock a wide berth",
          "s": "Nothing happens."
        }
      }
    }
  }
};
for (const event of EVENTS) {
  const voices = eventVoices[event.id];
  if (!voices) continue;
  event.v = Object.fromEntries(Object.entries(voices).map(([fac, {o: copy, ...card}]) => {
    const options = event.o.map((option, i) => {
      const {l = option.l, s = option.s} = copy[option.k || String(i)] || {};
      return {...option, l, s};
    });
    return [fac, {...card, o: options}];
  }));
}

// the tithe vault and the tomb-world fights already reward a relic through the elite battle; 'tombhome' is the Deathless-only twin of 'tomb'
const EVENT_FALLBACK='quiet'; // shown when a run has seen every other event
// ---------- B4 the Nemesis: one named enemy commander per run (also the story rival, R7) ----------
// Two fixed weaknesses rolled at run start (true from the first meeting; intel reveals them to you), a visible clock, and one capped
// adaptation per sector, read from how you fought the sector before. He never takes control of your ships, and his fights are always
// marked on the map before you commit (no ship loss without warning).
const NEM_CLOCK=4; // the clock fills with every fight you win and every loud choice; when full, your next fight is his
const NEM_WEAK={
  flank:{n:'Thin stern plating',d:'Enemy ships take 25% more damage on rear-arc hits.',v:{chorus:{n:'Thin aft hide',d:'Enemy ships take 25% more damage on rear-arc hits.'}}},
  ion:{n:'Brittle shield emitters',d:'Ion and lance hits strip 50% more shield from enemy ships.'},
  torp:{n:'Poor point defense',d:'Torpedoes are 15 easier to land on enemy ships.'},
  board:{n:'Green boarding crews',d:'Enemy ships carry 30% fewer crew to repel boarders.'},
  brawl:{n:'Long-gun doctrine',d:'Enemy ships aim 10 worse at targets 2 hexes away or closer.'},
  anchor:{n:'A proud flagship',d:'Enemy escorts break and flee once the flagship falls below 60% hull.'},
  slow:{n:'Worn engines',d:'Enemy ships have 1 less movement.'}};
const NEM_ADAPT={
  shields:{n:'Reinforced shields',d:'Enemy ships have 20% more shields.',why:'you leaned on lances and ion fire'},
  pd:{n:'Extra point defense',d:'Up to two enemy ships without point defense bolt it on.',why:'you leaned on torpedoes and wings'},
  armor:{n:'Ram plating',d:'Enemy ships have 10% more armor.',why:'you rammed and boarded'},
  evasion:{n:'Evasive drills',d:'Enemy ships have 8 more evasion.',why:'you leaned on flank guns and batteries'},
  aim:{n:'Gunnery drills',d:'Enemy ships aim 8 better.',why:'you won by staying hard to hit'}};
// ---------- R42 Nemesis v2: a different rival every run, built per faction (never a player admiral), with faction behaviour ----------
// Name: one part from pre and one from post (plus a title and an epithet), so it never matches an ADMIRALS name. Personality and two strength traits
// come from the faction pools; the portrait is one of six per faction (nem_<faction>_1..6); scars add overlays and a new epithet each time he survives.
// beh: how he behaves. clock = clock gain per win (patient below 1, zealous above); flee = he withdraws from a lost fight (flagship hull or
// shields test) and comes back; revive = he comes back once after his flagship is destroyed; strike = what a full clock does on the map
// (raid: takes credits, or a crippled ship if you have none, always announced on his card first; reinforce: his fight brings reinforcements;
// challenge: a duel with your flagship; tithe: your fleet loses hull to the hunt); fleet = archetype his fleet is built as; ai = battle weights.
const NEM_TRAITS={
  gunnery:{n:'Master gunners',d:'Enemy ships aim 6 better.'}, armored:{n:'Heavy plating',d:'Enemy ships have 8% more armor.'}, swift:{n:'Hot engines',d:'Enemy ships have 1 more movement.'},
  veterans:{n:'Veteran crews',d:'Enemy ships have 12% more hull.'}, deadeye:{n:'Deadeyes',d:'Enemy ships have 10% more critical chance.'}, shielded:{n:'Overcharged shields',d:'Enemy ships have 20% more shields.'},
  boarders:{n:'Boarding gangs',d:'Enemy ships carry 30% more crew.',v:{chorus:{n:'Breach broods',d:'Enemy ships have 30% more boarding organisms.'}}}, regrowth:{n:'Deep regrowth',d:'Enemy ships regrow 4 more hull each turn.'}, brood:{n:'Swollen broods',d:'Enemy launch ships can replace one more wing and carry one more spare.'},
  undying:{n:'Spare frames',d:'One more eligible enemy ship can reassemble after falling.'}, veil:{n:'Veil-dancers',d:'Enemy ships are 8 harder to hit.'}, artillery:{n:'Artillery line',d:'Enemy guns other than point defense and squadron weapons reach 1 hex further.'},
  zeal:{n:'Close assault',d:'Enemy ships deal 12% more damage to a ship next to them.'}, rockets:{n:'Rocket hoarders',d:'Enemy torpedoes reload a turn faster.'}};
function nemEntry(table,key,fac){ const entry=table[key]; return entry?.v?.[fac] || entry; }
// Issue 1182: a save from an older build can hold a trait or weakness key the table no longer has; show the raw key, never crash.
function nemEntryName(table,key,fac){ const entry=nemEntry(table,key,fac); return entry&&entry.n!=null?entry.n:String(key); }
const NEM_PERSONA={
  cunning:{n:'Cunning',d:'Strikes your flanks and your weakest ship.',ai:{focusWeak:1,rear:1}}, zealous:{n:'Zealous',d:'Charges in and never backs off.',ai:{tw:.6,range:-2}},
  cruel:{n:'Cruel',d:'Finishes crippled ships first.',ai:{focusWeak:1}}, patient:{n:'Patient',d:'Waits for you to close in.',ai:{tw:1.3,range:2}},
  proud:{n:'Proud',d:'Leads from the front, flagship first.',ai:{flagFront:1}}, greedy:{n:'Greedy',d:'Goes for your richest prize, your flagship.',ai:{focusFlag:1}},
  methodical:{n:'Methodical',d:'Advances cautiously under fire.',ai:{tw:1.2}}, ravenous:{n:'Ravenous',d:'Swarms whatever is closest.',ai:{tw:.5,range:-1}}};
const NEM_FAC={
  corsair:{pre:['Krag','Drog','Rusk','Gor','Snag','Hask','Grul','Murg','Skarn','Jagg'],post:['Tooth','Maw','Gut','Vise','Hook','Knuckle','Rot','Grin','Spur','Wreck'],titles:['Apex','First Claw','Den-alpha','Warlord'],
    personas:['cunning','greedy','proud','cruel'],g:null,fem:[],traits:['boarders','swift','rockets','deadeye','gunnery','veterans'],scars:['the Burned','Broken-Jaw','Half-Face','the Uncaught','Patchwork','One-Eye'],scarBy:{fled:['the Uncaught'],burn:['the Burned','Half-Face'],wound:['Broken-Jaw','Patchwork','One-Eye']},
    beh:{clock:1,flee:{hull:.35},strike:'raid',fleet:'swarm',d:"Raids your supply lanes. At full clock, steals 25% of your credits (or a ship under 25% hull if you have under 30 credits and 3+ ships); kill the commander to take everything back. Flees losing fights and returns with an extra hull."}},
  deathless:{pre:['Mar','Kae','Hal','Tor','Ess','Ul','Vor','Iv','Sar','Den'],post:['un','lo','vane','eth','ane','ix','or','ael','en','ast'],titles:['High Nadir','Eclipse-prime','Archivist'],
    personas:['patient','proud','cruel','methodical'],g:null,fem:['Ess','Kae','Iv'],traits:['undying','armored','veterans','regrowth','gunnery','deadeye'],scars:['the Twice-Dead','the Rebuilt','Cracked-Visor','Half-Restored','Split-Visor','of the Late Copy'],scarBy:{fled:['of the Late Copy','Half-Restored'],burn:['Split-Visor','the Rebuilt'],wound:['the Twice-Dead','Cracked-Visor','the Rebuilt']},
    beh:{clock:.5,revive:1,strike:'tithe',fleet:'heavy',d:"Clock fills at half speed and never retreats. Destroyed early, the frame rebuilds; destroyed in sector III, rises once more for a final battle. At full clock, drains 6% hull across your fleet (never below 1)."}},
  ithar:{pre:['Kor','Sev','Tal','Ol','Ves','Dre','Ish','Ren','Cal','Ny'],post:['ek','is','oro','an','et','ul','ith','im','os','ae'],titles:['Lens-keeper','First Mirror','Keeper of Astra','Duelist'],
    personas:['cunning','proud','patient','cruel'],g:null,fem:['Ves','Ish','Ny','Dre'],traits:['veil','shielded','swift','deadeye','gunnery','artillery'],scars:['the Cracked Prism','Dimmed','the Scarred Vane','Thornwing','the Unbowed','Ashwake'],scarBy:{fled:['the Unbowed','Ashwake'],burn:['Dimmed','the Cracked Prism'],wound:['the Scarred Vane','Thornwing','the Cracked Prism']},
    beh:{clock:1,flee:{shields:1,hull:.6},strike:'duel',fleet:'duel',ai:{range:3,focusWeak:1},d:"Runs a small elite duelist formation, picks off damaged ships at range, and withdraws once its flagship drops shields and falls below 60% hull, returning with sharper shields and aim."}},
  chorus:{pre:["Eighth", "Sunken", "Bitter", "Swollen", "Rusted", "Ashen", "Split", "Molten", "Cinder", "Dredged"],post:["Siphon", "Cluster", "Gullet", "Spore", "Vein", "Trench", "Cyst", "Swarm", "Rasp", "Maw"],titles:['Spawn-mother','Elder Throat','Gorge-mind','Maw-mother'],
    personas:['ravenous','cruel','cunning','patient'],g:'n',fem:[],traits:['regrowth','brood','veterans','swift','boarders','deadeye'],scars:['the Scarred Maw','Half-Eaten','the Burned Throat','Rotflesh','the Gnawed','Scabhide'],scarBy:{fled:['Half-Eaten'],burn:['the Burned Throat','Scabhide'],wound:['the Scarred Maw','Rotflesh','the Gnawed']},
    beh:{clock:1,feeds:1,adaptFast:1,strike:'swarm',fleet:'swarm',d:"Grows stronger from every ship you lose anywhere (+4% fleet toughness per loss, up to 32%). Swarms aggressively and adapts after every battle."}},
  hegemony:{pre:["Dietrich", "Anneliese", "Lukas", "Bettina", "Stefan", "Freya", "Henrik", "Maren", "Tobias", "Astrid"],post:["Steiner", "Valk", "Morgan", "Hale", "Draxen", "Kolb", "Vos", "Ostrander", "Kramer", "Bauer"],titles:['First Admiral','Fleet Marshal','Line Admiral','High Commodore'],
    personas:['methodical','proud','patient','cunning'],g:null,fem:["Anneliese", "Bettina", "Freya", "Maren", "Astrid"],traits:['artillery','shielded','gunnery','armored','veterans','deadeye'],scars:['the Burned Admiral','Ironside','One-Arm','the Unbroken','Scar-Cheek','the Survivor'],scarBy:{fled:['the Survivor','the Unbroken'],burn:['the Burned Admiral','Scar-Cheek'],wound:['One-Arm','Ironside','Scar-Cheek']},
    beh:{clock:1,strike:'reinforce',fleet:'heavy',line:1,d:"Escorts hold a tight artillery column around the flagship (less long-range falloff while close), and reinforcements jump in on round 3. Adapts by tightening formation."}},
  voidsworn:{pre:['Leofric','Margit','Osmund','Ida','Berthold','Hedda','Wendel','Agathe','Gunther','Edda'],post:["Bramwell", "Caldwell", "Fenwick", "Graves", "Harlan", "Keats", "Maddock", "Redfern", "Thatcher", "Weyland"],titles:['High Warden','Warden of the Roll','Dawnwarden','Oath-warden'],
    personas:['zealous','proud','cruel','methodical'],g:null,fem:['Margit','Ida','Hedda','Agathe','Edda'],masc:['Leofric','Osmund','Berthold','Wendel','Gunther'],traits:['zeal','boarders','armored','veterans','gunnery','artillery'],scars:['the Branded','Iron-Armed','the Frost-Scarred','Burnt-Oath','the Debt-Bound','Ashface'],scarBy:{fled:['the Debt-Bound'],burn:['the Branded','Burnt-Oath','Ashface'],wound:['Iron-Armed','the Frost-Scarred']},
    beh:{clock:1.5,noFlee:1,strike:'challenge',fleet:'line',ai:{hunt:1,charge:1},d:"Clock fills fast, never retreats, and challenges your flagship to single combat (+20% damage both ways; if your flagship falls, targets your strongest remaining ship)."}}};
// faction-specific adaptations: the same counters as NEM_ADAPT, in each faction's own words, plus one faction-only adaptation (special) that he
// takes when nothing in particular stood out in how you fought
const NEM_ADAPT_FAC={
  corsair:{shields:'Stolen shield cells',pd:'Chaff launchers',armor:'Scrap ram plating',evasion:'Overbored burners',aim:'Stolen gun sights',special:{id:'riches',n:'Bigger fleet',d:'One more ship joins the fleet.'}},
  deathless:{shields:'Corona ward',pd:'Null spires',armor:'Sunshade shell',evasion:'Fold skips',aim:'Long-memory sight',special:{id:'legion',n:'Deeper backups',d:'One more eligible enemy ship can reassemble.'}},
  ithar:{shields:'Prism matrix',pd:'Mirror veil',armor:'Waveguide spine',evasion:'Crystal vanes',aim:'Interferometer lenses',special:{id:'veil',n:'Deeper veil',d:'Enemy ships are 6 harder to hit.'}},
  chorus:{shields:'Thickened membrane',pd:'Spore curtains',armor:'Chitin layers',evasion:'Fin clusters',aim:'Tasting pores',special:{id:'hunger',n:'Hunger',d:'Enemy ships regrow 3 more hull each turn.'}},
  hegemony:{shields:'Deflector drills',pd:'Picket screens',armor:'Bow plating',evasion:'Attitude drills',aim:'Fire-control drills',special:{id:'formation',n:'Tight formation',d:'Synchronized fire reaches one hex further.'}},
  voidsworn:{shields:'Screen drills',pd:'Spark flak',armor:'Riveted plate',evasion:'Oath of speed',aim:'Hand-laid sights',special:{id:'zeal',n:'Battle grit',d:'Enemy ships deal 8% more damage.'}}};
// what he says when you meet again (placeholders until the story helper's rival line pools arrive; {beat} is how you beat him last time)
const NEM_LINES={
  meet:{cunning:'Your weak points are clear.',zealous:'Clear our lane or burn.',cruel:'Your fleet will come apart one ship at a time.',patient:'There is time to wait. Come closer.',proud:'You are not worthy of these guns. They will fire anyway.',greedy:'Your flagship will look fine in the yards.',methodical:'Every move you can make has been planned for.',ravenous:'More. Always more.'},
  again:'You relied on {beat} last time. We came ready for it.', // only when he took the counter to it
  remember:'We still remember how you used {beat} against us.', // beaten, but no counter yet
  gloat:{flagship:'Your flagship broke last time. This time finishes the job.',retreat:'You ran last time. Run again.',loss:'You lost once already. Nothing has changed.'}};
const NEM_BEAT_WORD={lance:'lances',torp:'torpedoes',sq:'your wings',ram:'rams',board:'boarding parties',battery:'massed batteries',evasive:'speed and evasion'}; // last_beat ids match the story helper's pools
// R101 (#173, adopted Nov 4 2026; built in #121): the commanders' own lines, per faction and persona, spoken through nemSay (pronouns
// swapped at runtime, {beat} replaced with a NEM_BEAT_WORD value). meet opens his battle; win, flee and fall close it (fall_final: an Eclipse
// commander destroyed in the last sector, rising once more); again and remember replace NEM_LINES' when he has met you; adapt is said when
// he adapts; lessons are the debrief teaching a lost meeting records on the commander met. All six factions have a block: the five
// adopted in contrib/muse/design/nemesis_writing_2026_11/text_table.md, plus the Sunward Crusade pasted word for word from
// contrib/muse/design/nemesis_writing_2026_11/crusade_voice.md (#395).
const NEM_VOICE = {
  "hegemony": {
    "methodical": {
      "meet": [
        "Registry contact verified. Your approach vector already matches Contingency Four.",
        "Hold your current heading; every firing arc is measured against the column plot."
      ],
      "win": [
        "Engagement resolved within projected margins. Recording hostile losses to the sector ledger.",
        "Outcome verified as modeled. Proceeding to the next waypoint on schedule."
      ],
      "flee": [
        "Column integrity compromised. Executing controlled withdrawal to preserve hull data.",
        "Current vector is no longer cost-effective. Disengaging for fleet reallocation."
      ],
      "fall": [
        "Command vessel offline. Meridian will close this dossier and assign a replacement column.",
        "Hull lost cleanly. Transmit all engagement telemetry before reactor cutoff."
      ],
      "again": "Your earlier reliance on {beat} has been incorporated into standard column drills.",
      "remember": "Meridian still holds your {beat} profile from our prior encounter."
    },
    "proud": {
      "meet": [
        "You are engaging a First-Line Meridian flagship. Do not expect our column to yield a single hex.",
        "My flagship sets the firing standard for this sector. Match it or break apart."
      ],
      "win": [
        "A disciplined line holds because its commander refuses to drift. Note the difference.",
        "You challenged the front of a Directorate column and accomplished nothing."
      ],
      "flee": [
        "Escort attrition is unacceptable. Pulling back to refit, not surrendering the lane.",
        "Reassigning to a cleaner firing orbit; Meridian will review this shortly."
      ],
      "fall": [
        "A First-Line flagship struck from the active register... completely unacceptable.",
        "An unexpected failure. Ensure the admiralty studies exactly how this occurred."
      ],
      "again": "You won our previous exchange with {beat}. My forward screen is specifically configured to stop it now.",
      "remember": "I have not forgotten how you used {beat} against my column."
    },
    "patient": {
      "meet": [
        "Take whatever time you require to close. Our firing grid is already calibrated.",
        "Approach when ready. A Directorate column has no need to rush an engagement."
      ],
      "win": [
        "You committed across open space too early, exactly as projected.",
        "Patience and range control decide fleet actions far more reliably than haste."
      ],
      "flee": [
        "Holding this position no longer justifies the repair outlay. Withdrawing cleanly.",
        "Disengaging ahead of critical loss. Another opportunity will present itself."
      ],
      "fall": [
        "Our caution cost us the initiative. Log the error accurately for Meridian.",
        "Even a patient column breaks when outflanked. Closing active telemetry."
      ],
      "again": "After your success with {beat}, we extended our stand-off protocols to neutralize it.",
      "remember": "Your use of {beat} remains flagged at the top of my tactical brief."
    },
    "cunning": {
      "meet": [
        "Your weakest escort is already bracketed on my tactical plot. Proceed whenever you like.",
        "We anticipated your flank maneuver before you exited jump. Engage."
      ],
      "win": [
        "One exposed flank was sufficient to collapse your entire formation.",
        "You noticed our crossfire two rounds too late. Recording final results."
      ],
      "flee": [
        "Current engagement parameters have shifted unfavorably. Breaking contact to reset the board.",
        "Controlled exit complete. Our next intercept will leave fewer escape vectors."
      ],
      "fall": [
        "One miscalculated firing lane undid the entire intercept. Annotate the file before shutdown.",
        "Well played. Meridian's analysts will find this engagement instructive."
      ],
      "again": "Your {beat} maneuver worked once; we have written a direct counter into this engagement.",
      "remember": "We still track the exact opening you exploited with {beat}."
    },
    "adapt": {
      "shields": "Deflector reinforcement active. Your lance harmonics have been mapped.",
      "pd": "Expanded picket screens deployed. Expect heavy intercept fire on your torpedoes.",
      "armor": "Reinforced bow bulkheads fitted. Impact tactics will yield minimal returns.",
      "evasion": "Attitude-thruster drills complete. Your massed batteries will struggle to hold lock.",
      "aim": "Fire-control telemetry updated. Your evasive burns are now accounted for.",
      "special": "Tightened column synchronization extends linked fire range by one hex."
    },
    "lessons": {
      "flank": "Directorate columns protect their fronts first and rotate slowly. Hit their rear arcs before they tighten formation.",
      "ion": "Their shield emitters are running brittle. Open with ion or lance fire to drop the pool early.",
      "torp": "Their point defense is thin on this deployment. Launch torpedoes once their escorts commit forward.",
      "board": "Their security crews are green. Separate an escort from the column and hit it with a breach team.",
      "brawl": "Their gunners are drilled for long range and lose accuracy up close. Push straight inside two hexes.",
      "anchor": "Their escorts depend heavily on flagship morale. Drive the flagship under 60% hull and the rest will break.",
      "slow": "Worn drive coils limit their repositioning. Cut off their retreat lanes and keep pressure on.",
      "strike": "This commander jumps in fresh reinforcements on round 3. Break the core line before the fleet doubles."
    }
  },
  "corsair": {
    "cunning": {
      "meet": [
        "Nice clean hull plating you brought us! Already picked which escort we're peeling first.",
        "Saw your heat spikes two hexes back. Thanks for flying straight into the rocks!"
      ],
      "win": [
        "Told you! The softest escort comes off first, and the rest fall apart right after!",
        "Clean angle, cheap repairs, and plenty of shiny scrap left drifting!"
      ],
      "flee": [
        "Too much flak for one haul! Burn dark and hit them harder next lane!",
        "Not losing good claws over half a prize! Scatter and come back heavy!"
      ],
      "fall": [
        "Damn it, walked right into your crossfire... fine, keep your plating!",
        "Bad trade... tell the dens somebody finally out-flanked me..."
      ],
      "again": "Tried to pull that {beat} stunt again, huh? Bolted on the counter before we even jumped in!",
      "remember": "Still owe you for that {beat} trick last fight, and I don't forget a bad bruise."
    },
    "greedy": {
      "meet": [
        "Look at the trim on that flagship! Keep the heavy guns off the bow, I want it whole!",
        "Forget the escorts, crews, the richest prize in the sector just jumped right into range!"
      ],
      "win": [
        "Flagship's cracked and the best armor's ours! Strip the rest for fuel money!",
        "Oh, that's a gorgeous trophy! Welders, get out there before anything drifts!"
      ],
      "flee": [
        "Too many guns hugging that flagship! Pull back and hit them when they're stretched thin!",
        "Hold off! I'm not letting that prize get blasted to dust when I can take it clean next time!"
      ],
      "fall": [
        "Got too hungry for the big hull... blast it, my harness is yours...",
        "Walked straight into the escort guns chasing a shiny bow..."
      ],
      "again": "You kept me off your flagship with {beat} before. Won't work now that I've fitted new hardware!",
      "remember": "You saved your flagship with {beat} once, doesn't mean I'm done chasing its plating!"
    },
    "proud": {
      "meet": [
        "I fly point in my own flagship! Come try knocking my bow off the lane!",
        "Best-plated raider in this belt right in front of you! Let's see what your guns do!"
      ],
      "win": [
        "Front plate barely even blistered! Now hand over the wrecks!",
        "Took your best volley square on the chin and kept burning! Strongest keeps it!"
      ],
      "flee": [
        "Forward welds are popping! Break off before they ruin my bow; we'll finish this next jump!",
        "Lucky hits! Pull out and weld thicker steel on, nobody beats me twice!"
      ],
      "fall": [
        "Gah... cracked my own bow open... alright, bolt my plates on your hull, you earned them...",
        "Hard fight... every den in the Ashfall's going to hear about this one..."
      ],
      "again": "Thought {beat} would drop me a second time? Bolted twice the iron onto my bow since!",
      "remember": "Everybody at Rattlehold heard you beat me with {beat}. I'm shutting them up today!"
    },
    "cruel": {
      "meet": [
        "Look at those scorched escorts limping along your flank! We're tearing the weak ones open first!",
        "My thermal scopes love a crippled hull. Let's finish off your wounded before the big ships turn!"
      ],
      "win": [
        "Ripped the crippled ones apart first, and the rest folded right on cue!",
        "Always start with the limping ships; makes the healthy crews panic faster!"
      ],
      "flee": [
        "Taking too many hits! Burn clear, we'll catch your damaged hulls at the next relay!",
        "Not today! Patch your little cripples all you want, I'll tear them open later!"
      ],
      "fall": [
        "Blast it... the wounded ones bit back harder than I called...",
        "No... engines are gone... don't let the engine gangs see me go down like this..."
      ],
      "again": "Still leaning on {beat} to cover your crippled hulls? Doesn't scare my crews anymore!",
      "remember": "I remember how you pulled your wounded out with {beat}. Not letting them slip twice!"
    },
    "adapt": {
      "shields": "Bolted stolen shield cells onto every cruiser. Good luck cutting us up with lances now!",
      "pd": "Chaff launchers welded across the whole formation. Watch your torpedoes pop early!",
      "armor": "Welded heavy ram-plates onto every bow. Go ahead, try colliding with us now!",
      "evasion": "Overbored every thruster nozzle in the pack. Your flank guns are going to shoot empty space!",
      "aim": "Bolted stolen Directorate fire-control onto our turrets. Quit jinking, we've got your burn!",
      "special": "Brought an extra hull from the dens! Let's see how you like worse odds!"
    },
    "lessons": {
      "flank": "Hullbreaker cruisers swing wide to line up rockets and leave thin rear plating open. Punish their sterns on the turn.",
      "ion": "Their jury-rigged shield cells fail fast under ion fire. Strip their thin screens before they close to ramming range.",
      "torp": "Poor point defense leaves them vulnerable to torpedo salvos once they commit to a burn.",
      "board": "Their boarding gangs hit hard, yet their own crews are undisciplined on defense. Counter-breach isolated raiders.",
      "brawl": "This commander favors long-range rocket harassment and aims worse inside two hexes. Close in and brawl.",
      "anchor": "The pack rallies around its warlord's flagship. Knock it below 60% hull and the escorts lose nerve.",
      "slow": "Overworked thrusters limit their chase speed. Kite their turns and hammer their rear arcs.",
      "strike": "When this commander's clock fills, raiders steal 25% of your credits (or a badly crippled ship if you're broke). Kill the commander to get everything back."
    }
  },
  "chorus": {
    "ravenous": {
      "meet": [
        "So many bright reactors clustered together! We accelerate before the heat scatters.",
        "Open the forward pores! Your hulls are close enough to crack right now."
      ],
      "win": [
        "Metal parted, cores absorbed, and the brood already swells heavier.",
        "Rich alloy, hot fuel. We drift onward with full chambers."
      ],
      "flee": [
        "Too much fire on our outer sacs! We pull back into the dust to heal and return.",
        "Our forward broods are thin. We withdraw until new shells harden."
      ],
      "fall": [
        "This cluster ruptures cold, yet our spores already drift toward the next system.",
        "Heat spills into vacuum. Other broods will finish what we started."
      ],
      "again": "You drove us off with {beat} before, and we grew new tissue specifically to blunt it.",
      "remember": "Every surviving spore still carries the burn-pattern of your {beat}."
    },
    "cruel": {
      "meet": [
        "Your damaged hulls leak the brightest thermal plumes. We crack those open first.",
        "One crippled ship slows an entire formation; we start our feeding right there."
      ],
      "win": [
        "Your wounded broke first, and the rest couldn't hold the gap.",
        "Slow, thorough digestion. Every alloy plate stripped clean."
      ],
      "flee": [
        "We've taken too many deep cuts. Your crippled ships can wait until our next pass.",
        "Pull the torn broods back into cold space; we'll finish your stragglers later."
      ],
      "fall": [
        "Our central sac tears open, yet the outer spores still cling to your hulls.",
        "We fall dark here, leaving our acid still working along your bulkheads."
      ],
      "again": "We remember how you shielded your wounded with {beat}. Our new brood cuts right past it.",
      "remember": "Memory kept the exact signature of your {beat} from our last hunt."
    },
    "cunning": {
      "meet": [
        "We read the weak thermal seam along your flank before you even cleared jump.",
        "Your escorts drifted too wide; we slip into the gap and cut."
      ],
      "win": [
        "One exposed flank opened the whole formation for us.",
        "We read your turn before your helms committed, and the brood closed cleanly."
      ],
      "flee": [
        "You sealed the gap faster than we expected. We drift dark and look for a better angle.",
        "Not worth losing a brood-sac here. We wait along the next jump lane."
      ],
      "fall": [
        "We misread your firing arc and paid with the cluster. The next swarm will know better.",
        "A clean trap. Our dying spores broadcast the correction outward."
      ],
      "again": "You caught us with {beat} last time. We've grown around that angle now.",
      "remember": "We still hold the vector you used with {beat} in our collective memory."
    },
    "patient": {
      "meet": [
        "We drifted cold behind these rocks until your drives heated the lane. Now we move.",
        "Advance at your own pace; cold vacuum costs us nothing while your fuel burns."
      ],
      "win": [
        "Waiting in the dark paid off. Your hulls came straight into tendril range.",
        "You rushed into our range while we stayed cold. Now we feed."
      ],
      "flee": [
        "The firing geometry turned unfavorable. We slip back into dormancy until you thin out.",
        "Too much firepower concentrated here. We pull back and wait."
      ],
      "fall": [
        "We waited a beat too long before closing. Other clusters will take up the trail.",
        "This brood cools to ash, while the deeper swarm keeps moving toward Ardent."
      ],
      "again": "After your {beat} broke our ambush before, we adapted our outer sacs to hold longer.",
      "remember": "We waited out the dark remembering how your {beat} cut us."
    },
    "adapt": {
      "shields": "Dense ablative membranes now layer our hides, dispersing focused lance heat.",
      "pd": "Thick spore curtains hang around our broods to detonate incoming torpedoes early.",
      "armor": "Calcified bone-plate now sheaths our forward ribs against ramming bows.",
      "evasion": "Lateral thruster fins have grown larger so we turn clean through your flank fire.",
      "aim": "Thermal sensory pits have widened across our bows, tracking every evasive burn.",
      "special": "Deep regrowth surges through every hull: +3 extra hull regenerated each round."
    },
    "lessons": {
      "flank": "Chorus hulls turn aggressively to feed and expose thinner aft chitin. Hammer their rear arcs.",
      "ion": "Chorus bio-hulls carry no shields at all, so ion bonus damage is wasted. Bring high-damage armor-piercing or incendiary fire instead.",
      "torp": "Light spore screens leave clear lanes for torpedo salvos when their hulls bunch together.",
      "board": "Their interior defense broods are thin on this strain. Counter-breach isolated hulls if you have strong boarding crews.",
      "brawl": "This cluster prefers spitting from medium range and aims poorly nose-to-nose. Close in and overwhelm them.",
      "anchor": "Their escorts fracture if the primary brood-ship drops below 60% hull. Focus the flagship.",
      "slow": "Sluggish propulsion sacs keep them from chasing fast ships. Kite their acid range and pick off stragglers.",
      "strike": "Every ship you lose anywhere in the run makes this Chorus fleet 4% tougher (up to 32%). Fight clean and protect your escorts."
    }
  },
  "ithar": {
    "cunning": {
      "meet": [
        "The glare off this dust field already shows the thin seam along your flank. Let's begin.",
        "One careless turn opens an entire formation, and our mirrors are already angled for it."
      ],
      "win": [
        "Exactly where the refraction model predicted your shield would fold. Clean work.",
        "A precise cut along an unguarded flank ends a battle before it turns ugly."
      ],
      "flee": [
        "Outer mirror compromised. Withdraw along the glare line and reset our approach.",
        "This angle no longer favors us. We'll resume the duel on cleaner terms."
      ],
      "fall": [
        "Clean shot through the primary prism. You read the angle better than I expected.",
        "The lens fractures. Remember what it cost to break a craft three centuries old."
      ],
      "again": "You caught our blind arc with {beat} before; our mirrors are turned to cover it now.",
      "remember": "Every captain in my formation still studies how you broke us with {beat}."
    },
    "proud": {
      "meet": [
        "You are challenging a First Mirror of the Glasswrights. Hold steady and let's test your craft.",
        "This engagement was framed long before your fleet exited jump. Show us what you have."
      ],
      "win": [
        "Our alignment held without a tremor while your line fell apart.",
        "Clean beams, clean arcs, zero wasted shots. That's how fleet combat should look."
      ],
      "flee": [
        "A hairline fracture on the primary hull; we withdraw to anneal it and return sharper.",
        "Not risking an ancestral hull on a sloppy exchange. We'll finish this later."
      ],
      "fall": [
        "Impossible... the primary mirror's gone... let the surviving cutters jump clear.",
        "A rare failure of focus. The Lattice yards will remember this engagement."
      ],
      "again": "You relied on {beat} to force our retreat last time. Our shields are re-tuned to answer it.",
      "remember": "I haven't forgotten the damage your {beat} inflicted on my flagship."
    },
    "patient": {
      "meet": [
        "Keep your distance if you prefer; our primary lances hold focus much farther than your batteries.",
        "Cross open space whenever you're ready. Our alignment has already settled."
      ],
      "win": [
        "Waiting for you to overextend worked exactly as planned.",
        "You rushed into our focal band and paid with your shields."
      ],
      "flee": [
        "Shield capacitors dropping below safe margins. Disengage and re-align elsewhere.",
        "A careful commander knows when to preserve fragile hulls for the next hour."
      ],
      "fall": [
        "We held position one round too long. Let the remaining ships clear the debris.",
        "Focus broken. Three centuries of patience ended in a single volley."
      ],
      "again": "Your earlier push with {beat} forced us to adjust our stand-off range. Come try it again.",
      "remember": "We've spent every jump since calibrating against your {beat}."
    },
    "cruel": {
      "meet": [
        "Your damaged hulls glow brightest on our optical plot, so we'll dismantle those first.",
        "Once a hull's shields fail, the rest comes apart effortlessly. Watch closely."
      ],
      "win": [
        "Your weakened escorts went dark first, and your command ship couldn't cover them.",
        "Surgical dismantling from the softest hull upward. Clean and quiet."
      ],
      "flee": [
        "Not clean enough; we break off before your return fire cracks an irreplaceable frame.",
        "Withdraw and hone the arrays. Your damaged hulls won't stay patched forever."
      ],
      "fall": [
        "Miscalculated your armor depth... our primary prism's shattering!",
        "You held together under focused fire better than any metal fleet had a right to."
      ],
      "again": "Still counting on {beat} to protect your wounded hulls? We've adjusted our beams to bypass it.",
      "remember": "We still have the optical replay of how you used {beat} against us."
    },
    "adapt": {
      "shields": "Re-tuned prism matrices now split incoming lance frequencies across the shield pool.",
      "pd": "Mirror veils deployed along every hull to scatter torpedo guidance locks.",
      "armor": "Reinforced waveguide spines fitted to survive close-in impact blows.",
      "evasion": "Recalibrated crystal vanes shift our hulls clean out of your flank battery arcs.",
      "aim": "Interferometer lenses locked onto your drive signature; evasive burns won't hide you now.",
      "special": "Deeper optical veil active: every Glasswright hull is 6 harder to hit."
    },
    "lessons": {
      "flank": "Glasswright duelists rely on speed and expose their rear arcs during sharp turns. Punish them mid-pivot.",
      "ion": "Their massive shields are their entire lifeline, and brittle emitters collapse fast under ion fire.",
      "torp": "Light point defense lets fast torpedo salvos land if you force them to turn across your nose.",
      "board": "Fragile crystal hulls carry small crews. Breach isolated escorts once their shields drop.",
      "brawl": "Built for stand-off lances, they lose accuracy in a tight brawl. Close inside two hexes.",
      "anchor": "Drop the flagship's shields and push it under 60% hull to force an early withdrawal.",
      "slow": "Damaged drives rob them of their vane evasion bonus. Pin their movement and focus fire.",
      "strike": "This duelist runs a small elite fleet and retreats once its flagship loses shields and drops under 60% hull, returning sharper each time."
    }
  },
  "deathless": {
    "patient": {
      "meet": [
        "Rushing won't save your hulls. Every century we wait, your kind forgets another mistake we still remember.",
        "Take as many turns as you need to close. After a thousand years in the dark, a few extra minutes mean nothing."
      ],
      "win": [
        "Your fleet failed right where our earlier engagement models predicted.",
        "Steady arcs, unbroken hulls. Patience always outlasts haste."
      ],
      "flee": [],
      "fall": [
        "This chassis fails, yet the backup stream is already spinning up a fresh frame.",
        "Break the metal all you like; I will wake again before your welders cool."
      ],
      "fall_final": [
        "Even at Ardent's rim, one restoration remains. Prepare for a second fight.",
        "The Archive authorizes one final chassis before cutoff. Let us finish this properly."
      ],
      "again": "My restored mind reviewed every volley of your {beat} before this chassis even left the rack.",
      "remember": "Restoration strips minor noise away, yet it never erases a defeat to {beat}."
    },
    "proud": {
      "meet": [
        "My flagship leads the approach, just as it did when Ardent still burned overhead.",
        "I never hide behind escorts; that held on my first chassis, and it holds on this one."
      ],
      "win": [
        "Our forward plates held without yielding a hex, as they have for ten centuries.",
        "You tested an Archive flagship head-on and learned why our frames endured."
      ],
      "flee": [],
      "fall": [
        "My bow breaks, yet the mind inside walks straight into the next frame.",
        "A costly breach, nothing more. The Archive will have me back on your lane shortly."
      ],
      "fall_final": [
        "Even here at the rim, I rise once more, flagship first, to settle this.",
        "One last chassis left in the rack. Come finish what you started!"
      ],
      "again": "The frame that returns today was armored specifically after watching your {beat} crack the last one.",
      "remember": "Pride survives restoration intact, and so does the sting of your {beat}."
    },
    "cruel": {
      "meet": [
        "We'll burn your crippled ships down first so the healthy crews watch what's coming.",
        "Wounded hulls lose armor fast; our corona arcs will clear them off the plot before we touch your flagship."
      ],
      "win": [
        "Your damaged hulls collapsed first, and the rest couldn't hold without them.",
        "Clean dismantling. We'll archive your surviving bridge logs as a keepsake."
      ],
      "flee": [],
      "fall": [
        "An interruption only. My next chassis will pick up right where this volley ended.",
        "Enjoy the breathing room while my replacement frame spins up."
      ],
      "fall_final": [
        "I rise one final time to put your fleet in cold storage instead.",
        "One last chassis, one final pass at Ardent's rim. Make your shots count."
      ],
      "again": "You saved your crippled ships with {beat} last time. My arcs are tuned to cut through it now.",
      "remember": "Every scar from your {beat} sits fresh in my restored combat memory."
    },
    "methodical": {
      "meet": [
        "Every maneuver your fleet can execute has been tested against older enemies than you.",
        "Our advance is measured and our firing lanes are set. Proceed."
      ],
      "win": [
        "Your hulls folded cleanly inside our firing geometry.",
        "Advance, fire, verify cutoff. Another obstruction cleared from the siphon lane."
      ],
      "flee": [],
      "fall": [
        "Frame integrity lost. The next hull advances along the exact same vector.",
        "This chassis stops here; the replacement is already downloading our telemetry."
      ],
      "fall_final": [
        "One reserve chassis remains active. Executing final engagement sequence.",
        "Final restoration online. After this fight, one of us stays dark permanently."
      ],
      "again": "My restored telemetry patched the exact gap your {beat} exploited last time.",
      "remember": "Hulls wear out, yet the Archive retains every detail of your {beat}."
    },
    "adapt": {
      "shields": "Corona-ward layers installed over our hull bands to absorb your focused beams.",
      "pd": "Null spires calibrated from archived intercepts; your torpedoes will detonate short.",
      "armor": "Heavier sunshade plating bolted forward. Ramming this bow will only wreck yours.",
      "evasion": "Fold-drive micro-skips retimed so your flank volleys strike empty vacuum.",
      "aim": "Long-memory optics aligned to your thruster curve; evasive turns won't break lock.",
      "special": "Deep backup relays online: one additional fallen Eclipse ship can reassemble."
    },
    "lessons": {
      "flank": "Heavy Eclipse cruisers turn slowly and leave their rear bands thin. Fold or burn behind them on the turn.",
      "ion": "Eclipse frames carry no shields at all, so ion bonus damage is wasted. Bring high-pierce hull weapons and focus down wrecks.",
      "torp": "Limited null-spire coverage gives torpedoes clean approaches if you overwhelm one flank.",
      "board": "Their boarding defense is thin on freshly restored frames. Breach them right after they reassemble.",
      "brawl": "Built around slow corona volleys at mid-range, they struggle when surrounded inside two hexes.",
      "anchor": "Focus the flagship down below 60% hull to fracture escort morale.",
      "slow": "Heavy armor slows their cruise burn. Control the lanes and focus one hull at a time so swarms can't rebuild all of them.",
      "strike": "This commander's clock advances slowly, never retreats, rises once in sector 3, and drains 6% hull across your fleet when the hunt triggers."
    }
  },
  "voidsworn": {
    "zealous": {
      "meet": [
        "Forty worlds are freezing behind us, and you're standing in our jump lane! Open fire!",
        "We swore back in Vesper orbit we'd burn straight through anyone blocking the sun! Come on!"
      ],
      "win": [
        "Lane's clear! Chalk the victory on the bulkhead and check our fuel!",
        "Tried to stop a Crusade line and paid for it! Keep moving sunward!"
      ],
      "flee": [],
      "fall": [
        "Flagship's going up... don't stop for us, keep pushing toward the siphon!",
        "Bulkheads are gone! Chalk my name under the others and finish the job!"
      ],
      "again": "You beat us with {beat} last time, alright, so we're hitting twice as hard today!",
      "remember": "My gunners still have your {beat} chalked beside the loading rails. Nobody forgot."
    },
    "proud": {
      "meet": [
        "This flagship has led the dawn watch through three sectors! Answer our challenge or break!",
        "I fly right up front where every captain can see my radiators. Come test our iron!"
      ],
      "win": [
        "Our front line held every shot you had and broke your fleet clean in half!",
        "Looked straight down our flank guns and blinked first! Keep pushing!"
      ],
      "flee": [],
      "fall": [
        "Front hull's buckling... close the gap over us and don't let them pass!",
        "Damn fine shooting... the Crusade doesn't stop for one broken flagship!"
      ],
      "again": "Thought {beat} would fold my front line twice? We braced every bulkhead for it!",
      "remember": "I still carry the dents your {beat} put on my bow, and I mean to return them."
    },
    "cruel": {
      "meet": [
        "Look at those leaking escorts on your flank. We're burning the weak ones down first!",
        "Tag their most damaged hull and pour every flank gun into it until it cracks!"
      ],
      "win": [
        "Took your crippled hulls off the plot first and watched the rest fold!",
        "Every scorched hull goes on the roll. Keep the burners hot!"
      ],
      "flee": [],
      "fall": [
        "Reactor's failing... guess your wounded ones had more fight left than I figured...",
        "Bad way to go out... tell Vesper the cold won't be kinder to them either..."
      ],
      "again": "You kept your damaged hulls alive with {beat} before. We're cutting straight through that trick now!",
      "remember": "Still remember how you used {beat} to save those crippled escorts."
    },
    "methodical": {
      "meet": [
        "Screens at full, guns laid by hand, intervals locked. Advance on my mark.",
        "Every firing lane is measured and every crew knows their station. Engage."
      ],
      "win": [
        "Clean volleys, steady screens, minimal hull losses. That's how you cross three sectors.",
        "Formation held from start to finish. Patch the burns and plot the next jump."
      ],
      "flee": [],
      "fall": [
        "Command hull's failing. Transfer the flag to the senior cruiser and keep the line closed.",
        "One gap in the line, not the whole Crusade. Hold steady and finish the fight."
      ],
      "again": "We drilled against your {beat} tactics every watch since our last fight.",
      "remember": "My tactical plot still carries the firing angles from your {beat}."
    },
    "adapt": {
      "shields": "Reinforced screen drills active. Your focused beams won't crack us easily now.",
      "pd": "Spark flak crews doubled across the line. Expect your torpedoes to detonate early.",
      "armor": "Riveted extra black-iron plate onto our bows. Try ramming that.",
      "evasion": "Running lighter thruster trims across the line so your flank volleys miss wide.",
      "aim": "Hand-laid optical sights zeroed in on your burn profile. Quit dodging, we've got you.",
      "special": "Crews running hot on battle rations and grit: +8% damage across all guns."
    },
    "lessons": {
      "flank": "Crusade cruisers commit hard to forward charges and leave thin rear armor exposed. Swing behind them.",
      "ion": "Their front screens are strong, yet brittle emitters collapse fast under sustained ion fire.",
      "torp": "Sparse point defense leaves clear torpedo lanes once their escorts commit to the flank.",
      "board": "Green breach defense crews struggle if you isolate a cruiser away from its escorts.",
      "brawl": "Their hand-laid guns lose tracking speed inside two hexes. Close in and force a knife-fight.",
      "anchor": "Their escorts fight around the flagship's example. Drive it below 60% hull to break their nerve.",
      "slow": "Heavy iron hulls burn sluggishly on worn drives. Cut off their pivots and pound their sterns.",
      "strike": "This commander never flees and challenges your flagship to single combat (+20% damage both ways). Screen your flagship or turn the duel back on them."
    }
  }
};
// ---------- B4 faction campaign verbs: one small action per faction, once per sector, from the map ----------
// cost: cred (credits), mod (a refit from the hold), xp (flagship captain experience). free: an earlier event flag that waives the cost.
// next: an effect on your next battle (battle.js applyVerb). Each use writes the flag verb_<id>.
const FAC_VERBS={
  voidsworn:{id:'vigil',n:'Keep the dawn watch',d:'Next battle, ships next to an ally take 15% less hull damage.',cost:{cred:40},free:'shrine',freeK:['offer','chalk','relic'],freeD:'free after an offering at a wall of names',next:1},
  hegemony:{id:'drill',n:'Fleet drill',d:'Next battle, synchronized fire reaches 4 hexes from the flagship and its bonus rises to +20%.',cost:{cred:35},free:'defector',freeK:['question','enlist'],freeD:'free once a defector has briefed you',next:1},
  corsair:{id:'shake',n:'Shake down the lanes',d:'Gain 30 credits, plus 10 for every greedy choice this run. The Nemesis clock moves on.',cost:{},next:0},
  chorus:{id:'gorge',n:'Gorge',d:'Consume a refit from the hold: every ship regrows 20% of its hull (30% if the fleet has fed at a spawning field).',cost:{mod:1},next:0},
  ithar:{id:'attune',n:'Prism attunement',d:'Next battle, every shield is 25% stronger.',cost:{xp:25},free:'lament',freeK:['join'],freeD:'free once you have answered the tone',next:1},
  deathless:{id:'waken',n:'Back up the fleet',d:'Next battle, Archive restore brings back one more ship.',cost:{cred:45},free:'tombhome',freeK:['wake'],freeD:'free once a dormant yard has woken a hull for you',next:1}};
// ---------- B4 wing doctrines: a stance per carrier, one free switch per round; up to three veteran perks per carrier's wings ----------
const WING_STANCES={
  strike:{n:'Strike',d:'Default. Wings hit the best target in reach, ships first for bombers.'},
  screen:{n:'Screen',d:'Wings stay within 3 hexes of their carrier, prioritize enemy craft, and intercept torpedoes aimed within 2 hexes.'},
  hunt:{n:'Hunt',d:'Wings range 4 hexes further and go for crippled ships (+20% damage below half hull), but fly exposed (10 easier to hit).'}};
const WING_PERKS={
  aces:{n:'Aces',d:'Wings aim 10 better.'},
  armored:{n:'Armored cockpits',d:'Wings have 25% more hull.'},
  reserve:{n:'Deep reserves',d:'The carrier holds one more spare wing.'},
  killers:{n:'Ship killers',d:'Wings deal 15% more damage to ships.'},
  pickets:{n:'Picket pilots',d:'Screening wings shoot down torpedoes more often.'},
  jinkers:{n:'Jinkers',d:'Wings are 8 harder to hit.'}};
const WING_XP=[3,8,15]; // wing kills a carrier's wings need for their first, second and third perk
// ---------- captains and ship names by faction ----------
const CAPTAINS={
  voidsworn:{ranks:RANKS,first:CAP_FIRST,last:CAP_LAST},
  hegemony:{ranks:['Lieutenant','Commander','Captain','Commodore','Rear admiral'],first:['Konrad','Marit','Joost','Mara','Anders','Rhea','Viktor','Lena','Aldric','Petra','Gerold','Sanne','Halvar','Ines','Ruprecht','Katrin'],last:['Reiter','Kassel','Brandt','Vollmer','Hollis','Strand','Varga','Kessler','Drexel','Moran','Falk','Lindqvist','Achterberg','Roth','Vandermeer','Haldane']},
  corsair:{ranks:['Claw','Fang','Howler','Ripper','Warlord'],first:['Krogg','Gash','Rorr','Brak','Hulg','Drask','Olk','Thrag','Grisk','Vorg','Gnarl','Karsk','Bruk','Ulm','Rask','Tusk'],last:['the Gutter','Rattlebone','Two-Claws','Scrapback','Longjaw','Gristle','Chainback','Ashmane','Red-Jaw','Torn-Ear','Rusthide','the Quiet','Bent-Tooth','Boltneck','Plateback','the Tracker']},
  chorus:{ranks:['Spawn-mind','Node','Throat','Elder throat','Great throat'],names:['Seventh Mouth','Hollow Gut','Deep Murmur','Thrumming Coil','Pale Cyst','Wet Whisper','Ninth Tooth','Gnawing Tide','Brine Mouth','Moult','Ashk-of-Many','Sallow Rasp','Undertow','Last Spore','Coiled Gullet','Lantern Gut']},
  ithar:{ranks:['Glimmer','Glint','Facet','Mirror','Lens-keeper'],first:['Oskel','Ilvy','Teo','Kesh','Lun','Pell','Ressa','Taro','Imre','Nell','Tobin','Avin','Sefa','Davin','Orra','Fen'],last:['of the Second Lens','of the Bright Collector','of the Long Beamline','of the Quiet Mirror','of the Ninth Facet','of the Cold Lens','of the Far Collector','of the First Prism','of the Split Beam','of the Slow Focus','of the Silver Array','of the Deep Mirror']},
  deathless:{ranks:['Shade','Gloam','Umbra','Midnight','Nadir'],names:['Quorel','Benth','Ivess','Toran','Odrun','Desmae','Selith','Vantor','Imra','Caddex','Rhosse','Altheve','Keshet','Pallun'],epithets:['of the Second Frame','of the Fifth Frame','the Thrice-Copied','of the Old Copy','the Seventh-Housed','the Once-Restored','of the Clean Copy','of the Twelfth Frame','the Never-Dark','of the Last Backup']}};
const MORE_SHIP_NAMES={
  hegemony:['MDV Steadfast','MDV Arbiter','MDV Optimal','MDV Resolute','MDV Consensus','MDV Ascendancy','MDV Projection','MDV Punctual','MDV Paragon','MDV Unflinching'],
  corsair:['No Quarter','Gut Hook','Chain of Teeth','Forty Captains','Second Death','Scrapjaw','Cold Trail','Rattletrap','Long Howl','Last Trail'],
  chorus:['Shrieking Coil','Brood Vessel Om','Sour Gut','Spine Gullet','Node Vesk','Crawling Maw','Wet Mouth','Gnawing Cyst','Tide of Teeth','Hollowgut'],
  ithar:['Last Reflection','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Held Spectrum','Farlight','Moonsorrow','What We Built'],
  deathless:['Remembered Noon','Warmth Recalled','Silent Procession','Long Night','The Unsleeping','Shade of Noon','Ninth Winter','Sunless Hours','Cold Archive','Noon Kept']};
// every faction's hulls get a shipyard price, refit slots and their boss flag (only the Voidsworn set had them;
// other factions showed 'Buy for NaN', had no refit slots, and the Voidsworn dreadnought wasn't marked as a boss)
// B3 price ladder (Oct 26, Claude's numbers, vetoable): each faction prices its own classes. Hegemony is the 1.0 baseline; Chorus swarms cheap and
// prices its big hulls up; Corsairs go cheap small and dear heavy; Ithar tax everything (elite glass); Deathless pay most for few, durable hulls;
// Sunward carriers have a 10% premium before rounding. Shipyard prices, ransom, strip and scrap values all follow h.cost.
// Enemy fleets are still built by command points, so battle difficulty does not move with this table.
const FAC_PRICE={hegemony:{},voidsworn:{Carrier:1.1},corsair:{Frigate:.8,Destroyer:.85,Cruiser:1.05,Carrier:1.15},chorus:{Frigate:.65,Destroyer:.75,Cruiser:1,Carrier:1.2},
  ithar:{Frigate:1.3,Destroyer:1.3,Cruiser:1.15,Carrier:1.1},deathless:{Frigate:1.55,Destroyer:1.6,Cruiser:1.65,Battleship:1.6}}; // R1 (FS-2): a future Eclipse battleship never prices below the Eclipse cruiser
// B3 roster gates and prohibitions: what each faction cannot field or do. Checked by canOrder (brace), the prize screen and towing (weapon kinds).
const FAC_GATES={corsair:{noKind:['lance'],d:'Hullbreakers field no lance weapons (no long-range beams): they win up close.'},ithar:{noBrace:1,d:'Glasswright hulls cannot Brace for impact: they live by shields and speed.'}};
function factionGate(fac,tpl){ const G=FAC_GATES[fac], h=HULLS[tpl]; if(!G||!h) return null; if(G.noKind&&h.w.some(([id])=>W[id]&&G.noKind.includes(W[id].k))) return G.d; return null; }
// R78 Q9 (issue 41): from run 3 the Crusade's Cinder Line yards sell captured Hegemony and Eclipse hulls, links ripped
// out, at Crusade prices. cinderOpen() gates the yard stock; a 'ripped' ship loses the Hegemony synchronized fire and
// the Eclipse Archive restore in battle (both key off the hull faction, battle.js). Strip and ransom on the prize
// screen are unchanged: this adds a way to keep an enemy hull, it does not touch the keep/strip/ransom choice.
const CINDER_PRIZES=['h_picket','h_interdictor','h_vanguard','h_dominion','d_scythe','d_jackal','d_harvester'];
const CINDER_FIRST_RUN=3;
function cinderOpen(){ return typeof RUN!=='undefined'&&!!RUN&&RUN.fac==='voidsworn'&&typeof META!=='undefined'&&!!META&&META.stats&&(META.stats.runs||0)>=CINDER_FIRST_RUN; }
for(const [fid,F] of Object.entries(FACTIONS)){ if(F.boss&&HULLS[F.boss]) HULLS[F.boss].boss=true;
  for(const id of F.roster){ const h=HULLS[id]; if(!h||h.sq) continue; const cp=h.cp||1;
    if(h.cost==null) h.cost=Math.round((60*cp+10)/5)*5; if(h.slots==null) h.slots=cp<=2?1:cp<=4?2:3;
    const pm=(FAC_PRICE[fid]||{})[h.cls]||1; if(pm!==1&&h.cost0==null){ h.cost0=h.cost; h.cost=Math.round(h.cost*pm/5)*5; } } }
// Issue 1354 (Nov 20): Navy hulls 20% and Crusade hulls 5% cheaper in the shop, to lift both back above 30% at Veteran after the
// Glasswright hull rise (PR 1353). Shop price only: h.val keeps the ladder price, so ransom, strip, scrap and Cinder Line
// prices (shipValue, capturedHullPrice) and every enemy ship are unchanged.
const SHOP_DISCOUNT={hegemony:.8,voidsworn:.95};
// issue 1384: the Crusade's Daybreak dreadnought (ascendant) sits on FACTIONS.voidsworn.boss, not the roster, but its yards sell it
for(const [fid,d] of Object.entries(SHOP_DISCOUNT)) for(const id of [...FACTIONS[fid].roster,FACTIONS[fid].boss]){ const h=HULLS[id]; if(!h||h.sq||h.val!=null||!Number.isFinite(h.cost)) continue;
  h.val=h.cost; h.cost=Math.round(h.cost*d/5)*5; }

// ---------- progression between runs ----------
// Hull variants: bought once with renown, then sold in your faction's shipyards beside the standard hull
const HULL_VARIANTS={
  vs_harrow_t:{base:'harrow',n:'Harrow torpedo-destroyer',d:'Twin prow torpedo tubes and no turret: a one-shot assassin.',w:[['torp','F'],['torp','F']],cost:20},
  vs_penitent_g:{base:'penitent',n:'Vigil gun-cruiser',d:'Swaps the prow lance for a dorsal sear battery: guns in every arc.',w:[['battery','P'],['battery','S'],['battery','T']],cost:25},
  h_picket_i:{base:'h_picket',n:'Picket interceptor',d:'Turret laser and +6 evasion: screens wherever it points.',w:[['laser','T'],['flak','T']],mod:{ev:24},cost:15},
  h_vanguard_g:{base:'h_vanguard',n:'Vector gunship',d:'No hangar or automatic wings; a third plasma battery turret instead.',w:[['turbo','T'],['turbo','T'],['turbo','T'],['ion','F']],mod:{ab:null,hangar:0},cost:25},
  c_reaver_t:{base:'c_reaver',n:'Turret gutship',d:'Scatter cannons on a turret instead of one flank mount.',w:[['torp','F'],['scatter','T']],cost:15},
  c_hulk_g:{base:'c_hulk',n:'Gun-hulk',d:'No hangar or automatic wings; scatter flank mounts, a turret and 20 more hull.',w:[['scatter','P'],['scatter','S'],['turret','T']],mod:{ab:null,hangar:0,hp:190},cost:25},
  b_spitter_s:{base:'b_spitter',n:'Spitter stinger',d:'Trades a prow gun for boarding tendrils: brutal up close.',w:[['bioplasma','T'],['tendril','T']],cost:15},
  b_razor_s:{base:'b_razor',n:'Bladeback stalker',d:'Trades its spine volley for a second tendril cluster: +1 speed and +8 evasion.',w:[['tendril','T'],['tendril','T']],mod:{sp:5,ev:12},cost:25},
  i_wisp_l:{base:'i_wisp',n:'Sliver lancer',d:'A prism lance in place of the prism shards.',w:[['pulsar','F']],cost:15},
  i_song_w:{base:'i_song',n:'Warded prism',d:'One prism lance on a turret in place of the two prow lances, and 30% more shields.',w:[['pulsar','T'],['turret','T']],mod:{sh:34},cost:25},
  d_scythe_s:{base:'d_scythe',n:'Mote sentinel',d:'Adds a null spire: shoots down squadrons and boarders’ craft.',w:[['gauss','T'],['gsentry','T']],cost:15},
  d_harvester_t:{base:'d_harvester',n:'Turreted zenith',d:'Its corona arc sits on a turret, so it no longer has to turn to fire, but it carries one null cannon instead of two.',w:[['gauss','T'],['doom','T'],['gsentry','T']],cost:30}};
// R41 arc unlocks (story helper draft godot/story/unlocks.md, Oct 26): one sidegrade per faction, earned by finishing that faction's story arc
// (its Nemesis's last fight), never sold for renown (cost 0, arc field). Numbers sim-checked against the base hulls in stream B.
Object.assign(HULL_VARIANTS,{
  vs_penitent_l:{base:'penitent',arc:'voidsworn',n:'Vigil lance-cruiser',d:'Two fore lances and a dorsal battery turret instead of flank batteries: its heavy punch points one way.',w:[['lance','F'],['lance','F'],['battery','T']],cost:0},
  h_interdictor_e:{base:'h_interdictor',arc:'hegemony',n:'Cordon column escort',d:'Adds a flak turret, paid for with a lighter hull (60) and one hex of speed.',w:[['ion','F'],['turbo','T'],['flak','T']],mod:{hp:60,sp:3},cost:0},
  c_marauder_g:{base:'c_marauder',arc:'corsair',n:'Trophy wrecker',d:'A second prow torpedo instead of flak, and one hex slower.',w:[['scatter','P'],['scatter','S'],['torp','F'],['torp','F']],mod:{sp:3},cost:0},
  b_razor_e:{base:'b_razor',arc:'chorus',n:'Star-gorged bladeback',d:'Swaps its tendrils for a second turret spine volley; regrows 9 hull per round (3 more than the base hull), 1 hex slower.',w:[['bioplasma','T'],['bioplasma','F']],mod:{regen:9,sp:3},cost:0},
  i_carrier_a:{base:'i_carrier',arc:'ithar',n:'Ringing aperture',d:'A third wing, paid for with lighter shields (22) and one hex of speed.',w:[['pulsar','F'],['turret','T']],mod:{hangar:3,sh:22,sp:3},cost:0},
  d_jackal_h:{base:'d_jackal',arc:'deathless',n:'Archive guard flare',d:'Keeps the forward null lance and adds a null spire turret that shoots down squadrons on every side, paid for with 15 less hull (85).',w:[['nlance','F'],['gsentry','T']],mod:{hp:85},cost:0}});
const ARC_VARIANT=Object.fromEntries(Object.entries(HULL_VARIANTS).filter(([,v])=>v.arc).map(([id,v])=>[v.arc,id]));
// Customization reserve (Oct 26, customization brainstorm section 6; schema only, nothing reads these for rules yet).
// Variant rows: base (parent hull id: the variant inherits its model, sections and sounds), cost (renown; 0 with arc = earned by finishing that story arc), arc.
// Ship instance fit (reserved field on a RUN.fleet ship, absent until used): ship.fit = {pod: weapon id or null, module: module id or null, trim: trim id or null}.
// A ship's weapons and numbers still come only from HULLS[ship.tpl] through derive(); a future fit resolver applies ship.fit on top, flagship only.
const FIT_SLOTS={pod:'one swappable weapon pod (flagship only; its spinal weapon stays)',module:'one module slot (flagship only)',trim:'one of four zero-sum section trims (flagship only)'};
for(const [id,v] of Object.entries(HULL_VARIANTS)){ const b=HULLS[v.base]; HULLS[id]=Object.assign({},b,{n:v.n,w:v.w,variant:id,base:v.base},v.mod||{}); if(HULLS[id].ab===null) delete HULLS[id].ab; }
// Faction weapon pool tags: every weapon id a faction's own hulls carry (variants included), so a pod pool can be filtered by faction from day one.
const FAC_WPOOL=Object.fromEntries(Object.keys(FACTIONS).map(f=>[f,[...new Set(Object.values(HULLS).filter(h=>h.fac===f).flatMap(h=>(h.w||[]).map(x=>x[0])))].sort()]));
// Admiral mastery: every admiral levels up as you fly with them, in any faction
const MASTERY_XP=[0,6,16,30,50];
const MASTERY_PERKS=[
  null,
  {n:'Alternate fleet',d:'Choose a second starting fleet for this admiral.'},
  {n:'Wider counsel',d:'Your flagship is offered four refits instead of three.'},
  {n:'Second Command',d:'Choose between two Commands before the run.'},
  {n:'Flag captain',d:'Your flagship starts at Mk II, its captain two ranks up with a perk.'}];
// Glasswrights test slice. Content: skill_tree_phase1_assembled_2026_10_29.md.
const LINEAGE_XP=[0,6,16,30,50,75,110,160,230];
// Job 7 step 14: capstone mastery. A chosen level 8 evolution keeps growing at 320, 440 and 600 XP.
// The effect texts are placeholders: the tree pack carries no capstone mastery text yet.
const CAPSTONE_MASTERY_XP=[320,440,600];
const CAPSTONE_MASTERY_PERKS=[
  {n:'Capstone mastery I',d:'Placeholder: the mastery effect for this evolution is not written yet.'},
  {n:'Capstone mastery II',d:'Placeholder: the mastery effect for this evolution is not written yet.'},
  {n:'Capstone mastery III',d:'Placeholder: the mastery effect for this evolution is not written yet.'}];
const LINEAGE_TREES={
  "aelith": {
    "branches": {
      "A": {
        "n": "Recorded Flight",
        "tiers": [
          [
            {
              "n": "Flight Paths in the Glass",
              "d": "an extra wing that strikes the target its carrier last fired at gains +15% damage."
            },
            {
              "n": "Cast Twice in Light",
              "d": "one carrier's extra wing strikes, is recorded, and strikes the same target again at half damage if that target has not moved."
            }
          ],
          [
            {
              "n": "The Replay Corrects",
              "d": "an extra wing's strike again against a target already hit this round gains +10% damage."
            },
            {
              "n": "Starlings in Formation",
              "d": "extra wings that strike the same target as another extra wing gain +10 aim."
            }
          ],
          [
            {
              "n": "Flaw in the Flight Removed",
              "d": "extra wings ignore the point defense of one chosen enemy ship for this Command."
            },
            {
              "n": "Every Lens Aloft",
              "d": "a carrier that held still this round launches one additional extra wing, and that wing strikes this round at the full strike again bonus."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Deployment Read from the Shards",
              "d": "after seeing the enemy deployment, reposition one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Casting Corrected Before Battle",
              "d": "after deployment, swap the positions of any two of your ships."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Lens",
              "d": "once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim."
            },
            {
              "n": "First Light Recorded",
              "d": "the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Flight Cast Perfectly",
        "d": "during Starling flight, wings striking the same target ignore its flak, its shields stop only the first wing hit, and wing hits after the first deal +25% damage to its most damaged section."
      },
      {
        "n": "The Forge Casts Ahead",
        "d": "after the Command, one extra wing per carrier strikes the same target again at the start of next round, at +15% damage."
      }
    ]
  },
  "vaelen": {
    "branches": {
      "A": {
        "n": "Long Focus",
        "tiers": [
          [
            {
              "n": "Focus Drawn Long",
              "d": "volley shots at targets beyond half the firing ship's range gain +20% damage."
            },
            {
              "n": "One Lens, One Target",
              "d": "choose one of your ships: it fires its whole volley at a single target you name, and its shots gain +25% damage against that target."
            }
          ],
          [
            {
              "n": "Light Arrives Together",
              "d": "during the volley, a shot at a target already hit by one of your other ships this round gains +15% damage."
            },
            {
              "n": "The Recorded Angle",
              "d": "before the volley, each ship may turn once to bring its best lance to bear."
            }
          ],
          [
            {
              "n": "Burning the Flaw Out",
              "d": "volley hits on one target stack; the third and later hits on that target ignore its shields."
            },
            {
              "n": "Long Light",
              "d": "lance weapons in the volley gain +2 hexes of range for any ship that has not turned this round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Deployment Read from the Shards",
              "d": "after seeing the enemy deployment, reposition one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Casting Corrected Before Battle",
              "d": "after deployment, swap the positions of any two of your ships."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Lens",
              "d": "once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim."
            },
            {
              "n": "First Light Recorded",
              "d": "the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Sun Through One Lens",
        "d": "Burning glass may concentrate every ship's volley on one target; its shields stop only the first hit, and no shot suffers range falloff."
      },
      {
        "n": "The Flaw, Corrected Forever",
        "d": "after Burning glass, your lances keep +15% damage against the target the volley hit most, for the rest of the battle."
      }
    ]
  },
  "thorne": {
    "branches": {
      "A": {
        "n": "Refraction",
        "tiers": [
          [
            {
              "n": "Two Images Appear",
              "d": "during the scatter, the first enemy shot at each of your ships each round is aimed at a false image and loses a further 20 accuracy."
            },
            {
              "n": "Angles Recorded",
              "d": "a ship that ends its scatter movement facing a different direction than it started gains +10 evasion until next round."
            }
          ],
          [
            {
              "n": "The Mirror Steps Aside",
              "d": "during the scatter, a ship may dive under one enemy-held hex at no extra cost."
            },
            {
              "n": "Light Split Three Ways",
              "d": "during the scatter, a ship may move its full remaining movement after it fires."
            }
          ],
          [
            {
              "n": "Refraction Deepens",
              "d": "during the scatter, a ship that moves its full distance cannot be targeted by weapons fired from beyond range 6 until next round."
            },
            {
              "n": "Every Mirror Turns",
              "d": "at the end of scatter movement, every ship may face any direction at no cost."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Deployment Read from the Shards",
              "d": "after seeing the enemy deployment, reposition one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Casting Corrected Before Battle",
              "d": "after deployment, swap the positions of any two of your ships."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Lens",
              "d": "once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim."
            },
            {
              "n": "First Light Recorded",
              "d": "the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Fleet Is Elsewhere",
        "d": "the first time an enemy fires at your fleet this battle, every ship gains +2 movement and may turn once for free."
      },
      {
        "n": "A Hundred False Hulls",
        "d": "in the scatter round, the first two enemy attacks are wasted on false images and automatically miss their targets."
      }
    ]
  },
  "mirelle": {
    "branches": {
      "A": {
        "n": "Prism Recasting",
        "tiers": [
          [
            {
              "n": "Light Bent to the Weak Side",
              "d": "during the ward, the friendly ship with the lowest shields takes 20% less hull damage until the start of next round."
            },
            {
              "n": "Prisms Face the Fire",
              "d": "a ship facing its nearest enemy gains shields above its maximum equal to 25% of its maximum shields during the ward."
            }
          ],
          [
            {
              "n": "Recharge While Lit",
              "d": "during the ward, shields recharge a second time at round end, at the prism recharge rate."
            },
            {
              "n": "The Lens Rotates",
              "d": "during the ward, a ship that changes its facing gains +10 evasion until its next turn."
            }
          ],
          [
            {
              "n": "Flaw in the Glass Corrected",
              "d": "while the ward is active, the first ship whose shields fall to zero refills to 15%, once per battle."
            },
            {
              "n": "Facet Ward",
              "d": "during the ward, a ship's remaining shields also block the first section damage it would take."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Deployment Read from the Shards",
              "d": "after seeing the enemy deployment, reposition one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Casting Corrected Before Battle",
              "d": "after deployment, swap the positions of any two of your ships."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Lens",
              "d": "once per round, the flagship may focus one enemy; your lance shots against it gain +10 aim."
            },
            {
              "n": "First Light Recorded",
              "d": "the flagship records the first enemy ship that fires each battle; your fleet gains +10 evasion against that ship for the battle."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Ward of Clear Glass",
        "d": "during Prism ward, an enemy ship that fires at a warded ship loses 20 accuracy on its next shot, once per enemy ship."
      },
      {
        "n": "Every Facet Lit",
        "d": "during the ward, each warded ship gains temporary hull equal to 20% of its maximum shields."
      }
    ]
  },
  "vex": {
    "branches": {
      "A": {
        "n": "The Inherited Line",
        "tiers": [
          [
            {
              "n": "Chalked Firing Lanes",
              "d": "a ship firing its volley from a port or starboard flank arc gains +15% damage."
            },
            {
              "n": "Held on the Roll",
              "d": "you may hold one ship volley when the Command is declared and fire it after that ship moves this round."
            }
          ],
          [
            {
              "n": "Named on the Roll",
              "d": "before the volley, name one enemy; every ship may aim its volley at the named enemy even if another target is closer."
            },
            {
              "n": "Inherited Aim",
              "d": "a ship that has not moved this round fires its volley at +15% damage."
            }
          ],
          [
            {
              "n": "Every Gun Sworn",
              "d": "each ship chooses its own volley target freely, ignoring the best target rule, and ships that choose the same target gain +10 aim against it."
            },
            {
              "n": "Debt Comes Due",
              "d": "you may delay the whole volley to the start of next round; when it fires, every ship gains +20% damage."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Sworn Deployment",
              "d": "after seeing the enemy deployment, place one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Reserve Hulls Ready",
              "d": "hold one ship off the field; it enters at full strength at the start of round 2 at any edge of your deployment zone."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Keeps the Roll",
              "d": "once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage."
            },
            {
              "n": "Standard of the First Crusade",
              "d": "once per round, one ship within 2 hexes of the flagship may reroll a missed shot."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Vesper Roll",
        "d": "once per battle, when Fire for effect is used, choose one enemy; every ship that can reach it fires at it, and its shields stop only the first hit."
      },
      {
        "n": "Final Reckoning",
        "d": "after Fire for effect resolves, each ship that destroyed its target with the free volley fires one weapon again at a new target."
      }
    ]
  },
  "malek": {
    "branches": {
      "A": {
        "n": "The Hunter Roll",
        "tiers": [
          [
            {
              "n": "Prey Entered by Name",
              "d": "when the salvo begins, mark one enemy; torpedoes fired at the mark this round gain +15% damage."
            },
            {
              "n": "Salvo in Two Hands",
              "d": "you may hold the damage bonus for up to half your ships and spend it next round instead of this one."
            }
          ],
          [
            {
              "n": "Torpedoes Run True",
              "d": "torpedoes fired during the salvo round gain +10 to hit."
            },
            {
              "n": "Rear Arc Reckoning",
              "d": "during the salvo round, rear arc hits from any weapon gain +15% damage."
            }
          ],
          [
            {
              "n": "The Debt Hunts",
              "d": "during the salvo round, a ship that starts its activation closer to its target than any other friendly ship treats side arc hits on that target as rear arc hits."
            },
            {
              "n": "Two Salvos Sworn",
              "d": "the salvo damage bonus also covers the first torpedo each ship fires next round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Sworn Deployment",
              "d": "after seeing the enemy deployment, place one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Reserve Hulls Ready",
              "d": "hold one ship off the field; it enters at full strength at the start of round 2 at any edge of your deployment zone."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Keeps the Roll",
              "d": "once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage."
            },
            {
              "n": "Standard of the First Crusade",
              "d": "once per round, one ship within 2 hexes of the flagship may reroll a missed shot."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Salvo Without End",
        "d": "during the salvo round, each ship may fire one torpedo a second time at half damage."
      },
      {
        "n": "The Named Prey Falls",
        "d": "when the salvo is declared, choose one enemy; it takes +25% damage from all hits this round."
      }
    ]
  },
  "ashgrove": {
    "branches": {
      "A": {
        "n": "Wings on the Roll",
        "tiers": [
          [
            {
              "n": "Escort Sworn to a Name",
              "d": "an extra wing may be assigned as escort to one named friendly ship instead of striking, intercepting fire aimed at it this round."
            },
            {
              "n": "First Wave Owes the Second",
              "d": "choose the launch order carrier by carrier; the last carrier to launch has its extra wing strike at +20% damage."
            }
          ],
          [
            {
              "n": "The Volley Splits",
              "d": "an extra wing that strikes a different target than its carrier's other wings gains +15% damage."
            },
            {
              "n": "Held in Reserve",
              "d": "you may keep one extra wing unlaunched; it launches free at the start of next round and strikes then."
            }
          ],
          [
            {
              "n": "Every Generation Aloft",
              "d": "a carrier that has not moved this round launches one additional extra wing."
            },
            {
              "n": "Wings Settle the Debt",
              "d": "an extra wing striking the same target as its carrier guns gains +30% damage and is screened at half effect, once per carrier."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Sworn Deployment",
              "d": "after seeing the enemy deployment, place one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Reserve Hulls Ready",
              "d": "hold one ship off the field; it enters at full strength at the start of round 2 at any edge of your deployment zone."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Keeps the Roll",
              "d": "once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage."
            },
            {
              "n": "Standard of the First Crusade",
              "d": "once per round, one ship within 2 hexes of the flagship may reroll a missed shot."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Roll of Wings",
        "d": "during Scramble all wings, every squadron strike ignites the struck enemy section and reduces the target's point defense by 1 for the rest of the battle."
      },
      {
        "n": "Oath of Unbroken Wings",
        "d": "during Scramble all wings, extra wings may form an escort wall across the fleet, granting every friendly ship within 2 hexes of a carrier +25% screen refill and intercepting the first torpedo fired at each escorted ship this round."
      }
    ]
  },
  "thale": {
    "branches": {
      "A": {
        "n": "The Iron Roll",
        "tiers": [
          [
            {
              "n": "Hold and Be Counted",
              "d": "a ship that does not move during Iron wall keeps the damage reduction for one extra round."
            },
            {
              "n": "Screens Where the Debt Falls",
              "d": "you may shift the wall's protection: one chosen ship takes 20 points more hull damage reduction, and one other ship takes 20 points less."
            }
          ],
          [
            {
              "n": "Wall Declared Early",
              "d": "if Iron wall is declared before any of your ships has moved or fired this round, its damage reduction is 10 points stronger this round."
            },
            {
              "n": "Oath of Stillness",
              "d": "during Iron wall, a ship that holds its position refills its shields again at half strength at round end."
            }
          ],
          [
            {
              "n": "Unpaid and Unbroken",
              "d": "during Iron wall, ships below half hull take 60% less hull damage instead of 40%."
            },
            {
              "n": "The Wall Answers",
              "d": "while Iron wall is active, a ship whose shields are emptied by a hit fires its smallest weapon at the attacker, once per ship per battle."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Sworn Deployment",
              "d": "after seeing the enemy deployment, place one of your ships anywhere in your deployment zone."
            },
            {
              "n": "Reserve Hulls Ready",
              "d": "hold one ship off the field; it enters at full strength at the start of round 2 at any edge of your deployment zone."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Keeps the Roll",
              "d": "once per battle, the flagship may order one other ship that has already fired to fire one weapon again at half damage."
            },
            {
              "n": "Standard of the First Crusade",
              "d": "once per round, one ship within 2 hexes of the flagship may reroll a missed shot."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Iron Standing Order",
        "d": "Iron wall lasts two rounds, and shields refill again at half strength at the start of the second round."
      },
      {
        "n": "The Wall That Moves",
        "d": "while Iron wall is active, your ships gain +1 movement."
      }
    ]
  },
  "kassar": {
    "branches": {
      "A": {
        "n": "Synchrony",
        "tiers": [
          [
            {
              "n": "Wide Net",
              "d": "synchronized fire radius +1 hex."
            },
            {
              "n": "Second Volley",
              "d": "the first synced target each round may be fired on by one additional synced ship out of arc."
            }
          ],
          [
            {
              "n": "Shared Solution",
              "d": "each synced ship fires with the best aim modifier any synced ship has."
            },
            {
              "n": "Cold Drill",
              "d": "a synced ship that has not moved this round fires at +10 aim."
            }
          ],
          [
            {
              "n": "Rolling Fire",
              "d": "once per round, when a synced ship kills an enemy, another synced ship that has not yet fired this round may fire one weapon at once at a new target."
            },
            {
              "n": "Iron Tempo",
              "d": "the first time the sync anchor is destroyed or captured, the largest remaining Directorate ship becomes the new anchor for the rest of the battle."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Filed Before Battle",
              "d": "ships that end their movement next to two friendly ships gain +10 aim that round."
            },
            {
              "n": "Drill Revision One",
              "d": "once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Registry Beacon",
              "d": "once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy."
            },
            {
              "n": "Standard Borne Forward",
              "d": "ships that move toward the flagship this round gain +1 movement."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Living Relay",
        "d": "the flagship projects sync from its position at double radius."
      },
      {
        "n": "Single Fire Solution",
        "d": "once per battle, every synced ship fires at one named target, and its shields stop only the first hit."
      }
    ]
  },
  "vorn": {
    "branches": {
      "A": {
        "n": "Filed Interdiction",
        "tiers": [
          [
            {
              "n": "Triple-Indexed Target",
              "d": "when the strike begins, file one enemy as the interdicted target; your hits on it gain +10 crit chance."
            },
            {
              "n": "Strike by the Book",
              "d": "during the strike round, a ship gains +15% damage if its speed is at least the speed of the last ship that fired this round."
            }
          ],
          [
            {
              "n": "Cross-Referenced Fire",
              "d": "during the strike round, the second and later hits on the same target gain +15% damage."
            },
            {
              "n": "Filed Before Movement",
              "d": "during Interdiction strike, a ship that fires before it has moved this round gains +10 crit chance."
            }
          ],
          [
            {
              "n": "Total Interdiction",
              "d": "during Interdiction strike, any target hit by three or more of your ships takes +30% damage from every hit that round."
            },
            {
              "n": "Standard Seven Breach",
              "d": "during the strike round, a critical hit also shuts down the struck section's weapons for one round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Filed Before Battle",
              "d": "ships that end their movement next to two friendly ships gain +10 aim that round."
            },
            {
              "n": "Drill Revision One",
              "d": "once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Registry Beacon",
              "d": "once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy."
            },
            {
              "n": "Standard Borne Forward",
              "d": "ships that move toward the flagship this round gain +1 movement."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Interdiction, Permanent File",
        "d": "any target hit during Interdiction strike takes the strike damage bonus again from all your fire next round."
      },
      {
        "n": "One Order, Every Gun",
        "d": "during Interdiction strike, every ship may fire one weapon a second time at half damage."
      }
    ]
  },
  "reyes": {
    "branches": {
      "A": {
        "n": "Strike Group Procedure",
        "tiers": [
          [
            {
              "n": "Cruisers Filed as Carriers",
              "d": "during the launch, choose one ship without a hangar; it launches one wing this Command."
            },
            {
              "n": "Launch Order Published",
              "d": "publish the strike order before launching; the first wing to strike gains +20% damage."
            }
          ],
          [
            {
              "n": "Second Wave on Schedule",
              "d": "you may hold all extra wings and launch them at the start of next round instead; they strike then at normal damage, and the Command's strike bonus does not carry over."
            },
            {
              "n": "Procedure Rehearsed",
              "d": "every extra wing's strike again this Command gains +10 aim."
            }
          ],
          [
            {
              "n": "Full Group Assembled",
              "d": "if every launch ship launches an extra wing, each launch ship launches one more, but all extra wings must strike the single filed target."
            },
            {
              "n": "Registry of Escorts",
              "d": "extra wings may instead form a screen over your fleet, cutting enemy wing damage by 25% this round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Filed Before Battle",
              "d": "ships that end their movement next to two friendly ships gain +10 aim that round."
            },
            {
              "n": "Drill Revision One",
              "d": "once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Registry Beacon",
              "d": "once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy."
            },
            {
              "n": "Standard Borne Forward",
              "d": "ships that move toward the flagship this round gain +1 movement."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "One Target, Every Wing Filed",
        "d": "designate one enemy before the launch; all extra wings must strike it, and it takes +35% damage from all wing hits this round."
      },
      {
        "n": "Standing Strike Group",
        "d": "after the Command, one extra wing per launch ship stays on patrol; the first time an enemy ship moves within its launch ship's range each round, it strikes that enemy at once."
      }
    ]
  },
  "maren": {
    "branches": {
      "A": {
        "n": "Column Standard",
        "tiers": [
          [
            {
              "n": "Column Filed Straight",
              "d": "during the wall, ships that end their movement in a straight line of three or more friendly ships gain shields above their maximum equal to 25% of their maximum shields."
            },
            {
              "n": "Overflow by Regulation",
              "d": "during the wall, a ship that is at full shields gains +10 evasion until its next turn."
            }
          ],
          [
            {
              "n": "Wall on the Chime",
              "d": "while the wall is active, the first hit against your fleet each round deals no hull damage."
            },
            {
              "n": "Standard Rotation",
              "d": "during the wall, once per ship, a ship may swap hexes with an adjacent friendly ship."
            }
          ],
          [
            {
              "n": "The Column Endures",
              "d": "while the wall is active, the first ship each round to have its shield emptied immediately refills it to 25%."
            },
            {
              "n": "Filed in Armor",
              "d": "during the wall, a ship that has not fired yet when it is hit takes 15 points less hull damage."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Filed Before Battle",
              "d": "ships that end their movement next to two friendly ships gain +10 aim that round."
            },
            {
              "n": "Drill Revision One",
              "d": "once per battle, after the enemy has moved, reposition one of your ships up to 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "Flagship Registry Beacon",
              "d": "once per round, the flagship may stamp one enemy; your ships gain +10 aim against the stamped enemy."
            },
            {
              "n": "Standard Borne Forward",
              "d": "ships that move toward the flagship this round gain +1 movement."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Standard Covers All",
        "d": "while Shield wall order is active, every ship takes a further 20% less hull damage."
      },
      {
        "n": "The Flagship Holds the Standard",
        "d": "while the wall is active, the flagship counts as part of any friendly line, and ships in a line with the flagship gain shields above their maximum equal to 10% of their maximum shields."
      }
    ]
  },
  "grax": {
    "branches": {
      "A": {
        "n": "The Scar Run",
        "tiers": [
          [
            {
              "n": "Run at the Biggest Thing",
              "d": "ships that end their burn movement closer to the largest enemy than they started gain +15% damage this round."
            },
            {
              "n": "First Through the Breach",
              "d": "a ship that moves at least 4 hexes during the burn boards at +25% strength."
            }
          ],
          [
            {
              "n": "The Pack Closes",
              "d": "during the burn, a ship that ends its movement next to a friendly ship gains +10 aim this round."
            },
            {
              "n": "Rush the Hull",
              "d": "a ship that ends its burn movement adjacent to an enemy may board it even if it has already fired this round."
            }
          ],
          [
            {
              "n": "All Scars Forward",
              "d": "during the burn, a ship gains +1 movement for each enemy ship it passes adjacent to, up to +2."
            },
            {
              "n": "The Maw Opens",
              "d": "during the burn, the first ram by each ship deals +30% damage."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Prey Chosen by Wake",
              "d": "at battle start, name the pack's prey; your ships gain +10 aim against it."
            },
            {
              "n": "Loose Pack, Wide Lanes",
              "d": "a ship gains +1 movement on a move that ends with no friendly ship within 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Takes the First Scar",
              "d": "once per battle, the flagship may take a hit aimed at an adjacent friendly ship onto itself."
            },
            {
              "n": "Trophy Standard",
              "d": "after the flagship lands a kill, every friendly ship may turn once for free."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Burn Until the Hulls Meet",
        "d": "Full burn movement, turns and accuracy protection carry into the next round."
      },
      {
        "n": "Run of the Warlord",
        "d": "when Full burn is declared, the flagship may move twice, and may board after each move."
      }
    ]
  },
  "sable": {
    "branches": {
      "A": {
        "n": "Scars Behind the Prey",
        "tiers": [
          [
            {
              "n": "Knife Finds the Back",
              "d": "during the Command round, rear arc hits gain +15% damage on top of the Command bonus."
            },
            {
              "n": "Torpedoes in the Dark",
              "d": "torpedoes fired this round are intercepted at half the usual chance: enemy flak and screen wings roll at half effect."
            }
          ],
          [
            {
              "n": "Cut and Turn",
              "d": "a ship that lands a rear arc hit this round may turn once for free after firing."
            },
            {
              "n": "Second Knife",
              "d": "torpedoes that miss this round reload one turn sooner than normal."
            }
          ],
          [
            {
              "n": "The Smile Before the Cut",
              "d": "each round during the Command, the first of your ships to activate gains +20% damage on its first shot."
            },
            {
              "n": "Every Knife at Once",
              "d": "if three or more of your ships hit the same target rear arc this round, that target's weapons lose 20 accuracy next round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Prey Chosen by Wake",
              "d": "at battle start, name the pack's prey; your ships gain +10 aim against it."
            },
            {
              "n": "Loose Pack, Wide Lanes",
              "d": "a ship gains +1 movement on a move that ends with no friendly ship within 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Takes the First Scar",
              "d": "once per battle, the flagship may take a hit aimed at an adjacent friendly ship onto itself."
            },
            {
              "n": "Trophy Standard",
              "d": "after the flagship lands a kill, every friendly ship may turn once for free."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Dark Full of Knives",
        "d": "the Command damage bonus also applies to the first shot each ship fires next round, if that shot comes from a rear arc."
      },
      {
        "n": "The Cut That Feeds the Pack",
        "d": "when the Command is declared, every ship may immediately move 2 hexes toward the nearest enemy rear arc."
      }
    ]
  },
  "mott": {
    "branches": {
      "A": {
        "n": "Junkyard Wings",
        "tiers": [
          [
            {
              "n": "Patched Wing",
              "d": "choose one carrier; its extra wing is patched together from scrap, strikes at +25% damage, and is removed after its strike."
            },
            {
              "n": "Hulk Holds More",
              "d": "choose one of your largest ships that is not a carrier; it launches one extra wing during the Command, from the Hulk's spare racks."
            }
          ],
          [
            {
              "n": "Re-Tasked Mid-Flight",
              "d": "an extra wing that strikes a target no other wing struck this round gains +20% damage."
            },
            {
              "n": "Launched from the Wreck Line",
              "d": "carriers that did not move this round launch their extra wings at +15% damage."
            }
          ],
          [
            {
              "n": "The Whole Yard Flies",
              "d": "a launch ship that launches all its wings this Command launches one more extra wing."
            },
            {
              "n": "Wings Come Back Screaming",
              "d": "an extra wing's strike again gains +15% damage when it hits a target already hit this round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Prey Chosen by Wake",
              "d": "at battle start, name the pack's prey; your ships gain +10 aim against it."
            },
            {
              "n": "Loose Pack, Wide Lanes",
              "d": "a ship gains +1 movement on a move that ends with no friendly ship within 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Takes the First Scar",
              "d": "once per battle, the flagship may take a hit aimed at an adjacent friendly ship onto itself."
            },
            {
              "n": "Trophy Standard",
              "d": "after the flagship lands a kill, every friendly ship may turn once for free."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Swarm Over the Scrap Field",
        "d": "Release the swarm launches the extra wings twice: once when the Command is used, and once after your last activation this round."
      },
      {
        "n": "Old Mott's Private Wing",
        "d": "choose one launch ship; its extra wing stays for the battle and gains +20% damage on its first strike each round."
      }
    ]
  },
  "vesh": {
    "branches": {
      "A": {
        "n": "Scar Welding",
        "tiers": [
          [
            {
              "n": "Weld What Matters",
              "d": "instead of spreading the repair evenly, you may put one ship's entire repair share onto its single most damaged section."
            },
            {
              "n": "Patch Over the Guns",
              "d": "a ship whose weapons section is repaired by the Command gains +10 aim this round."
            }
          ],
          [
            {
              "n": "Scrap to the Front",
              "d": "you may take the flagship's repair share and give it to any one other ship, doubled."
            },
            {
              "n": "Welded While Fighting",
              "d": "a ship repaired by the Command may fire one weapon at half damage at once."
            }
          ],
          [
            {
              "n": "Double-Bolted Plate",
              "d": "a section patched by the Command gains +20% section hull for the rest of the battle."
            },
            {
              "n": "The Pack Bites On",
              "d": "a ship that the Command brings back above half hull gains +15% damage next round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Prey Chosen by Wake",
              "d": "at battle start, name the pack's prey; your ships gain +10 aim against it."
            },
            {
              "n": "Loose Pack, Wide Lanes",
              "d": "a ship gains +1 movement on a move that ends with no friendly ship within 2 hexes."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Takes the First Scar",
              "d": "once per battle, the flagship may take a hit aimed at an adjacent friendly ship onto itself."
            },
            {
              "n": "Trophy Standard",
              "d": "after the flagship lands a kill, every friendly ship may turn once for free."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Welded Whole",
        "d": "Patch and weld restores one destroyed section on every ship to full strength, not merely patched function."
      },
      {
        "n": "Nothing Stays Broken",
        "d": "the first time one of your ships would lose a section this battle, that section is not broken and is restored to full."
      }
    ]
  },
  "matriarch": {
    "branches": {
      "A": {
        "n": "Too Many Mouths",
        "tiers": [
          [
            {
              "n": "Choose the Brood That Swells",
              "d": "one brood releases two extra swarms instead of one, and the other broods release none extra."
            },
            {
              "n": "Spores on the Tide",
              "d": "extra swarms may be placed up to 2 hexes from their brood instead of adjacent to it."
            }
          ],
          [
            {
              "n": "The Brood Splits",
              "d": "an extra swarm that strikes a different target than its brood's other swarms gains +15% damage."
            },
            {
              "n": "Spawned Before the Strike",
              "d": "a brood that moved this round has its extra swarms strike at +15% damage."
            }
          ],
          [
            {
              "n": "Every Throat Opens",
              "d": "a brood that did not move this round has its extra swarms strike at +25% damage."
            },
            {
              "n": "The Second Throat Bites",
              "d": "a swarm striking a target already hit by another swarm this round gains +25% damage."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Roles Assigned at Hatching",
              "d": "at battle start, give each ship a role: strike (its shots gain +10 aim), screen (it gains +10 evasion), or mend (its repair and regrowth effects are 10% stronger); a ship may change its role once per battle."
            },
            {
              "n": "Broods in Reserve",
              "d": "hold one brood off the field; it enters, grown and ready, at the start of round 2."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The First Throat Opens",
              "d": "once per battle, one other ship may act immediately after the flagship finishes its activation."
            },
            {
              "n": "Throat of the Deep",
              "d": "ships within 2 hexes of the flagship gain +10 aim."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Nine Throats, One Hunger",
        "d": "when Spawning surge is used, choose one enemy; every extra swarm strikes it, and it takes +25% damage from swarm hits this round."
      },
      {
        "n": "The Brood Does Not Stop",
        "d": "an extra swarm that destroys its target strikes another enemy at half damage in the same round."
      }
    ]
  },
  "razormaw": {
    "branches": {
      "A": {
        "n": "The Hunting Throat",
        "tiers": [
          [
            {
              "n": "Run Down the Slowest",
              "d": "during the frenzy, your ships gain +20% damage against targets slower than themselves."
            },
            {
              "n": "Teeth at the Throat",
              "d": "a ship's first rear arc hit in the frenzy round gains +25% damage."
            }
          ],
          [
            {
              "n": "One Prey in Both Throats",
              "d": "name one prey when the frenzy begins; ships moving toward the prey gain +1 movement."
            },
            {
              "n": "Scent in the Dark",
              "d": "during the frenzy, a ship that changes targets after a kill gains +10 aim on its next shot."
            }
          ],
          [
            {
              "n": "Frenzy Feeds the Throat",
              "d": "a ship that lands a rear arc hit during the frenzy may immediately move 2 more hexes."
            },
            {
              "n": "Breath Before the Bite",
              "d": "during the frenzy, an enemy adjacent to two or more of your ships loses a further 20 accuracy."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Roles Assigned at Hatching",
              "d": "at battle start, give each ship a role: strike (its shots gain +10 aim), screen (it gains +10 evasion), or mend (its repair and regrowth effects are 10% stronger); a ship may change its role once per battle."
            },
            {
              "n": "Broods in Reserve",
              "d": "hold one brood off the field; it enters, grown and ready, at the start of round 2."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The First Throat Opens",
              "d": "once per battle, one other ship may act immediately after the flagship finishes its activation."
            },
            {
              "n": "Throat of the Deep",
              "d": "ships within 2 hexes of the flagship gain +10 aim."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Throat Turns Red",
        "d": "ships that end the frenzy round adjacent to an enemy gain +25% damage on the first shot they fire next round."
      },
      {
        "n": "One Prey, Every Mouth",
        "d": "when the frenzy is declared, every ship may move directly toward the named prey, ignoring its turn limit once."
      }
    ]
  },
  "mending": {
    "branches": {
      "A": {
        "n": "The Mending Throat",
        "tiers": [
          [
            {
              "n": "Grow Where It Hurts",
              "d": "you may assign one ship's entire regrowth to a single damaged section."
            },
            {
              "n": "Skin Grown Thick",
              "d": "a ship may take its regrowth as temporary extra hull, up to +15%, instead of repairing damage."
            }
          ],
          [
            {
              "n": "The Tide Comes Early",
              "d": "if Regrowth tide is used before any of your ships has taken damage this round, every repair is 10 points stronger."
            },
            {
              "n": "Growth Holds the Wound",
              "d": "a section healed by the tide heals again at the next round start, for the same amount."
            }
          ],
          [
            {
              "n": "Flesh Knit for War",
              "d": "a ship the tide brings above three quarters hull gains +20% damage next round."
            },
            {
              "n": "The Throat Refuses Holes",
              "d": "while any of your ships is below half hull, the most damaged ship regrows 10% at each round start until it passes half."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Roles Assigned at Hatching",
              "d": "at battle start, give each ship a role: strike (its shots gain +10 aim), screen (it gains +10 evasion), or mend (its repair and regrowth effects are 10% stronger); a ship may change its role once per battle."
            },
            {
              "n": "Broods in Reserve",
              "d": "hold one brood off the field; it enters, grown and ready, at the start of round 2."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The First Throat Opens",
              "d": "once per battle, one other ship may act immediately after the flagship finishes its activation."
            },
            {
              "n": "Throat of the Deep",
              "d": "ships within 2 hexes of the flagship gain +10 aim."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Tide Without End",
        "d": "Regrowth tide heals a second time at the end of the round, at half strength."
      },
      {
        "n": "What Was Torn Grows Back",
        "d": "the tide restores destroyed sections to full function, and a section restored this way cannot be destroyed again this battle."
      }
    ]
  },
  "voice": {
    "branches": {
      "A": {
        "n": "The Acid Throat",
        "tiers": [
          [
            {
              "n": "Acid Before Aim",
              "d": "each ship may spit its volley at the nearest enemy instead of the best target."
            },
            {
              "n": "Every Throat Spits",
              "d": "a ship whose guns cannot bear may still spit once at half damage at the nearest enemy in range."
            }
          ],
          [
            {
              "n": "The Burn Stays",
              "d": "an enemy hit by the volley takes acid damage at the start of next round equal to 15% of the volley damage it took."
            },
            {
              "n": "Spat in Two Rounds",
              "d": "choose up to half your ships: they hold their spit in the volley and fire it at the start of next round at half damage."
            }
          ],
          [
            {
              "n": "Acid Finds the Seams",
              "d": "volley hits ignore armor on targets below half hull."
            },
            {
              "n": "Many Mouths at Once",
              "d": "before the volley resolves, each ship may switch its target once; if four or more ships spit at one target, that target loses 20 accuracy next round as acid eats at its scanners."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Roles Assigned at Hatching",
              "d": "at battle start, give each ship a role: strike (its shots gain +10 aim), screen (it gains +10 evasion), or mend (its repair and regrowth effects are 10% stronger); a ship may change its role once per battle."
            },
            {
              "n": "Broods in Reserve",
              "d": "hold one brood off the field; it enters, grown and ready, at the start of round 2."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The First Throat Opens",
              "d": "once per battle, one other ship may act immediately after the flagship finishes its activation."
            },
            {
              "n": "Throat of the Deep",
              "d": "ships within 2 hexes of the flagship gain +10 aim."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "The Volley That Grows",
        "d": "after the volley, every ship that landed its opening acid burst fires a follow-up burst at half damage."
      },
      {
        "n": "Mouth of the Deep",
        "d": "choose one ship; it spits with every weapon it carries, twice, at any single target in range."
      }
    ]
  },
  "nekhet": {
    "branches": {
      "A": {
        "n": "Iteration of the Whole Hull",
        "tiers": [
          [
            {
              "n": "Restore from the Ninth Frame",
              "d": "restore one ship from its archived state for the full repair amount, and every other ship receives half the normal swarm repair."
            },
            {
              "n": "Copies Triage the Damage",
              "d": "a section the Command repairs to full also clears its ship's fire and acid."
            }
          ],
          [
            {
              "n": "Iteration Runs During Fire",
              "d": "a ship repaired by the Command gains +15% damage on its next shot this round."
            },
            {
              "n": "The Archive Answers First",
              "d": "if Release the repair swarms is used before any of your ships has acted this round, every repair is 10 points stronger."
            }
          ],
          [
            {
              "n": "Restored Beyond the Original",
              "d": "a section rebuilt by the swarms carries the next iteration plating, gaining +20% section hull for the rest of the battle."
            },
            {
              "n": "Every Copy Contributes",
              "d": "the flagship repair share may be divided among any number of friendly ships."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Loaded from Archive",
              "d": "ships that end their movement next to two friendly ships gain +10 evasion that round."
            },
            {
              "n": "Iteration Swap",
              "d": "once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Hosts the Index",
              "d": "once per round, the flagship may copy another friendly ship's target and fire at it at +15% damage."
            },
            {
              "n": "Frame Zero",
              "d": "the flagship's first missed shot each battle is recorded and fired again at half damage."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Tenth Frame",
        "d": "choose one ship when the Command is declared; that ship's repair is tripled, and one destroyed section on it returns to full function."
      },
      {
        "n": "The Earlier Copy Returns",
        "d": "choose one damaged ship; it is repaired for the full repair amount on every section, and all its damaged sections are patched."
      }
    ]
  },
  "sekhmar": {
    "branches": {
      "A": {
        "n": "Corona Iteration",
        "tiers": [
          [
            {
              "n": "Arcs Written Warm",
              "d": "a volley hit from a corona arc splashes 25% of its damage onto one enemy adjacent to the target."
            },
            {
              "n": "Noon Is a Choice",
              "d": "you may fire the volley at the start of the round, before movement, at +15% damage."
            }
          ],
          [
            {
              "n": "The Copy Fires Again",
              "d": "a ship whose volley destroys its target may fire one weapon at a new target."
            },
            {
              "n": "Target Archived Mid-Flight",
              "d": "before the volley resolves, each ship may choose its own target; a ship that chooses a target no other ship chose gains +10 aim against it."
            }
          ],
          [
            {
              "n": "Corona Without Shadow",
              "d": "the volley ignores evasion granted by terrain and cover."
            },
            {
              "n": "Every Frame at Noon",
              "d": "a ship that did not move fires its volley at +25% damage and +10 aim."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Loaded from Archive",
              "d": "ships that end their movement next to two friendly ships gain +10 evasion that round."
            },
            {
              "n": "Iteration Swap",
              "d": "once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Hosts the Index",
              "d": "once per round, the flagship may copy another friendly ship's target and fire at it at +15% damage."
            },
            {
              "n": "Frame Zero",
              "d": "the flagship's first missed shot each battle is recorded and fired again at half damage."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Noon That Does Not Pass",
        "d": "Noon volley fires again next round, at half damage, from every ship."
      },
      {
        "n": "One Sun, Copied",
        "d": "every ship's volley is also copied onto the enemy with the least remaining hull, at half damage."
      }
    ]
  },
  "anuket": {
    "branches": {
      "A": {
        "n": "The Long Copy Hunt",
        "tiers": [
          [
            {
              "n": "Copied from Behind",
              "d": "during the Command round, rear arc hits gain +20% damage on top of the Command bonus."
            },
            {
              "n": "Unseen in the Archive",
              "d": "during the Command round, a ship that was not targeted last round gains a further +15% damage."
            }
          ],
          [
            {
              "n": "The Shadow Is a Position",
              "d": "a ship that ends its movement in an enemy's rear arc gains +20% damage in the hunt round."
            },
            {
              "n": "Strike the Uncopied Target",
              "d": "during the Command round, hits on an enemy that has not yet been hit this battle gain +15% damage."
            }
          ],
          [
            {
              "n": "Iteration of the Kill",
              "d": "during the Command round, when one of your ships lands a rear arc hit, the next hit on that target this round gains +20% damage."
            },
            {
              "n": "Silent in the Archive",
              "d": "during the Command round, any ship that ends its activation outside enemy front arcs gains +15 evasion until next round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Loaded from Archive",
              "d": "ships that end their movement next to two friendly ships gain +10 evasion that round."
            },
            {
              "n": "Iteration Swap",
              "d": "once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Hosts the Index",
              "d": "once per round, the flagship may copy another friendly ship's target and fire at it at +15% damage."
            },
            {
              "n": "Frame Zero",
              "d": "the flagship's first missed shot each battle is recorded and fired again at half damage."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Out of Every Shadow",
        "d": "the Command bonus covers two consecutive rounds for any ship that ends each round in a rear arc or not targeted that round."
      },
      {
        "n": "The Long Copy Strikes",
        "d": "when the Command is declared, each ship may first move 2 hexes toward an enemy rear arc."
      }
    ]
  },
  "khepra": {
    "branches": {
      "A": {
        "n": "Layered Iterations",
        "tiers": [
          [
            {
              "n": "Plates over Shadow",
              "d": "during the wall, you may stack the wall on one ship: that ship takes 75% less hull damage this round, and every other ship takes 25% less instead of 50%."
            },
            {
              "n": "The Twice-Restored Order",
              "d": "a ship that has already been repaired earlier in this battle takes a further 15% less hull damage during the wall."
            }
          ],
          [
            {
              "n": "Wall Archived in Advance",
              "d": "if Sunshade wall is declared before any of your ships has moved this round, its damage reduction is 10 points stronger this round."
            },
            {
              "n": "Layers Shift",
              "d": "during the wall, at round end each ship may shift 1 hex toward the flagship without losing the wall damage reduction."
            }
          ],
          [
            {
              "n": "No Layer Falls Alone",
              "d": "while the wall is active, the first hit each ship takes in a battle is absorbed by its layered plates, once per ship."
            },
            {
              "n": "Stillness Counted",
              "d": "during the wall, a ship that does not move gains +20 aim on its first shot next round."
            }
          ]
        ]
      },
      "B": {
        "n": "Fleet",
        "tiers": [
          [
            {
              "n": "Formation Loaded from Archive",
              "d": "ships that end their movement next to two friendly ships gain +10 evasion that round."
            },
            {
              "n": "Iteration Swap",
              "d": "once per battle, swap the positions of two of your ships, as the Archive substitutes a corrected version of the plan."
            }
          ]
        ]
      },
      "C": {
        "n": "Flagship and line",
        "tiers": [
          [
            {
              "n": "The Flagship Hosts the Index",
              "d": "once per round, the flagship may copy another friendly ship's target and fire at it at +15% damage."
            },
            {
              "n": "Frame Zero",
              "d": "the flagship's first missed shot each battle is recorded and fired again at half damage."
            }
          ]
        ]
      }
    },
    "capstones": [
      {
        "n": "Wall of Ten Thousand Copies",
        "d": "while the wall is active, hull damage each ship takes in a round cannot exceed 25% of its maximum hull."
      },
      {
        "n": "The Restored Fleet",
        "d": "while the wall is active, a ship repaired this round keeps the wall hull damage reduction into next round after the wall ends."
      }
    ]
  }
};
// Admiral tree effect numbers (issue #305 job 1: the plumbing and the Glasswrights pilot).
// The pick key is the lineage key from LINEAGE_TREES; the text lives there and these numbers drive battle.
// A row with no entry is inert (the 12 Glasswrights x and c rows wait for the Muse text pass, #311).
const TREE_FX={
  "aelith:A:0:1":{k:"castTwice",n:.5},
  "aelith:A:2:0":{k:"flakSkip"},
  "aelith:A:2:1":{k:"lensAloft"},
  // Job 7a: the waiting Glasswrights rows (Muse text pass, PR 324).
  "aelith:A:0:0":{k:"flightPaths",n:.15},
  "aelith:A:1:0":{k:"replay",n:.1},
  "aelith:A:1:1":{k:"starlings",n:10},
  "aelith:cap:0":{k:"flightCast",n:.25},
  "aelith:cap:1":{k:"forgeAhead",n:.15},
  "vaelen:A:0:0":{k:"longFocus",n:.2},
  "vaelen:A:1:1":{k:"recordedAngle"},
  "vaelen:A:2:0":{k:"burnFlaw"},
  "vaelen:A:2:1":{k:"longLight",n:2},
  "vaelen:cap:1":{k:"flawForever",n:.15},
  "vaelen:A:0:1":{k:"oneLens",n:.25},
  "vaelen:A:1:0":{k:"lightTogether",n:.15},
  "vaelen:cap:0":{k:"sunLens"},
  "thorne:A:0:0":{k:"twoImages",n:20},
  "thorne:A:0:1":{k:"anglesRecorded",n:10},
  "thorne:A:2:0":{k:"refraction",n:6},
  "thorne:A:2:1":{k:"mirrorTurns"},
  "thorne:cap:1":{k:"falseHulls",n:2},
  "thorne:A:1:0":{k:"mirrorAside"},
  "thorne:A:1:1":{k:"splitThree"},
  "thorne:cap:0":{k:"fleetElsewhere",n:2},
  "mirelle:A:1:0":{k:"rechargeLit"},
  "mirelle:A:2:0":{k:"glassCorrected",n:.15},
  "mirelle:A:2:1":{k:"hardLight"},
  "mirelle:cap:0":{k:"wardGlass",n:20},
  "mirelle:A:0:0":{k:"weakSide",n:.2},
  "mirelle:A:0:1":{k:"prismsFace",n:.25},
  "mirelle:A:1:1":{k:"lensRotates",n:10},
  "mirelle:cap:1":{k:"facetLit",n:.2},
  "aelith:B:0:0":{k:"deployRead"},"aelith:B:0:1":{k:"castCorrected"},"aelith:C:0:0":{k:"flagshipLens",n:10},"aelith:C:0:1":{k:"firstLight",n:10},
  "vaelen:B:0:0":{k:"deployRead"},"vaelen:B:0:1":{k:"castCorrected"},"vaelen:C:0:0":{k:"flagshipLens",n:10},"vaelen:C:0:1":{k:"firstLight",n:10},
  "thorne:B:0:0":{k:"deployRead"},"thorne:B:0:1":{k:"castCorrected"},"thorne:C:0:0":{k:"flagshipLens",n:10},"thorne:C:0:1":{k:"firstLight",n:10},
  "mirelle:B:0:0":{k:"deployRead"},"mirelle:B:0:1":{k:"castCorrected"},"mirelle:C:0:0":{k:"flagshipLens",n:10},"mirelle:C:0:1":{k:"firstLight",n:10},
  // Sunward Crusade (issue #305 job 2). The 25 a and b rows; the 10 x and 1 c rows stay inert until the Muse text pass (#311).
  "vex:A:0:1":{k:"heldAccount"},
  "vex:A:1:0":{k:"namedLedger"},
  "vex:A:1:1":{k:"inheritedAim",n:.15},
  "vex:A:2:0":{k:"everyGun",n:10},
  "malek:A:0:0":{k:"preyName",n:.15},
  "malek:A:0:1":{k:"salvoTwoHands"},
  "malek:A:2:0":{k:"debtHunts"},
  "malek:A:2:1":{k:"twoSalvos"},
  "malek:cap:1":{k:"namedPrey",n:.25},
  "ashgrove:A:0:0":{k:"escortName"},
  "ashgrove:A:0:1":{k:"firstWave",n:.2},
  "ashgrove:A:1:1":{k:"wingReserve"},
  "ashgrove:A:2:0":{k:"generation"},
  "ashgrove:A:2:1":{k:"wingsDebt",n:.3},
  "ashgrove:cap:0":{k:"rollWings"},
  "ashgrove:cap:1":{k:"oathWings"},
  "thale:A:0:0":{k:"holdCounted"},
  "thale:A:1:1":{k:"oathStillness"},
  "thale:A:2:0":{k:"unpaid",n:.2},
  "thale:A:2:1":{k:"wallAnswers"},
  "thale:cap:0":{k:"ironTestament"},
  // Job 7a: the waiting Sunward Crusade rows (Muse text pass, PR 324).
  "vex:A:0:0":{k:"ledgerArcs",n:.15},
  "vex:A:2:1":{k:"debtDue",n:.2},
  "vex:cap:0":{k:"grandLedger"},
  "vex:cap:1":{k:"lastAccount"},
  "malek:A:1:0":{k:"torpFirst"},
  "malek:A:1:1":{k:"rearReckoning",n:.15},
  "malek:cap:0":{k:"salvoEnd"},
  "ashgrove:A:1:0":{k:"accountSplits",n:.15},
  "thale:A:0:1":{k:"screensShift",n:.2},
  "thale:A:1:0":{k:"wallEarly",n:.1},
  "thale:cap:1":{k:"wallMoves",n:1},
  "vex:B:0:0":{k:"swornDeploy"},"vex:B:0:1":{k:"debtsReserve"},"vex:C:0:0":{k:"flagshipLedger"},"vex:C:0:1":{k:"standardReroll"},
  "malek:B:0:0":{k:"swornDeploy"},"malek:B:0:1":{k:"debtsReserve"},"malek:C:0:0":{k:"flagshipLedger"},"malek:C:0:1":{k:"standardReroll"},
  "ashgrove:B:0:0":{k:"swornDeploy"},"ashgrove:B:0:1":{k:"debtsReserve"},"ashgrove:C:0:0":{k:"flagshipLedger"},"ashgrove:C:0:1":{k:"standardReroll"},
  "thale:B:0:0":{k:"swornDeploy"},"thale:B:0:1":{k:"debtsReserve"},"thale:C:0:0":{k:"flagshipLedger"},"thale:C:0:1":{k:"standardReroll"},
  // Eclipse (issue #305 job 3). The a and b rows; the 6 x and 1 c rows stay inert until the Muse text pass (#311).
  "nekhet:A:0:0":{k:"restoreNinth"},
  "nekhet:A:2:0":{k:"restoredBeyond",n:.2},
  "nekhet:A:2:1":{k:"copiesContribute"},
  "nekhet:cap:0":{k:"tenthFrame"},
  "nekhet:cap:1":{k:"earlierCopy"},
  "sekhmar:A:0:0":{k:"arcsWarm",n:.25},
  "sekhmar:A:0:1":{k:"noonChoice",n:.15},
  "sekhmar:A:1:0":{k:"copyFires"},
  "sekhmar:A:2:0":{k:"coronaShadow"},
  "sekhmar:A:2:1":{k:"everyFrame",n:.25,a:10},
  "sekhmar:cap:0":{k:"noonRepeat"},
  "sekhmar:cap:1":{k:"oneSunCopied"},
  "anuket:A:0:0":{k:"copiedBehind",n:.2},
  "anuket:A:0:1":{k:"unseenArchive",n:.15},
  "anuket:A:1:1":{k:"uncopiedTarget",n:.15},
  "anuket:A:2:0":{k:"iterationKill",n:.2},
  "anuket:A:2:1":{k:"silentArchive",n:15},
  "anuket:cap:0":{k:"outShadow"},
  "anuket:cap:1":{k:"longCopy"},
  "khepra:A:0:0":{k:"platesShadow"},
  "khepra:A:0:1":{k:"twiceRestored",n:.15},
  "khepra:A:1:1":{k:"layersShift"},
  "khepra:A:2:0":{k:"noLayer"},
  "khepra:A:2:1":{k:"stillnessCounted",n:20},
  "khepra:cap:0":{k:"tenThousand",n:.25},
  "khepra:cap:1":{k:"restoredFleet"},
  "nekhet:B:0:1":{k:"iterationSwap"},"nekhet:C:0:0":{k:"flagshipIndex",n:.15},"nekhet:C:0:1":{k:"frameZero"},
  "sekhmar:B:0:1":{k:"iterationSwap"},"sekhmar:C:0:0":{k:"flagshipIndex",n:.15},"sekhmar:C:0:1":{k:"frameZero"},
  "anuket:B:0:1":{k:"iterationSwap"},"anuket:C:0:0":{k:"flagshipIndex",n:.15},"anuket:C:0:1":{k:"frameZero"},
  "khepra:B:0:1":{k:"iterationSwap"},"khepra:C:0:0":{k:"flagshipIndex",n:.15},"khepra:C:0:1":{k:"frameZero"},
  // Job 7b: the waiting Eclipse rows (Muse text pass, PR 324).
  "nekhet:A:0:1":{k:"copiesTriage"},
  "nekhet:A:1:0":{k:"iterationFire",n:.15},
  "nekhet:A:1:1":{k:"archiveFirst",n:.1},
  "anuket:A:1:0":{k:"shadowPos",n:.2},
  "khepra:A:1:0":{k:"wallEarly",n:.1},
  "sekhmar:A:1:1":{k:"targetArchived",n:10},
  "nekhet:B:0:0":{k:"eclFormation",n:10},"sekhmar:B:0:0":{k:"eclFormation",n:10},"anuket:B:0:0":{k:"eclFormation",n:10},"khepra:B:0:0":{k:"eclFormation",n:10},
  // The Chorus (issue #305 job 4). The 26 a and b rows; the 9 x rows and the shared c row stay inert until the Muse text pass (#311).
  "matriarch:A:0:0":{k:"chooseBrood"},
  "matriarch:A:0:1":{k:"sporeTide",n:2},
  "matriarch:A:2:0":{k:"everyThroat",n:.25},
  "matriarch:A:2:1":{k:"secondThroat",n:.25},
  "razormaw:A:0:0":{k:"runDown",n:.2},
  "razormaw:A:1:0":{k:"razorPrey",n:1},
  "razormaw:A:2:0":{k:"frenzyFeeds",n:2},
  "razormaw:A:2:1":{k:"breathBite",n:20},
  "razormaw:cap:0":{k:"throatRed",n:.25},
  "razormaw:cap:1":{k:"preyEveryMouth",n:1},
  "mending:A:0:0":{k:"growHurts"},
  "mending:A:0:1":{k:"skinThick",n:.15},
  "mending:A:2:0":{k:"fleshKnit",n:.2},
  "mending:A:2:1":{k:"refuseHoles",n:.1},
  "mending:cap:0":{k:"tideEnd"},
  "mending:cap:1":{k:"tornBack"},
  "voice:A:0:0":{k:"acidBeforeAim"},
  "voice:A:0:1":{k:"throatSpits",n:.5},
  "voice:A:1:0":{k:"burnStays",n:.15},
  "voice:A:2:0":{k:"acidSeams"},
  "voice:A:2:1":{k:"manyMouths",n:20},
  "voice:cap:0":{k:"volleyGrows",n:.5},
  "voice:cap:1":{k:"mouthDeep"},
  "matriarch:B:0:1":{k:"broodReserve"},"matriarch:C:0:0":{k:"firstThroat"},"matriarch:C:0:1":{k:"throatDeep",n:10},
  "razormaw:B:0:1":{k:"broodReserve"},"razormaw:C:0:0":{k:"firstThroat"},"razormaw:C:0:1":{k:"throatDeep",n:10},
  "mending:B:0:1":{k:"broodReserve"},"mending:C:0:0":{k:"firstThroat"},"mending:C:0:1":{k:"throatDeep",n:10},
  "voice:B:0:1":{k:"broodReserve"},"voice:C:0:0":{k:"firstThroat"},"voice:C:0:1":{k:"throatDeep",n:10},
  // Job 7b: the waiting Chorus rows (Muse text pass, PR 324).
  "matriarch:A:1:0":{k:"accountSplits",n:.15},
  "matriarch:cap:0":{k:"nineThroats",n:.25},
  "razormaw:A:0:1":{k:"teethThroat",n:.25},
  "mending:A:1:0":{k:"tideEarly",n:.1},
  "mending:A:1:1":{k:"growthWound"},
  "voice:A:1:1":{k:"spatRounds"},
  // The Ashfall Hullbreakers (issue #305 job 5). All 36 rows, including the rewritten x and c rows (Muse PR 324).
  "grax:A:0:0":{k:"runBigger",n:.15},
  "grax:A:0:1":{k:"railBoarding",n:.25},
  "grax:A:1:0":{k:"packCloses",n:10},
  "grax:A:1:1":{k:"rushRail"},
  "grax:A:2:0":{k:"allScars",n:2},
  "grax:A:2:1":{k:"mawOpens",n:.3},
  "grax:cap:0":{k:"burnCarry"},
  "grax:cap:1":{k:"warlordRun"},
  "sable:A:0:0":{k:"knifeBack",n:.15},
  "sable:A:0:1":{k:"darkTorps"},
  "sable:A:1:0":{k:"cutTurn"},
  "sable:A:1:1":{k:"secondKnife"},
  "sable:A:2:0":{k:"smileCut",n:.2},
  "sable:A:2:1":{k:"everyKnife",n:20},
  "sable:cap:0":{k:"darkKnives"},
  "sable:cap:1":{k:"cutFeeds"},
  "mott:A:0:0":{k:"patchedWing",n:.25},
  "mott:A:0:1":{k:"hulkMore"},
  "mott:A:1:0":{k:"reTasked",n:.2},
  "mott:A:1:1":{k:"wreckLine",n:.15},
  "mott:A:2:0":{k:"wholeYard"},
  "mott:A:2:1":{k:"screaming",n:.15},
  "mott:cap:0":{k:"swarmScrap"},
  "mott:cap:1":{k:"privateWing",n:.2},
  "vesh:A:0:0":{k:"weldMatters"},
  "vesh:A:0:1":{k:"patchGuns",n:10},
  "vesh:A:1:0":{k:"scrapFront"},
  "vesh:A:1:1":{k:"weldedFight"},
  "vesh:A:2:0":{k:"doubleBolted",n:.2},
  "vesh:A:2:1":{k:"packBites",n:.15},
  "vesh:cap:0":{k:"weldedWhole"},
  "vesh:cap:1":{k:"nothingBroken"},
  "grax:B:0:0":{k:"preyScent",n:10},"grax:B:0:1":{k:"loosePack"},"grax:C:0:0":{k:"firstScar"},"grax:C:0:1":{k:"trophyStandard"},
  "sable:B:0:0":{k:"preyScent",n:10},"sable:B:0:1":{k:"loosePack"},"sable:C:0:0":{k:"firstScar"},"sable:C:0:1":{k:"trophyStandard"},
  "mott:B:0:0":{k:"preyScent",n:10},"mott:B:0:1":{k:"loosePack"},"mott:C:0:0":{k:"firstScar"},"mott:C:0:1":{k:"trophyStandard"},
  "vesh:B:0:0":{k:"preyScent",n:10},"vesh:B:0:1":{k:"loosePack"},"vesh:C:0:0":{k:"firstScar"},"vesh:C:0:1":{k:"trophyStandard"},
  // The Hegemony Navy (issue #305 job 6). All 36 rows, including the rewritten x and c rows (Muse PR 324).
  "kassar:A:0:0":{k:"wideNet",n:1},
  "kassar:A:0:1":{k:"secondVolley"},
  "kassar:A:1:0":{k:"sharedSolution"},
  "kassar:A:1:1":{k:"coldDrill",n:10},
  "kassar:A:2:0":{k:"rollingFire"},
  "kassar:A:2:1":{k:"ironTempo"},
  "kassar:cap:0":{k:"livingRelay"},
  "kassar:cap:1":{k:"oneVoice"},
  "vorn:A:0:0":{k:"filedTriplicate",n:10},
  "vorn:A:0:1":{k:"strikeBook",n:.15},
  "vorn:A:1:0":{k:"crossFire",n:.15},
  "vorn:A:1:1":{k:"filedBefore",n:10},
  "vorn:A:2:0":{k:"totalInterdiction",n:.3},
  "vorn:A:2:1":{k:"sevenBreach"},
  "vorn:cap:0":{k:"permanentFile"},
  "vorn:cap:1":{k:"oneOrder"},
  "reyes:A:0:0":{k:"cruisersCarriers"},
  "reyes:A:0:1":{k:"launchOrder",n:.2},
  "reyes:A:1:0":{k:"secondWave"},
  "reyes:A:1:1":{k:"rehearsed",n:10},
  "reyes:A:2:0":{k:"fullGroup"},
  "reyes:A:2:1":{k:"escorts",n:.25},
  "reyes:cap:0":{k:"oneTarget",n:.35},
  "reyes:cap:1":{k:"standingGroup"},
  "maren:A:0:0":{k:"columnStraight",n:.25},
  "maren:A:0:1":{k:"overflow",n:10},
  "maren:A:1:0":{k:"bell"},
  "maren:A:1:1":{k:"rotation"},
  "maren:A:2:0":{k:"columnEndures",n:.25},
  "maren:A:2:1":{k:"filedArmor",n:15},
  "maren:cap:0":{k:"standardCovers",n:.2},
  "maren:cap:1":{k:"flagshipStandard",n:.1},
  "kassar:B:0:0":{k:"formation",n:10},"kassar:B:0:1":{k:"drillRevision"},"kassar:C:0:0":{k:"beacon",n:10},"kassar:C:0:1":{k:"standardForward",n:1},
  "vorn:B:0:0":{k:"formation",n:10},"vorn:B:0:1":{k:"drillRevision"},"vorn:C:0:0":{k:"beacon",n:10},"vorn:C:0:1":{k:"standardForward",n:1},
  "reyes:B:0:0":{k:"formation",n:10},"reyes:B:0:1":{k:"drillRevision"},"reyes:C:0:0":{k:"beacon",n:10},"reyes:C:0:1":{k:"standardForward",n:1},
  "maren:B:0:0":{k:"formation",n:10},"maren:B:0:1":{k:"drillRevision"},"maren:C:0:0":{k:"beacon",n:10},"maren:C:0:1":{k:"standardForward",n:1},
  // Issue 529: the last seven waiting rows. The four Chorus role rows (n: aim for strike and evasion for screen; m: the mend boost),
  // Spawned Before the Strike, The Brood Does Not Stop (n: the damage of the second strike), Scent in the Dark.
  "matriarch:B:0:0":{k:"roles",n:10,m:.1},"razormaw:B:0:0":{k:"roles",n:10,m:.1},"mending:B:0:0":{k:"roles",n:10,m:.1},"voice:B:0:0":{k:"roles",n:10,m:.1},
  "matriarch:A:1:1":{k:"spawnedStrike",n:.15},
  "matriarch:cap:1":{k:"broodNoStop",n:.5},
  "razormaw:A:1:1":{k:"scentDark",n:10}
};
// Issue 529: the tree skills whose text says "you may" ask the player yes or no when the Command is given. The bot, the sims
// and every test without an answer take "yes", which is what the skill did before the prompt existed.
// cmd: the Command that asks; q: the one line the prompt shows; yes and no: the two buttons.
const TREE_MAY={
  heldAccount:{cmd:'barrage',q:'Hold one ship\'s volley until that ship has moved this round?',yes:'Hold one volley',no:'Fire every volley now'},
  debtDue:{cmd:'barrage',q:'Delay the whole volley to the start of next round? It fires then with +20% damage.',yes:'Delay the volley',no:'Fire it now'},
  salvoTwoHands:{cmd:'hunt',q:'Hold the damage bonus for half your ships and spend it next round instead?',yes:'Hold half',no:'Spend it all now'},
  wingReserve:{cmd:'scramble',q:'Keep one extra wing unlaunched? It launches free at the start of next round.',yes:'Keep one back',no:'Launch them all'},
  secondWave:{cmd:'scramble',q:'Hold all extra wings and launch them at the start of next round instead?',yes:'Hold the wings',no:'Launch them now'},
  screensShift:{cmd:'iron',q:'Shift the wall: one ship takes 20 points more damage reduction, another 20 points less?',yes:'Shift the wall',no:'Keep it even'},
  platesShadow:{cmd:'iron',q:'Stack the wall on one ship: 75% less damage for it, 25% less for every other ship?',yes:'Stack the wall',no:'Keep it even'},
  weldMatters:{cmd:'restore',q:'Put one ship\'s whole repair share onto its most damaged section?',yes:'Weld one section',no:'Spread the repair'},
  scrapFront:{cmd:'restore',q:'Give the flagship\'s repair share, doubled, to one other ship?',yes:'Give it away',no:'Keep it'},
  growHurts:{cmd:'restore',q:'Put one ship\'s whole regrowth onto its most damaged section?',yes:'Grow one section',no:'Spread the regrowth'}
};
// Issue 529: Roles Assigned at Hatching. The three roles in prompt order, with the one line each button explains.
const TREE_ROLES=[{id:'strike',n:'Strike',d:'+10 aim'},{id:'screen',n:'Screen',d:'+10 evasion'},{id:'mend',n:'Mend',d:'repair and regrowth 10% stronger'}];
// Patron favour: grows with every boon you take from a patron
const FAVOUR_TIERS=[{at:0,n:'Listening'},{at:4,n:'Partial sync',d:'Its protocols are rare more often.'},{at:12,n:'Synced',d:'If it is in range of your run, you start with one of its protocols.'},{at:25,n:'Full sync',d:'Its protocols are never common.'}];
// R78 Q15 (issue 42): a Chorus run may eat one core it has not synced with in sector 3; each Chorus ship gains this much hull for the run
const CORE_EAT_HULL=0.1;
// Heat: optional rules after your first victory; each level adds 10% renown
// enemy fleet archetypes: the same budget spent three different ways, named per faction and shown on the map
const ARCHETYPES={
  swarm:{d:'Many light hulls. Flank batteries and flak shine; lances are wasted on them.',names:{voidsworn:'Frontier flotilla',hegemony:'Picket screen',corsair:'Wolfpack',chorus:'Brood swarm',ithar:'Sliver flight',deathless:'Mote cloud'}},
  heavy:{d:'Few, big hulls. Bring lances, torpedoes and a flank.',names:{voidsworn:'Bastion line',hegemony:'Line of battle',corsair:'Hulk convoy',chorus:'Bloat pod',ithar:'Prism line',deathless:'Phalanx'}},
  carrier:{d:'Built around a carrier and its wings. Fighters and flak pay off.',names:{voidsworn:'Hearth group',hegemony:'Carrier group',corsair:'Hulk den',chorus:'Brood cluster',ithar:'Aperture host',deathless:'Repair host'}}};
// node modifiers: a twist on one fight, shown on the map
const NODE_MODS={
  bounty:{n:'Bounty',short:'Bounty',d:'A price on this fleet: +50% credits, and they bring 10% more ships.'},
  veteran:{n:'Veteran captain',short:'Veteran',d:'Their largest ship has an elite captain.'}};
// sector conditions: each sector of a run has one, shown on the sector map and applied to every fight there
const SECTOR_CONDS={
  ion:{n:'Ion season',d:'Ion storms sweep every battlefield, and shields recharge 25% slower on both sides.',regen:.75,terr:'storm'},
  dark:{n:'Dark sector',d:'Thick nebulae choke every battlefield: more hexes where shots go wide (\u221215 to hit inside).',terr:'neb'},
  wreck:{n:'Wreck belt',d:'Old battle wreckage everywhere: more debris hexes (\u221210 to hit inside), and wreckage adds 15% to every battle\u2019s pay.',terr:'debris',cred:.15},
  war:{n:'War zone',d:'Every fight here draws reinforcements for one side or the other, and pays 20% more credits.',cred:.2,war:1},
  scarce:{n:'Scarcity',d:'Supply lines are cut: shipyards charge 20% more and repairs restore 25% less, but battles pay 25% more credits.',cred:.25,price:1.2,repair:.75}};
const HEAT={
  h_flag:{n:'Vengeful flagships',d:'Sector flagships have 20% more hull.',w:1},
  h_hunted:{n:'Hunted',d:'Enemy fleets are 15% larger.',w:2},
  h_elite:{n:'Veteran escorts',d:'One ship in every enemy fleet is an elite.',w:1},
  h_undying:{n:'Undying foes',d:'Any enemy ship may reassemble once when destroyed.',w:2},
  h_coffers:{n:'Lean coffers',d:'Shipyard prices are 25% higher.',w:1},
  h_repair:{n:'Thin repair crews',d:'Free repairs (repair docks, field repairs, event repairs and post-flagship regroups) restore half as much. Shipyard repairs are unaffected.',w:1},
  h_cmd:{n:'Slow orders',d:'Your Command reaches full power a round later.',w:1}};

// ---------- Patrons, boons and flagship aspects ----------
// Each run four of six patrons watch the crusade. Battles on the map carry a patron's sigil; win there and that patron offers three boons, take one.
// Boons change rules, not just numbers; rarity scales their strength (Common x1, Rare x1.5, Epic x2). Two patrons' boons together unlock duo boons.
const RARITY=[{n:'Common',m:1,col:'#cfc6b0'},{n:'Rare',m:1.5,col:'#62ccff'},{n:'Epic',m:2,col:'#c58bff'},{n:'Legendary',m:1,col:'#ff8a3d'}]; // B4 step 3: Legendary (index 3) is only ever a patron's legendary boon
const PATRONS={
  iron:{n:'K-1 Kovar, the Unbent',short:'Kovar',col:'#e0b04a',glyph:'K',theme:"Flank batteries, heavy armor, and holding formation",quote:"Lock your vector, soak the opening fire, and return double."},
  storm:{n:'V-2 Vyre, the Storm Queen',short:'Vyre',col:'#5fd4ff',glyph:'V',theme:"Shields, ion overload, and arc discharge",quote:"Drop their capacitors first; bare hulls break fast."},
  hunger:{n:'H-3 Calyx, "the Hunger Below"',short:'Calyx',col:'#7ddc6a',glyph:'H',theme:"Squadrons, boarding breaches, and battlefield feeding",quote:"Crack the shell and pull every spare frame back into the brood."},
  star:{n:'A-4 Astra, the Silent Star',short:'Astra',col:'#b48cff',glyph:'A',theme:"Lances, long-range precision, and critical strikes",quote:"Hold focus on one seam until the reactor opens."},
  rook:{n:'R-5 Rook, the Breaker',short:'Rook',col:'#ff6b5a',glyph:'R',theme:"High-G burns, ramming prows, and raw momentum",quote:"Push past thruster redline and drive straight through their line."},
  ember:{n:'S-6 Seren, the Last Flame',short:'Seren',col:'#ff9f3a',glyph:'S',theme:"Torpedoes, thermal fires, and chain detonations",quote:"Light one magazine and let the blast wave finish the rest."}};
const boonPct=x=>Math.round(x*100)+'%';
const BOONS={
  // Kharon
  i_broad:{p:'iron',n:'Thunder Flank',d:m=>`Flank guns deal +${boonPct(.2*m)} damage.`,fx:m=>({broadPct:.2*m})},
  i_still:{p:'iron',n:'Stationary Volley',d:m=>`Unmoved ships gain +${boonPct(.25*m)} flank and battery damage. Uses the larger of this and synchronized fire.`,fx:m=>({stillPct:.25*m})},
  i_plate:{p:'iron',n:'Unbent Plating',d:m=>`+${boonPct(.08*m)} armor across the fleet.`,fx:m=>({armor:.08*m})},
  i_brace:{p:'iron',n:'Iron Discipline',d:m=>`Bracing blocks an extra ${boonPct(.1*m)}. Direct volleys that hit it deal ${Math.round(18*m)} damage back; torpedoes do not.`,fx:m=>({riposte:Math.round(18*m),bracePlus:.1*m})},
  i_line:{p:'iron',n:'Unbroken Line',d:m=>`Ships next to another of your ships take ${boonPct(.12*m)} less hull damage.${m>=2?' Epic: they are also 5 harder to hit.':''}`,fx:m=>({lineGuard:.12*m,lineEv:m>=2?5:0})},
  // Vyre
  s_cap:{p:'storm',n:'Capacitor Surge',d:m=>`Shields +${boonPct(.2*m)} across the fleet.`,fx:m=>({shPct:.2*m})},
  s_arc:{p:'storm',n:'Arc Discharge',d:m=>`When your fire knocks out an enemy shield, its generator shorts for ${Math.round(9*m)} hull damage.`,fx:m=>({arcShort:Math.round(9*m)})},
  s_ion:{p:'storm',n:'Ion Lash',d:m=>`Your weapons gain +${+(.22*m).toFixed(2)} to their shield damage multiplier.`,fx:m=>({ionPlus:.22*m})},
  s_regen:{p:'storm',n:'Storm Mantle',d:m=>`Each turn, working shield generators restore an extra ${boonPct(.18*m)} of the shield pool.`,fx:m=>({stormRegen:.18*m})},
  s_ev:{p:'storm',n:'Lightning Reflex',d:m=>`+${Math.round(6*m)} evasion across the fleet.`,fx:m=>({ev:Math.round(6*m)})},
  // The Hunger
  h_hatch:{p:'hunger',n:'Swarm Hatch',d:m=>`Launch ships field an extra wing${m>=1.5?` and carry ${m>=2?'2 more spare wings':'1 more spare wing'}`:''}.`,fx:m=>({hangar:1,spareWings:m>=2?2:(m>=1.5?1:0)})},
  h_wings:{p:'hunger',n:'Ravenous Wings',d:m=>`Squadrons deal +${boonPct(.25*m)} damage.`,fx:m=>({sqPct:.25*m})},
  h_chitin:{p:'hunger',n:'Hardened Chitin',d:m=>`Squadrons have +${boonPct(.3*m)} hull.`,fx:m=>({sqHp:.3*m})},
  h_board:{p:'hunger',n:'Boarding Frenzy',d:m=>`Boarding parties fight as ${boonPct(.25*m)} more crew, and a boarding that does not take the ship always sabotages a system.`,fx:m=>({boardPct:.25*m})},
  h_feast:{p:'hunger',n:'Feast on the Fallen',d:m=>`When your squadron destroys a target, its carrier gains a spare wing and repairs ${boonPct(.05*m)} hull.`,fx:m=>({feast:.05*m})},
  // Astra
  a_lance:{p:'star',n:'Starlight Lances',d:m=>`Lances deal +${boonPct(.35*m)} damage.`,fx:m=>({lancePct:.35*m})},
  a_aim:{p:'star',n:'Silent Aim',d:m=>`+${Math.round(5*m)} aim for every weapon.`,fx:m=>({aim:Math.round(5*m)})},
  a_crit:{p:'star',n:'Killing Light',d:m=>`+${Math.round(6*m)}% critical chance, criticals deal x${+(1.5+.25*m).toFixed(2)}, and a critical volley damages a system where possible.`,fx:m=>({crit:Math.round(6*m),critMul:.25*m,critSys:1})},
  a_long:{p:'star',n:'Long Silence',d:m=>`Ignore the first ${Math.floor(m*1.5)} hex${Math.floor(m*1.5)>1?'es':''} of long-range penalty.${m>=2?' Epic: lances reach 1 hex further.':''}`,fx:m=>({longAim:Math.floor(m*1.5),lanceRange:m>=2?1:0})},
  a_rear:{p:'star',n:'Blind Spot',d:m=>`Hits on an enemy's rear arc deal +${boonPct(.25*m)} damage.`,fx:m=>({rearPct:.25*m})},
  // Rook
  r_burn:{p:'rook',n:'Afterburners',d:m=>`+${m>=2?2:1} speed across the fleet${m>=1.5?`, and +${m>=2?10:6} evasion`:''}.`,fx:m=>({speed:m>=2?2:1,ev:m>=2?10:m>=1.5?6:0})},
  r_prow:{p:'rook',n:'Battering Bow',d:m=>`Rams deal +${boonPct(.35*m)} damage and can take up to ${boonPct(.4+.1*m)} of a ship's hull; recoil halved.`,fx:m=>({ramPct:.35*m,ramCap:.1*m,ramGuard:.5})},
  r_mom:{p:'rook',n:'Momentum',d:m=>`Ships deal +${boonPct(.05*m)} damage for each hex they moved this activation (up to 4).`,fx:m=>({momPct:.05*m})},
  r_jink:{p:'rook',n:'Evasive Burn',d:m=>`Ships that moved 3+ hexes are ${Math.round(15*m)} harder to hit until their next turn.`,fx:m=>({burnEv:Math.round(15*m)})},
  r_shock:{p:'rook',n:'Shockwave',d:m=>`Rams also hit every other enemy next to the target for ${boonPct(.25*m)} of the ram damage.`,fx:m=>({ramSplash:.25*m})},
  // The Ember Choir
  e_war:{p:'ember',n:'Incendiary Warheads',d:m=>`Torpedoes deal +${boonPct(.25*m)} damage.`,fx:m=>({torpPct:.25*m})},
  e_reload:{p:'ember',n:'Hot Tubes',d:m=>`Torpedo reload time -1 turn, to a minimum of 1.${m>=1.5?` Torpedoes deal +${m>=2?'20':'10'}% damage.`:''}`,fx:m=>({torpCd:1,torpPct:m>=2?.2:(m>=1.5?.1:0)})},
  e_kindle:{p:'ember',n:'Kindling',d:m=>`Hull hits have a ${boonPct(.12*m)} chance to start a fire (fires burn ${6+Math.round(4*m)} a turn for 2 turns).`,fx:m=>({igniteCh:.12*m,fireDmg:Math.round(4*m)})},
  e_chain:{p:'ember',n:'Chain Reaction',d:m=>`Enemy ships you destroy explode, dealing ${Math.round(20*m)} damage to every enemy within 2 hexes.${m>=2?' Epic: the blast sets them burning.':''}`,fx:m=>({chainBoom:Math.round(20*m),chainFire:m>=2?1:0})},
  e_hunt:{p:'ember',n:'Funeral Pyre',d:m=>`+${boonPct(.2*m)} damage against ships already below half hull; hits there stop passive regrowth, feeding and reassembly.`,fx:m=>({huntPct:.2*m,pyre:1})},
  // Duo boons: need a boon from each of two patrons
  d_jugg:{duo:['iron','rook'],n:'Juggernaut',d:()=>'Rams deal +50% damage and the rammer takes no recoil.',fx:()=>({ramPct:.5,ramGuard:1})},
  d_bastion:{duo:['iron','storm'],n:'Fortress',d:()=>'Bracing also refills the shield pool and blocks an extra 10% of hull damage.',fx:()=>({bastion:1,bracePlus:.1})},
  d_ionlance:{duo:['storm','star'],n:'Ion Lance',d:()=>'Lances gain +1 to their shield damage multiplier.',fx:()=>({ionLance:1})},
  d_burnswarm:{duo:['hunger','ember'],n:'Burning Swarm',d:()=>'Squadron hull hits on ships have a 30% chance to start a fire.',fx:()=>({sqIgnite:.3})},
  d_hunter:{duo:['star','rook'],n:"Hunter's Line",d:()=>'Ships that moved 3+ hexes gain +25% critical chance.',fx:()=>({momCrit:25})},
  d_inferno:{duo:['ember','iron'],n:'Flank Inferno',d:()=>'Flank hull hits have a 40% chance to ignite ships for 10 a turn for 3 turns.',fx:()=>({broadIgnite:.4,fireLong:1,fireDmg:4})}};
// boons that only matter if the fleet has the right kit; offers skip them when it doesn't
// B4 step 3: rule-changing boons (one per patron) and a legendary per patron. A legendary is offered at an elite or flagship reward once you
// hold two boons from that patron (Hades style), always in the third slot; it never rolls otherwise (leg:true keeps it out of every normal pool).
Object.assign(BOONS,{
  i_wall:{p:'iron',n:'Shield Wall',d:m=>`Bracing covers every ship next to the braced ship too: they take the brace’s hull cut${m>1?` and an extra ${boonPct(.1*(m-1))} hull cut`:''} until its next turn.`,fx:m=>({wallBrace:1,wallPlus:.1*(m-1)})},
  s_chain:{p:'storm',n:'Chain Lightning',d:m=>`When your fire knocks out an enemy shield, its next recharge is ${Math.round(m/3*100)}% weaker.`,fx:m=>({chainSh:m/3})},
  h_brood:{p:'hunger',n:'Brood Harvest',d:m=>`Each enemy capital ship your fleet destroys lets your nearest carrier launch a free wing, if it has a free hex beside it${m>1?`, and repairs ${boonPct(.1*(m-1))} of its hull`:''}.`,fx:m=>({broodTithe:1,broodRepair:.1*(m-1)})},
  a_mark:{p:'star',n:'Marked for Death',d:m=>`Each round, the first enemy ship your lances hit is marked: your whole fleet aims ${Math.round(10*m)} better against it until the round ends.`,fx:m=>({markLance:m})},
  r_slip:{p:'rook',n:'Slip the Net',d:m=>`Your ships may move after firing, up to ${m>=2?'90% of':m>=1.5?'70% of':'half'} the movement they had left (without climbing over or diving under).`,fx:m=>({fade:m>=2?.9:(m>=1.5?.7:.5)})},
  e_spread:{p:'ember',n:'Spread Pattern',d:m=>`If a torpedo salvo misses, it bursts: its target and enemy ships within 1 hex take ${boonPct(.3*m)} of one torpedo\u2019s damage.`,fx:m=>({spread:.3*m})},
  L_iron:{p:'iron',leg:1,n:'Unbreakable',d:()=>'Legendary. Every ship survives its first killing blow each battle at 1 hull.',fx:()=>({lastStand:1})},
  L_storm:{p:'storm',leg:1,n:'Eye of the Storm',d:()=>'Legendary. Working shield generators refill the pool at the start of your turn, before storm damage.',fx:()=>({stormRegen:1})},
  L_hunger:{p:'hunger',leg:1,n:'Feast Without End',d:()=>'Legendary. Launch ships field two more wings and carry 99 spares.',fx:()=>({hangar:2,endless:1})},
  L_star:{p:'star',leg:1,n:'One Clean Line',d:()=>'Legendary. Lances hit at 95% (75% against Full burn) and pass straight through shields.',fx:()=>({lanceSure:1})},
  L_rook:{p:'rook',leg:1,n:'Unstoppable',d:()=>'Legendary. Rams deal 50% more, can take 70% of a ship’s hull, and the rammer takes no recoil.',fx:()=>({ramPct:.5,ramCap:.3,ramGuard:1})},
  L_ember:{p:'ember',leg:1,n:'Pyre of Stars',d:()=>'Legendary. Every enemy ship you destroy explodes for 40 damage to every enemy within 2 hexes.',fx:()=>({chainBoom:40})}});
const BOON_NEED={L_storm:'shields',h_brood:'carrier',a_mark:'lance',e_spread:'torp',L_hunger:'carrier',L_star:'lance',i_still:'still',s_cap:'shields',s_regen:'shields',d_bastion:'shields',i_broad:'broad',d_inferno:'broad',e_war:'torp',e_reload:'torp',a_lance:'lance',d_ionlance:'lance',h_hatch:'carrier',h_wings:'sq',h_chitin:'sq',h_feast:'sq',d_burnswarm:'sq'};
// the flagship's aspect is picked at the start of a run, from three offered at random
const ASPECTS={
  lancer:{n:'Spearhead Refit',d:'Your flagship’s forward guns deal +50% damage and reach 1 hex further, and it can turn once more each round to bring them to bear.',fx:{prowPct:.5,prowRange:1,turns:1}},
  hive:{n:'Carrier Frame',d:'Your flagship starts with a wing (+1 if it has a hangar); its wings deal +30% damage. Only a carrier flagship replaces lost wings.',fx:{hive:1,sqPct:.3}},
  ram:{n:'Ramming Rig',d:'Your flagship rams for +60% damage, can take up to 60% of a ship’s hull, takes no recoil, and has +1 speed.',fx:{ramPct:.6,ramCap:.2,ramGuard:1,speed:1}},
  bulwark:{n:'Bulwark Frame',d:'Your flagship has +70% hull and shields, ships next to it take 25% less hull damage, and enemy ships within 4 hexes that can fire on it must.',fx:{hpPct:.7,shPct:.7,guardAura:.25,taunt:4}},
  storm:{n:'Storm Array',d:'Your flagship gains +0.5 to weapon shield damage multipliers, and shields recharge twice as fast.',fx:{ionPlus:.5,regenPct:1}},
  admiral:{n:'Command Hull',d:'Your Admiral’s Command starts one power level higher (full power from round 2), and your flagship gets +10 aim.',fx:{cmdTier:1,aim:10}}};

// One-battle rewards promised by the beat 3 choices.
const BEAT3_REWARDS={power:.25,dmgPct:.1,core:{corsair:'rook',chorus:'hunger'}};
// Approved story beat 3 text. Source: contrib/muse/design/story_beat3_2026_11/.
const STORY_BEAT3={
  "voidsworn": {
    "id": "arc_vs_owed",
    "t": "The Siphon at the Rim",
    "fight": false,
    "o": [
      {
        "t": "Overcharge the flagship with Seren's core fire",
        "r": {
          "dmgFlag": 0.25,
          "power": 1
        },
        "tx": "Your engineers bleed Seren's thermal charge straight into the flagship's main bus. Every gun on the hull runs white-hot for the coming battle, though the heat buckles a quarter of the inner bulkheads before you even cross the jump."
      },
      {
        "t": "Keep the reactors clean and patch the fleet",
        "r": {
          "repair": 0.15
        },
        "tx": "You lock the core casing shut and put the welders on standard hull repairs instead. The Roll-master nods once; the gunnery crews grumble over their cooling coils, though every ship enters the rim intact."
      }
    ],
    "lines": [
      "Roll-master: \"There's the siphon relay, Admiral, drinking Vesper's light straight across the black hole's rim. The last expedition overdrove their flagship with Seren's charge right here.\"",
      "Captain: \"And did they make it home?\"",
      "Roll-master: \"No. They cracked the outer collector rings wide enough for us to reach it, though. Your call whether we pay the same price or fight it cold.\""
    ],
    "debrief": "Every captain chalked the fleet's decision beside their helm station before entering firing range.",
    "learning": "Win or lose, the next expedition out of Vesper will pull your flight recorders from the rim and build their approach around what worked here.",
    "spotlights": {
      "vex": "Vex checks the chalked crew roll beside the dorsal airlock before every jump, quietly adding a single date beneath the last column.",
      "malek": "Torben runs a gloved hand along the loaded torpedo rails. 'Every warhead in this bay is paid for by a frozen farm moon back in the Reach.'",
      "ashgrove": "Ashgrove taps her headset mic as the launch lights turn amber. 'Tight lanes, kids. Bring those fighters back to my rails in one piece.'",
      "thale": "Thale pours lukewarm tea from a battered thermos while the proximity alarms chirp. 'Meridian wrote Vesper off seventy years ago. Let's make them check their math again.'"
    }
  },
  "hegemony": {
    "id": "arc_hg_minute",
    "t": "The Unlogged Minute",
    "fight": false,
    "o": [
      {
        "t": "Cut the Registry links for one minute and speak to the crews",
        "r": {
          "xp": 25,
          "syncDown": 1
        },
        "tx": "Every officer drops off the Meridian net simultaneously. Without live telemetry, your synchronized fire lags on round one, yet the crews hear their admiral speak without a Registry timestamp for the first time in the campaign."
      },
      {
        "t": "Stay linked and secure the rim by the book",
        "r": {
          "credits": 40
        },
        "tx": "Every link stays green, Meridian credits your operational ledger for strict compliance, and the column locks into formation at the Hollow Sun perimeter. Your flag captain folds the paper casualty list back into her jacket without comment."
      }
    ],
    "lines": [
      "Flag captain: \"Admiral, we are within visual range of the Hollow Sun perimeter. Before a decisive engagement, line commanders customarily drop their Registry links for sixty seconds.\"",
      "Admiral: \"To say what, Captain?\"",
      "Flag captain: \"The names of the crews we lost reaching this sector, Admiral. Meridian only archives serial numbers.\""
    ],
    "debrief": "Meridian updated its casualty projection for the Hollow Sun perimeter twice during the fight, without attaching an explanation.",
    "learning": "Regardless of the outcome, an unsigned addendum enters the Directorate tactical manual via slow courier, arriving one sector late and still saving more crews than the official projection.",
    "spotlights": {
      "kassar": "Kassar runs two extra timing drills before the approach. 'Clean volleys end battles quickly, and short battles cost fewer hulls.'",
      "vorn": "Vorn wipes three conservative firing plots off the holotable until only one razor-thin intercept remains. 'That is the shot that breaks their command deck.'",
      "reyes": "Reyes broadcasts Meridian's predicted squadron loss rate over the flight channel so every pilot knows the exact number they intend to beat.",
      "maren": "Maren inspects every bow deflector reading himself before strapping in. 'Meridian tracks tonnage. I track who gets off my ship at Meridian Yards.'"
    }
  },
  "corsair": {
    "id": "arc_hb_rook",
    "t": "Rook in the Wreck Field",
    "fight": false,
    "o": [
      {
        "t": "Hold heavy guns off the core and breach for Rook intact",
        "r": {
          "dmgFlag": 0.15,
          "core": 1
        },
        "tx": "Your gunners hold fire on the core's containment cage while your flagship eats the return salvo head-on. If your crews drag Rook out of those wrecks in chains, every den in the Ashfall will hear about it."
      },
      {
        "t": "Open every weapon and smash straight through",
        "r": {
          "xp": 25
        },
        "tx": "Nobody holds back for clean salvage. Your crews push the reactors red-hot and tear into the enemy line full tilt, ready to crack the wrecks and Rook right along with them if that's what winning takes."
      }
    ],
    "lines": [
      "Howler: \"Scope lock confirmed, Warlord! R-5 Rook's sitting right in the middle of that wreck pile, pulsing hotter than a cruiser core!\"",
      "Warlord: \"Good! Means we didn't haul all this iron across three sectors for nothing. Arm the breach clamps!\""
    ],
    "debrief": "No cheering on the open band after the guns cool. Just captains tallying kills, hauling intact plates, and checking who didn't make it back.",
    "learning": "The plates bolted to your hulls tell the whole belt what worked out here, and the next pack that hunts the Hollow Sun will study every weld seam.",
    "spotlights": {
      "grax": "Grax slams the throttle past the redline and laughs over open comms as the breach clamps bite into enemy plate, half the pack howling back on the same channel.",
      "sable": "Sable kills all exterior lights until only the red cockpit glow remains. 'Big proud ships always forget to armor their radiator vents.'",
      "mott": "Old Mott spits a chewed rivet pin into a scrap bucket and checks the bay telemetry. 'Forty captains tried taking my command chair. Don't make me count to forty-two today.'",
      "vesh": "Vesh zooms the tactical feed onto the opposing flagship's bow trim, muttering measurements to her weld crew. 'Don't you dare slag that dorsal array!'"
    }
  },
  "chorus": {
    "id": "arc_ch_crucible",
    "t": "The Two Throats at Ardent",
    "fight": false,
    "o": [
      {
        "t": "Let Memory call out to the Lattice cores",
        "r": {
          "core": 1,
          "dmgPctDown": 1
        },
        "tx": "Memory reaches toward the Hollow Sun using the dead Fleshwrights' old access codes, and a dormant core responds with fresh protocols. Yet the borrowed maker cadence makes our hunter broods hesitate a fraction of a second on the kill."
      },
      {
        "t": "Drown Memory and let Hunger take full control",
        "r": {
          "dmgPctUp": 1
        },
        "tx": "We clamp the old maker voices shut under layers of fresh tissue. The swarm surges forward faster and cleaner, pure thermal predation aimed straight at the cores."
      }
    ],
    "lines": [
      "Memory: \"Ardent's ruins... our makers grew us in cold vats to punish Eclipse for killing this star. We still remember their control ciphers.\"",
      "Hunger: \"Ciphers don't fill brood-sacs. Five hot cores sit right behind that fleet. Tear through!\"",
      "The Swarm: \"One choice shapes the next clutch we hatch.\""
    ],
    "debrief": "Every brood-chamber in the swarm absorbs the chemical shift before the spores even settle.",
    "learning": "Win or lose, the next swarm grown from our surviving spores carries that balance straight into its neural sacs.",
    "spotlights": {
      "matriarch": "The Matriarch opens all nine brood-valves toward the black hole's rim, drinking the stray radiation while her young stir against the membranes.",
      "razormaw": "Red Undertow surges ahead of the main cluster with scorched hull plating still stuck to its forward spines, impatient to close.",
      "mending": "The Mending Throng knits fresh chitin across every scarred seam between jumps, keeping the swarm whole for the final push.",
      "voice": "Under the wet thrum of acid sacs, the Voice broadcasts a single broken Starwright launch coordinate that makes enemy sensors glitch."
    }
  },
  "ithar": {
    "id": "arc_gw_flaw",
    "t": "The Last Lens & the Killing Flaw",
    "fight": false,
    "o": [
      {
        "t": "Fly the corrected slow arc to avoid the old trap",
        "r": {
          "weak": 1,
          "clock": 1
        },
        "tx": "You swing the fleet along the corrected vector your ancestors paid for with their ships. {rival} spots the wider approach early, yet you enter the lens's orbit knowing the exact firing blind spot that killed the first voyage."
      },
      {
        "t": "Hold the fast burn straight for the lens mounting",
        "r": {
          "xp": 20
        },
        "tx": "You commit at full speed straight down the hazardous lane to deny {rival} time to fortify the lens. Every captain runs razor-thin tolerances, shaving past the exact debris field that claimed the old fleet."
      }
    ],
    "lines": [
      "Lens-keeper: \"There hangs the last primary lens of Ardent, Captain, and our recorders just pulled the full optical replay of the fleet that died trying to recover it three centuries ago.\"",
      "Captain: \"They turned too early into the mounting's shadow.\"",
      "Lens-keeper: \"Exactly. Take the wide correction and lose surprise, or gamble our shields on outrunning the same mistake.\""
    ],
    "debrief": "Every bridge crew watched the old optical replay before locking weapons, their inlays pulsing pale violet in quiet tribute.",
    "learning": "Whether this fleet carries the lens home or breaks apart in the debris belt, the optical forge will pull your telemetry and cast the next expedition sharper.",
    "spotlights": {
      "aelith": "Tamsa fans her starling wings wide around the aperture bays, checking every flight vector through rippling bands of blue-white light.",
      "vaelen": "Saro says nothing across three full minutes of approach, adjusting the primary mirror by fractions of a degree until the focal line locks dead center.",
      "thorne": "Vell tilts the outer vanes into the black hole's halo, splitting the flagship's silhouette into four clean radar ghosts.",
      "mirelle": "Brin brings the prism wards up to full brilliance around the smaller escorts, refusing to let another family line end on this rim."
    }
  },
  "deathless": {
    "id": "arc_ec_count",
    "t": "The Final Backup Window",
    "fight": false,
    "o": [
      {
        "t": "Reserve the last clean Archive sync for the command frame",
        "r": {
          "xp": 25
        },
        "tx": "You lock the high-bandwidth uplink onto the flagship's bridge core before committing to the stellar frame. If the command hull breaks, your tactical memory survives intact; the escort minds go in knowing they'll wake missing months."
      },
      {
        "t": "Spread the Archive pass across the escort crews",
        "r": {
          "repair": 0.25
        },
        "tx": "You divert the backup window and repair swarms across every escort in the line, leaving your own mind running on an older stamp. 'If I wake up missing this sector,' you signal across the formation, 'tell me whether the new sun lit.'"
      }
    ],
    "lines": [
      "Flag officer: \"The stellar frame sits dead ahead, Commander, waiting on the last cores. Interference from Ardent's gravity well gives us bandwidth for one clean Archive sync before contact.\"",
      "Commander: \"A thousand years in cold metal teaches you what's worth preserving. Allocate the window and bring the corona arcs online.\""
    ],
    "debrief": "Before opening fire, every ship displayed the last optical capture of Ardent's noon across its bridge glass, holding it three seconds past regulation.",
    "learning": "Win or lose, the Archive retains this entire engagement. Eclipse won't send strangers back to Ardent's rim; it will wake this exact fleet again with every mistake corrected.",
    "spotlights": {
      "nekhet": "Aurex's monumental ring of floating plates shifts half a degree toward the stellar frame, white-gold light steady behind the visor.",
      "sekhmar": "Vessane counts the opposing hulls one by one, verifying every hull's drone-weld tolerance against a thousand-year ignition chart.",
      "anuket": "Ostrel trims every stray emitter down to background noise. 'Continuity takes discipline; panic is what corrupts a backup.'",
      "khepra": "Seveth checks the twice-welded bow plates and signals ready. After two restorations, another siege at Ardent's rim feels almost routine."
    }
  }
};
