$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path -LiteralPath '.env')) {
    $text = Get-Content -LiteralPath '.env.example' -Raw
    $text = $text.Replace('CHANGE_ME_S3_SECRET', [guid]::NewGuid().ToString('N'))
    $text = $text.Replace('CHANGE_ME_POSTGRES_PASSWORD', [guid]::NewGuid().ToString('N'))
    $text = $text.Replace('CHANGE_ME_WITH_A_LONG_RANDOM_KEY_32_CHARS',
        ([guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')))
    Set-Content -LiteralPath '.env' -Value $text -Encoding ascii
    Write-Host 'Created .env'
}
if (-not (Test-Path -LiteralPath '.env.bi')) {
    $key = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
    Set-Content -LiteralPath '.env.bi' -Value "SUPERSET_SECRET_KEY=$key" -Encoding ascii
    Write-Host 'Created .env.bi'
}
Write-Host 'Existing local environment files were preserved.'
