---
name: wizard
description: Disabled in this repo. A guided step-by-step walkthrough for something only Ryan can do (a sign-in, a dashboard, pasting a key). Use only to plan the steps as a double-click .bat; never read .env files, never write GitHub secrets.
---

# Wizard (disabled here)

The upstream Pocock wizard (SOURCE.md) generates a bash script that reads `.env` files, writes captured values back and can
set GitHub secrets with `gh secret set` on whatever repository the shell points at. That clashes with how keys work in this
repo, so the upstream instructions and `template.sh` are not installed (Artoo on PR 1675).

What to do instead:

- **Keys and secrets.** Never ask for a key in chat, a GitHub comment or an issue, and never read or write a real `.env` or
  a GitHub secret. Ryan pastes keys only into a masked double-click installer on his PC, in the pattern of
  `tools/pc/claude_api_key.bat` and `tools/pc/openai_api_key.bat`. A new key gets a new `.bat` of that shape, reviewed like
  any other PR.
- **Other steps only Ryan can do** (a dashboard, a sign-in, a setting): write the stages as plain numbered steps in your own
  reply, each with its link and what he will see, or as a double-click `.bat` that opens each link and pauses between stages
  (RULEBOOK 1.4). It writes nothing outside its own log.
