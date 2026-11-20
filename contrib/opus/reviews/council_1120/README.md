# Adversarial council audit, Nov 20 2026

Outside review of the whole game, findings only, no code changes. Ryan asked for it in the Project (Nov 20 14:37 UTC) and
approved this plan ("Yes please", 14:38 UTC). Not a ruling: every finding is a proposal until the Board files it and, where
it is taste, Ryan picks.

## Why these seats

The Opus codebase audit (issue 1333, PR 1339: bugs 1336, 1337, 1338; report contrib/opus/reviews/codebase_audit_1120.md)
already covered rules parity, saves, battle state and campaign flow. There is no code QA seat. The council covers what that
audit did not: how the game feels to a new player, the screens, the art, the lore and Godot practice.

| Seat | Brief | Who sits it |
|---|---|---|
| First-time player | seats/first_time_player.md | Fable (one leg) and Muse's free legs: DeepSeek, Qwen, Grok, Google Flash (one leg each) |
| UI/UX expert | seats/ui_ux.md | Fable and Rey (Muse), blind of each other |
| Graphic design and art | seats/art.md | Fable and Rey, blind of each other |
| Sci-fi lore | seats/lore.md | Fable and Rey, blind of each other |
| Godot game dev | seats/godot_dev.md | Fable (reads the code); Astra later goes deeper |

Free models sit only the first-time player seat: on code and art they add noise the Board has to sift.

## Rounds

1. **Blind round.** Every seat writes alone from the pack (pack.md) and its seat brief. Fable runs as Opus-thread subagents in
   the cloud; Muse runs as one muse issue (muse_issue.md), Rey's blind leg first as always (R89).
2. **Challenge round.** Fable reads Muse's findings and Muse reads Fable's (challenge.md). Each must try to knock findings down:
   wrong, already fixed on main, already ruled by Ryan, not something a player would feel, or a fix that breaks a ruling.
   A finding survives only if it stands up to that.
3. **Ranked list.** The thread merges what survived into one list ordered by what a player would feel most (ranking below),
   checks each against live main and FINDINGS, and sends it to the Board to file.
4. **Astra pass (held).** One gpt-6.2-astra deep engineering and Godot pass that reads the ranked list and goes after what the
   council could only point at (astra_brief.md). Ryan gets one Astra shot in the next two days: the Board confirms before it
   is spent.

## Ranking

Score each finding: **Feel** (how much a player notices it: 3 every run, 2 most runs, 1 sometimes, 0 never) times **Reach**
(3 first hour, 2 mid run, 1 late or rare) plus **Agreement** (+1 per independent seat that found it, +1 if it survived the
challenge with no counter). Ties go to the cheaper fix. Taste items (look, tone) are marked "Ryan picks" and never filed as
a bug.

## Hard limits on every seat

- Findings only. Nobody edits game code, tools or docs.
- Never contradict an owner ruling as if it were a bug: check RULEBOOK.md and the newest FINDINGS rows. A seat may argue a
  ruling should be reopened, marked "reopen: Ryan's call", with the reason.
- Muse never gets sound work (Ryan, Nov 19). No seat reviews sound; it is out of scope.
- Ship builds in flight (Chorus rebuild 1291, Sunward starters, CD5 and others) are not finished: judge them as in progress,
  name the stage shown in the picture.
- Each finding cites its evidence: a picture name from the pack, a file:line, or a quote of the text.
