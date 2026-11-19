param(
    [Parameter(Mandatory = $true)][string]$Project
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/../../..").Path
$Project = (Resolve-Path -LiteralPath $Project).Path
$installed = (Resolve-Path "$repo/godot").Path
$scratch = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\', '/') + '\'
if ($Project -eq $installed -or !$Project.StartsWith($scratch, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Use the isolated run 4 Godot project copied into this job temp folder.'
}
if (!(Test-Path -LiteralPath "$Project/gen/manifest.json")) {
    throw 'The isolated project needs the generated run 4 ship cache and sky.'
}

function Replace-Once($Text, $Before, $After) {
    $first = $Text.IndexOf($Before, [StringComparison]::Ordinal)
    if ($first -lt 0 -or $Text.IndexOf($Before, $first + $Before.Length, [StringComparison]::Ordinal) -ge 0) {
        throw "Expected one scene 207 staging hook: $Before"
    }
    return $Text.Replace($Before, $After)
}

$destination = "$Project/bench/glass_light_1119"
New-Item -ItemType Directory -Force -Path "$destination/glass1058" | Out-Null
Copy-Item -Path "$PSScriptRoot/*.gd", "$PSScriptRoot/probe.tscn" -Destination $destination
Copy-Item -LiteralPath "$repo/tools/blender/kits/ithar/glass_review.gd", `
    "$repo/tools/blender/kits/ithar/blown_glass.gdshader" -Destination "$destination/glass1058"

# Same two roster substitutions as issue 1058. Keep the 24-ship storm battle.
$gate = [IO.File]::ReadAllText("$repo/godot/bench/scene_gate.gd")
$gate = Replace-Once $gate '"b_spitter", "b_drone", "i_blade", "i_wisp"' '"b_razor", "b_drone", "i_boss", "i_wisp"'
$gate = Replace-Once $gate 'Time.get_ticks_usec() + 60000000' 'Time.get_ticks_usec() + 180000000'
[IO.File]::WriteAllText("$destination/scene_gate_1058.gd", $gate)

# Adapt the older sampler's return type to today's scene gate. Timing code is reused verbatim.
$perf = [IO.File]::ReadAllText("$repo/contrib/codex/perf_1118/perf_1118.gd").Replace("`r`n", "`n")
$perf = Replace-Once $perf 'extends "res://bench/scene_gate.gd"' 'extends "scene_gate_1058.gd"'
$perf = Replace-Once $perf 'func _build(mode: String, seed: int) -> void:' 'func _build(mode: String, seed: int) -> bool:'
$perf = Replace-Once $perf "`t`tawait super._build(mode, seed)" "`t`tif not await super._build(mode, seed):`n`t`t`treturn false"
$perf = Replace-Once $perf "`t`t_engagement_camera()`n`t`treturn" "`t`t_engagement_camera()`n`t`treturn true"
$perf = Replace-Once $perf "`t`tfailures += 1`n`t`treturn`n`tapi.new_battle_scenario" "`t`tfailures += 1`n`t`treturn false`n`tapi.new_battle_scenario"
$perf = Replace-Once $perf "`tawait get_tree().process_frame`n`n`nfunc _engagement_camera" "`tawait get_tree().process_frame`n`treturn not b.warming and not b.busy`n`n`nfunc _engagement_camera"
[IO.File]::WriteAllText("$destination/perf_1118.gd", $perf)
