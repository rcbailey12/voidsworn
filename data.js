// ======================= DATA =======================
const W = {
  autocannon:{n:'Autocannon',k:'battery',shots:3,dmg:5,r:4,opt:2,acc:80,fall:8,crit:5},
  flak:{n:'Flak battery',k:'flak',shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6},
  battery:{n:'Macro battery',k:'battery',shots:4,dmg:6,r:5,opt:3,acc:72,fall:8,crit:5},
  hbattery:{n:'Heavy macro battery',k:'battery',shots:5,dmg:7,r:5,opt:3,acc:72,fall:8,crit:6},
  lance:{n:'Lance array',k:'lance',shots:1,dmg:20,r:7,opt:6,acc:82,fall:6,pierce:.6,crit:10},
  torp:{n:'Torpedo salvo',k:'torp',shots:1,dmg:42,r:6,opt:6,acc:64,fall:0,pierce:.3,crit:15,cd:2,evMult:2},
  turret:{n:'Dorsal turret',k:'battery',shots:2,dmg:8,r:5,opt:3,acc:74,fall:8,crit:5},
  laser:{n:'Laser cannon',k:'battery',shots:2,dmg:7,r:4,opt:3,acc:80,fall:8,crit:5},
  turbo:{n:'Turbolaser',k:'battery',shots:2,dmg:9,r:5,opt:3,acc:74,fall:8,crit:5},
  hturbo:{n:'Heavy turbolaser',k:'battery',shots:3,dmg:9,r:6,opt:4,acc:72,fall:7,crit:6},
  ion:{n:'Ion cannon',k:'lance',shots:1,dmg:12,r:6,opt:5,acc:80,fall:6,ion:2.5,crit:4},
  scatter:{n:'Scatter cannons',k:'battery',shots:5,dmg:5,r:3,opt:2,acc:78,fall:10,crit:6},
  htorp:{n:'Heavy torpedoes',k:'torp',shots:2,dmg:34,r:6,opt:6,acc:60,fall:0,pierce:.3,crit:15,cd:2,evMult:2},
  tendril:{n:'Boarding tendrils',k:'bio',shots:2,dmg:13,r:1,opt:1,acc:85,fall:0,pierce:.5,crit:12},
  bioplasma:{n:'Bio-plasma',k:'bio',shots:2,dmg:12,r:4,opt:3,acc:74,fall:8,pierce:.2,crit:8},
  spores:{n:'Spore mines',k:'flak',shots:3,dmg:4,r:2,opt:2,acc:78,fall:8,vsSq:3,vsCap:.6},
  pulsar:{n:'Pulsar lance',k:'lance',shots:2,dmg:12,r:6,opt:5,acc:80,fall:6,pierce:.6,crit:10},
  startorp:{n:'Star torpedo',k:'torp',shots:1,dmg:38,r:5,opt:5,acc:66,fall:0,pierce:.4,crit:15,cd:2,evMult:2},
  gauss:{n:'Gauss flayer',k:'gauss',shots:3,dmg:6,r:5,opt:3,acc:74,fall:8,pierce:0.6,crit:5},
  gsentry:{n:'Gauss sentries',k:'flak',shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6},
  doom:{n:'Doom arc',k:'lance',shots:1,dmg:40,r:5,opt:4,acc:78,fall:6,pierce:.6,crit:12,cd:2},
  shard:{n:'Shuriken cannon',k:'battery',shots:3,dmg:6,r:4,opt:2,acc:80,fall:8,crit:6,vsSq:1.6},
  guns:{n:'Interceptor guns',k:'sq',shots:3,dmg:4,r:1,opt:1,acc:82,fall:0,vsSq:2.2,vsCap:.5},
  bombs:{n:'Bomb payload',k:'sq',shots:2,dmg:9,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.2,crit:10},
  sporeb:{n:'Spore burst',k:'sq',shots:2,dmg:10,r:1,opt:1,acc:78,fall:0,pierce:.6,vsSq:.3,crit:8},
};
const ARC_NAME = {F:'Prow',P:'Port broadside',S:'Starboard broadside',T:'Turret (all arcs)',R:'Rear'};
const KIND_NAME = {battery:'Battery',lance:'Lance',torp:'Torpedo',flak:'Point defense',bio:'Bio-weapon',gauss:'Gauss',sq:'Squadron'};

// Ship templates. size = draw scale; cp = command points.
// v46: each faction names (and draws) its guns its own way; the numbers underneath are unchanged until the v47 mechanics pass
const FAC_WNAMES={
  voidsworn:{autocannon:'Las-repeater',battery:'Las-battery',hbattery:'Heavy las-broadside',turret:'Las-turret',lance:'Penance lance',torp:'Hellfire torpedo',flak:'Censer flak'},
  hegemony:{laser:'Plasma cannon',turbo:'Plasma lance',hturbo:'Heavy plasma lance',ion:'Ion cannon',flak:'Picket lasers'},
  corsair:{autocannon:'Autocannon',scatter:'Scrap scatter gun',turret:'Junk turret',torp:'Rattle-rocket pod',htorp:'Heavy rocket pod',flak:'Chaff guns'},
  chorus:{bioplasma:'Spine volley',tendril:'Boarding tendrils',spores:'Spore cloud',sporeb:'Acid sacs'},
  ithar:{shard:'Prism shards',pulsar:'Pulsar lance',startorp:'Star torpedo',turret:'Needle beam',flak:'Mirror veil'},
  deathless:{gauss:'Gauss flayer',doom:'Doom arc',gsentry:'Gauss pylon',flak:'Gauss shredder'}};
function wName(fac,id){ return (FAC_WNAMES[fac]&&FAC_WNAMES[fac][id])||(W[id]&&W[id].n)||id; }
// v48 faction weapon traits: same hulls and budgets, but each faction's guns behave differently
const WTRAITS={
  las:{d:'holds its aim at long range',f:w=>{ w.fall=Math.ceil(w.fall/2); w.acc+=4; }},
  hellfire:{d:'sets the target burning',f:w=>{ w.ignite=1; }},
  plasma:{d:'a quarter burns through shields',f:w=>{ w.pierce=Math.max(w.pierce||0,.25); w.dmg+=1; }},
  scrap:{d:'an extra shot, wild aim, lucky crits',f:w=>{ w.shots+=1; w.acc-=12; w.crit=(w.crit||0)+3; }},
  rockets:{d:'a rocket salvo: hard to dodge, but point defense can shoot rockets down',f:w=>{ w.shots*=3; w.dmg=Math.round(w.dmg/2.9); w.acc+=2; w.evMult=1.5; w.rockets=1; }},
  spines:{d:'each hit strips 3% armor (down to 15% less)',f:w=>{ w.shred=.03; }},
  acid:{d:'acid eats 4 hull a turn for 2 turns, through shields and armor',f:w=>{ w.acid=1; }},
  needle:{d:'precise: better aim and more criticals',f:w=>{ w.acc+=6; w.crit=(w.crit||0)+8; }},
  star:{d:'fast: hard to dodge',f:w=>{ w.evMult=1.2; }},
  gauss:{d:'ignores half of armor',f:w=>{ w.armorPierce=.5; }}};
const FAC_WTRAIT={voidsworn:{autocannon:'las',battery:'las',hbattery:'las',turret:'las',torp:'hellfire'},hegemony:{laser:'plasma',turbo:'plasma',hturbo:'plasma'},
  corsair:{autocannon:'scrap',scatter:'scrap',turret:'scrap',torp:'rockets',htorp:'rockets'},chorus:{bioplasma:'spines',tendril:'acid',sporeb:'acid'},
  ithar:{shard:'needle',turret:'needle',startorp:'star'},deathless:{gauss:'gauss',doom:'gauss'}};
function nameWeapons(fac,list){ for(const w of list){ w.n=wName(fac,w.id); const tk=!(typeof process!=='undefined'&&process.env&&process.env.NOTRAITS)&&FAC_WTRAIT[fac]&&FAC_WTRAIT[fac][w.id]; if(tk&&WTRAITS[tk]&&!w.trait){ w.trait=tk; WTRAITS[tk].f(w); } } return list; }

