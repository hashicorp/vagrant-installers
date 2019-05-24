<#
.SYNOPSIS
    Bootstrap for package building

.DESCRIPTION
    Installs required software and builds package
#>

$TmpDir = [System.IO.Path]::GetTempPath()
$SubstrateDestination = [System.IO.Path]::Combine($TmpDir, "substrate_windows_x64.zip")

if(!$env:VAGRANT_PACKAGE_OUTPUT_DIR){
    $pkg_dir = "pkg"
} else {
    $pkg_dir = $env:VAGRANT_PACKAGE_OUTPUT_DIR
}

# http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
# http://stackoverflow.com/questions/8978052/powershell-2-0-redirection-file-handle-exception
[System.IO.Directory]::CreateDirectory("C:\vagrant\substrate-assets") | Out-Null
[System.IO.Directory]::CreateDirectory("C:\vagrant\${pkg_dir}") | Out-Null

$SubstratePath = "C:\vagrant\substrate-assets\substrate_windows_x86_64.zip"
$SubstrateExists = Test-Path -LiteralPath $SubstratePath

if(!$SubstrateExists) {
    Write-Host "Error: No substrate found @ ${SubstratePath}!"
    exit 1
}

Write-Host "Starting package build"
Set-Location -Path "C:\vagrant\${pkg_dir}"

if(!$env:SignKeyPath) {
    $SignKeyPath = "C:\vagrant\Win_CodeSigning.p12"
} else {
    $SignKeyPath = $env:SignKeyPath
}
$SignKeyExists = Test-Path -LiteralPath $SignKeyPath
$PackageScript = "C:\vagrant\package\package.ps1"

Write-Host "Starting 64-bit package process"

if($SignKeyExists) {
    if(!$env:SignKeyPassword) {
        Write-Host "Error: No password provided for code signing key!"
        exit 1
    }
    $PackageArgs = @{
        "SubstratePath"="${SubstratePath}";
        "VagrantRevision"="master";
        "SignKey"="${SignKeyPath}";
        "SignKeyPassword"="${env:SignKeyPassword}"
    }
} else {
    $PackageArgs = @{
        "SubstratePath"="${SubstratePath}";
        "VagrantRevision"="master"
    }
}

& $PackageScript @PackageArgs
if(!$?){
    Write-Host "Error: Packaging failed!"
    exit 1
}

Write-Host "Starting 32-bit package process..."
$SubstratePath = "C:\vagrant\substrate-assets\substrate_windows_i686.zip"

if($SignKeyExists) {
    if(!$env:SignKeyPassword) {
        Write-Host "Error: No password provided for code signing key!"
        exit 1
    }
    $PackageArgs = @{
        "SubstratePath"="${SubstratePath}";
        "VagrantRevision"="master";
        "SignKey"="${SignKeyPath}";
        "SignKeyPassword"="${env:SignKeyPassword}"
    }
} else {
    $PackageArgs = @{
        "SubstratePath"="${SubstratePath}";
        "VagrantRevision"="master"
    }
}

& $PackageScript @PackageArgs
if(!$?){
    Write-Host "Error: Packaging failed!"
    exit 1
}
