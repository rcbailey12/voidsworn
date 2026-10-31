function nemAdaptName(a,fac){ const T=NEM_ADAPT_FAC[fac]||{}; if(T.special&&T.special.id===a) return T.special.n; return T[a]||(NEM_ADAPT[a]&&NEM_ADAPT[a].n)||a; }
