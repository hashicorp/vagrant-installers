<#
.SYNOPSIS
    Bootstrap for package building

.DESCRIPTION
    Installs required software and builds package
#>

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

if($SubstrateExists) {
    Write-Output "Starting 64-bit package build"
    Set-Location -Path "C:\vagrant\${pkg_dir}"

    if(!$env:SignKeyPath) {
        $SignKeyPath = "C:\users\vagrant\Win_CodeSigning.p12"
    } else {
        $SignKeyPath = $env:SignKeyPath
    }
    $SignKeyExists = Test-Path -LiteralPath $SignKeyPath
    $PackageScript = "C:\vagrant\package\package.ps1"

    Write-Output "Starting 64-bit package process"

    if($SignKeyExists) {
        if(!$env:SignKeyPassword) {
            Write-Error "Error: No password provided for code signing key!"
        }
        $PackageArgs = @{
            "SubstratePath"="${SubstratePath}";
            "VagrantRevision"="main";
            "SignKey"="${SignKeyPath}";
            "SignKeyPassword"="${env:SignKeyPassword}";
            "SignRequired"="${env:VAGRANT_PACKAGE_SIGNING_REQUIRED}";
        }
    } else {
        $PackageArgs = @{
            "SubstratePath"="${SubstratePath}";
            "VagrantRevision"="main";
            "SignRequired"="${env:VAGRANT_PACKAGE_SIGNING_REQUIRED}";
        }
    }

    & $PackageScript @PackageArgs
    if(!$?){
        Write-Error "Error: Packaging 64-bit build failed!"
    }
}

$SubstratePath = "C:\vagrant\substrate-assets\substrate_windows_i686.zip"
$SubstrateExists = Test-Path -LiteralPath $SubstratePath

if($SubstrateExists) {
    Write-Output "Starting 32-bit package process..."

    if($SignKeyExists) {
        if(!$env:SignKeyPassword) {
            Write-Error "Error: No password provided for code signing key!"
        }
        $PackageArgs = @{
            "SubstratePath"="${SubstratePath}";
            "VagrantRevision"="main";
            "SignKey"="${SignKeyPath}";
            "SignKeyPassword"="${env:SignKeyPassword}";
            "SignRequired"="${env:VAGRANT_PACKAGE_SIGNING_REQUIRED}";
        }
    } else {
        $PackageArgs = @{
            "SubstratePath"="${SubstratePath}";
            "VagrantRevision"="main";
            "SignRequired"="${env:VAGRANT_PACKAGE_SIGNING_REQUIRED}";
        }
    }

    & $PackageScript @PackageArgs
    if(!$?){
        Write-Error "Error: Packaging 32-bit build failed!"
    }
}