const HULLS = {
  // ---- player: Voidsworn gothic fleet
  warden:{n:'Warden-class frigate',cls:'Frigate',fac:'voidsworn',size:.5,cp:1,hp:45,sh:10,rg:5,ar:.1,sp:5,tn:3,ev:20,w:[['autocannon','F'],['flak','T']],ab:'evasive',slots:1,cost:70},
  harrow:{n:'Harrow-class destroyer',cls:'Destroyer',fac:'voidsworn',size:.6,cp:2,hp:78,sh:14,rg:6,ar:.15,sp:4,tn:2,ev:12,w:[['torp','F'],['turret','T']],ab:'reload',slots:1,cost:130},
  penitent:{n:'Penitent-class cruiser',cls:'Cruiser',fac:'voidsworn',size:.76,cp:3,hp:120,sh:20,rg:8,ar:.2,sp:3,tn:2,ev:5,w:[['battery','P'],['battery','S'],['lance','F']],ab:'focus',slots:2,cost:200},
  reliquary:{n:'Reliquary-class carrier',cls:'Carrier',fac:'voidsworn',size:.84,cp:4,hp:130,sh:22,rg:9,ar:.15,sp:2,tn:1,ev:0,w:[['turret','T'],['flak','T']],ab:'launch',hangar:2,slots:2,cost:260},
  cathedral:{n:'Cathedral-class battleship',cls:'Battleship',fac:'voidsworn',size:.95,cp:5,hp:220,sh:30,rg:12,ar:.3,sp:2,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['lance','F'],['flak','T']],ab:'surge',slots:3,cost:340},
  ascendant:{n:'Ascendant-class dreadnought',cls:'Dreadnought',fac:'voidsworn',size:1.18,cp:8,hp:370,sh:32,rg:15,ar:.35,sp:1,tn:1,ev:0,w:[['hbattery','P'],['hbattery','S'],['turret','T'],['flak','T']],ab:'nova',slots:3,cost:520,unique:true},
  // ---- squadrons (shared)
  fighter:{n:'Fighter wing',cls:'Squadron',size:.34,cp:0,hp:18,sh:0,rg:0,ar:0,sp:6,tn:9,ev:35,w:[['guns','T']],sq:'fighter'},
  bomber:{n:'Bomber wing',cls:'Squadron',size:.34,cp:0,hp:28,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['bombs','T']],sq:'bomber'},
  spore:{n:'Spore swarm',cls:'Squadron',fac:'chorus',size:.34,cp:0,hp:26,sh:0,rg:0,ar:0,sp:5,tn:9,ev:25,w:[['sporeb','T']],sq:'bomber'},
  // ---- Hegemony Navy
  h_picket:{n:'Hegemony picket',cls:'Frigate',fac:'hegemony',size:.5,cp:1,hp:40,sh:10,rg:5,ar:.1,sp:5,tn:3,ev:18,w:[['laser','F'],['flak','T']],ab:'evasive'},
  h_interdictor:{n:'Interdictor destroyer',cls:'Destroyer',fac:'hegemony',size:.6,cp:2,hp:74,sh:18,rg:7,ar:.15,sp:4,tn:2,ev:10,w:[['ion','F'],['turbo','T']],ab:'ionpulse'},
  h_vanguard:{n:'Vanguard star cruiser',cls:'Cruiser',fac:'hegemony',size:.78,cp:4,hp:140,sh:24,rg:10,ar:.2,sp:3,tn:1,ev:4,w:[['turbo','T'],['turbo','T'],['ion','F']],ab:'launch',hangar:1},
  h_dominion:{n:'Dominion star dreadnought',cls:'Battleship',fac:'hegemony',size:.98,cp:6,hp:230,sh:32,rg:12,ar:.25,sp:2,tn:1,ev:0,w:[['hturbo','P'],['hturbo','S'],['ion','F'],['flak','T']],ab:'launch',hangar:1},
  h_boss:{n:'The Iron Mandate',cls:'Super-dreadnought',fac:'hegemony',size:1.3,cp:12,hp:560,sh:40,rg:10,ar:.3,sp:1,tn:1,ev:0,w:[['hturbo','P'],['hturbo','S'],['turbo','T'],['ion','F'],['flak','T']],ab:'nova',boss:true},
  // ---- Ashfall Corsairs
  c_raider:{n:'Corsair raider',cls:'Frigate',fac:'corsair',size:.48,cp:1,hp:46,sh:8,rg:4,ar:.05,sp:6,tn:3,ev:28,w:[['autocannon','T']],ab:'overburn'},
  c_reaver:{n:'Corsair reaver',cls:'Destroyer',fac:'corsair',size:.6,cp:2,hp:68,sh:10,rg:5,ar:.1,sp:5,tn:2,ev:15,w:[['torp','F'],['scatter','S']],ab:'reload'},
  c_marauder:{n:'Corsair marauder',cls:'Cruiser',fac:'corsair',size:.74,cp:3,hp:120,sh:16,rg:7,ar:.15,sp:4,tn:2,ev:6,w:[['scatter','P'],['scatter','S'],['torp','F'],['flak','T']],ab:'overburn'},
  c_hulk:{n:'Corsair hulk-carrier',cls:'Carrier',fac:'corsair',size:.86,cp:4,hp:170,sh:16,rg:6,ar:.2,sp:2,tn:1,ev:0,w:[['turret','T'],['turret','T']],ab:'launch',hangar:2},
  c_boss:{n:"Warlord's Pyre-Barge",cls:'Battle-barge',fac:'corsair',size:1.22,cp:10,hp:600,sh:30,rg:8,ar:.25,sp:2,tn:1,ev:0,w:[['scatter','P'],['scatter','S'],['htorp','F'],['flak','T']],ab:'launch',hangar:2,boss:true},
  // ---- The Chorus (bio-swarm)
  b_drone:{n:'Chorus drone-spawn',cls:'Frigate',fac:'chorus',size:.48,cp:1,hp:46,sh:0,rg:0,ar:.05,sp:5,tn:3,ev:15,w:[['tendril','T']],ab:'regrow',regen:5},
  b_spitter:{n:'Chorus spitter',cls:'Destroyer',fac:'chorus',size:.6,cp:2,hp:82,sh:0,rg:0,ar:.1,sp:4,tn:2,ev:8,w:[['bioplasma','T'],['bioplasma','F']],ab:'regrow',regen:6},
  b_razor:{n:'Chorus razorfiend',cls:'Cruiser',fac:'chorus',size:.76,cp:3,hp:150,sh:0,rg:0,ar:.2,sp:4,tn:2,ev:4,w:[['tendril','T'],['bioplasma','F']],ab:'frenzy',regen:9},
  b_brood:{n:'Chorus brood-mother',cls:'Carrier',fac:'chorus',size:.9,cp:5,hp:200,sh:0,rg:0,ar:.2,sp:2,tn:1,ev:0,w:[['bioplasma','F'],['spores','T']],ab:'launch',hangar:3,regen:10},
  b_boss:{n:'Hive Leviathan',cls:'Bio-titan',fac:'chorus',size:1.3,cp:12,hp:650,sh:0,rg:0,ar:.25,sp:2,tn:1,ev:0,w:[['bioplasma','F'],['bioplasma','F'],['tendril','T'],['spores','T']],ab:'launch',hangar:3,regen:20,boss:true},
  // ---- The Ithar (elder race)
  i_wisp:{n:'Ithar wisp',cls:'Frigate',fac:'ithar',size:.46,cp:1,hp:30,sh:12,rg:6,ar:0,sp:7,tn:3,ev:28,w:[['shard','F']],ab:'blink'},
  i_blade:{n:'Ithar shadowblade',cls:'Destroyer',fac:'ithar',size:.58,cp:2,hp:60,sh:16,rg:8,ar:0,sp:6,tn:3,ev:24,w:[['shard','F'],['startorp','F']],ab:'blink'},
  i_song:{n:'Ithar songship',cls:'Cruiser',fac:'ithar',size:.74,cp:4,hp:90,sh:26,rg:10,ar:.05,sp:5,tn:2,ev:16,w:[['pulsar','F'],['pulsar','F'],['turret','T']],ab:'surge'},
  i_carrier:{n:'Ithar wraithcarrier',cls:'Carrier',fac:'ithar',size:.84,cp:5,hp:140,sh:28,rg:10,ar:.05,sp:4,tn:2,ev:12,w:[['pulsar','F'],['turret','T']],ab:'launch',hangar:2},
  i_boss:{n:'Worldsong Ark',cls:'Ark',fac:'ithar',size:1.26,cp:11,hp:470,sh:34,rg:14,ar:.2,sp:3,tn:2,ev:6,w:[['pulsar','F'],['pulsar','F'],['pulsar','T'],['turret','T'],['flak','T']],ab:'surge',boss:true},
  // ---- The Deathless Dynasty
  d_scythe:{n:'Deathless scythe',cls:'Frigate',fac:'deathless',size:.5,cp:1,hp:56,sh:0,rg:0,ar:.2,sp:4,tn:2,ev:14,w:[['gauss','T']],ab:'phase',regen:3,reanimate:true},
  d_jackal:{n:'Deathless jackal',cls:'Destroyer',fac:'deathless',size:.62,cp:2,hp:110,sh:0,rg:0,ar:.25,sp:3,tn:2,ev:6,w:[['gauss','T'],['gauss','F']],ab:'phase',regen:3,reanimate:true},
  d_harvester:{n:'Deathless harvester',cls:'Cruiser',fac:'deathless',size:.82,cp:4,hp:145,sh:0,rg:0,ar:.3,sp:2,tn:1,ev:0,w:[['gauss','T'],['gauss','T'],['doom','F'],['gsentry','T']],ab:'reclaim',regen:4,reanimate:true},
  d_boss:{n:'The Undying Throne',cls:'Tomb-ark',fac:'deathless',size:1.3,cp:12,hp:480,sh:0,rg:0,ar:.35,sp:1,tn:1,ev:0,w:[['gauss','T'],['gauss','T'],['doom','F'],['flak','T']],ab:'nova',regen:8,boss:true},
};

