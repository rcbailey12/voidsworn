// spiral.js - the loss spiral recovery test, shared by the driver and its test.
// The README's definition: at the second loss in a row, the hull money (credits
// in the baseline, biomass in the biomass setups) cannot pay for a repair of 25
// percent of the worst ship's maximum hull, capped at what that ship is missing,
// priced as the shipped repair is priced (1 credit per 2 hull at priceMult), or
// buy the cheapest hull the faction can field. An empty fleet is no recovery.
//
// Run 1 priced a FULL repair of every point the worst ship was missing. Issue
// 1085 run 2 corrects that to the stated 25 percent test.
function mcRepairHull(worstMissing, worstMax){
  const miss=Math.max(0,worstMissing||0);
  if(!(miss>0)) return 0;
  return Math.min(miss,Math.ceil(Math.max(0,worstMax||0)*0.25));
}
function mcRepairCost(worstMissing, worstMax, pm){
  const mult=(pm==null)?1:pm;
  return Math.ceil(mcRepairHull(worstMissing,worstMax)/2*mult);
}
// alive false means an empty fleet. money is credits or biomass. A zero or
// missing cheapest hull price means the hull shelf is not a recovery route.
function mcUnrecoverable(worstMissing, worstMax, money, pm, cheapestHull, alive){
  if(alive===false) return true;
  const worst=Math.max(0,worstMissing||0);
  if(!(worst>0)) return false;
  const hull=cheapestHull||0;
  return money<mcRepairCost(worst,worstMax,pm)&&money<hull;
}
if(typeof module!=='undefined'&&module.exports) module.exports={mcRepairHull,mcRepairCost,mcUnrecoverable};
