# Review protocol for outside AI agents (Argon, Gemini, ChatGPT, others)

Outside reviews keep coming back half-read or made up. These rules are mandatory. A review that skips them gets thrown out.

## 1. Prove you read it
- Open files in raw view: `https://github.com/rcbailey12/voidsworn/raw/main/<path>`. Not the normal GitHub page (it folds long lines and loads in chunks).
- Write down the commit you reviewed (the short id shown on the repo's main page).
- For every file: total line count, and the exact text of the first 40 characters of the LAST line.
- Big files (over 1,500 lines or 60 KB): read in parts by line range and list each range you read. Never assume the rest.
- If you cannot see the end of a file, stop and say so.

## 2. Stay in scope
- Answer only the question you were given, on only the files named. No general advice ("consider adding tests").
- Max 10 findings, most important first. Fewer good findings beat many weak ones.

## 3. Evidence for every claim
- Each finding: file, line number, and an exact quote (under 20 words) copied from the file.
- Every function, variable or setting you name must appear in the file. Search for it before you write it. Do not invent names or APIs.
- Mark each finding OBSERVED (you saw it in the code) or INFERRED (your reasoning). Inferred findings need a reason.
- "Not enough info" is a good answer. Guessing is not.

## 4. Check yourself before you hand it in
- Re-open every cited line and confirm the quote matches word for word. Delete any finding whose quote does not match.
- End with "Not checked": what you did not read or could not verify.

## 5. Output
- Table: # | finding | OBSERVED/INFERRED | file:line | exact quote | why it matters | your fix | confidence (high/med/low)
- Then your one recommended next step.
- Save it as `contrib/<your-name>/reviews/<topic>.md`. Do not edit any file outside `contrib/`.

## Tips for whoever starts the review
- Gemini: uploading the files directly (it takes very long inputs) is more reliable than letting it browse.
- One system per run (battle rules, then AI, then menus...), not "the whole game".
- Paste this file's rules into the prompt, or tell the agent: "Follow docs/REVIEW_PROTOCOL.md exactly."
- Claude checks every claim against the code before merging anything (see docs/ship_pipeline/AUDIT_SYNTHESIS.md).
