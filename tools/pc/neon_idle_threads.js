'use strict';
// The installed T3 Code stores V2 thread state in this SQLite projection. Read it only.
// Run with node --experimental-sqlite (Node 22.11 uses that flag).
const { DatabaseSync } = require('node:sqlite');
const [dbPath, workspace, cutoffText] = process.argv.slice(2);
const cutoff = Date.parse(cutoffText);
if (!dbPath || !workspace || !Number.isFinite(cutoff)) throw new Error('Missing Neon cleanup inputs');
const canonical = p => typeof p === 'string' ? p.replaceAll('\\', '/').toLowerCase() : '';
const terminal = new Set(['completed', 'failed', 'cancelled', 'interrupted']);
const db = new DatabaseSync(dbPath, { readOnly: true });
try {
  const rows = db.prepare(`
    SELECT t.thread_id AS id, json_extract(t.payload_json, '$.worktreePath') AS path,
      json_extract(t.payload_json, '$.branch') AS branch,
      json_extract(t.payload_json, '$.settledAt') AS settled, t.archived_at AS archived,
      t.deleted_at AS deleted, t.updated_at AS updated, p.workspace_root AS workspace,
      (SELECT count(*) FROM orchestration_v2_projection_runs r
        WHERE r.thread_id = t.thread_id) AS runs,
      (SELECT max(completed_at) FROM orchestration_v2_projection_runs r
        WHERE r.thread_id = t.thread_id) AS completed,
      (SELECT count(*) FROM orchestration_v2_projection_runs r WHERE r.thread_id = t.thread_id
        AND (r.completed_at IS NULL OR r.status NOT IN ('completed','failed','cancelled','interrupted'))) AS running,
      EXISTS(SELECT 1 FROM orchestration_v2_projection_provider_turns r WHERE r.thread_id = t.thread_id
        AND (r.completed_at IS NULL OR r.status NOT IN ('completed','failed','cancelled','interrupted'))) AS turning,
      EXISTS(SELECT 1 FROM orchestration_v2_projection_provider_threads r WHERE r.thread_id = t.thread_id
        AND r.status NOT IN ('idle','stopped')) AS busy,
      EXISTS(SELECT 1 FROM orchestration_v2_thread_launch_workflows w WHERE w.thread_id = t.thread_id
        AND w.status NOT IN ('completed','failed','cancelled')) AS launching,
      (SELECT status FROM projection_thread_sessions s WHERE s.thread_id = t.thread_id) AS legacyStatus,
      (SELECT active_turn_id FROM projection_thread_sessions s WHERE s.thread_id = t.thread_id) AS legacyTurn
    FROM orchestration_v2_projection_threads t
    LEFT JOIN projection_projects p ON p.project_id = t.project_id
    WHERE json_extract(t.payload_json, '$.worktreePath') IS NOT NULL
  `).all();
  const groups = new Map();
  for (const row of rows) {
    const key = canonical(row.path);
    if (!key) continue;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(row);
  }
  const old = value => typeof value === 'string' && Number.isFinite(Date.parse(value)) && Date.parse(value) < cutoff;
  const eligible = row => canonical(row.workspace) === canonical(workspace) &&
    old(row.archived || row.deleted || row.settled) && old(row.updated) &&
    (!row.runs || old(row.completed)) && !row.running && !row.turning && !row.busy && !row.launching &&
    !row.legacyTurn && (!row.legacyStatus || terminal.has(row.legacyStatus) || row.legacyStatus === 'stopped');
  for (const group of groups.values()) {
    if (!group.every(eligible)) continue;
    const branches = [...new Set(group.map(row => row.branch).filter(Boolean))];
    if (branches.length !== 1 || !/^neon\/issue-[1-9]\d*(?:-[\w-]+)?$/.test(branches[0])) continue;
    const ids = group.map(row => row.id).filter(id => /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(id));
    console.log(JSON.stringify({ path: group[0].path, branch: branches[0], ids }));
  }
} finally {
  db.close();
}
