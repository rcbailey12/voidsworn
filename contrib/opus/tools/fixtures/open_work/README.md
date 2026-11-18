# Open work fixtures (Refs #838, #890)

`api_replies.json` contains saved GitHub REST replies from Nov 16 2026 UTC:

- `https://api.github.com/repos/rcbailey12/voidsworn/pulls?state=open&per_page=100&page=1`
- `https://api.github.com/repos/rcbailey12/voidsworn/issues?state=open&per_page=100&page=1`

Only the fields used by the generator are kept. Both replies fit on one page.

`closed_pulls` (issue 890) is a later save of the same day:
`https://api.github.com/repos/rcbailey12/voidsworn/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=1`.
It keeps number, title, body and merged_at, and each body is cut to its lines that hold
"#" and a digit (lines kept to 200 characters), so the file stays small. Because it was
saved later than the open lists, a few PRs show as both open and merged; the test only
needs the bytes to replay.

The offline test splits the saved arrays into small pages to exercise pagination
through each transport. No live API calls or credentials are needed by the tests.
`expected.md` is the expected page at a fixed UTC time.
`edge_cases.json` adds artificial table text and empty-label cases, plus live status cases
(a running issue, a draft PR, merged and unmerged closed PRs naming issues);
`edge_expected.md` is their expected page. Unicode escapes keep source files free
of em dashes while still testing titles and labels containing them.
