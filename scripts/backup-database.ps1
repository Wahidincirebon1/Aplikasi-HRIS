param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\backups')
)

$ErrorActionPreference = 'Stop'
$composeFile = Join-Path $PSScriptRoot '..\docker-compose.yml'
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $resolvedOutput "hris-$timestamp.dump"
$containerPath = "/tmp/hris-backup-$timestamp.dump"
$containerId = docker compose -f $composeFile ps -q db
if ($LASTEXITCODE -ne 0 -or -not $containerId) {
  throw 'Container database belum berjalan.'
}

try {
  docker compose -f $composeFile exec -T db sh -c 'pg_dump -Fc --no-owner -U "$POSTGRES_USER" "$POSTGRES_DB" -f "$1"' sh $containerPath
  if ($LASTEXITCODE -ne 0) { throw 'pg_dump gagal.' }
  docker cp "${containerId}:$containerPath" $backupPath
  if ($LASTEXITCODE -ne 0) { throw 'Gagal menyalin backup ke komputer ini.' }
  Write-Output "Backup database berhasil: $backupPath"
} finally {
  docker compose -f $composeFile exec -T db rm -f $containerPath | Out-Null
}
