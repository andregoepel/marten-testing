[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ServerId,
    [Parameter(Mandatory)][ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')][string]$RunName,
    [string]$Project
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$policy = Get-Content (Join-Path $PSScriptRoot 'main-policy.json') -Raw | ConvertFrom-Json
$contract = Get-Content (Join-Path $PSScriptRoot 'contract.json') -Raw | ConvertFrom-Json
if (!$Project) { $Project = "$($policy.project)-local" }
if ($ServerId -ceq $policy.serverId -or $Project -notmatch "^$([regex]::Escape($policy.project))-local(?:-[a-z0-9]+)*$") {
    throw 'Use this repository''s separate local Sonar project, never the central project.'
}
if (!$env:WORKFLOWS_SONAR_TOKEN -or !$env:WORKFLOWS_SONAR_VERIFY_TOKEN) {
    throw 'Supply the existing local project credentials through the protected process environment.'
}

$directory = Join-Path $root "artifacts/sonar/acceptance/$RunName"
if (Test-Path -LiteralPath $directory) { throw 'Choose a new run name; retain previous evidence.' }
$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
$source = Join-Path $temporaryRoot ('msa-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
if (Test-Path -LiteralPath $source) { throw 'The temporary source directory already exists.' }
[IO.Directory]::CreateDirectory($directory) | Out-Null
$files = @(git -C $root ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0 -or $files.Count -eq 0) { throw 'Could not inventory the repository.' }
foreach ($relative in $files) {
    $inputPath = [IO.Path]::GetFullPath((Join-Path $root $relative))
    $outputPath = [IO.Path]::GetFullPath((Join-Path $source $relative))
    if (!$inputPath.StartsWith($root + [IO.Path]::DirectorySeparatorChar) -or !$outputPath.StartsWith($source + [IO.Path]::DirectorySeparatorChar)) {
        throw 'A source path escapes the snapshot.'
    }
    $item = Get-Item -LiteralPath $inputPath
    if ($item.LinkType) { throw 'Linked source files require separate review.' }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputPath)) | Out-Null
    [IO.File]::Copy($inputPath, $outputPath, $false)
}
$files | ForEach-Object {
    [ordered]@{ path = $_; sha256 = (Get-FileHash -LiteralPath (Join-Path $source $_)).Hash.ToLowerInvariant() }
} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $directory 'source-manifest.json')

