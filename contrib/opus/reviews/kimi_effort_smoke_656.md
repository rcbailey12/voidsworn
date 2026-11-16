# Kimi effort smoke (issue 656, Opus, Nov 13 2026)

## The answer

For the issue 42 trial the Board sets, on the kimicode arm:

```
set "WORK_MODEL=kimicode/kimi-for-coding"
set "WORK_EFFORT=low"
work_issue.bat 42 kimicode
```

(inside a q_ file, with setlocal, as LOOP requires.) The run's out\model.txt and stats.txt then read
`kimicode/kimi-for-coding --variant low`.

What the smoke proves, in three lines:
1. The setting reaches the API. OpenCode 1.19.5 sends `reasoning_effort: "low"` in the request body on every agent call of a
   `--variant low` run, and sends no effort field at all on a default run. The known case of openai-compatible model options
   being silently dropped did NOT happen here.
2. The API reads the field. `reasoning_effort: "none"` switches the separate thinking channel off (0 reasoning tokens; the
   model then thinks out loud in its answer instead), so the field is parsed, not ignored. The API does not reject unknown
   values: `"bogus"` returns 200 and thinks like the default.
3. Low lowers the thinking, but only modestly and noisily: on the same short puzzle, low averaged 1021 reasoning tokens a call
   (8 calls, range 390 to 1524) against 1414 for the default (7 calls, range 439 to 2275), about 28 percent less. In the two
   tiny agent runs the thinking was the same size either way (a few hundred to about 1200 tokens a run); what those runs spend
   is input: about 6,000 prompt tokens a step, mostly the agent's own system prompt, cached after the first call.

So low is worth setting (it is sent, it is read, it trims thinking), but it will not by itself make a job fit the 5-hour window:
an agent job's draw is mostly the context it resends each step, not the thinking. Expect a small gain; the issue 42 trial
measures the real one.

## What changed

- tools/pc/work_issue.bat: optional `WORK_EFFORT` (low, high or max, any case), turned into OpenCode's `--variant <effort>`.
  Unset, the command line is exactly as before for every arm. Kimicode arm only; on any other arm, or with any other value, it
  prints "WORK_EFFORT ... ignored" and runs at the default (so a WORK_EFFORT left in the queue watcher's window cannot change an
  opus or deepseek run, the WORK_MODEL trap of Nov 13). The effort is written into out\model.txt.
