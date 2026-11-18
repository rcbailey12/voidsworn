// commission_policy.js - the purchase gate for the Glasswright commission
// (G-C) layer, shared by the driver and commission_test.js.
//
// Artoo on PR 1102: the shipyard loop checked "one order in flight" once before
// walking the stock shelf, so one visit could queue several hulls. The gate
// below is checked at the purchase point, inside mcGeBuyHull, so the second
// affordable offer is refused even when the first left the queue after the
// loop's earlier check.
//
// One order at a time, paid in full now, and the arriving hull must fit the
// command cap when the order is placed.
function mcCommissionCanOrder(pending, credits, cost, cpUsed, cpCost, cpCap){
  if(!(pending<1)) return false;
  if(!(credits>=cost)) return false;
  return cpUsed+cpCost<=cpCap;
}
if(typeof module!=='undefined'&&module.exports) module.exports={mcCommissionCanOrder};
