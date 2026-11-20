# Neon seat: council referee (added by Ryan, Nov 20 18:36 UTC)

Ryan: "we should also add neon as a council reviewer after". Neon runs after its current reviews (1377, 1378) and after the
challenge round, before the final ranked list and before Astra.

Why this seat: Ryan sends anything important to Neon, and Neon is a different model family from both Fable (Claude) and
Muse's chair, so it is the best outside check on what the council agreed. It does not repeat a seat.

Job: read draft_ranked_list.md and the legs it cites (fable/legs/, contrib/muse/reviews/council_1120/, challenge/). For each
of the top 25 items, check it against the code at the named commit and against the pack pictures, and give one verdict:
Confirmed (OBSERVED, with file:line and quote or picture name), Wrong, Already fixed on main (name the PR), Ruled by Ryan
(FINDINGS row), Not felt by a player, or Bad fix (with a better one). Then up to 10 findings of its own the whole council
missed, in docs/REVIEW_PROTOCOL.md format. Findings only, no code changes. No sound.

Deliver: contrib/neon/reviews/council_1120_referee.md on branch neon/issue-<n>, "Refs #<n>". The thread then reorders the
list using Neon's verdicts and hands the top engineering items to Astra.