- tools/pc/work/opencode_lean.json (the kimicode arm's config): each kimicode model (kimi-for-coding, k3.1-pro, k3) gets
  `variants: low/high/max = { "reasoningEffort": "<effort>" }`. OpenCode builds no variants of its own for a model id with
  "kimi" in it or for a custom model with no reasoning flag. Without these, `--variant low` is dropped silently: tested free
  with the old config through the stub, the run exits 0 and no call carries any effort field. This is the "silently
  dropped" trap the job warned of, in its OpenCode 1.19.5 form; writing the variants into the config is the fix.
- tools/pc/work/opencode_mock.json: the same variants on the stand-in models, so a dry run with WORK_EFFORT set works.
- tools/pc/work/kimi_effort_smoke.js: the smoke tool (a local relay between OpenCode and api.kimi.com that logs the effort
  fields each call sent and the usage each call got back; `--upstream stub` free; `--direct N` bare API calls).
- tools/pc/work/README.md: how WORK_EFFORT works and how to rerun the smoke.
- tools/pc/work/opencode.json is not changed: no arm that takes WORK_EFFORT reads it.

## Measurements

Everything below ran on Nov 13 2026, 18:26 to 18:38 UTC, on Ryan's PC, OpenCode 1.19.5, Kimi Code plan key, model
kimi-for-coding. Total spend on the plan: about 85,000 tokens (most of it cached prompt), well under a twentieth of the
roughly 2M tokens the earlier k3 runs used up a window with.

### 1. Free: what OpenCode sends (`--upstream stub`, no plan use)

| run | call | reasoning_effort in the body |
|---|---|---|
| default | session title (no tools) | "low" |
| default | agent step | absent |
| low | session title (no tools) | "low" |
| low | agent step | "low" |

The title call is OpenCode's own small call to name the session; once the model has a low variant, OpenCode sends that call
at "low" whatever the run's effort (with the old config it carried no effort field).

The same free test with the old opencode_lean.json (no variants) and `--variant low`: exit 0, answer given, and neither call
carried any effort field. So the variant only reaches the API because the config now defines it.

### 2. Two tiny identical OpenCode runs on the plan, default and low

The job: read puzzle.txt with the read tool, reply with one number. Same prompt, same config, through the relay.

Easy puzzle (answer 204; first pair):

| run | exit | seconds | steps | input | output | reasoning | answer |
|---|---|---|---|---|---|---|---|
| default | 0 | 15.2 | 2 | 6362 | 91 | 45 | 204 |
| low | 0 | 6.8 | 2 | 2524 | 91 | 45 | 204 |

- default step 1: input 6016, output 75, reasoning 5, cache read 0
- default step 2: input 346, output 16, reasoning 40, cache read 5888
- low step 1: input 2176, output 75, reasoning 7, cache read 3840
- low step 2: input 348, output 16, reasoning 38, cache read 5888

The input difference is the cache (the low run found the system prompt already cached), not the effort. The puzzle was too easy
to show any thinking, so a harder one followed.

Hard puzzle (answer 19: integers under 1000 with digit sum 12 that divide by 4; second pair):

| run | exit | seconds | steps | input | output | reasoning | answer |
|---|---|---|---|---|---|---|---|
| default | 0 | 37.7 | 3 | 2095 | 192 | 1167 | 19 |
| low | 0 | 37.5 | 2 | 719 | 91 | 1249 | 19 |

- default step 1: input 384, output 75, reasoning 77, cache read 5632
- default step 2: input 384, output 101, reasoning 1070, cache read 5888
- default step 3: input 1327, output 16, reasoning 20, cache read 6144
- low step 1: input 384, output 75, reasoning 28, cache read 5632
- low step 2: input 335, output 16, reasoning 1221, cache read 5888

Per API call as the relay saw it (hard pair):

| run | call | status | reasoning_effort sent | prompt tokens | completion tokens | reasoning tokens |
|---|---|---|---|---|---|---|
| default | agent step | 200 | absent | 6016 | 152 | 77 |
| default | session title | 200 | "low" | 640 | 98 | 78 |
| default | agent step | 200 | absent | 6272 | 1171 | 1070 |
| default | agent step | 200 | absent | 7471 | 36 | 20 |
| low | agent step | 200 | "low" | 6016 | 103 | 28 |
| low | session title | 200 | "low" | 640 | 133 | 112 |
| low | agent step | 200 | "low" | 6223 | 1237 | 1221 |

One run each cannot separate the effort from the model's normal spread: the default run chose to work the count out with a
tool call (one extra step), the low run did it in its head, and their thinking came out the same size.

### 3. Bare API calls (no OpenCode), the same hard puzzle, to measure the thinking itself

Prompt about 116 tokens, so the thinking is the whole cost. Calls interleaved low and default.

| effort sent | calls | reasoning tokens each | mean | right answers |
|---|---|---|---|---|
| low | 8 | 402, 1184, 390, 1216, 1038, 903, 1524, 1510 | 1021 | 7 of 8 (one said 18) |
| none sent (default) | 7 | 1618, 1346, 439, 1132, 2275, 1538, 1552 | 1414 | 7 of 7 |
| max | 1 | 1737 | 1737 | 1 of 1 |
| "bogus" | 1 | 1912 | 1912 | 1 of 1 |
| none | 3 | 0, 0, 0 (thinking moved into the visible answer, 588 to 1001 output tokens) | 0 | 0 of 3 (answer not a bare number) |

Reading: the default behaves like max (the vendor docs say the model defaults to max), low is lower on average and never
reached the default's top values, "none" proves the field is read, and an unknown value silently falls back to the default (so
a typo in a variant would not show as an error; the runner only lets low, high or max through).

## Checks of how the change reaches the rest

- Callers: WORK_EFFORT is read only in tools/pc/work_issue.bat; the new VARIANT variable only feeds the OpenCode command line
  and out\model.txt. model.txt is read only by work_issue.ps1 stats (printed as the "model:" line). No check, tool or
  workflow in the repo reads the OpenCode configs or the runner.
- Saves: no game, profile or save data touched.
- Twins: no rules files touched; no table re-export needed.
- UI: nothing the player sees.
- CI: the smoke tool is a PC tool, not a check; nothing new for run_all_checks.js.

How it was tested:
- Runner logic: the runner's own lines up to the effort step, run under cmd.exe: unset gives no variant (kimicode and sonnet);
  low, LOW and High give `--variant low` / `--variant high`; bogus, "low high" and "low&echo x" are ignored with the line;
  WORK_EFFORT=low on the opus and deepseek arms is ignored with the line; WORK_MODEL=kimicode/kimi-for-coding with
  WORK_EFFORT=low gives that model with `--variant low`.
- Runner end to end: a dry run (`work_issue.bat 656 kimicode dryrun`, WORK_MODEL=kimicode/kimi-for-coding, WORK_EFFORT=low,
  sparse clone, timecap scenario, 75 s cap): OpenCode accepted `--variant low`, the stand-in model got its calls, model.txt and
  stats.txt read `kimicode/kimi-for-coding --variant low`, and the run ended as a PARTIAL dry push as the scenario intends.

## Not done

- No issue 42 run: the job says the Board launches it after this lands.
- Only kimi-for-coding was measured. k3.1-pro and k3 have the same variants written in (their docs list low, high and max),
  untested on the plan.
- The window's absolute size is still unpublished; how much agent time low buys is for the issue 42 trial to log.
