<#
.SYNOPSIS
    Bootstrap for package building

.DESCRIPTION
    Installs required software and builds package
#>

$CurPath = [Environment]::GetEnvironmentVariable("PATH"); [Environment]::SetEnvironmentVariable("PATH", "${CurPath};C:\Program Files (x86)\Wix Toolset v3.10\bin\", "Machine")

$TmpDir = [System.IO.Path]::GetTempPath()
$SubstrateURL = "https://s3.amazonaws.com/hc-ops/vagrant-substrate/substrate_windows_x64.zip"
$SubstrateDestination = [System.IO.Path]::Combine($TmpDir, "substrate_windows_x64.zip")

# http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
# http://stackoverflow.com/questions/8978052/powershell-2-0-redirection-file-handle-exception
[System.IO.Directory]::CreateDirectory("C:\vagrant\substrate-assets") | Out-Null
[System.IO.Directory]::CreateDirectory("C:\vagrant\pkg") | Out-Null

$SubstratePath = "C:\vagrant\substrate-assets\substrate_windows_x64.zip"
$SubstrateExists = Test-Path -LiteralPath $SubstratePath

if(!$SubstrateExists){
  Write-Host "Downloading windows substrate for package build."
  $WebClient = New-Object System.Net.WebClient
  $WebClient.DownloadFile($SubstrateURL, $SubstrateDestination)
  Move-Item $SubstrateDestination, $SubstratePath
}
Write-Host "Starting package build"
Set-Location -Path C:\vagrant\pkg

$SignKeyPath = "C:\vagrant\Win_CodeSigning.p12"
$SignKeyExists = Test-Path -LiteralPath $SignKeyPath
if($SignKeyExists){
  if(!$env:SignKeyPassword){
    Write-Host "Error: No password provided for code signing key!"
    exit 1
  }
  Invoke-Expression "C:\vagrant\package\package.ps1 -SubstratePath ${SubstratePath} -VagrantRevision master -SignKey ${SignKeyPath} -SignKeyPassword ${env:SignKeyPassword} -SignPath 'C:\Program Files (x86)\Windows Kits\8.1\bin\x86\signtool.exe'"
} else {
  Invoke-Expression "C:\vagrant\package\package.ps1 -SubstratePath ${SubstratePath} -VagrantRevision master"
}