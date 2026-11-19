param(
    [Parameter(Mandatory = $true)]
    [string]$CertPath,

    [switch]$Remove
)

$pem = Get-Content -Raw -Path $CertPath
$base64 = $pem -replace '-----BEGIN CERTIFICATE-----', '' -replace '-----END CERTIFICATE-----', '' -replace '\s', ''
$bytes = [Convert]::FromBase64String($base64)
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 @(, $bytes)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'CurrentUser')
$store.Open('ReadWrite')

try {
    # Match by thumbprint: every Caddy project uses the same subject name.
    $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }

    if ($Remove) {
        if ($existing) {
            $existing | ForEach-Object { $store.Remove($_) }
            Write-Output "Root CA $($cert.Thumbprint) removed from the current user trust store."
        } else {
            Write-Output "Root CA $($cert.Thumbprint) was not in the current user trust store."
        }
    } elseif ($existing) {
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
