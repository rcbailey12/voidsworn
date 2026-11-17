# Mission Control phone redesign: proposal (r1, Nov 17 2026, not built)

Design review only. Nothing in the repo, runners, PC, settings or Tailscale was changed.
Mockups: MC_redesign_r1_{now,lanes,detail,bad}_mockup.png (412 x 720, Pixel width). All mockup data is SAMPLE: the "now" and "lanes" frames copy the real PC state at 22:38 CST Nov 16 as the redesigned page would show it; the "bad night" frame is invented to show failed, blocked, stale, offline and a question for Ryan.

## What I checked (22:38 CST, Nov 16)
- Page: docs/mission/index.html + tools/pc/mission/publisher.js (PR 926, issue 918), phone link through Tailscale Serve (PR 939, issue 934, merged). Read-only, local, refreshes each minute. Only source: PC lane text files and each job's status/result/log. No GitHub reads.
- Live snapshot: Downloads\voidsworn_test\mission_local\status.json at 04:37 UTC, plus the lane files behind it.
- Runner work in flight: PR 948 (#947 lane folders), PR 949 (#944 pause report), PR 950 (#945 self-test time), PR 864 (#860). None touch tools/pc/mission or docs/mission. No overlap. The page cannot prove any of them is installed and will not claim to.

## Why the screenshots were wrong (real evidence)
1. Codex main showed "#944, title unavailable, stale". The main lane was in fact running #928 (Hull hit redo); its log was written at 22:38. At 21:58 the misconfigured lane C copy claimed #944 inside the main lane's folder (board\issue-944), the Board stopped it at 22:00, and its status.json was left saying "running". The page picks the newest-started job folder per lane, so the dead stub hid the live job. #947 stops new stubs; the page still needs to rank by "what the live chain says is current" and flag orphans.
2. Codex main's "Next #823, #912 +2" came from chains 15H, 15Z and 16A, which the Board paused ("paused by the Board ... not started"). The parser does not know that line, so paused chains count as live queues. The real queue (chain 16B) is 929, 912, 930, 920, 921. Lane B's "Next #903, #922" has the same cause (paused B23/B25); both of those jobs already ran.
3. DeepSeek showed #932 stale for 227 min. The run ended at 19:58 (checks failed, retry clone failed, ds_15s.txt says "all done"). DeepSeek's latest.txt points at the job folder, not a run, so the page falls back to the 18:48 run whose old status says "running". The fix later merged as PR 937. The page has no GitHub view, so it cannot see that.
4. "Title unavailable" happens when the runner left no task header. GitHub has every title.

## 1. Redesign with data we already have
- Feed strip: PC feed fresh/lost with time and age (exists). Per-lane "data stale" kept separate from the PC feed.
- Attention first, each item with a kind word and a plain "what this means for you" line: Failed, Blocked (with its reason: usage limit, chain stopped, refused), Stale, Leftover record (orphan "running" stub the live chain does not name), Ended without a push.
- Compact lane cards: lane + role (GPU builds, Godot UI, code only, small code jobs), status, short title, issue number small, started, last activity, one "Next" line. Tap opens a sheet: full title, issue link, PR search link, runner state, log time, chain, full queue, sources.
- Publisher fixes (same files, no new source): honour "paused"/"stopped" lines so dead chains drop out of Next; let the newest started chain's current job win over a newer orphan folder, and list the orphan under Attention; treat a DeepSeek chain's "all done" plus a retry log ending as ended, not running.
- No percentages, ETAs, progress stages or "all clear". Counts only (Working, Idle, Attention). Art and motion: none that suggests activity.

## 2. What needs a new source (smallest pick)
- **One read-only GitHub read by the publisher, every 5 minutes, with no token.** The repo is public, so 2 to 3 unauthenticated GET calls per round (open and recent issues with labels and titles; recent PRs by branch; recent issue comments) stay well under GitHub's 60 an hour. Gives: real titles, "PR open / merged" per delivery branch, the "needs Ryan" marker, and last recorded activity for Claude (opus/ branches, Board commits), Muse (muse/ branches) and Artoo (comments starting "Artoo (technical review):"). It is shown as "GitHub check, last read HH:MM"; a failed read says "not checked", never "nothing". Data stays on the PC and goes out only over the existing Tailscale link. If you prefer, the PC's existing GitHub login could be used instead, but it has write rights, so I'd avoid it.
- **Needs Ryan marker:** today nothing reliable exists. AGENTS.md already defines a `ryan` label ("waiting on Ryan") but no open issue carries it; every Codex issue carries `blocked` as a dispatch lock, so `blocked` can never mean "you"; LOOP.md's "Waiting on Ryan" is free text with only answered items. Smallest reliable fix: the Board puts the `ryan` label on the issue that holds the question and adds one line to the top of its body: `Ask Ryan: <one question> | Picture: <link>`. The Board removes both when answered. The page shows only labelled issues with that line, and until the first one exists it says "For you: not checked". This is a rulebook line plus a habit, not a second task list.
- **Other agents:** no live feed exists for Claude threads, Muse/Rey or Artoo. Claude threads have no status the PC can read; Muse's watcher runs off the PC; Artoo posts through your GitHub account. So the Crew section shows "Last on GitHub HH:MM: <what>" with a NO LIVE FEED tag. A real heartbeat would need each agent to write one, which is later work.
- **Art:** I found no Artoo droid art and no Muse or Rey likeness in the repo or the PC concepts folder (only concepts\glasswright_r9). godot/portraits/crests/reyes.svg is an unrelated game crest. The mockup leaves Artoo's slot empty and marked "art not on file"; Claude and Muse get plain monograms.

## 3. Mockup
See the four pictures. Look: the game's own fonts (Chakra Petch headings, Barlow text, Azeret Mono numbers), deep space black, ember accents, steel lines, fine tick marks and corner brackets.

## 4. Build and check plan (about 2 agent runs + 1 review round)
- Run 1 (Codex lane C or a cloud worker, code only): publisher fixes (paused chains, orphan stubs, DeepSeek ended runs), the GitHub read, the new page. Same two files plus fixtures and tests; nothing in runners or launchers.
- Fixtures for each view: running, waiting, blocked, failed, finished, stale, leftover record, ended without push, PC offline, GitHub not checked, needs-Ryan present and absent. The 22:38 night becomes a fixture (main lane with the #944 stub, paused chains, DeepSeek 932) and must show #928 as working with the 16B queue.
- Existing selftest.bat and browser_test.js extended; pictures at 412 px wide for each view, labelled revision and "fixture".
- Then on the PC: run against live folders, compare with LOOP and GitHub by hand, phone check on the Pixel through PHONE_ON. Board review, then you look at the phone.

## 5. Decisions for Ryan
1. GitHub read with no token (my pick) or the PC's existing GitHub login.
2. "Needs Ryan" marker: `ryan` label + "Ask Ryan:" line (my pick), or the LOOP "Waiting on Ryan" section in a fixed format.
3. Artoo art: send me the approved image, or keep the empty slot for now (my pick until you send it).
4. Build after #947/#948 merge (my pick, so the fixture matches the fixed runner), or now in parallel.
