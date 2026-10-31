'use strict';
function replace(s,a,b,label){if(s.split(a).length!==2)throw Error('Expected one anchor: '+label);return s.replace(a,b);}
function nemJS(s){
 s=replace(s,'let pickA=Object.keys(score).filter(k=>!N.adapt.includes(k)&&score[k]>0)',"const blocked=new Set(); if((N.revealed||[]).includes('ion')) blocked.add('shields'); if((N.revealed||[]).includes('torp')) blocked.add('pd');\n  let pickA=Object.keys(score).filter(k=>!blocked.has(k)&&!N.adapt.includes(k)&&score[k]>0)",'nem scored guard');
 s=replace(s,'Object.keys(score).filter(k=>!N.adapt.includes(k))[0]','Object.keys(score).filter(k=>!blocked.has(k)&&!N.adapt.includes(k))[0]','nem fallback guard');
 const a="else { N.clock=1; N.gloat=o.myFlagDead?'flagship':result==='retreat'?'retreat':'loss'; out.push(say(`${nemFull()} drove you off. He will remember this.`)); }";
 const b=a.slice(0,-2)+"\n    const found=Array.isArray(o.found)?o.found.filter(k=>N.weak.includes(k)):[]; nemFoundMerge(found);\n    const learned=[...new Set(found)]; const w=learned[0]||nemReveal();\n    if(w) out.push(`Your analysts piece together the engagement: ${N.name} is vulnerable to ${(learned.length?learned:[w]).map(k=>NEM_WEAK[k].n).join(', ')}.`);\n    else out.push(`The engagement confirms what your analysts already held: the file on ${N.name} is complete.`); }";
 s=replace(s,a,b,'loss learning');
 s=replace(s,'  if(beh.adaptFast){ const a=nemAdapt();',"  if(result==='win'){ const fw=nemFoundMerge(o.found); if(fw.length) out.push(`Weakness confirmed: ${fw.map(k=>NEM_WEAK[k].n).join(', ')}.`); }\n  if(beh.adaptFast){ const a=nemAdapt();",'merge before fast adaptation');return s;
}
function nemGD(s){
 s=replace(s,'\tvar ks = ssort(score.keys().filter(func(k): return not N["adapt"].has(k) and score[k] > 0)', '\tvar blocked = []\n\tif or_(N.get("revealed"), []).has("ion"): blocked.append("shields")\n\tif or_(N.get("revealed"), []).has("torp"): blocked.append("pd")\n\tvar ks = ssort(score.keys().filter(func(k): return not blocked.has(k) and not N["adapt"].has(k) and score[k] > 0)','GD scored guard');
 s=replace(s,'var rest = score.keys().filter(func(k): return not N["adapt"].has(k))','var rest = score.keys().filter(func(k): return not blocked.has(k) and not N["adapt"].has(k))','GD fallback guard');
 s=replace(s,'\tif jt(beh.get("adaptFast")):\n\t\tvar a = nemAdapt()',`\t\tvar found = o["found"].filter(func(k): return N["weak"].has(k)) if o.get("found") is Array else []
\t\tnemFoundMerge(found)
\t\tvar learned = []
\t\tfor k in found:
\t\t\tif not learned.has(k): learned.append(k)
\t\tvar w = learned[0] if not learned.is_empty() else nemReveal()
\t\tif w != null:
\t\t\tvar names = (learned if not learned.is_empty() else [w]).map(func(k): return str(NEM_WEAK[k]["n"]))
\t\t\tout.append("Your analysts piece together the engagement: " + str(N["name"]) + " is vulnerable to " + ", ".join(PackedStringArray(names)) + ".")
\t\telse: out.append("The engagement confirms what your analysts already held: the file on " + str(N["name"]) + " is complete.")
\tif result == "win":
\t\tvar fw = nemFoundMerge(o.get("found"))
\t\tif not fw.is_empty(): out.append("Weakness confirmed: " + ", ".join(PackedStringArray(fw.map(func(k): return str(NEM_WEAK[k]["n"])))) + ".")
\tif jt(beh.get("adaptFast")):
\t\tvar a = nemAdapt()`,'GD learning');
 s=replace(s,'{"fled": jt(B.get("nemFled")), "beat": nemBeatOf','{"found": or_(B.get("nemFound"), []), "fled": jt(B.get("nemFled")), "beat": nemBeatOf','GD battle consumer');return s;
}
const boonJS=`function rollBoonOffer(p,minR){
  ensurePatrons(); const s=(RUN&&RUN.sector)||1, have=boonPatrons(), kit=fleetKit();
  // Candidate tuning: useful on-patron entries carry weight 3, other held patrons weight 1.
  const pool=Object.keys(BOONS).filter(id=>{ const b=BOONS[id]; return b.p&&!b.leg&&(b.p===p||RUN.patrons.includes(b.p))&&!hasBoon(id)&&boonUseful(id,kit); });
  const out=[];
  while(out.length<3&&pool.length){
    const total=pool.reduce((n,id)=>n+(BOONS[id].p===p?3:1),0); let x=rnd()*total, at=0;
    for(;at<pool.length-1;at++){ const w=BOONS[pool[at]].p===p?3:1; if(x<w) break; x-=w; }
    const id=pool.splice(at,1)[0]; out.push({id,r:rollRarity(minR,s,p)});
  }
  const duos=Object.keys(BOONS).filter(id=>{ const b=BOONS[id]; return b.duo&&!hasBoon(id)&&boonUseful(id,kit)&&b.duo.includes(p)&&b.duo.every(q=>have.has(q)||q===p)&&b.duo.some(q=>q!==p&&have.has(q)); });
  const L=legendaryFor(p,minR); let special=null;
  // One special slot: when both qualify, duo 45 / legendary 55. This is explicit candidate tuning.
  if(L) special=duos.length&&rnd()<.45?{id:pick(duos),r:0}:{id:L,r:3};
  else if(duos.length&&(out.length<3||rnd()<.45)) special={id:pick(duos),r:0};
  if(special){ if(out.length>=3) out[2]=special; else out.push(special); }
  return out;
}
`;
const boonGD=`func rollBoonOffer(p, minR) -> Array:
\tensurePatrons()
\tvar s = RUN["sector"] if RUN != null else 1
\tvar have = boonPatrons(); var kit = fleetKit(); var pool = []
\tfor id in BOONS.keys():
\t\tvar b = BOONS[id]; var bp = b.get("p")
\t\tif jt(bp) and not jt(b.get("leg")) and (bp == p or RUN["patrons"].has(bp)) and not hasBoon(id) and boonUseful(id, kit): pool.append(id)
\tvar out = []
\twhile out.size() < 3 and not pool.is_empty():
\t\tvar total = 0
\t\tfor id in pool: total += 3 if BOONS[id].get("p") == p else 1
\t\tvar x = rnd() * total; var at = 0
\t\twhile at < pool.size() - 1:
\t\t\tvar weight = 3 if BOONS[pool[at]].get("p") == p else 1
\t\t\tif x < weight: break
\t\t\tx -= weight; at += 1
\t\tvar id = pool[at]; pool.remove_at(at); out.append({"id": id, "r": rollRarity(minR, s, p)})
\tvar duos = []
\tfor id in BOONS.keys():
\t\tvar b = BOONS[id]
\t\tif not jt(b.get("duo")) or hasBoon(id) or not boonUseful(id, kit) or not b["duo"].has(p): continue
\t\tvar all_ok = true; var some = false
\t\tfor q in b["duo"]:
\t\t\tif not (have.has(q) or q == p): all_ok = false
\t\t\tif q != p and have.has(q): some = true
\t\tif all_ok and some: duos.append(id)
\tvar L = legendaryFor(p, minR); var special = null
\tif L != null: special = {"id": pick(duos), "r": 0} if not duos.is_empty() and rnd() < 0.45 else {"id": L, "r": 3}
\telif not duos.is_empty() and (out.size() < 3 or rnd() < 0.45): special = {"id": pick(duos), "r": 0}
\tif special != null:
\t\tif out.size() >= 3: out[2] = special
\t\telse: out.append(special)
\treturn out
`;
function boonCore(s){const a=s.indexOf('function rollBoonOffer('),b=s.indexOf('function legendaryFor(',a);if(a<0||b<0)throw Error('boon function anchors');return s.slice(0,a)+boonJS+s.slice(b);}
function boonCampaign(s){const a=s.indexOf('func rollBoonOffer('),b=s.indexOf('func legendaryFor(',a);if(a<0||b<0)throw Error('GD boon anchors');return s.slice(0,a)+boonGD+s.slice(b);}
function boonData(s){return replace(s,"const BOON_NEED={h_brood:","const BOON_NEED={L_storm:'shields',h_brood:",'shield legendary gate');}
function battleConsumer(s){return replace(s,'{fled:!!B.nemFled,beat:nemBeatOf','{found:B.nemFound||[],fled:!!B.nemFled,beat:nemBeatOf','browser battle consumer');}
module.exports={replace,nemJS,nemGD,boonCore,boonCampaign,boonData,battleConsumer};
