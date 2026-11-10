// campaign_run.js functions that battle.js calls when they exist (typeof checks). The browser always loads campaign_run.js
// beside battle.js, so the harness defines them too. This extract is a fallback: the harness reads the root campaign_run.js first.
function nemAdaptName(a,fac){ const T=NEM_ADAPT_FAC[fac]||{}; if(T.special&&T.special.id===a) return T.special.n; return T[a]||(NEM_ADAPT[a]&&NEM_ADAPT[a].n)||a; }
