# Initial setup for a NEW deployment. Run after Lakekeeper becomes healthy.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$config = @{}
foreach ($line in Get-Content -LiteralPath '.env') {
    if ($line.Trim() -and -not $line.TrimStart().StartsWith('#')) {
        $pair = $line -split '=', 2
        if ($pair.Count -eq 2) {
            $config[$pair[0].Trim()] = $pair[1].Trim()
        }
    }
}
foreach ($key in @('S3_ACCESS_KEY', 'S3_SECRET_KEY')) {
    if (-not $config[$key]) { throw "Missing $key in .env" }
}
docker compose exec -T silo mcli alias set local http://localhost:9000 $config['S3_ACCESS_KEY'] $config['S3_SECRET_KEY']
if ($LASTEXITCODE -ne 0) { throw 'S3 alias failed' }
docker compose exec -T silo mcli mb --ignore-existing local/lakehouse
if ($LASTEXITCODE -ne 0) { throw 'Bucket creation failed' }

try {
    Invoke-RestMethod -Method Post -Uri 'http://localhost:8181/management/v1/bootstrap' -ContentType 'application/json' -Body '{"accept-terms-of-use":true}' | Out-Null
}
catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 409) {
        Write-Host 'Lakekeeper is already bootstrapped.'
    }
    else { throw }
}

$body = @{
    'warehouse-name' = 'lakehouse'
    'project-id' = '00000000-0000-0000-0000-000000000000'
    'storage-profile' = @{
        type = 's3'
        bucket = 'lakehouse'
        'key-prefix' = 'warehouse'
        endpoint = 'http://silo:9000'
        region = 'us-east-1'
        'path-style-access' = $true
        flavor = 's3-compat'
        'sts-enabled' = $true
    }
    'storage-credential' = @{
        type = 's3'
        'credential-type' = 'access-key'
        'aws-access-key-id' = $config['S3_ACCESS_KEY']
        'aws-secret-access-key' = $config['S3_SECRET_KEY']
    }
} | ConvertTo-Json -Depth 10

# Creation is intentionally explicit: do not recreate an existing warehouse.
Invoke-RestMethod -Method Post -Uri 'http://localhost:8181/management/v1/warehouse' -ContentType 'application/json' -Body $body | Select-Object id, 'warehouse-id', name
Invoke-RestMethod -Uri 'http://localhost:8181/catalog/v1/config?warehouse=lakehouse' | ConvertTo-Json -Depth 10
