param(
    [Parameter(Mandatory = $true)]
    [string]$CertPath
)

$pem = Get-Content -Raw -Path $CertPath
$base64 = $pem -replace '-----BEGIN CERTIFICATE-----', '' -replace '-----END CERTIFICATE-----', '' -replace '\s', ''
$bytes = [Convert]::FromBase64String($base64)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 @(, $bytes)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'CurrentUser')
$store.Open('ReadWrite')

try {
    $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    if ($existing) {
        Write-Output 'Root CA already trusted.'
    } else {
        $store.Add($cert)
        Write-Output 'Root CA added to the current user trust store. Restart the browser once if the warning remains.'
    }
} catch {
    Write-Error $_
    exit 1
} finally {
    $store.Close()
}
