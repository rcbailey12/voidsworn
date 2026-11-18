# Run from a reviewed main checkout on the Windows PC. PowerShell 5.1 and Node 22.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MainCheckout,
    [string]$PcRoot = (Join-Path $env:USERPROFILE 'Downloads\voidsworn_test'),
    [ValidateRange(1, 65535)][int]$Port = 8918
)

$ErrorActionPreference = 'Stop'
$pair = @('tools\pc\mission', 'docs\mission')
$publisherRelative = 'tools\pc\mission\publisher.js'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Step([string]$Message) {
    $line = [DateTime]::UtcNow.ToString('s') + 'Z ' + $Message
    if ($script:log) { [IO.File]::AppendAllText($script:log, $line + [Environment]::NewLine, $utf8) }
    Write-Host $line
}

function Assert-PlainPath([string]$Path) {
    for ($item = Get-Item -LiteralPath $Path; $item; $item = $item.Parent) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'A deployment folder is a link.' }
    }
}

function Copy-MissionPair([string]$Source, [string]$Destination, [bool]$Required) {
    foreach ($part in $pair) {
        $from = Join-Path $Source $part
        if (!$Required -and !(Test-Path -LiteralPath $from)) { continue }
        Assert-PlainPath $from
        if (Get-ChildItem -LiteralPath $from -Recurse -Force -Attributes ReparsePoint) { throw 'A deployment file is a link.' }
        $to = Join-Path $Destination $part
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
        Copy-Item -LiteralPath $from -Destination $to -Recurse
    }
}

function Get-InstalledPublisher {
    Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" -OperationTimeoutSec 5 | Where-Object {
        # The two supported launchers pass the absolute publisher script as Node's first argument.
        $words = [regex]::Matches([string]$_.CommandLine, '"([^"]*)"|(\S+)')
        if ($words.Count -ge 2) {
            $scriptArg = $words[1].Value.Trim('"')
            [IO.Path]::IsPathRooted($scriptArg) -and [IO.Path]::GetFullPath($scriptArg) -eq $installedPublisher
        }
    }
}

function Stop-InstalledPublisher {
    foreach ($process in @(Get-InstalledPublisher)) {
        $same = Get-InstalledPublisher | Where-Object {
            $_.ProcessId -eq $process.ProcessId -and $_.CreationDate -eq $process.CreationDate
        }
        if ($same) {
            Stop-Process -Id $process.ProcessId
            Wait-Process -Id $process.ProcessId -Timeout 5 -ErrorAction SilentlyContinue
        }
    }
    if (Get-InstalledPublisher) { throw 'The installed publisher is still running.' }
}

function Start-InstalledPublisher {
    $arguments = '"{0}" --root "{1}" --port {2}' -f $installedPublisher, $pcRootPath, $Port
    Start-Process -FilePath $node -ArgumentList $arguments -WorkingDirectory $installed -WindowStyle Hidden -PassThru
}

function Get-LocalResponse([string]$Route, [DateTime]$Deadline) {
    $remaining = [int][Math]::Min(2000, ($Deadline - [DateTime]::UtcNow).TotalMilliseconds)
    if ($remaining -le 0) { throw 'HTTP check timed out.' }
    $cancel = New-Object System.Threading.CancellationTokenSource($remaining)
    try {
        $response = $client.GetAsync("http://127.0.0.1:$Port$Route", $cancel.Token).GetAwaiter().GetResult()
        try {
            if ([int]$response.StatusCode -ne 200) { throw 'HTTP check did not return 200.' }
            @{Bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult(); Type = $response.Content.Headers.ContentType.MediaType}
        } finally { $response.Dispose() }
    } finally { $cancel.Dispose() }
}

function Wait-Status($Process, [DateTime]$Deadline) {
    while ([DateTime]::UtcNow -lt $Deadline) {
        $Process.Refresh()
        if ($Process.HasExited) { throw 'Publisher exited during startup.' }
        try { return Get-LocalResponse '/status.json' $Deadline }
        catch [System.Net.Http.HttpRequestException] { Start-Sleep -Milliseconds 200 }
        catch [System.OperationCanceledException] { Start-Sleep -Milliseconds 200 }
    }
    throw 'Publisher did not answer the HTTP check.'
}

