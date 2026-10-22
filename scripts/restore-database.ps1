param(
  [Parameter(Mandatory = $true)]
  [string]$BackupFile,

  [Parameter(Mandatory = $true)]
  [string]$DatabaseName
)

$ErrorActionPreference = 'Stop'
if ($DatabaseName -notmatch '^[a-zA-Z][a-zA-Z0-9_]{0,62}$') {
  throw 'Nama database hanya boleh berisi huruf, angka, dan underscore.'
}
$resolvedBackup = (Resolve-Path -LiteralPath $BackupFile).Path
$composeFile = Join-Path $PSScriptRoot '..\docker-compose.yml'
$containerId = docker compose -f $composeFile ps -q db
if ($LASTEXITCODE -ne 0 -or -not $containerId) {
  throw 'Container database belum berjalan.'
}
$postgresUser = docker compose -f $composeFile exec -T db printenv POSTGRES_USER
if ($LASTEXITCODE -ne 0 -or -not $postgresUser) { throw 'Gagal membaca pengguna database.' }
$exists = docker compose -f $composeFile exec -T db psql -U $postgresUser.Trim() -d postgres -Atc "SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = '$DatabaseName')"
if ($LASTEXITCODE -ne 0) { throw 'Gagal memeriksa database tujuan.' }
if ($exists.Trim() -eq 't') {
  throw 'Database tujuan sudah ada. Restore hanya boleh dilakukan ke database baru.'
}

$containerPath = '/tmp/hris-restore.dump'
$createdDatabase = $false
try {
  docker cp $resolvedBackup "${containerId}:$containerPath"
  if ($LASTEXITCODE -ne 0) { throw 'Gagal menyalin file backup ke container.' }
  docker compose -f $composeFile exec -T db sh -c 'createdb -T template0 -U "$POSTGRES_USER" "$1"' sh $DatabaseName
  if ($LASTEXITCODE -ne 0) { throw 'Gagal membuat database tujuan.' }
  $createdDatabase = $true
  docker compose -f $composeFile exec -T db sh -c 'pg_restore --no-owner -U "$POSTGRES_USER" -d "$1" "$2"' sh $DatabaseName $containerPath
  if ($LASTEXITCODE -ne 0) { throw 'Restore gagal; database tujuan dibuat khusus untuk percobaan ini.' }
  Write-Output "Restore berhasil ke database baru: $DatabaseName"
} catch {
  if ($createdDatabase) {
    docker compose -f $composeFile exec -T db sh -c 'dropdb --if-exists -U "$POSTGRES_USER" "$1"' sh $DatabaseName | Out-Null
  }
  throw
} finally {
  docker compose -f $composeFile exec -T db rm -f $containerPath | Out-Null
}
