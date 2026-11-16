# Check: PR 854, the R275 to R279 words landing (docs/words/2026-11.md)

Refs #256. Batch item 1 (Board brief, issue 256 comment 6915278472): PR 854 (OPEN, head de801d4de, branch opus/issue-841-r275) adds six lines to docs/words/2026-11.md, the verbatim words ledger, covering rulings R275 to R279. The brief: quotes verbatim against FINDINGS. Chair-verified line by line against contrib/opus/FINDINGS.md rows 305 to 309 on main. This is a record check, verified mechanically against the record of record; no council legs were run, because the question is textual identity, not judgment.

## Verdict: GO

All six lines check out. Four match the FINDINGS quotes exactly, word for word, including Ryan's own typing ("orchestraor" in R278's message, "builds.bomber" in R279's). The other two are fuller than the FINDINGS quotes, and in both cases the FINDINGS quote is an exact contiguous excerpt of the words-file line, with no word differing:

- R275 (21:28 CST): "1 Merge them, yes. 2. Yes, send it back for those." Identical in row 305.
- R276 (21:51 CST): the words file carries the full question, opening "okay i noticed that in loop.md, there's a rule that says only job GPU job at a time." Row 306 quotes the question from "is that a real rule" onward, an exact suffix of the fuller line.
- R276 (22:00 CST): "merge and make those changes to gpu jobs". Identical in row 306.
- R277 (22:17 CST): "Agree on null cannon, let's test it and see in game. Agreed on shield. Agreed on doom arc, it's almost there though but add the violet sheath." Identical in row 307.
- R278 (22:33 CST): the words file carries the full message, opening "Okay cool. As a note," and closing with the station question ("What do you need for me for the station"). Row 308 quotes the operative middle, from "you're getting close to 70% weekly usage" through "reviewer", an exact substring with the same lowercase "you're" the message has mid-sentence.
- R279 (Nov 16, 01:03 CST): "Send it back toward t2. Opus or codex is fine for builds.bomber on to paint". Identical in row 309.

Dates, times and the Board chat attribution match rows 305 to 309 in every case, and the added lines follow the file's existing format (the R272 to R274 lines directly above them).

One scope note for the next checker: this verifies the words file against FINDINGS, which is the standard the brief set. The two fuller lead-ins (R276's opening clause, R278's opening and closing sentences) are not in FINDINGS and cannot be verified from the repo; they conflict with nothing in it, and the words ledger carrying the fuller message while FINDINGS quotes the operative part is the right division between the two files. No condition.
