# Issue 726: stage 5 keeps a separate log for each render pass.
# This function only reads evidence, so the Windows self-test can use it without a bake.
function Assert-Hb726Stage5Logs([string]$Job, [string]$Cell) {
    $bake = Join-Path $Job 'log_bake.txt'
    if (-not (Test-Path -LiteralPath $bake -PathType Leaf)) { throw ($Cell + ': missing bake log ' + $bake) }
    if (Select-String -LiteralPath $bake -Pattern 'out of SVM stack space|failed to compile|shader compil(?:e|ation) (?:error|failed)|error compiling' -Quiet) {
        throw ($Cell + ': Cycles could not compile a bake shader')
    }
    $surface = Join-Path $Job 'log_surface.txt'
    if (-not (Test-Path -LiteralPath $surface -PathType Leaf)) { throw ($Cell + ': missing surface log ' + $surface) }
    if (-not (Select-String -LiteralPath $surface -Pattern '^PASS surface check' -Quiet)) { throw ($Cell + ': missing PASS surface check in ' + $surface) }
    foreach ($name in @('log_render.txt', 'log_render_concept.txt', 'log_render_far.txt')) {
        $log = Join-Path $Job $name
        if (-not (Test-Path -LiteralPath $log -PathType Leaf)) { throw ($Cell + ': missing render pass log ' + $name) }
        $count = @(Select-String -LiteralPath $log -Pattern 'RENDER DONE').Count
        if ($count -ne 1) { throw ($Cell + ': expected one RENDER DONE in ' + $name + ', got ' + $count) }
    }
}
