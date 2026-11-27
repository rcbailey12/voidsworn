# Proof shared by the relay prune and cache compaction tools. Uses the caller's read-only Run-Git for inspection.
function Read-BranchTips($sourceUrl, $local, $patterns) {
  $tips = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
  $lines = if ($local) { Run-Git --git-dir $local for-each-ref '--format=%(objectname) %(refname)' @patterns }
           else { Run-Git -c credential.interactive=never -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=30 ls-remote --refs $sourceUrl @patterns }
  foreach ($line in $lines) {
    if ($line -notmatch '\A([0-9a-f]{40})\s+refs/heads/(\S+)\z') { throw "unexpected Git branch row: $line" }
    $tips.Add($Matches[2], $Matches[1])
  }
  return ,$tips
}
function Get-RelayProof($name, $sha, $relayTips, $mirror, $relayMirror) {
  $paired = $name.Substring('board/'.Length)
  $target = ''
  if (-not $relayTips.TryGetValue($paired, [ref]$target)) {
    return @{ State = 'unverified'; Detail = "no $paired on relay" }
  }
  if ($sha -ceq $target) { return @{ State = 'covered'; Detail = "$paired at identical tip $target"; Tip = $target } }
  try {
    # Git quotes special paths consistently. Keep the full row (mode, type and object ID) and compare paths case-sensitively.
    $remoteFiles = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($row in @(Run-Git --no-replace-objects --git-dir $relayMirror -c core.quotePath=true ls-tree -r --full-tree $target)) {
      $remoteFiles.Add($row.Substring($row.IndexOf("`t") + 1), $row)
    }
    $missing = @(foreach ($row in @(Run-Git --no-replace-objects --git-dir $mirror -c core.quotePath=true ls-tree -r --full-tree $sha)) {
      $file = $row.Substring($row.IndexOf("`t") + 1)
      $copy = ''
      if (-not $remoteFiles.TryGetValue($file, [ref]$copy)) { "missing $file" }
      elseif ($copy -cne $row) { "changed $file" }
    })
  } catch { return @{ State = 'unverified'; Detail = "cannot read the advertised trees from the local mirrors: $($_.Exception.Message)" } }
  if ($missing.Count) { return @{ State = 'only-here'; Detail = "$($missing.Count) missing or changed paths on $paired at $target"; Paths = $missing } }
  return @{ State = 'covered'; Detail = "all tip paths, modes and object IDs on $paired at $target"; Tip = $target }
}
function Write-RelayProof($name, $sha, $proof) {
  "relay $($proof.State) $name $sha ($($proof.Detail))"
  foreach ($file in $proof.Paths) { "  $file" }
}