$projects = @($files | Where-Object { $_.EndsWith('.csproj') } | Sort-Object)
$production = @($projects | Where-Object { $_.StartsWith('src/') })
if ($production.Count -ne 1) { throw 'Review this drill when the production project inventory changes.' }
$probeRelative = [IO.Path]::GetDirectoryName($production[0]).Replace('\', '/') + '/SonarCoverageFailureProbe.cs'
$probe = Join-Path $source $probeRelative
if (Test-Path -LiteralPath $probe) { throw 'The isolated failure probe already exists.' }
$probeHash = $null
$results = [ordered]@{}

function Require([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw $Message }
}

function Analyze([string]$Stage, [bool]$ExpectedFailure) {
    $stageName = "$RunName-$Stage"
    & (Join-Path $source 'scripts/sonar/analyze.ps1') -ServerId $ServerId -RunName $stageName -Project $Project *> (Join-Path $directory "$Stage.log")
    $exitCode = $LASTEXITCODE
    $path = Join-Path $source "artifacts/sonar/$stageName/publish/summary.json"
    Require (Test-Path -LiteralPath $path) "$Stage did not produce an analysis summary."
    $summary = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Require ($summary.project -ceq $Project -and $summary.serverId -ceq $ServerId -and $summary.releaseEligible -eq $false) 'Unexpected analysis identity.'
    Require ($summary.taskId -and $summary.analysisId -and $summary.gate.ignoredConditions -eq $false) 'No complete gate result was retained.'
    Require (!(Compare-Object $projects @($summary.analyzedProjects | Sort-Object))) 'The analysis omitted a project.'
    Require (@($summary.tests.PSObject.Properties).Count -eq @($contract.tests.PSObject.Properties).Count) 'The test inventory changed.'
    foreach ($test in $contract.tests.PSObject.Properties) {
        $actual = $summary.tests.($test.Name)
        Require ($actual.discovered -eq $test.Value -and $actual.passed -eq $test.Value) 'A required test was missing or failed.'
    }
    foreach ($anchor in $contract.coverageAnchors) {
        Require ($summary.coverage.executedSources -ccontains $anchor) 'A required source file was not covered.'
    }
    if ($ExpectedFailure) {
        $condition = @($summary.gate.conditions | Where-Object metricKey -ceq 'coverage')
        Require ($exitCode -ne 0 -and $summary.state -ceq 'failed' -and $summary.scannerExitCode -ne 0 -and $summary.gate.status -ceq 'ERROR') 'The injected analysis did not fail.'
        Require ($condition.Count -eq 1 -and $condition[0].status -ceq 'ERROR' -and $condition[0].comparator -ceq 'LT' -and $condition[0].errorThreshold -ceq '80' -and [decimal]$condition[0].actualValue -lt 80) 'Failure was not the expected coverage gate rejection.'
        Require ($summary.coverage.mappedSources -ccontains $probeRelative -and $summary.coverage.executedSources -cnotcontains $probeRelative) 'The probe was not mapped as uncovered production code.'
    } else {
        Require ($exitCode -eq 0 -and $summary.state -ceq 'complete' -and $summary.scannerExitCode -eq 0 -and $summary.gate.status -ceq 'OK') 'The clean analysis did not pass.'
        Require ($summary.measures.violations -ceq '0' -and $summary.measures.security_hotspots -ceq '0') 'The clean analysis has findings or hotspots.'
    }
    return $summary
}

Push-Location $source
try {
    $results.clean = Analyze 'clean' $false
    $lineCount = [Math]::Max(64, [int]$results.clean.measures.lines_to_cover + 32)
    $lines = @('namespace SonarAcceptance;', '', 'internal static class SonarCoverageFailureProbe', '{', '    internal static int Evaluate(int value)', '    {')
    $lines += @(1..$lineCount | ForEach-Object { "        value = unchecked(value * 31 + $_);" })
    $lines += @('        return value;', '    }', '}')
    [IO.File]::WriteAllText($probe, ($lines -join "`n") + "`n")
    dotnet csharpier format $probe
    if ($LASTEXITCODE -ne 0) { throw 'Could not format the isolated probe.' }
    $probeHash = (Get-FileHash -LiteralPath $probe).Hash
    try {
        $results.failure = Analyze 'failure' $true
    } finally {
        if ((Test-Path -LiteralPath $probe) -and (Get-FileHash -LiteralPath $probe).Hash -ceq $probeHash) {
            Remove-Item -LiteralPath $probe
        }
    }
    Require (!(Test-Path -LiteralPath $probe)) 'The probe changed during the drill; inspect it before recovery.'
    $results.recovery = Analyze 'recovery' $false
    Require ($results.clean.sourceSha256 -ceq $results.recovery.sourceSha256 -and $results.clean.sourceSha256 -cne $results.failure.sourceSha256) 'Recovery did not analyze the original clean source.'
    Require (@($results.Values.analysisId | Sort-Object -Unique).Count -eq 3 -and @($results.Values.taskId | Sort-Object -Unique).Count -eq 3) 'The drill reused an analysis or task.'
    foreach ($stage in @('failure', 'recovery')) {
        Require ($results.clean.contractSha256 -ceq $results[$stage].contractSha256) 'The coverage/test contract changed.'
        Require (($results.clean.gate.period | ConvertTo-Json -Compress) -ceq ($results[$stage].gate.period | ConvertTo-Json -Compress)) 'The local comparison period changed.'
    }
    $record = [ordered]@{ repository = $policy.repository; localOnly = $true; centralAcceptance = $false; releaseEligible = $false; results = $results }
} finally {
    Pop-Location
    $analysisDirectory = Join-Path $source 'artifacts/sonar'
    if (Test-Path -LiteralPath $analysisDirectory) {
        Copy-Item -LiteralPath $analysisDirectory -Destination (Join-Path $directory 'analyses') -Recurse
    }
    $resolved = [IO.Path]::GetFullPath($source)
    if ([IO.Path]::GetDirectoryName($resolved) -ceq $temporaryRoot -and [IO.Path]::GetFileName($resolved) -match '^msa-[0-9a-f]{8}$' -and !(Get-Item -LiteralPath $resolved).LinkType) {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

$record | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $directory 'verified.json')
Write-Output 'Local clean / coverage-failure / recovery verified. Central new-code and readiness rejection remain separate acceptance checks.'