function Confirm-ServedFile([string]$Route, [string]$File, [string]$Type, [DateTime]$Deadline) {
    $reply = Get-LocalResponse $Route $Deadline
    $served = [BitConverter]::ToString($sha.ComputeHash($reply.Bytes)).Replace('-', '')
    if ($reply.Type -ne $Type -or $served -ne (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash) {
        throw 'The server returned different file bytes or content type.'
    }
}

function Confirm-BuildStatus($Reply) {
    $status = $utf8.GetString($Reply.Bytes) | ConvertFrom-Json
    if ($Reply.Type -ne 'application/json' -or $status.schemaVersion -ne 2 -or
        $status.build.id -ne $build.id -or $status.build.diskId -ne $build.id -or
        $status.build.sourceRevision -ne $revision -or $status.build.stale -ne $false -or
        $status.build.sourceAt -ne $build.sourceAt -or $status.build.diskSourceAt -ne $build.sourceAt) {
        throw 'HTTP build or source file timestamp did not match.'
    }
    $started = [DateTimeOffset]::Parse($status.build.startedAt).UtcDateTime
    if ($started -lt $launchedAt -or $started -gt [DateTime]::UtcNow) {
        throw 'The reported publisher start does not match this launch.'
    }
    return $status
}

$phase = 'Prepare deployment'
$lock = $client = $sha = $null
$oldMoved = $newMoved = $wasRunning = $stopAttempted = $false
try {
    $pcRootPath = (Resolve-Path -LiteralPath $PcRoot).ProviderPath
    $checkout = (Resolve-Path -LiteralPath $MainCheckout).ProviderPath
    Assert-PlainPath $pcRootPath
    Assert-PlainPath $checkout
    $installed = Join-Path $pcRootPath 'mission'
    $installedPublisher = Join-Path $installed $publisherRelative
    if (Test-Path -LiteralPath $installed) { Assert-PlainPath $installed }
    if ($checkout -eq $installed -or $checkout.StartsWith($installed + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The source must be a separate checkout.'
    }
    $lockPath = Join-Path $pcRootPath 'mission_deploy.lock'
    if (Test-Path -LiteralPath $lockPath) { Assert-PlainPath $lockPath }
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
    $datedName = 'mission_backup_{0}_{1}' -f [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss'), [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $dated = Join-Path $pcRootPath $datedName
    [void][IO.Directory]::CreateDirectory($dated)
    $script:log = Join-Path $dated 'deploy.log'
    $candidate = Join-Path $dated 'candidate'
    $previous = Join-Path $dated 'previous'
    Write-Step 'Prepare deployment from the checkout.'
    $revision = & git -C $checkout rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[a-f0-9]{40}$') { throw 'Checkout revision unavailable.' }
    $node = Join-Path $pcRootPath 'node\node.exe'
    if (!(Test-Path -LiteralPath $node -PathType Leaf)) {
        $node = Get-Command node.exe -CommandType Application | Select-Object -First 1 -ExpandProperty Source
    }

    $phase = 'Stage the publisher, queue, page and assets'
    Write-Step $phase
    Copy-MissionPair $checkout $candidate $true
    $candidatePublisher = Join-Path $candidate $publisherRelative
    [IO.File]::WriteAllText((Join-Path (Split-Path -Parent $candidatePublisher) 'build.json'),
        ('{"revision":"' + $revision + '"}'), $utf8)
    $manifest = & $node -e 'const p = require(process.argv[1]); console.log(JSON.stringify({id:p.buildHash(), assets:p.ASSETS, sourceAt:p.buildSourceAt(), checkoutAt:p.buildSourceAt(process.argv[2])}));' $candidatePublisher (Split-Path -Parent (Join-Path $checkout $publisherRelative)) 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Could not load the staged publisher.' }
    $build = $manifest | ConvertFrom-Json
    if ($build.id -notmatch '^[a-f0-9]{64}$' -or !$build.assets) { throw 'Build metadata unavailable.' }
    if (!$build.sourceAt -or $build.sourceAt -ne $build.checkoutAt) { throw 'Staged source file timestamps did not match the checkout.' }
    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.UseProxy = $false
    $handler.AllowAutoRedirect = $false
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.MaxResponseContentBufferSize = 16MB
    $sha = [Security.Cryptography.SHA256]::Create()

    $phase = 'Back up the installed publisher and page'
    Write-Step $phase
    Copy-MissionPair $installed (Join-Path $dated 'backup') $false
    $phase = 'Stop the installed publisher'
    Write-Step $phase
    $wasRunning = @(Get-InstalledPublisher).Count -gt 0
    $stopAttempted = $true
    Stop-InstalledPublisher

    $phase = 'Install the staged publisher and page together'
    Write-Step $phase
    if (Test-Path -LiteralPath $installed) {
        [IO.Directory]::Move($installed, $previous)
        $oldMoved = $true
    }
    [IO.Directory]::Move($candidate, $installed)
    $newMoved = $true
    $phase = 'Start the publisher hidden'
    Write-Step $phase
    $launchedAt = [DateTime]::UtcNow.AddMilliseconds(-1)
    $deadline = $launchedAt.AddSeconds(150)
    $process = Start-InstalledPublisher

    $phase = 'Check status and build over HTTP'
    Write-Step $phase
    $status = Confirm-BuildStatus (Wait-Status $process $deadline)
    $phase = 'Check the page and every asset over HTTP'
    Write-Step $phase
    $page = Join-Path $installed 'docs\mission'
    Confirm-ServedFile '/' (Join-Path $page 'index.html') 'text/html' $deadline
    foreach ($asset in $build.assets.PSObject.Properties) {
        Confirm-ServedFile $asset.Name (Join-Path $page ($asset.Name.TrimStart('/'))) $asset.Value $deadline
    }
    $phase = 'Check the first PC source scan'
    Write-Step $phase
    while (!$status.generatedAt -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 500
        $status = Confirm-BuildStatus (Wait-Status $process $deadline)
    }
    if (!$status.generatedAt -or !$status.pcSource.lastAttemptAt -or !$status.lanes.Count) { throw 'No PC scan was published.' }
    $scanned = [DateTimeOffset]::Parse($status.generatedAt).UtcDateTime
    $attempted = [DateTimeOffset]::Parse($status.pcSource.lastAttemptAt).UtcDateTime
    if ($scanned -lt $launchedAt -or $attempted -lt $scanned -or $attempted -gt [DateTime]::UtcNow -or
        @($status.lanes | Where-Object { $_.source.refreshedAt -ne $status.generatedAt }).Count -gt 0) {
        throw 'PC source scan timestamps did not match the running build.'
    }
    Write-Step ('Verified build ' + $build.id.Substring(0, 12) + ', source ' + $build.sourceAt + ', PC scan ' + $status.generatedAt + '.')
    Write-Step 'Deployment passed. The backup was kept.'
} catch {
    Write-Step ('Failed step: ' + $phase + '.')
    if ($stopAttempted) {
        try {
            Write-Step 'Restore the previous installation.'
            if ($newMoved) {
                Stop-InstalledPublisher
                [IO.Directory]::Move($installed, (Join-Path $dated 'failed_candidate'))
            }
            if ($oldMoved) { [IO.Directory]::Move($previous, $installed) }
            if ($wasRunning -and !(Get-InstalledPublisher)) {
                $restored = Start-InstalledPublisher
                $null = Wait-Status $restored ([DateTime]::UtcNow.AddSeconds(10))
                Write-Step 'The previous publisher answered over HTTP.'
            }
            Write-Step 'Rollback finished. All copies were kept.'
        } catch { Write-Step 'Rollback needs attention. The dated backup was kept.' }
    }
    exit 1
} finally {
    if ($client) { $client.Dispose() }
    if ($sha) { $sha.Dispose() }
    if ($lock) { $lock.Dispose() }
}