// v50 drives: how each faction bends the thruster rules (battle.js MOVE_BASE). n/d show in the ship panel and codex.
const MOVE_RULES={
  voidsworn:{rake:.2,n:'Broadside doctrine',d:'Port and starboard guns hit 20% harder after moving 2+ hexes (others get 10%).'},
  hegemony:{rev:1,n:'Retro thrusters',d:'Backing off one hex costs 1 movement instead of 2.'},
  corsair:{slip:1,n:'Bolted burners',d:'Sideslips cost 1 movement instead of 2.'},
  chorus:{pivot:1,n:'Living hull',d:'The first turn each round costs no movement.'},
  ithar:{evadeAt:2,evade:10,n:'Fan sails',d:'After moving 2+ hexes, enemies get \u221210 to hit it (others need 3 hexes for \u22125).'},
  deathless:{over:0,n:'Phase drive',d:'Passes through rocks, wrecks and enemy ships at no extra cost.'}};
const FACTIONS = {
  voidsworn:{n:'Voidsworn Crusade',boss:'ascendant',roster:['warden','harrow','penitent','reliquary','cathedral'],hull:'#4a4440',trim:'#c8501f',glow:'#ff7a2a',style:'gothic',blurb:'Gothic crusader battleships. Heavy armor, lance batteries and broadsides that hit like a cathedral falling.'},
  hegemony:{n:'Hegemony Navy',hull:'#c4ccd5',trim:'#3a78d0',glow:'#5fa0ff',style:'wedge',
    blurb:'An imperial war-machine of wedge-hulled destroyers. Ion cannons strip shields; carriers launch fighter screens.',
    roster:['h_picket','h_interdictor','h_vanguard','h_dominion'],boss:'h_boss',sq:'fighter'},
  corsair:{n:'Ashfall Corsairs',hull:'#6a2c22',trim:'#b8402a',glow:'#e0402c',style:'junk',
    blurb:'Pirate raiders in stolen hulls. Fast, thin shields, and far too many torpedoes.',
    roster:['c_raider','c_reaver','c_marauder','c_hulk'],boss:'c_boss',sq:'bomber'},
  chorus:{n:'The Chorus',hull:'#57364c',trim:'#a4913a',glow:'#d6d24a',style:'bio',
    blurb:'A hungering bio-swarm. No shields at all, but their flesh knits back together every round.',
    roster:['b_drone','b_spitter','b_razor','b_brood'],boss:'b_boss',sq:'spore'},
  ithar:{n:'The Ithar',hull:'#eef3f1',trim:'#d7c88a',glow:'#9fffd2',style:'sail',
    blurb:'An ancient, dying elder race. Blindingly fast, heavily shielded, fragile once the shields fall.',
    roster:['i_wisp','i_blade','i_song','i_carrier'],boss:'i_boss',sq:'fighter'},
  deathless:{n:'The Deathless Dynasty',hull:'#1d2220',trim:'#1fbf4a',glow:'#3dff6a',style:'tomb',
    blurb:'Machine necropolis-ships. Gauss weapons tear through shields, and wrecks sometimes stand back up.',
    roster:['d_scythe','d_jackal','d_harvester'],boss:'d_boss',sq:null},
};
const SECTOR_POOL = [['corsair','hegemony'],['chorus','ithar','hegemony'],['deathless','chorus','ithar']];

const ABILITIES = {
  evasive:{n:'Evasive burn',d:'+25 evasion until your next turn and +2 movement now.',cd:3},
  reload:{n:'Reload torpedoes',d:'Torpedo tubes are ready to fire again immediately.',cd:3},
  focus:{n:'Concentrated fire',d:'All of this ship\u2019s weapons deal +30% damage this turn.',cd:3},
  launch:{n:'Launch squadron',d:'Carriers start each battle with their wings in flight. This launches a replacement for a lost wing into an adjacent hex; each carrier has one spare wing per hangar slot.',cd:1},
  surge:{n:'Shield surge',d:'Every shield facing restored to full strength.',cd:4},
  nova:{n:'Nova cannon',d:'Spinal shell: 40 damage to a hex 3\u20139 away and 20 to everything adjacent. Hits friends too.',cd:3,target:true},
  // faction abilities: every faction's line ships get something to press besides fire and brace
  ionpulse:{n:'Ion pulse',d:'Every enemy ship within 4 hexes loses half of each shield facing.',cd:3},
  overburn:{n:'Overburn',d:'+3 movement now, and a ram this turn hits 50% harder.',cd:3},
  frenzy:{n:'Blood frenzy',d:'All of this ship\u2019s weapons deal +30% damage this turn.',cd:3},
  regrow:{n:'Rapid regrowth',d:'Regrow 25% of this ship\u2019s hull right now.',cd:3},
  blink:{n:'Phase jump',d:'Jump to any open hex within 3, straight past rocks and ships. Tap the hex.',cd:3,target:true},
  phase:{n:'Dimensional shift',d:'+25 evasion until your next turn and +2 movement now.',cd:3},
  reclaim:{n:'Reanimation beam',d:'Restore 20% hull to your most damaged ship within 3 hexes (this one included).',cd:3},
};
const ORDERS = {
  brace:{n:'Brace for impact',d:'Instead of firing: hull damage \u221240% until your next turn. The ship can move first, but can\u2019t brace after it has fired, and bracing ends its turn.'},
};

// fx keys: hpPct shPct regenPct armor speed turns ev aim crit dmgPct broadPct lancePct torpPct sqPct sqHp battShots flakPlus torpCd hangar hullRegen cdMod lastStand rearPct huntPct bracePlus longAim
const MODULES = {
  prow:{n:'Reinforced prow',d:'+15% hull, +5% armor.',fx:{hpPct:.15,armor:.05},cost:70},
  auspex:{n:'Auspex array',d:'+10 aim for every weapon.',fx:{aim:10},cost:80},
  drive:{n:'Plasma drive',d:'+1 speed.',fx:{speed:1},cost:75},
  gyro:{n:'Gyro-stabilisers',d:'+1 turn allowance, +5 evasion.',fx:{turns:1,ev:5},cost:60},
  capacitor:{n:'Void shield capacitor',d:'+30% shield strength.',fx:{shPct:.3},cost:80},
  regen:{n:'Shield regenerator',d:'+50% shield regeneration.',fx:{regenPct:.5},cost:70},
  loaders:{n:'Macro loaders',d:'Battery weapons fire +1 shot.',fx:{battShots:1},cost:90},
  crystal:{n:'Lance focusing crystal',d:'Lance damage +25%.',fx:{lancePct:.25},cost:80},
  magazine:{n:'Torpedo magazine',d:'Torpedo reload time \u22121 turn, +15% torpedo damage.',fx:{torpCd:1,torpPct:.15},cost:85},
  flakplus:{n:'Flak batteries',d:'Point defense +2 shots and +1 range.',fx:{flakPlus:1},cost:55},
  damcon:{n:'Damage control crews',d:'Repair 4% hull at the start of each of your turns.',fx:{hullRegenPct:.04},cost:85},
  hangar:{n:'Hangar expansion',d:'Carriers only: +1 squadron in flight.',fx:{hangar:1},cost:90,only:'launch'},
  cogitator:{n:'Targeting cogitator',d:'+10% critical chance.',fx:{crit:10},cost:75},
};

const PERKS = {
  gunnery:{n:'Gunnery master',d:'+10 aim.',fx:{aim:10}},
  killer:{n:'Killer instinct',d:'+10% critical chance.',fx:{crit:10}},
  deflector:{n:'Deflector savant',d:'+40% shield regeneration.',fx:{regenPct:.4}},
  ironhull:{n:'Iron hull',d:'+15% max hull.',fx:{hpPct:.15}},
  helm:{n:'Born helmsman',d:'+1 speed.',fx:{speed:1}},
  steady:{n:'Steady hand',d:'Ignore the first 2 hexes of long-range penalty.',fx:{longAim:2}},
  broad:{n:'Broadside specialist',d:'Broadside weapons +15% damage.',fx:{broadPct:.15}},
  lanceadept:{n:'Lance adept',d:'Lance and torpedo damage +15%.',fx:{lancePct:.15,torpPct:.15}},
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
  martyr:{n:'Reliquary of the Martyr',d:'When one of your ships is destroyed, every other ship repairs 15% of its hull.',run:{avenge:.15}},
  cogitator:{n:'Archeotech rangefinder',d:'Each ship\u2019s first attack in every battle hits 95% of the time.',run:{firstSure:1}},
  lattice:{n:'Xeno shield lattice',d:'Shields +15% across the fleet.',fx:{shPct:.15}},
  spore:{n:'Tamed spore culture',d:'Every ship regenerates 3 hull per turn.',fx:{hullRegen:3}},
  phylactery:{n:'Deathless phylactery',d:'The first of your ships destroyed each battle reawakens at 25% hull.',run:{revive:1}},
  ledger:{n:'Smuggler\u2019s ledger',d:'+25% credits from battles.',run:{credPct:.25}},
  compass:{n:'Wraithbone compass',d:'+1 speed across the fleet.',fx:{speed:1}},
  banner:{n:'Captured war banner',d:'Every enemy ship one of your ships destroys gives that ship +15% damage for the rest of the battle (up to +45%).',run:{bloodied:.15}},
  salvage:{n:'Salvage rig',d:'After each battle, gain 15 credits and repair 8% hull.',run:{salvage:1}},
  coils:{n:'Blessed plasma coils',d:'Ability cooldowns \u22121 across the fleet.',fx:{cdMod:1}},
  logbook:{n:'Log of Admiral Rhel',d:'+30% captain experience.',run:{xpPct:.3}},
  armourweave:{n:'Adamant armourweave',d:'+6% armor across the fleet.',fx:{armor:.06}},
};

