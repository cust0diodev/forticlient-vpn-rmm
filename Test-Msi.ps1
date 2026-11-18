$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$msi = Join-Path $base 'FortiClientVPN-7.4.3.6002-x64.msi'
$product = '{15C7B361-A0B2-4E79-93E0-868B5000BA3F}'
$arpPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + $product
$result = [ordered]@{ identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name; install=$null; uninstall=$null; signature=$null; version=$null; success=$false }
try {
    if ($result.identity -ne 'NT AUTHORITY\SYSTEM') { throw 'Test must run as SYSTEM' }
    $expected=(Get-Content (Join-Path $base 'package.json') -Raw | ConvertFrom-Json).sha256
    if ((Get-FileHash $msi -Algorithm SHA256).Hash -ne $expected) { throw 'MSI hash mismatch' }
    $signature=Get-AuthenticodeSignature -LiteralPath $msi
    $result.signature=[string]$signature.Status
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Fortinet') { throw 'MSI signature is not valid Fortinet signature' }
    $log=Join-Path $base 'install.log'
    $p=Start-Process msiexec.exe -WindowStyle Hidden -ArgumentList @('/i', ('"'+$msi+'"'), '/qn', '/norestart', 'REBOOT=ReallySuppress', 'DONT_PROMPT_REBOOT=1', '/L*v', ('"'+$log+'"')) -Wait -PassThru
    $result.install=$p.ExitCode
    if ($p.ExitCode -notin 0,3010) { throw "Install failed: $($p.ExitCode)" }
    $arp=Get-ItemProperty -LiteralPath $arpPath
    $result.version=$arp.DisplayVersion
    if ($arp.DisplayVersion -ne '7.4.3.6002' -or $arp.WindowsInstaller -ne 1) { throw 'Wrong or missing Windows Installer registration' }
    foreach ($file in 'FortiClient.exe','FortiTray.exe') {
        $path=Join-Path 'C:\Program Files\Fortinet\FortiClient' $file
        if (!(Test-Path -LiteralPath $path)) { throw "Missing $file" }
    }
    $services=Get-CimInstance Win32_Service | Where-Object PathName -Match 'Fortinet|FortiClient'
    if (!$services) { throw 'No Fortinet service registered' }
    $result['services']=@($services | Select-Object Name,State)
    $drivers=Get-CimInstance Win32_SystemDriver | Where-Object { $_.PathName -match 'forti|ftvnic|ftsvnic|fctap' }
    if (!$drivers) { throw 'No Fortinet driver registered' }
    $result['drivers']=@($drivers | Select-Object Name,State)
    $log=Join-Path $base 'uninstall.log'
    $p=Start-Process msiexec.exe -WindowStyle Hidden -ArgumentList @('/x', $product, '/qn', '/norestart', 'REBOOT=ReallySuppress', 'DONT_PROMPT_REBOOT=1', '/L*v', ('"'+$log+'"')) -Wait -PassThru
    $result.uninstall=$p.ExitCode
    if ($p.ExitCode -notin 0,3010) { throw "Uninstall failed: $($p.ExitCode)" }
    if (Test-Path -LiteralPath $arpPath) { throw 'Product remains registered after uninstall' }
    $result.success=$true
} catch {
    $result['error']=$_.Exception.Message
} finally {
    $result | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $base 'test-result.json') -Encoding UTF8
}
if (!$result.success) { exit 1 }
