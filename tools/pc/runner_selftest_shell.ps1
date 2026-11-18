# A warm Windows PowerShell process for runner_selftest.js. Each request calls
# the real script in a fresh script scope, with the caller's directory and env.
$utf8 = New-Object Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8
$initialEnv = [Environment]::GetEnvironmentVariables()
$initialDirectory = [Environment]::CurrentDirectory
while ($null -ne ($line = [Console]::ReadLine())) {
  $req = ConvertFrom-Json -InputObject $line
  $code = 0
  $output = @()
  try {
    foreach ($key in $initialEnv.Keys) {
      if ($null -eq $req.env.PSObject.Properties[$key]) {
        [Environment]::SetEnvironmentVariable($key, $null)
      }
    }
    foreach ($item in $req.env.PSObject.Properties) {
      [Environment]::SetEnvironmentVariable($item.Name, [string]$item.Value)
    }
    Set-Location -LiteralPath $req.cwd
    [Environment]::CurrentDirectory = $req.cwd
    $global:LASTEXITCODE = 0
    $words = @($req.args | ForEach-Object { [string]$_ })
    if ($req.file) {
      $output = @(& $req.file @words *>&1)
    } else {
      # The client only routes the launchers' timestamp expressions here.
      $command = [scriptblock]::Create($req.command)
      $output = @(& $command *>&1)
    }
    $code = $LASTEXITCODE
  } catch {
    $output += $_
    $code = 1
  } finally {
    foreach ($item in $req.env.PSObject.Properties) {
      [Environment]::SetEnvironmentVariable($item.Name, $initialEnv[$item.Name])
    }
    foreach ($key in $initialEnv.Keys) {
      [Environment]::SetEnvironmentVariable($key, $initialEnv[$key])
    }
    Set-Location -LiteralPath $initialDirectory
    [Environment]::CurrentDirectory = $initialDirectory
  }
  $stdout = @($output | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
  $stderr = @($output | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ })
  $reply = @{ code = $code; stdout = $stdout; stderr = $stderr } | ConvertTo-Json -Compress
  [Console]::WriteLine($reply)
}