const ADMIRALS = {
  vex:{n:'Admiral Castellan Vex',doc:'Line of battle',d:'Broadside weapons deal +15% damage.',fx:{broadPct:.15},start:['penitent','harrow','warden'],cost:0},
  malek:{n:'Inquisitor-Captain Malek Draven',doc:'Hunter-killer',d:'Torpedoes reload a turn faster. +20% damage on rear-arc hits.',fx:{torpCd:1,rearPct:.2},start:['harrow','harrow','warden','warden'],cost:30},
  ashgrove:{n:'Commodore Sera Ashgrove',doc:'Carrier doctrine',d:'Squadrons deal +25% damage and carriers hold +1 wing.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['reliquary','harrow','warden'],cost:45},
  thale:{n:'High Admiral Oryn Thale',doc:'Iron doctrine',d:'All ships +15% hull and +10% shields.',fx:{hpPct:.15,shPct:.1},start:['cathedral','warden'],cost:80},
};

// ---------- faction admirals: four per faction, own ships, own Command ----------
Object.assign(ADMIRALS.vex,{fac:'voidsworn',cmd:{id:'barrage',n:'Fire for effect',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}});
Object.assign(ADMIRALS.malek,{fac:'voidsworn',cmd:{id:'hunt',n:"Hunter's salvo",d:'Torpedoes reload at once and every ship deals +30% damage this round.'}});
Object.assign(ADMIRALS.ashgrove,{fac:'voidsworn',cmd:{id:'scramble',n:'Scramble all wings',d:'Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round.'}});
Object.assign(ADMIRALS.thale,{fac:'voidsworn',cmd:{id:'iron',n:'Iron wall',d:'All shields refill and your ships take 40% less hull damage this round.'}});
Object.assign(ADMIRALS,{
  kassar:{fac:'hegemony',n:'Grand Admiral Ilsa Kassar',doc:'Fire discipline',d:'Batteries fire one extra shot per volley.',fx:{battShots:1},start:['h_vanguard','h_interdictor'],cost:0,cmd:{id:'barrage',n:'Synchronized broadside',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  vorn:{fac:'hegemony',n:'Commodore Dace Vorn',doc:'Interdiction',d:'+10 aim and +10% critical-hit chance.',fx:{aim:10,crit:10},start:['h_interdictor','h_interdictor','h_picket','h_picket'],cost:30,cmd:{id:'hunt',n:'Interdiction strike',d:'Every ship deals +30% damage this round.'}},
  reyes:{fac:'hegemony',n:'Fleet Marshal Corin Reyes',doc:'Strike group',d:'Squadrons deal +25% damage and star cruisers hold +1 wing.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['h_vanguard','h_picket','h_picket'],cost:45,cmd:{id:'scramble',n:'Launch the strike group',d:'Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round.'}},
  maren:{fac:'hegemony',n:'Line Admiral Oskar Maren',doc:'Armored column',d:'All ships +15% hull and +10% shields.',fx:{hpPct:.15,shPct:.1},start:['h_dominion','h_picket','h_picket'],cost:80,cmd:{id:'iron',n:'Shield wall protocol',d:'All shields refill and your ships take 40% less hull damage this round.'}},
  grax:{fac:'corsair',n:'Warlord Grax Ironjaw',doc:'Ram and board',d:'+1 speed for every ship and +10% damage.',fx:{speed:1,dmgPct:.1},start:['c_marauder','c_reaver','c_raider'],cost:0,cmd:{id:'surge',n:'Full burn',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  sable:{fac:'corsair',n:'Sable Venn, the Smiling Knife',doc:'Knife work',d:'+20% damage on rear-arc hits and +10% crit chance.',fx:{rearPct:.2,crit:10},start:['c_reaver','c_reaver','c_raider','c_raider'],cost:30,cmd:{id:'hunt',n:'Knife in the dark',d:'Torpedoes reload at once and every ship deals +30% damage this round.'}},
  mott:{fac:'corsair',n:'Old Mott Brannigan',doc:'Junkyard carriers',d:'Squadrons deal +25% damage and hulks hold +1 wing.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['c_hulk','c_reaver'],cost:45,cmd:{id:'scramble',n:'Release the swarm',d:'Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round.'}},
  vesh:{fac:'corsair',n:'Vesh the Collector',doc:'Scrap armor',d:'Ships patch 5% of their hull each round and have +10% armor.',fx:{hullRegenPct:.05,armor:.1},start:['c_hulk','c_marauder'],cost:80,cmd:{id:'restore',n:'Patch and pray',d:'Every ship repairs 25% of its hull and patches damaged sections, even destroyed ones.'}},
  matriarch:{fac:'chorus',n:'The Matriarch of Nine Throats',doc:'Brood swarm',d:'Spore swarms deal +25% damage and broods hold +1 swarm.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['b_brood','b_drone'],cost:0,cmd:{id:'scramble',n:'Spawning surge',d:'Every brood releases an extra swarm (even past its limit), then all swarms strike again at once with +50% damage this round.'}},
  razormaw:{fac:'chorus',n:'Razormaw',doc:'Hunter pack',d:'+1 speed and +15% damage on rear-arc hits.',fx:{speed:1,rearPct:.15},start:['b_razor','b_spitter','b_drone'],cost:30,cmd:{id:'surge',n:'Blood frenzy',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  mending:{fac:'chorus',n:'The Mending Choir',doc:'Regrowth',d:'Ships regrow 6% of their hull each round.',fx:{hullRegenPct:.06},start:['b_razor','b_razor'],cost:45,cmd:{id:'restore',n:'Regrowth tide',d:'Every ship regrows 25% of its hull and heals damaged sections, even destroyed ones.'}},
  voice:{fac:'chorus',n:'Voice of the Deep',doc:'Acid chorus',d:'+15% damage with every weapon.',fx:{dmgPct:.15},start:['b_razor','b_spitter','b_drone','b_drone'],cost:80,cmd:{id:'barrage',n:'Discordant volley',d:'Every ship spits a free volley at the best target it can reach, right now.'}},
  aelith:{fac:'ithar',n:'Aelith Dawnsail',doc:'Wing-mistress',d:'Squadrons deal +25% damage and carriers hold +1 wing.',fx:{sqPct:.25,hangar:1,sqHp:.25},start:['i_carrier','i_wisp'],cost:0,cmd:{id:'scramble',n:'Starling flight',d:'Every carrier launches an extra wing (even past its hangar limit), then all squadrons strike again at once with +50% damage this round.'}},
  vaelen:{fac:'ithar',n:'Seraph Vaelen',doc:'Lance choir',d:'Lances deal +20% damage and gain +10 aim.',fx:{lancePct:.2,aim:10},start:['i_song','i_blade'],cost:30,cmd:{id:'barrage',n:'Chord of light',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  thorne:{fac:'ithar',n:'Thorne of the Veil',doc:'Veil tactics',d:'+8 evasion for every ship.',fx:{ev:8},start:['i_blade','i_blade','i_wisp','i_wisp'],cost:45,cmd:{id:'surge',n:'Phase drift',d:'Every ship gains +2 movement and +1 turn, and enemy fire loses 20 accuracy against you this round.'}},
  mirelle:{fac:'ithar',n:'Mirelle Starwarden',doc:'Prism hulls',d:'All ships +15% shields, and shields recharge 20% faster.',fx:{shPct:.15,regenPct:.2},start:['i_song','i_wisp','i_wisp'],cost:80,cmd:{id:'iron',n:'Prism ward',d:'All shields refill and your ships take 40% less hull damage this round.'}},
  nekhet:{fac:'deathless',n:'Overlord Nekhet the Undying',doc:'Eternal legion',d:'Ships regrow 6% of their hull each round.',fx:{hullRegenPct:.06},start:['d_harvester','d_jackal'],cost:0,cmd:{id:'restore',n:'Reanimation protocol',d:'Every ship rebuilds 25% of its hull and mends damaged sections, even destroyed ones.'}},
  sekhmar:{fac:'deathless',n:'Sekhmar the Reaper',doc:'Reaping arcs',d:'Doom arcs deal +20% damage and every weapon +10%.',fx:{lancePct:.2,dmgPct:.1},start:['d_harvester','d_scythe','d_scythe'],cost:30,cmd:{id:'barrage',n:'Harvest of souls',d:'Every ship fires a free volley at the best target its guns can reach, right now.'}},
  anuket:{fac:'deathless',n:'Cryptlord Anuket',doc:'Silent hunters',d:'+20% damage on rear-arc hits and +10 evasion.',fx:{rearPct:.2,ev:10},start:['d_jackal','d_jackal','d_scythe','d_scythe'],cost:45,cmd:{id:'hunt',n:'Tomb-blade strike',d:'Every ship deals +30% damage this round.'}},
  khepra:{fac:'deathless',n:'Khepra the Patient',doc:'Living stone',d:'All ships +20% hull.',fx:{hpPct:.2},start:['d_jackal','d_jackal','d_jackal'],cost:80,cmd:{id:'iron',n:'Living stone',d:'All shields refill and your ships take 40% less hull damage this round.'}},
});

const LEGACY = {
  u_carrier:{n:'Carrier hulls',d:'Carrier hulls appear in shipyards.',cost:30,group:'Shipyards'},
  u_battleship:{n:'Battleship hulls',d:'Battleship-class hulls appear in shipyards.',cost:60,group:'Shipyards'},
  u_dread:{n:'Dreadnought hulls',d:'Voidsworn fleets may take one Ascendant-class dreadnought.',cost:120,group:'Shipyards',req:'u_battleship'},
  chest1:{n:'War chest I',d:'+75 starting credits.',cost:20,group:'Supply'},
  chest2:{n:'War chest II',d:'+75 more starting credits.',cost:40,group:'Supply',req:'chest1'},
  chest3:{n:'War chest III',d:'+75 more starting credits.',cost:65,group:'Supply',req:'chest2'},
  cmd1:{n:'Command authority I',d:'+2 fleet command points.',cost:35,group:'Command'},
  cmd2:{n:'Command authority II',d:'+2 more fleet command points.',cost:70,group:'Command',req:'cmd1'},
  vets:{n:'Veteran officers',d:'Starting captains begin at Commander rank with a perk.',cost:50,group:'Command'},
  founder:{n:'Relic of the founders',d:'Begin each run with a random relic.',cost:60,group:'Supply'},
  wrights:{n:'Master shipwrights',d:'Shipyard prices \u221215%.',cost:45,group:'Supply'},
  salvagers:{n:'Salvage protocols',d:'+20% credits from battles.',cost:40,group:'Supply'},
};

const SHIP_NAMES = ['Unyielding Oath','Saint Vesper\u2019s Wrath','Ashen Vigil','Lament of Iron','Bright Censure','Hymn of Ruin','Oathkeeper','Merciless Litany','Cinder Psalm','Pale Crusader','Everwatch','Grave Tithe','Sanctified Fury','Iron Requiem','Dawn of Cinders','Martyr\u2019s Resolve','Judgement Bell','Votive Flame','Sorrow\u2019s Edge','Penance Undying','Relentless Canticle','Obsidian Choir','Hallowed Anvil','Last Benediction','Wrathful Seraph','Cold Absolution','Thorn of Heaven','Vigilant Censer'];
const CAP_FIRST = ['Ilse','Corvin','Maren','Tobias','Anselm','Vera','Casimir','Odile','Lucan','Serafine','Aurek','Helka','Brannoc','Isolde','Garrick','Mireille','Dagan','Thessaly','Rourke','Elsbeth','Konrad','Yara','Osric','Ninette','Halvard','Petra','Lysander','Calla'];
const CAP_LAST = ['Varrow','Kade','Morrow','Ashdown','Quell','Harrowgate','Vane','Stroud','Rennick','Draeger','Holloway','Sable','Wyndham','Corvane','Ostrava','Marchetti','Blackwood','Ferro','Vashti','Kellan','Maddox','Serrano','Ivers','Lachance','Okonkwo','Brandt','Salo','Teague'];

// ---------- faction names: same effects, each faction's own words ----------
const MOD_NEED={loaders:'batt',crystal:'lance',magazine:'torp',flakplus:'flak',capacitor:'shields',regen:'shields',hangar:'carrier'};
const MOD_NAMES={
  hegemony:{prow:'Reinforced bow plating',auspex:'Fire-control computer',drive:'Ion drive upgrade',gyro:'Attitude thrusters',capacitor:'Deflector capacitor',regen:'Deflector regenerator',loaders:'Turbolaser cyclers',crystal:'Ion focus lens',magazine:'Proton magazine',flakplus:'Point-defense array',damcon:'Damage control teams',hangar:'Expanded hangar bay',cogitator:'Targeting computer'},
  corsair:{prow:'Scrap ram plating',auspex:'Stolen gun sights',drive:'Overbored thrusters',gyro:'Jury-rigged gyros',capacitor:'Salvaged shield cells',regen:'Hot-wired regenerator',loaders:'Ammo hoppers',crystal:'Cracked lens array',magazine:'Extra torpedo racks',flakplus:'Bolted-on flak',damcon:'Welding gangs',hangar:'Welded-on hangar',cogitator:'Gunner’s lucky charm'},
  chorus:{prow:'Chitin layers',auspex:'Hunting eyes',drive:'Propulsion sacs',gyro:'Fin clusters',capacitor:'Membrane bloom',regen:'Membrane regrowth',loaders:'Spine glands',crystal:'Venom lens',magazine:'Spore bladders',flakplus:'Stinger pores',damcon:'Mending tissue',hangar:'Brood chamber',cogitator:'Predator instinct'},
  ithar:{prow:'Wraithbone keel',auspex:'Farsight crystal',drive:'Solar sail extension',gyro:'Starwind vanes',capacitor:'Prism capacitor',regen:'Dawnlight lattice',loaders:'Shuriken feeders',crystal:'Starlight focus',magazine:'Star torpedo cradle',flakplus:'Shard screen',damcon:'Song of mending',hangar:'Wing cradle',cogitator:'Seer’s sight'},
  deathless:{prow:'Living-metal plating',auspex:'Tomb sight',drive:'Inertialess drive',gyro:'Gravitic vanes',capacitor:'Quantum shield node',regen:'Quantum regenerator',loaders:'Gauss accelerators',crystal:'Doom-arc focus',magazine:'Arc capacitors',flakplus:'Sentry nodes',damcon:'Repair scarabs',hangar:'Scarab hive',cogitator:'Calculus lattice'}};
const RELIC_NAMES={
  hegemony:{martyr:'Medal of the Grand Fleet',cogitator:'Imperial targeting array',lattice:'Deflector matrix prototype',spore:'Captured Chorus culture',ledger:'Smuggler’s ledger',compass:'Hyperdrive motivator',banner:'Captured war banner',salvage:'Salvage rig',coils:'Overclocked reactors',logbook:'Admiralty logbook',armourweave:'Durasteel weave'},
  corsair:{martyr:'Captain’s lucky skull',cogitator:'Stolen Navy rangefinder',lattice:'Ithar shield shard',ledger:'Smuggler’s ledger',compass:'Wraithbone compass',banner:'Trophy war banner',salvage:'Salvage rig',coils:'Hot-rodded reactor',logbook:'Pirate king’s logbook',armourweave:'Scrap armor weave'},
  chorus:{martyr:'Heart of the first brood',cogitator:'Compound eye cluster',lattice:'Stolen shield lattice',spore:'Ancestral spore culture',ledger:'Hoard of the deep',compass:'Migration current',banner:'Prey’s war banner',salvage:'Scavenger gut',coils:'Quickening gland',logbook:'Memory of the hive',armourweave:'Carapace weave'},
  ithar:{martyr:'Tear of the dying star',cogitator:'Seer’s eye',lattice:'Prism lattice',ledger:'Ledger of the exiles',banner:'Banner of the lost world',coils:'Starlight coils',logbook:'Log of the last voyage',armourweave:'Sunstone weave'},
  deathless:{martyr:'Crown of the first dynasty',cogitator:'Calculus engine',phylactery:'Phylactery of the Undying',ledger:'Tithe ledger',compass:'Gravitic compass',banner:'Standard of the conquered',salvage:'Harvest engine',coils:'Chronometron',logbook:'Annals of the dynasty',armourweave:'Living-metal weave'}};
// what a run is called, by faction
const RUN_WORD={voidsworn:'crusade',hegemony:'campaign',corsair:'raid',chorus:'hunt',ithar:'voyage',deathless:'reclamation'};

const EVENTS = [
  {id:'derelict',t:'A derelict in the dark',b:'Your auspex finds an ancient gothic warship drifting without power, its hull etched with prayers no one has spoken in ten thousand years.',
   o:[{l:'Send boarding parties',s:'Risky. Could hold archeotech, could hold something awake.',r:'derelictBoard'},
      {l:'Strip the hull from range',s:'+35 credits, no risk.',r:{cred:35}},
      {l:'Leave it to its prayers',s:'Nothing happens.',r:{}}]},
  {id:'beacon',not:['hegemony'],t:'Hegemony distress beacon',b:'A Hegemony supply tender is limping home with a shattered drive. Its captain is broadcasting on every band.',
   o:[{l:'Offer aid',s:'Your crews patch their drive. They pay in kind.',r:{cred:50,xp:10}},
      {l:'Seize the cargo',s:'+100 credits. Their escort might remember your colours.',r:{cred:100,ambush:true}},
      {l:'Ignore it',s:'Nothing happens.',r:{}}]},
  {id:'astropath',t:'The astropath\u2019s vision',b:'Your fleet astropath wakes screaming. She has seen where a relic lies, but reaching it means sailing through a warp-rift.',v:{hegemony:{t:'A ghost signal',b:'Your sensor officer has decoded a ghost signal: an old Navy relic cache, deep inside a hyperspace rift.'},corsair:{t:'The navigator\u2019s hunch',b:'Your half-mad navigator swears she can smell treasure on the far side of a rift. She is usually right. Usually.'},chorus:{t:'A scent in the void',b:'The brood-mind tastes something ancient and delicious beyond a rift in space.'},ithar:{t:'A seer\u2019s dream',b:'Your seer dreams of a lost treasure of your people, sleeping beyond a rift.'},deathless:{t:'A dynastic beacon',b:'An old dynastic beacon pulses from beyond a rift. Something of the dynasty is still out there.'}},
   o:[{l:'Go after it',s:'Gain a relic. A random ship takes heavy damage.',r:{relic:1,dmgOne:.3}},
      {l:'Move on',s:'Nothing happens.',r:{}}]},
  {id:'merc',t:'A mercenary captain',b:'A scarred destroyer captain hails you. Her crew has been paid off and she wants a new cause, for a price.',
   o:[{l:'Hire her (80 credits)',s:'A destroyer of your own kind, with a veteran captain, joins the fleet.',r:{cost:80,ship:'harrow',vet:1}},
      {l:'Decline',s:'Nothing happens.',r:{}}]},
  {id:'storm',t:'Warp storm',b:'A storm front rolls across your jump route, lightning the colour of old blood.',
   o:[{l:'Punch straight through',s:'Every ship takes 10% hull damage.',r:{dmgAll:.1}},
      {l:'Chart a way around (40 credits)',s:'Burn fuel and time instead.',r:{cost:40}}]},
  {id:'seer',not:['ithar'],t:'An Ithar seer',b:'A lone Ithar vessel matches your course. Its seer offers a trade: one of your refits for one of their treasures.',
   o:[{l:'Trade a module for a relic',s:'Lose a random installed module. Gain a relic.',r:{loseMod:1,relic:1}},
      {l:'Refuse politely',s:'Nothing happens.',r:{}}]},
  {id:'wright',t:'The rogue shipwright',b:'A hermit shipwright on an asteroid forge offers to rework one of your hulls. He asks only for the stories of your battles.',
   o:[{l:'Let him work',s:'Your most damaged ship is fully repaired and upgraded one Mark.',r:{upgradeOne:1}},
      {l:'Move on',s:'Nothing happens.',r:{}}]},
  {id:'moon',not:['chorus'],t:'The infested moon',b:'Chorus spores have taken a mining moon. Survivors are signalling from the deep shafts, but a brood is gestating.',
   o:[{l:'Purge the moon',s:'Fight an elite Chorus battle. Win a relic.',r:{fight:'chorus'}},
      {l:'Bombard from orbit and leave',s:'+20 captain experience for every captain.',r:{xp:20}}]},
  {id:'shrine',not:['chorus','deathless'],t:'A void-shrine',b:'An orbital shrine to a forgotten saint hangs over a dead world. Your crews ask to make an offering.',v:{hegemony:{b:'An old orbital shrine hangs over a dead world. Spacers are a superstitious lot, and your crews ask to leave an offering.'},corsair:{b:'An orbital shrine to some forgotten saint hangs over a dead world. Even pirates hedge their bets: your crews ask to leave an offering.'},ithar:{t:'A shrine of the old world',b:'A shrine from before your people\u2019s fall hangs over a dead world. Your crews ask to leave an offering.'}},
   o:[{l:'Offer 50 credits',s:'Every ship repairs 30% hull.',r:{cost:50,healAll:.3}},
      {l:'Pray and hope',s:'Even odds: repair 30%, or nothing.',r:{gamble:true}},
      {l:'Leave',s:'Nothing happens.',r:{}}]},
  {id:'deserters',not:['hegemony'],t:'Hegemony deserters',b:'A lifeboat of Hegemony officers begs for asylum. They know how the Navy fights.',
   o:[{l:'Take them in',s:'Your least experienced captain gains 60 experience.',r:{xpLow:60}},
      {l:'Hand them back for the bounty',s:'+60 credits.',r:{cred:60}}]},
  {id:'cache',not:['corsair'],t:'Smuggler cache',b:'A corsair cache hidden in the rings of a gas giant. The locks are primitive.',
   o:[{l:'Crack it open',s:'Gain a random module.',r:{mod:1}},
      {l:'Take the fuel and credits',s:'+45 credits.',r:{cred:45}}]},
];

// ---------- captains and ship names by faction ----------
const CAPTAINS={
  voidsworn:{ranks:RANKS,first:CAP_FIRST,last:CAP_LAST},
  hegemony:{ranks:['Lieutenant','Commander','Captain','Commodore','Rear admiral'],first:['Konrad','Ilsa','Dace','Mara','Oskar','Rhea','Viktor','Lena','Aldric','Petra','Gerold','Sanne','Halvar','Ines','Ruprecht','Katrin'],last:['Reiter','Kassel','Brandt','Vorn','Hollis','Strand','Varga','Kessler','Drexel','Moran','Falk','Lindqvist','Achterberg','Roth','Vandermeer','Haldane']},
  corsair:{ranks:['Mate','Skipper','Captain','Reaver-captain','Warlord'],first:['Rusty','Grim','Mad','One-Eye','Lucky','Red','Scrap','Knuckles','Salt','Patch','Dutch','Sly','Bones','Tiny','Hooks','Jinx'],last:['Krogg','Brannigan','Mallory','Blackwater','Rook','Sharkey','Gutter','Varrick','the Knife','Two-Guns','Tallow','Ironjaw','Spatchcock','Quill','Rattigan','Slade']},
  chorus:{ranks:['Spawn-mind','Brood-node','Throat','Elder throat','Matriarch'],names:['Seventh Mouth','Hollow Song','Deep Murmur','Thrumming Coil','Pale Bloom','Wet Whisper','Ninefold','Grieving Tide','Brine Hymn','Moult','Ashk-of-Many','Sallow Choir','Undertow','Last Spore','Coiled Psalm','Lantern Gut']},
  ithar:{ranks:['Wing','Sail','Seraph','High seraph','Starwarden'],first:['Siriel','Aelith','Vaelen','Thandor','Ilyra','Caelis','Ithrien','Nyssa','Orrin','Saelune','Talvar','Eluned','Faewyn','Liraen','Corvel','Ysolde'],last:['Starglass','Dawnsail','Veilborn','Moonreach','Sunward','Lightwhisper','Skyhollow','Silverwake','Brightmere','Glasswing','Nightbloom','Farcall']},
  deathless:{ranks:['Warden','Overseer','Cryptlord','Overlord','Dynast'],names:['Imhoten','Setekh','Amuneth','Rahotep','Tauret','Menkara','Khepset','Nefrah','Osirak','Ptahmet','Sobekar','Thutem','Wadjen','Hekamun'],epithets:['the Hollow','the Patient','the Silent','the Undying','of the Ninth Tomb','the Unbroken','the Pale','the Ever-Watching','the Iron-Hearted','of the Sunless Court']}};
const MORE_SHIP_NAMES={
  hegemony:['HNS Steadfast','HNS Arbiter','HNS Ironclad','HNS Resolute','HNS Bastion','HNS Ascendancy','HNS Vindicator','HNS Castellan','HNS Paragon','HNS Unflinching'],
  corsair:['Bilge Rat','Salt Debt','Last Laugh','Nine Lives','Scrapjaw','Black Ledger','Gilded Liar','Rattletrap','Widow\u2019s Wager','Low Tide'],
  chorus:['Shrieking Coil','Brood Vessel Om','Mournful Gut','Spine Choir','Hive-node Vesk','Crawling Hymn','Wet Psalm','Gnawing Bloom','Tide of Teeth','Hollowsong'],
  ithar:['Glass Requiem','Morningveil','Starfall','Quiet Wing','Lumen Arc','Silver Lament','Aurora\u2019s Grace','Farlight','Moonsorrow','Petal Storm'],
  deathless:['Tomb of Nine Kings','Ankh of Ash','Silent Procession','Dust Eternal','The Unsleeping','Obelisk of Night','Crypt of Teeth','Sunless Barge','Pale Sovereign','Ever-Watch']};
// every faction's hulls get a shipyard price, refit slots and their boss flag (only the Voidsworn set had them;
// other factions showed 'Buy for NaN', had no refit slots, and the Voidsworn dreadnought wasn't marked as a boss)
for(const [fid,F] of Object.entries(FACTIONS)){ if(F.boss&&HULLS[F.boss]) HULLS[F.boss].boss=true;
  for(const id of F.roster){ const h=HULLS[id]; if(!h||h.sq) continue; const cp=h.cp||1;
    if(h.cost==null) h.cost=Math.round((60*cp+10)/5)*5; if(h.slots==null) h.slots=cp<=2?1:cp<=4?2:3; } }

// ---------- progression between runs ----------
// Hull variants: bought once with renown, then sold in your faction's shipyards beside the standard hull
const HULL_VARIANTS={
  vs_harrow_t:{base:'harrow',n:'Harrow torpedo-destroyer',d:'Twin prow torpedo tubes and no turret: a one-shot assassin.',w:[['torp','F'],['torp','F']],cost:20},
  vs_penitent_g:{base:'penitent',n:'Penitent gun-cruiser',d:'Swaps the prow lance for a dorsal macro battery: guns in every arc.',w:[['battery','P'],['battery','S'],['battery','T']],cost:25},
  h_picket_i:{base:'h_picket',n:'Picket interceptor',d:'Turret laser and +6 evasion: screens wherever it points.',w:[['laser','T'],['flak','T']],mod:{ev:24},cost:15},
  h_vanguard_g:{base:'h_vanguard',n:'Vanguard gunship',d:'No hangar; a third turbolaser turret instead.',w:[['turbo','T'],['turbo','T'],['turbo','T'],['ion','F']],mod:{ab:null,hangar:0},cost:25},
  c_reaver_t:{base:'c_reaver',n:'Reaver gunboat',d:'Scatter cannons on a turret instead of one broadside.',w:[['torp','F'],['scatter','T']],cost:15},
  c_hulk_g:{base:'c_hulk',n:'Gun-hulk',d:'No hangar; scatter broadsides, a turret and 20 more hull.',w:[['scatter','P'],['scatter','S'],['turret','T']],mod:{ab:null,hangar:0,hp:190},cost:25},
  b_spitter_s:{base:'b_spitter',n:'Spitter stinger',d:'Trades a prow gun for boarding tendrils: brutal up close.',w:[['bioplasma','T'],['tendril','T']],cost:15},
  b_razor_s:{base:'b_razor',n:'Razorfiend stalker',d:'Two tendril clusters, +1 speed and +8 evasion.',w:[['tendril','T'],['tendril','T']],mod:{sp:5,ev:12},cost:25},
  i_wisp_l:{base:'i_wisp',n:'Wisp lancer',d:'A pulsar lance in place of the shuriken cannon.',w:[['pulsar','F']],cost:15},
  i_song_w:{base:'i_song',n:'Songship warden',d:'One lance on a turret, 30% more shields.',w:[['pulsar','T'],['turret','T']],mod:{sh:34},cost:25},
  d_scythe_s:{base:'d_scythe',n:'Scythe sentinel',d:'Adds gauss sentries: shoots down squadrons and boarders’ craft.',w:[['gauss','T'],['gsentry','T']],cost:15},
  d_harvester_t:{base:'d_harvester',n:'Harvester tomb-turret',d:'Its doom arc sits on a turret: it no longer has to turn to fire.',w:[['gauss','T'],['doom','T'],['gsentry','T']],cost:30}};
for(const [id,v] of Object.entries(HULL_VARIANTS)){ const b=HULLS[v.base]; HULLS[id]=Object.assign({},b,{n:v.n,w:v.w,variant:id,base:v.base},v.mod||{}); if(HULLS[id].ab===null) delete HULLS[id].ab; }
// Admiral mastery: every admiral levels up as you fly with them, in any faction
const MASTERY_XP=[0,6,16,30,50];
const MASTERY_PERKS=[
  null,
  {n:'Alternate fleet',d:'Choose a second starting fleet for this admiral.'},
  {n:'Wider counsel',d:'Your flagship is offered four aspects instead of three.'},
  {n:'Second Command',d:'Choose between two Commands before the run.'},
  {n:'Flag captain',d:'Your flagship starts at Mk II, its captain a Captain with a perk.'}];
// Patron favour: grows with every boon you take from a patron
const FAVOUR_TIERS=[{at:0,n:'Watching'},{at:4,n:'Favoured',d:'Their boons are rare more often.'},{at:12,n:'Devoted',d:'If they watch your run, you start with one of their boons.'},{at:25,n:'Chosen',d:'Their boons are never common.'}];
// Heat: optional rules after your first victory; each level adds 10% renown
// enemy fleet archetypes: the same budget spent three different ways, named per faction and shown on the map
const ARCHETYPES={
  swarm:{d:'Many light hulls. Broadsides and flak shine; lances are wasted on them.',names:{voidsworn:'Zealot flotilla',hegemony:'Picket screen',corsair:'Wolfpack',chorus:'Brood swarm',ithar:'Wisp flight',deathless:'Scythe harvest'}},
  heavy:{d:'Few, big hulls. Bring lances, torpedoes and a flank.',names:{voidsworn:'Cathedral line',hegemony:'Line of battle',corsair:'Hulk convoy',chorus:'Titan pod',ithar:'Songline',deathless:'Phalanx'}},
  carrier:{d:'Built around a carrier and its wings. Fighters and flak pay off.',names:{voidsworn:'Reliquary group',hegemony:'Carrier group',corsair:'Raider nest',chorus:'Hive cluster',ithar:'Wraith host',deathless:'Harvest ark'}}};
// node modifiers: a twist on one fight, shown on the map
const NODE_MODS={
  bounty:{n:'Bounty',short:'Bounty',d:'A price on this fleet: +50% credits, and they bring 10% more ships.'},
  veteran:{n:'Veteran captain',short:'Veteran',d:'Their largest ship has an elite captain.'}};
// sector conditions: each sector of a run has one, shown on the sector map and applied to every fight there
const SECTOR_CONDS={
  ion:{n:'Ion season',d:'Ion storms sweep every battlefield, and shields recharge 25% slower on both sides.',regen:.75,terr:'storm'},
  dark:{n:'Dark sector',d:'Thick nebulae choke every battlefield: more hexes where shots go wide (\u221215 to hit inside).',terr:'neb'},
  wreck:{n:'Wreck belt',d:'Old battle wreckage everywhere: more debris hexes (\u221210 to hit inside), and salvage adds 15% to every battle\u2019s pay.',terr:'debris',cred:.15},
  war:{n:'War zone',d:'Every fight here draws reinforcements for one side or the other, and pays 20% more credits.',cred:.2,war:1},
  scarce:{n:'Scarcity',d:'Supply lines are cut: shipyards charge 20% more and repairs restore 25% less, but battles pay 25% more credits.',cred:.25,price:1.2,repair:.75}};
const HEAT={
  h_flag:{n:'Vengeful flagships',d:'Sector flagships have 20% more hull.',w:1},
  h_hunted:{n:'Hunted',d:'Enemy fleets are 15% larger.',w:2},
  h_elite:{n:'Veteran escorts',d:'One ship in every enemy fleet is an elite.',w:1},
  h_undying:{n:'Undying foes',d:'Any enemy ship may reassemble once when destroyed.',w:2},
  h_coffers:{n:'Lean coffers',d:'Shipyard prices are 25% higher.',w:1},
  h_repair:{n:'Short supplies',d:'Every repair restores half as much.',w:1},
  h_cmd:{n:'Slow orders',d:'Your Command reaches full power a round later.',w:1}};

// ---------- Patrons, boons and flagship aspects ----------
// Each run four of six patrons watch the crusade. Battles on the map carry a patron's sigil; win there and that patron offers three boons, take one.
// Boons change rules, not just numbers; rarity scales their strength (Common x1, Rare x1.5, Epic x2). Two patrons' boons together unlock duo boons.
const RARITY=[{n:'Common',m:1,col:'#cfc6b0'},{n:'Rare',m:1.5,col:'#62ccff'},{n:'Epic',m:2,col:'#c58bff'}];
const PATRONS={
  iron:{n:'Kharon, the Iron Saint',short:'Kharon',col:'#e0b04a',glyph:'K',theme:'Broadsides, armor and holding the line',quote:'Stand. Fire. Stand again.'},
  storm:{n:'Vyre, the Storm Queen',short:'Vyre',col:'#5fd4ff',glyph:'V',theme:'Shields, ion fire and lightning',quote:'Every shield is a promise. Break theirs.'},
  hunger:{n:'The Hunger Below',short:'The Hunger',col:'#7ddc6a',glyph:'H',theme:'Squadrons, boarding and feeding on the fallen',quote:'More mouths. More wings. More.'},
  star:{n:'Astra, the Silent Star',short:'Astra',col:'#b48cff',glyph:'A',theme:'Lances, precision and critical hits',quote:'One clean line of light is enough.'},
  rook:{n:'Rook, the Breaker',short:'Rook',col:'#ff6b5a',glyph:'R',theme:'Rams, speed and momentum',quote:'Faster. Closer. Through them.'},
  ember:{n:'The Ember Choir',short:'The Choir',col:'#ff9f3a',glyph:'E',theme:'Torpedoes, fire and chain explosions',quote:'Sing, and let the void burn with you.'}};
const boonPct=x=>Math.round(x*100)+'%';
const BOONS={
  // Kharon
  i_broad:{p:'iron',n:'Thunder Broadside',d:m=>`Broadside guns deal +${boonPct(.2*m)} damage.`,fx:m=>({broadPct:.2*m})},
  i_still:{p:'iron',n:'Anchored Volley',d:m=>`A ship that hasn't moved this activation deals +${boonPct(.25*m)} damage with broadsides and batteries.`,fx:m=>({stillPct:.25*m})},
  i_plate:{p:'iron',n:"Saint's Plating",d:m=>`+${boonPct(.08*m)} armor across the fleet.`,fx:m=>({armor:.08*m})},
  i_brace:{p:'iron',n:'Iron Discipline',d:m=>`Bracing blocks an extra ${boonPct(.1*m)}, and braced ships strike back: every enemy attack that hits one takes ${Math.round(18*m)} damage in return.`,fx:m=>({riposte:Math.round(18*m),bracePlus:.1*m})},
  i_line:{p:'iron',n:'Unbroken Line',d:m=>`Ships next to another of your ships take ${boonPct(.12*m)} less hull damage.`,fx:m=>({lineGuard:.12*m})},
  // Vyre
  s_cap:{p:'storm',n:'Capacitor Surge',d:m=>`Shields +${boonPct(.2*m)} across the fleet.`,fx:m=>({shPct:.2*m})},
  s_arc:{p:'storm',n:'Arc Discharge',d:m=>`When your fire knocks out an enemy shield facing, its generator shorts for ${Math.round(9*m)} hull damage.`,fx:m=>({arcShort:Math.round(9*m)})},
  s_ion:{p:'storm',n:'Ion Lash',d:m=>`Your weapons strip ${boonPct(.22*m)} more shield per hit.`,fx:m=>({ionPlus:.22*m})},
  s_regen:{p:'storm',n:'Storm Mantle',d:m=>`Each turn, every shield facing on every ship restores an extra ${boonPct(.18*m)} of its strength.`,fx:m=>({stormRegen:.18*m})},
  s_ev:{p:'storm',n:'Lightning Reflex',d:m=>`+${Math.round(6*m)} evasion across the fleet.`,fx:m=>({ev:Math.round(6*m)})},
  // The Hunger
  h_hatch:{p:'hunger',n:'Swarm Hatch',d:m=>`Carriers field ${m>=1.5?'two extra wings':'an extra wing'}.`,fx:m=>({hangar:m>=1.5?2:1})},
  h_wings:{p:'hunger',n:'Ravenous Wings',d:m=>`Squadrons deal +${boonPct(.25*m)} damage.`,fx:m=>({sqPct:.25*m})},
  h_chitin:{p:'hunger',n:'Hardened Chitin',d:m=>`Squadrons have +${boonPct(.3*m)} hull.`,fx:m=>({sqHp:.3*m})},
  h_board:{p:'hunger',n:'Boarding Frenzy',d:m=>`Boarding parties fight as ${boonPct(.25*m)} more crew, and a failed boarding always sabotages a system.`,fx:m=>({boardPct:.25*m})},
  h_feast:{p:'hunger',n:'Feast on the Fallen',d:m=>`When your squadron destroys a target, its carrier gains a spare wing and repairs ${boonPct(.05*m)} hull.`,fx:m=>({feast:.05*m})},
  // Astra
  a_lance:{p:'star',n:'Starlight Lances',d:m=>`Lances deal +${boonPct(.35*m)} damage.`,fx:m=>({lancePct:.35*m})},
  a_aim:{p:'star',n:'Silent Aim',d:m=>`+${Math.round(5*m)} aim for every weapon.`,fx:m=>({aim:Math.round(5*m)})},
  a_crit:{p:'star',n:'Killing Light',d:m=>`+${Math.round(6*m)}% critical chance, criticals deal x${+(1.5+.25*m).toFixed(2)}, and every critical hit wrecks a ship system.`,fx:m=>({crit:Math.round(6*m),critMul:.25*m,critSys:1})},
  a_long:{p:'star',n:'Long Silence',d:m=>`Ignore the first ${Math.floor(m*1.5)} hex${Math.floor(m*1.5)>1?'es':''} of long-range penalty.`,fx:m=>({longAim:Math.floor(m*1.5)})},
  a_rear:{p:'star',n:'Blind Spot',d:m=>`Hits on an enemy's rear arc deal +${boonPct(.25*m)} damage.`,fx:m=>({rearPct:.25*m})},
  // Rook
  r_burn:{p:'rook',n:'Afterburners',d:m=>`+${m>=2?2:1} speed across the fleet${m>=1.5?`, and +${m>=2?10:6} evasion`:''}.`,fx:m=>({speed:m>=2?2:1,ev:m>=2?10:m>=1.5?6:0})},
  r_prow:{p:'rook',n:'Battering Prow',d:m=>`Rams deal +${boonPct(.35*m)} damage and can take up to ${boonPct(.4+.1*m)} of a ship's hull; recoil halved.`,fx:m=>({ramPct:.35*m,ramCap:.1*m,ramGuard:.5})},
  r_mom:{p:'rook',n:'Momentum',d:m=>`Ships deal +${boonPct(.05*m)} damage for each hex they moved this activation (up to 4).`,fx:m=>({momPct:.05*m})},
  r_jink:{p:'rook',n:'Evasive Burn',d:m=>`Ships that moved 3+ hexes are ${Math.round(15*m)} harder to hit until their next turn.`,fx:m=>({burnEv:Math.round(15*m)})},
  r_shock:{p:'rook',n:'Shockwave',d:m=>`Rams also hit every other enemy next to the target for ${boonPct(.25*m)} of the ram damage.`,fx:m=>({ramSplash:.25*m})},
  // The Ember Choir
  e_war:{p:'ember',n:'Choir Warheads',d:m=>`Torpedoes deal +${boonPct(.25*m)} damage.`,fx:m=>({torpPct:.25*m})},
  e_reload:{p:'ember',n:'Hymn of Reloading',d:m=>`Torpedoes reload ${m>=1.5?2:1} turn${m>=1.5?'s':''} faster.`,fx:m=>({torpCd:m>=1.5?2:1})},
  e_kindle:{p:'ember',n:'Kindling',d:m=>`Hull hits have a ${boonPct(.12*m)} chance to start a fire (fires burn ${6+Math.round(4*m)} a turn for 2 turns).`,fx:m=>({igniteCh:.12*m,fireDmg:Math.round(4*m)})},
  e_chain:{p:'ember',n:'Chain Reaction',d:m=>`Enemy ships you destroy explode, dealing ${Math.round(20*m)} damage to every enemy within 2 hexes.`,fx:m=>({chainBoom:Math.round(20*m)})},
  e_hunt:{p:'ember',n:'Funeral Pyre',d:m=>`+${boonPct(.2*m)} damage against ships below half hull, and ships you hit while below half can no longer regrow hull or reanimate.`,fx:m=>({huntPct:.2*m,pyre:1})},
  // Duo boons: need a boon from each of two patrons
  d_jugg:{duo:['iron','rook'],n:'Juggernaut',d:()=>'Rams deal +50% damage and the rammer takes no recoil.',fx:()=>({ramPct:.5,ramGuard:1})},
  d_bastion:{duo:['iron','storm'],n:'Bastion',d:()=>'Bracing also refills every shield facing and blocks an extra 10% of hull damage.',fx:()=>({bastion:1,bracePlus:.1})},
  d_ionlance:{duo:['storm','star'],n:'Ion Lance',d:()=>'Lances strip double shield per hit.',fx:()=>({ionLance:1})},
  d_burnswarm:{duo:['hunger','ember'],n:'Burning Swarm',d:()=>'Squadron hits have a 30% chance to start a fire.',fx:()=>({sqIgnite:.3})},
  d_hunter:{duo:['star','rook'],n:"Hunter's Line",d:()=>'Ships that moved 3+ hexes gain +25% critical chance.',fx:()=>({momCrit:25})},
  d_inferno:{duo:['ember','iron'],n:'Broadside Inferno',d:()=>'Broadside hits have a 40% chance to start a fire, and your fires burn hotter (10 a turn) and a turn longer.',fx:()=>({broadIgnite:.4,fireLong:1,fireDmg:4})}};
// boons that only matter if the fleet has the right kit; offers skip them when it doesn't
const BOON_NEED={i_still:'still',s_cap:'shields',s_regen:'shields',d_bastion:'shields',i_broad:'broad',d_inferno:'broad',e_war:'torp',e_reload:'torp',a_lance:'lance',d_ionlance:'lance',h_hatch:'carrier',h_wings:'sq',h_chitin:'sq',h_feast:'sq',d_burnswarm:'sq'};
// the flagship's aspect is picked at the start of a run, from three offered at random
const ASPECTS={
  lancer:{n:'Aspect of the Spear',d:'Your flagship’s forward guns deal +50% damage and reach 1 hex further, and it can turn once more each round to bring them to bear.',fx:{prowPct:.5,prowRange:1,turns:1}},
  hive:{n:'Aspect of the Hive',d:'Your flagship launches a squadron wing at the start of every battle (+1 wing if it is already a carrier), and its wings deal +30% damage.',fx:{hive:1,sqPct:.3}},
  ram:{n:'Aspect of the Ram',d:'Your flagship rams for +60% damage, can take up to 60% of a ship’s hull, takes no recoil, and has +1 speed.',fx:{ramPct:.6,ramCap:.2,ramGuard:1,speed:1}},
  bulwark:{n:'Aspect of the Bulwark',d:'Your flagship has +70% hull and shields, ships next to it take 25% less hull damage, and enemy ships within 4 hexes that can fire on it must.',fx:{hpPct:.7,shPct:.7,guardAura:.25,taunt:4}},
  storm:{n:'Aspect of the Storm',d:'Your flagship’s weapons strip 50% more shield per hit, and its shields recharge twice as fast.',fx:{ionPlus:.5,regenPct:1}},
  admiral:{n:'Aspect of the Admiral',d:'Your Admiral’s Command starts one power level higher (full power from round 2), and your flagship gets +10 aim.',fx:{cmdTier:1,aim:10}}};
