// Issue 1393: draws B2_1393_before_after (open b2.html and screenshot it at 1440x600). Usage: node draw.js <folder with before.json and after.json from dump.js>
const fs=require('fs'); const SP=process.argv[2];
const P=['before','after'].map(f=>JSON.parse(fs.readFileSync(SP+'/'+f+'.json')));
const col={asteroid:'#8a7b66',nebula:'#b8577f',storm:'#3fb6b0',debris:'#9a8f86',hulk:'#6b5f55',comet:'#c9b98a',station:'#d0a040'};
function panel(d,ox,title,sub){ const s=11.5; let g='';
  const xy=(q,r)=>[ox+30+s*Math.sqrt(3)*(q+r/2), 120+s*1.5*r];
  const hex=(cx,cy)=>{let p=[];for(let i=0;i<6;i++){const a=Math.PI/180*(60*i-30);p.push((cx+s*Math.cos(a)).toFixed(1)+','+(cy+s*Math.sin(a)).toFixed(1));}return p.join(' ');};
  for(const h of d.hexes){ const [x,y]=xy(h.q,h.r); const t=d.terrain[h.q+','+h.r]; g+=`<polygon points="${hex(x,y)}" fill="${t?(col[t]||'#777'):'#1a2030'}" stroke="#2c3550" stroke-width="0.8"/>`; }
  for(const u of d.units){ const [x,y]=xy(u.q,u.r); g+=`<circle cx="${x}" cy="${y}" r="${u.sq?4:7}" fill="${u.side==='player'?'#f2c14e':'#e5484d'}" stroke="#000" stroke-width="1"/>`; }
  const terr=[...new Set(Object.values(d.terrain))].join(', ')||'none';
  g+=`<text x="${ox+30}" y="40" font-size="24" font-weight="700" fill="#fff">${title}</text><text x="${ox+30}" y="70" font-size="16" fill="#c8cede">${sub}</text><text x="${ox+30}" y="94" font-size="15" fill="#9aa3b8">shape ${d.shape}, ${Object.keys(d.terrain).length} terrain hexes (${terr}); Corsairs, reinforcements round ${d.ev&&d.ev.r}</text>`;
  return g; }
const W=1440,H=600;
let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" font-family="Arial"><rect width="100%" height="100%" fill="#0d1018"/>`;
svg+=panel(P[0],0,'BEFORE (main): Battle 2, seed 121','the node\'s own shape');
svg+=panel(P[1],720,'AFTER (R366): Battle 2, seed 121','Battle 1\'s open strip');
svg+=`<text x="30" y="${H-18}" font-size="15" fill="#9aa3b8">B2_1393 · rules-state diagram (browser rules, fresh profile, Standard), not an in-game render · yellow = your fleet, red = Corsairs at the start · issue 1393</text></svg>`;
fs.writeFileSync(SP+'/b2.html',`<html><body style="margin:0;background:#0d1018">${svg}</body></html>`);
