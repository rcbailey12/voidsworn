// Close-up sheet of the new round 2 pieces (issue #271). Loads after mock2.js (?pieces=1 skips the screen build) and reuses its builders.
// Each piece is drawn restrained (left) and bold (right) at 1.5x so it reads on a phone.
document.body.classList.remove('restrained', 'bold');
const sheet = document.getElementById('ui');
sheet.style.cssText = 'position:absolute;inset:0;padding:22px 26px;';
const TITLE = `<div style="display:flex;align-items:baseline;gap:18px;margin-bottom:14px">
  <span style="font-family:Oxanium;font-weight:700;font-size:30px;letter-spacing:0.06em;color:var(--bone)">ROUND 2: THE NEW PIECES, CLOSE UP</span>
  <span class="s17 dim">Issue 271. Restrained left, bold right, at 1.5x. Numbers are Muse #292's numbered changes.</span></div>`;
function cell(num, title, note, inner, w) {
  return `<div style="width:${w}px;background:rgba(6,9,16,0.72);border:1px solid rgba(230,220,196,0.14);padding:12px 14px 14px">
    <div style="display:flex;align-items:baseline;gap:10px;margin-bottom:8px"><span style="font-family:Oxanium;font-weight:700;font-size:20px;color:var(--gilt)">${num}</span>
    <span style="font-family:Oxanium;font-weight:700;font-size:18px;letter-spacing:0.06em;color:var(--bone);text-transform:uppercase">${title}</span></div>
    <div class="s15 dim" style="margin-bottom:10px;line-height:1.35">${note}</div>${inner}</div>`;
}
const pair = (fn, w) => `<div style="display:flex;gap:14px">${['restrained', 'bold'].map(m => `<div class="${m}" style="width:${w}px;zoom:1.5">${fn(m)}</div>`).join('')}</div>`;
const well = (html, pad = '9px 12px') => `<div class="well" style="padding:${pad}">${html}</div>`;

// 6: Heat gauge
const heatP = pair(() => well(`<div class="row" style="gap:10px">${heatGauge()}<span class="s12 dim3">run setting</span></div>`, '7px 10px'), 190);
// 7: weapon rows, token form, with the cooldown tag
const W2 = WEAPONS.slice(0, 3).concat([{ k: 4, n: 'Cinder torpedo', tok: 'F 1-6', hit: 64, exp: 42, cd: 2 }]);
function rows2() {
  return `<div class="wtab hd"><span></span><span>Weapon</span><span style="text-align:center">Arc</span><span style="text-align:right">Hit</span><span style="text-align:right">Dmg</span><span style="text-align:right">Cost</span></div>`
    + W2.map(w => `<div class="wtab wrow ${w.armed ? 'armed' : ''} ${w.hit ? '' : 'no'}">${key(w.k)}<span class="wn">${w.n}</span><span class="tok">${w.tok}</span>`
      + (w.hit ? `<span class="hit">${w.hit}%</span><span class="exp">~${w.exp}</span>` : `<span class="why">${w.why}</span>`)
      + `<span class="cost ${w.cd ? 'cd' : ''}">${w.cd ? 'CD ' + w.cd : 'free'}</span></div>`).join('');
}
const wpnP = pair(() => well(rows2()), 400);
// 12: ghost expected markers (target block and its plate)
const ghostP = pair(() => well(targetHtml()) + `<div style="position:relative;height:58px;margin-top:8px"><div class="plate e tgt" style="left:90px;top:22px;transform:none">
  <div class="pn">Hullbreaker wrecker</div>${hbar(0.55, 8, 0.47)}${sbar([0, 18, 18, 18], 18, [null, null, null, 0])}<span class="odds">64%  2 guns</span></div></div>`, 400);
