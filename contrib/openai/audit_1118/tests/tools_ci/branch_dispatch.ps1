# Read-only probe of runner dispatch. No GitHub, checkout or model calls.
$ErrorActionPreference = 'Stop'
$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.Parent.Parent.Parent.FullName
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root 'tools/pc/runner_common.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'SETUP ERROR: could not parse runner_common.ps1' }
$functions = @('Find-BaseLines', 'Current-Body', 'Validate-Job')
foreach ($function in $ast.FindAll({param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -in $functions}, $false)) {
    . ([scriptblock]::Create($function.Extent.Text))
}
$body = @'
Owner: codex
Brief: below
Deliver to: job.md
Branch: codex/issue-42
Effort (Codex): high
Done when: review the result

Finish the new fixture job.
'@
$issue = @{state = 'open'; labels = @(@{name = 'codex'}, @{name = 'blocked'}); body = $body}
if (-not (Validate-Job $issue '42' 'codex' @() @())) { throw 'SETUP ERROR: a matching dispatch must pass' }
$issue.body = $body.Replace('Branch: codex/issue-42', 'Branch: work/issue-42-openai')
$rejected = $false
try { $null = Validate-Job $issue '42' 'codex' @() @() }
catch { $rejected = $true }
if (-not $rejected) {
    Write-Output 'FAIL: a Codex launch accepted an issue assigned to the OpenAI delivery branch'
    exit 1
}
Write-Output 'PASS: a stale launch is refused when the delivery branch changes'
