// Smoke-test player bot: plays one alternating round for the player side.
// Each pending ship fires every ready non-flak weapon it can at the first legal target,
// then ends its activation; the enemy AI answers between activations.
// Resolves to 'r2' once the round advances, or 'win' / 'loss' if the battle ends.
async function botAct(u){
  if(!u||u.dead||B.over) return;
  selectUnit(u);
  for(let i=0;i<u.weapons.length;i++){
    const w=u.weapons[i]; if(w.k==='flak'||B.over) continue;
    const t=alive('enemy').find(e=>canFire(u,w,e)); if(t) await fireWeapon(u,i,t);
  }
}
async function altRound(){
  const r0=B.round, sleep=ms=>new Promise(r=>setTimeout(r,ms)); let g=0;
  while(B&&!B.over&&B.round===r0&&g++<40){
    const pp=pendingP();
    if(pp.length&&B.side==='player'&&!B.busy){ await botAct(pp[0]); if(B.over) break; await endActivation(true); }
    else await sleep(250);
  }
  return B.over?B.over:(B.round>r0?'r2':'stuck');
}
