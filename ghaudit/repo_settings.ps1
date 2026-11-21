# Repo settings Ryan approved Nov 21 2026 ("Yes to all", GH repo audit, R385). Run on the PC with gh signed in as rcbailey12.
$ErrorActionPreference = 'Stop'
$r = 'repos/rcbailey12/voidsworn'
gh api -X PATCH $r -F delete_branch_on_merge=true --jq .delete_branch_on_merge
'{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}' | gh api -X PATCH $r --input - --jq .security_and_analysis
'{"name":"main: no force-push or delete","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"non_fast_forward"},{"type":"deletion"}]}' | gh api -X POST "$r/rulesets" --input - --jq '{id,name,enforcement}'
