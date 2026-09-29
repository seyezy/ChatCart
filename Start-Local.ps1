$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$backend = Join-Path $projectRoot 'Laravel_Backend'
$runtime = Join-Path $projectRoot '.local'
$php = (Get-Command php.exe -ErrorAction Stop).Source
$env:PHPRC = Join-Path $runtime 'php.ini'
if (-not (Test-Path $env:PHPRC)) { throw 'Project PHP configuration is missing from .local/php.ini.' }
$artisan = Join-Path $backend 'artisan'
$running = @{}
$record = Join-Path $runtime 'processes.json'
if (Test-Path $record) { $running = Get-Content $record -Raw | ConvertFrom-Json }
try {
    $health = Invoke-WebRequest 'http://127.0.0.1:8000/up' -UseBasicParsing -TimeoutSec 3
    Write-Host 'Laravel is already running.'
} catch {
    $server = Start-Process $php -ArgumentList @($artisan, 'serve', '--host=127.0.0.1', '--port=8000', '--no-reload') -WorkingDirectory $backend -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtime 'laravel-server.log') -RedirectStandardError (Join-Path $runtime 'laravel-server-error.log')
}
$workerRunning = $false
if ($running.worker) {
    $existing = Get-CimInstance Win32_Process -Filter "ProcessId=$($running.worker)"
    $workerRunning = $existing -and $existing.Name -eq 'php.exe' -and $existing.CommandLine -like '*artisan*queue:work*'
}
if (-not $workerRunning) {
    $worker = Start-Process $php -ArgumentList @($artisan, 'queue:work', '--sleep=3', '--tries=1') -WorkingDirectory $backend -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtime 'queue.log') -RedirectStandardError (Join-Path $runtime 'queue-error.log')
}
@{ server = $(if ($server) { $server.Id } else { $running.server }); worker = $(if ($worker) { $worker.Id } else { $running.worker }) } | ConvertTo-Json | Set-Content $record
Write-Host 'Admin: http://127.0.0.1:8000/admin'
Write-Host 'API:   http://127.0.0.1:8000/api/v1/products'
Write-Host 'Keep MySQL running in XAMPP. Logs and test credentials are in .local.'