// 14: keyword tooltip beside the hovered element (never over the column centre: it opens to the left of the column)
function tipFn(m) {
  return `<div style="position:relative;height:150px">
    <div class="ktip" style="left:0;top:4px;width:212px"><div class="kw">Starboard arc, range 1 to 5</div>
      <div class="kd">This gun fires into the 120 degree cone off the ship's right side, from 1 to 5 hexes. Best at 3 or closer.</div>
      <div class="kx">S 1-5 on a weapon row. Turn with Q / E to bring it to bear.</div></div>
    <svg style="position:absolute;left:212px;top:46px" width="20" height="10"><path d="M0 5h22" stroke="#d0a64b" stroke-width="1.5"/></svg>
    <div class="well" style="position:absolute;left:232px;top:30px;width:168px;padding:6px 4px"><div class="wtab wrow armed" style="grid-template-columns:22px 1fr 40px;padding:0 6px">${key(2)}<span class="wn">Broadside</span><span class="tok hov">S 1-5</span></div></div>
  </div>`;
}
const tipP = pair(tipFn, 400);
// 10: the danger badge on roster rows and on the hovered hex
function dngFn() {
  const rows = [FLEET[0], FLEET[4], FLEET[6], FLEET[1]];
  return well(rows.map(s => { const f = s.hp / s.mx, up = s.st === 'Up', done = s.st === 'Done';
    return `<div class="rr" style="padding:4px 6px;${up ? 'background:rgba(77,61,26,0.45);outline:1px solid var(--gilt);outline-offset:-1px;' : ''}${done ? 'opacity:0.55;' : ''}">
      <div class="row" style="gap:6px"><span class="grow ell" style="font-weight:600">${star(s)}${s.n}</span>${f < 0.35 ? '<span class="lowtag">LOW</span>' : ''}${s.dz ? dng(s.dz) : ''}<span class="s13 ${up ? 'gilt' : s.st === 'Ready' ? 'verd' : 'dim3'}" style="font-weight:600">${s.st}</span></div>
      <div style="margin-top:3px">${hbar(f)}${sbar(s.sh, s.sm)}</div></div>`; }).join(''), '4px 4px')
    + `<div style="position:relative;height:34px;margin-top:8px"><div class="hexbadge" style="left:0;top:4px">${dng(2)}<span>2 enemies can reach this hex</span><span class="dim3">now 1</span></div></div>`;
}
const dngP = pair(dngFn, 250);
// 13 and 9: the unacted set (two forms) and the End box counted line, height reserved
function setFn() {
  const r = READY;
  const b = `<div class="unacted" style="padding:0"><span class="s13" style="font-weight:600">5 unacted</span>${r.slice(0, 3).map(s => `<span class="chip">${s.n}</span>`).join('')}<span class="s13 dim">+2</span></div>`;
  const c = `<div class="unacted" style="padding:0"><span class="s13" style="font-weight:600">5 unacted</span><span class="s12 dim3">in reach first:</span><span class="chip">Unyielding Oath${dng(3)}</span><span class="chip">Debt Paid</span><span class="s13 dim">+3</span></div>`;
  return well(`<div class="s12 dim3" style="margin-bottom:3px">B form: roster order</div>${b}<div class="s12 dim3" style="margin:8px 0 3px">C form: ships in reach first</div>${c}`)
    + `<div style="height:8px"></div>` + well(`<span class="caps">3 End, and what happens next</span><div class="counted" style="margin-top:4px"><span class="verd" style="font-weight:600">5 ships still Ready</span></div>
      <div class="s12 dim3">the line above is empty when none are Ready; its height stays</div>`);
}
const setP = pair(setFn, 400);

sheet.innerHTML = TITLE + `<div style="display:grid;grid-template-columns:1260px 600px;gap:16px">
  <div style="display:flex;flex-direction:column;gap:16px">
    ${cell('7', 'Weapon rows, token form', 'One line per weapon, fixed columns in scan order: key, name, arc and range token, hit chance, expected damage, cost. The cost tag is the weapon\'s cooldown (CD 2 on a torpedo); guns with none read free. Reason text replaces the odds on a gun that cannot fire.', wpnP, 1260)}
    ${cell('12', 'Ghost expected markers', 'The hatched part of the target\'s hull bar and of the shield facing that will drop is what the volley is expected to take; the same ghost shows on the target\'s plate in the field. Labelled expected, never certain.', ghostP, 1260)}
    ${cell('14', 'Keyword tooltip, one layer', 'Hovering a keyword (arc tokens, Adapted, Weakness, Braced, LOW, ARM, Heat, facing names) opens one short definition beside it. From the column it opens to the left, over the field, so the column stays readable.', tipP, 1260)}
  </div>
  <div style="display:flex;flex-direction:column;gap:16px">
    ${cell('6', 'Heat gauge', 'Nine segments, the run\'s Heat level (3 here) in the top bar. Heat is a run difficulty setting in the rules, so it has no per-shot cost (see the README).', `<div style="display:flex;flex-direction:column;gap:10px">${['restrained', 'bold'].map(m => `<div class="${m}" style="zoom:1.5;width:300px">${well(`<div class="row" style="gap:10px">${heatGauge()}<span class="s12 dim3">${m}</span></div>`, '7px 10px')}</div>`).join('')}</div>`, 600)}
    ${cell('10', 'Danger badge', 'How many enemies can reach a ship next turn, on its roster row and on the hex under the pointer. Reticle glyph plus number, so it never rides on colour alone.', `<div style="display:flex;flex-direction:column;gap:10px">${['restrained', 'bold'].map(m => `<div class="${m}" style="zoom:1.5;width:360px"><div class="s12 dim3" style="margin-bottom:2px">${m}</div>${dngFn()}</div>`).join('')}</div>`, 600)}
  </div></div>
  <div style="margin-top:16px">${cell('13 and 9', 'Unacted set and the counted line', 'Top bar, under the acted pips: how many ships still have to act and up to three names, with no arrows and no numbering, because the player picks the order. The End box line shows only when ships are still Ready and keeps its height so End ship never moves.', setP, 1876)}</div>`;
