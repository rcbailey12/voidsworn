'use strict';
const HOUR_MS = 3600000;
const REQUEST_LIMIT = 30;
const MINUTE_LIMIT = 3;
const REMAINING_FLOOR = 15;
const SOURCE_INTERVAL_MS = {questions: 10 * 60000, issues: 10 * 60000, pulls: 10 * 60000, comments: 30 * 60000};
const BACKOFF_MS = [10, 20, 40, 60].map(n => n * 60000);
const iso = n => n > 0 ? new Date(n).toISOString() : null;
class Budget {
  constructor() { this.requests = []; this.pauseUntil = 0; this.remaining = null; this.resetAt = 0; this.pauseReason = null; }
  canSpend(now) {
    this.requests = this.requests.filter(t => t > now - HOUR_MS);
    return now >= this.pauseUntil && this.requests.length < REQUEST_LIMIT && this.requests.filter(t => t > now - 60000).length < MINUTE_LIMIT;
  }
  nextAvailableAt(now) {
    this.canSpend(now);
    const recent = this.requests.filter(t => t > now - 60000);
    return Math.max(now, this.pauseUntil, this.requests.length >= REQUEST_LIMIT ? this.requests[0] + HOUR_MS : 0,
      recent.length >= MINUTE_LIMIT ? recent[0] + 60000 : 0);
  }
  spend(now) {
    if (!this.canSpend(now)) return false;
    this.requests.push(now);
    return true;
  }
  headers(headers, status, now) {
    const remaining = headers.get('x-ratelimit-remaining'), reset = headers.get('x-ratelimit-reset');
    if (remaining !== null && /^\d+$/.test(remaining)) this.remaining = +remaining;
    if (reset !== null && /^\d+$/.test(reset)) this.resetAt = +reset * 1000;
    if ([403, 429].includes(status)) {
      this.pauseUntil = Math.max(this.pauseUntil, this.resetAt > now ? this.resetAt + 60000 : now + HOUR_MS + 60000);
      this.pauseReason = 'GitHub rate limit';
    } else if (remaining !== null && this.remaining <= REMAINING_FLOOR) {
      this.pauseUntil = Math.max(this.pauseUntil, this.resetAt > now ? this.resetAt : now + HOUR_MS);
      this.pauseReason = 'GitHub remaining allowance is 15 or fewer';
    }
  }
  snapshot(now) {
    const available = this.canSpend(now);
    return {plannedPerHour: 24, ceilingPerHour: REQUEST_LIMIT, ceilingPerMinute: MINUTE_LIMIT, requestsPastHour: this.requests.length,
      remaining: this.remaining, resetAt: iso(this.resetAt), pausedUntil: iso(this.pauseUntil),
      reason: available ? null : now < this.pauseUntil ? this.pauseReason : this.requests.length >= REQUEST_LIMIT ? 'Local hourly ceiling reached' : 'Request pacing; waiting for the next minute'};
  }
}
function sourceRecord(name) {
  return {intervalSeconds: SOURCE_INTERVAL_MS[name] / 1000, lastSuccessfulReadAt: null, lastAttemptAt: null,
    complete: false, reason: 'not checked', failures: 0, nextAttemptAt: null};
}
function backoff(failures) { return BACKOFF_MS[Math.min(Math.max(0, failures - 1), BACKOFF_MS.length - 1)]; }
module.exports = {Budget, sourceRecord, backoff, SOURCE_INTERVAL_MS};
