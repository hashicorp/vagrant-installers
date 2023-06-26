# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

<#
.SYNOPSIS
Packages a Vagrant installer from a substrate artifact and
an installed artifact

.DESCRIPTION
Builds an Windows Installer package using a Vagrant substrate
artifact and a Vagrant installed artifact (which is composed of
the gems installation directory in a substrate).

This script requires administrative privileges which are required
by MSI utilities invoked by WiX when running ICE modules.

.PARAMETER Substrate
Path to the substrate artifact file

.PARAMETER Installed
Path to the Vagrant installed artifact

.PARAMETER VagrantVersion
Version of Vagrant being packaged

.PARAMETER Destination
Directory to write installer artifact into
#>
param(
    [Parameter(Mandatory=$True)]
    [string]$Substrate,
    [Parameter(Mandatory=$True)]
    [string]$Installed,
    [Parameter(Mandatory=$True)]
    [string]$VagrantVersion,
    [Parameter(Mandatory=$True)]
    [string]$Destination
)

# Make sure 7zip and WiX are available on the Path
$env:Path = "${env:Path};C:\Program Files\7-Zip"
$wixdir = Get-Item -Path "C:\Program Files (x86)\WiX Toolset*"
$wixpath = $wixdir.FullName
$env:Path = "${env:Path};${wixpath}\bin"

# Helper to create a temporary directory
function New-TemporaryDirectory {
    $t = New-TemporaryFile
    Remove-Item -Path $t -Force | Out-Null
    New-Item -ItemType Directory -Path $t.FullName | Out-Null
    Get-Item -Path $t.FullName
}

# NOTE: Powershell has an archive module that can (de)compress
#       zip files. However, it is _extremely_ slow. These functions
#       use 7zip for handling compression/decompression of zip
#       artifacts resulting in a speedup gain of multiple orders
#       of magnitude

# Helper to compress zip file using 7zip
function Compress-Zipfile {
    param(
        [Parameter(Mandatory=$True)]
        [string]$SourceDirectory,
        [Parameter(Mandatory=$True)]
        [string]$Destination
    )
    $zipcmd = Get-Command 7z | Select-Object -ExpandProperty Definition
    $zipproc = Start-Process `
      -FilePath $zipcmd `
      -ArgumentList "a",$Destination,"." `
      -WorkingDirectory $SourceDirectory `
      -NoNewWindow `
      -PassThru
    $h = $zipproc.Handle
    $zipproc.WaitForExit()
    if ( $zipproc.ExitCode -ne 0 ) {
        Write-Error "Failed to zip directory (${SourceDirectory})"
    }
}

# Helper to decompress zip file using 7zip
function Expand-Zipfile {
    param(
        [Parameter(Mandatory=$True)]
        [string]$Path,
        [Parameter(Mandatory=$True)]
        [string]$Destination
    )
    $zipcmd = Get-Command 7z | Select-Object -ExpandProperty Definition
    $err = New-TemporaryFile
    $zipproc = Start-Process `
      -FilePath $zipcmd `
      -ArgumentList "x","-o${Destination}","${Path}" `
      -NoNewWindow `
      -PassThru
    $h = $zipproc.Handle
    $zipproc.WaitForExit()
    if ( $zipproc.ExitCode -ne 0 ) {
        $errContent | Write-Warning
        Write-Error "Failed to unzip file (${Path})"
    }
}


# Helper to create a temporary directory
function New-TemporaryDirectory() {
    $t = New-TemporaryFile
    Remove-Item -Path $t -Force | Out-Null
    New-Item -ItemType Directory -Path $t.FullName | Out-Null
    Get-Item -Path $t.FullName
}

# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

# Directory of this script
$ScriptDirectory = $PSScriptRoot
# Package directory
$PackageDirectory = Split-Path -Parent -Path $ScriptDirectory
# Project directory
$ProjectDirectory = Split-Path -Parent -Path $PackageDirectory

# Find required the WiX binaries. If these are not found
# it will force an error.
$WiXHeat = Get-Command heat | Select-Object -ExpandProperty Definition
$WiXCandle = Get-Command candle | Select-Object -ExpandProperty Definition
$WiXLight = Get-Command light | Select-Object -ExpandProperty Definition

# Get the full path to the substrate and gem. If the paths
# are invalid, this will error
$Substrate = Resolve-Path $Substrate
$Installed = Resolve-Path $Installed

# Check if the destination exists, and create if it does not
if ( ! ($Destination | Test-Path) ) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
}
$Destination = Resolve-Path $Destination

# Do a basic check on the version string that it
# at least kind of resembles a version
if ( ! ($VagrantVersion -match '(^[0-9]+\.[0-9]+\.[0-9]+)') ) {
    Write-Error "Vagrant version does not look like a valid version (${VagrantVersion})"
} else {
    $VagrantVersionCompat = $Matches[0]
}

# Find required the WiX binaries. If these are not found
# it will force an error.
$WiXHeat = Get-Command heat | Select-Object -ExpandProperty Definition
$WiXCandle = Get-Command candle | Select-Object -ExpandProperty Definition
$WiXLight = Get-Command light | Select-Object -ExpandProperty Definition

# Create a directory to work within
$WorkDirectory = New-TemporaryDirectory
$WorkPath = $WorkDirectory.FullName
Push-Location $WorkDirectory

# Create a directory to create our package structure within
$BuildDirectory = New-TemporaryDirectory
$BuildPath = $BuildDirectory.FullName

# Output start with defined variables
Write-Output "Starting Vagrant package installer build"
Write-Output "  Using Vagrant substrate: ${Substrate}"
Write-Output "  Using Vagrant installed: ${Installed}"
Write-Output "  Using Vagrant version: ${VagrantVersion}"
Write-Output "  Using Vagrant version compat: ${VagrantVersionCompat}"
Write-Output "  Build directory: ${BuildDirectory}"
Write-Output "  Work directory: ${WorkDirectory}"
Write-Output ""
Write-Output "-> Package destination: ${Destination}"
Write-Output ""

# Unpack the substrate into the work directory
Write-Output "Unpacking Vagrant substrate..."
Expand-Zipfile -Path $Substrate -Destination $BuildPath

# Detect the architecture based on available path
if ( Test-Path -Path "${BuildPath}\embedded\mingw64" ) {
    $SubstrateArch = "64"
} elseif ( Test-Path -Path "${BuildPath}\embedded\mingw32" ) {
    $SubstrateArch = "32"
} else {
    Write-Error "Could not detect architecture from unpacked substrate"
}

# Unpack the installed artifact into the embedded directory
Write-Output "Unpacking Vagrant installed artifact into substrate..."
$GemsDirectory = "${BuildPath}\embedded\gems"
if ( ! ($GemsDirectory | Test-Path) ) {
    New-Item -ItemType Directory -Path $GemsDirectory | Out-Null
}
Expand-ZipFile -Path $Installed -Destination $GemsDirectory

# Add the plugins and manifest files
$contents = @"
{
    "version": "1",
    "installed": {}
}
"@
$contents | Out-File -Encoding ASCII -FilePath "${BuildPath}\embedded\plugins.json"
$contents = @"
{
    "vagrant_version": "${VagrantVersion}"
}
"@
$contents | Out-File -Encoding ASCII -FilePath "${BuildPath}\embedded\manifest.json"

# Create a directory for building the installer structure
$InstallerDirectory = New-TemporaryDirectory
$InstallerPath = $InstallerDirectory.FullName

Write-Output "Building installer directory structure..."

# Create an asset directory and copy in assets
New-Item -ItemType Directory -Path "${InstallerPath}\assets" | Out-Null
Copy-Item "${PackageDirectory}\support\windows\bg_banner.bmp" `
  -Destination "${InstallerPath}\assets\bg_banner.bmp"
Copy-Item "${PackageDirectory}\support\windows\bg_dialog.bmp" `
  -Destination "${InstallerPath}\assets\bg_dialog.bmp"
Copy-Item "${PackageDirectory}\support\windows\license.rtf" `
  -Destination "${InstallerPath}\assets\license.rtf"
Copy-Item "${PackageDirectory}\support\windows\burn_logo.bmp" `
  -Destination "${InstallerPath}\assets\burn_logo.bmp"
Copy-Item "${PackageDirectory}\support\windows\vagrant.ico" `
  -Destination "${InstallerPath}\assets\vagrant.ico"

# Now copy over the WiX configuration
Copy-Item "${PackageDirectory}\support\windows\vagrant-en-us.wxl" `
  -Destination "${InstallerPath}\vagrant-en-us.wxl"
Copy-Item "${PackageDirectory}\support\windows\vagrant-main.wxs" `
  -Destination "${InstallerPath}\vagrant-main.wxs"

# The configuration file needs to be read in locally so we
# can apply our current values to the variables it defines
$ConfigContent = Get-Content -Path "${PackageDirectory}\support\windows\vagrant-config.wxi"

# The configuration defines variables for the vagrant
# version and the base directory (which is a reference
# to the installer directory)
$ConfigContent = $ConfigContent -replace "%VERSION_NUMBER%",$VagrantVersionCompat
$ConfigContent = $ConfigContent -replace "%BASE_DIRECTORY%",$InstallerPath

# Write config file with the updated content
$ConfigContent | Out-File -Encoding ASCII -FilePath "${InstallerPath}\vagrant-config.wxi"

# Now start the packaging process
Write-Output "Starting the Vagrant installer packaging process..."

# The first step is to run heat.exe against the build
# directory. This will collect information (referred to
# as "harvesting") about all the files (and the directory
# structure) that are to included within the installer package

# Define arguments passed to heat
$hargs = @(
    "dir",
    $BuildDirectory,
    "-nologo",
    "-sreg", # Do not harvest registry
    "-srd", # Do not harvest the root directory as an element
    "-gg", # Generate guids during the harvest
    "-g1", # Generate guids without braces
    "-sfrag", # Do not generate directory or component fragments
    "-cg", "VagrantDir", # Name of the component group
    "-dr", "INSTALLDIR", # Reference name used for the root directory
    "-var", "var.VagrantSourceDir", # Substitue path source with this variable name
    "-out", "${InstallerPath}\vagrant-files.wxs"
)

Write-Output "Running file harvest stage..."

# Launch the heat process
$HeatProc = Start-Process `
  -FilePath $WiXHeat `
  -ArgumentList $hargs `
  -NoNewWindow `
  -PassThru

# cache process handle so ExitCode is populated correctly
$handle = $HeatProc.Handle

# Wait for the process to complete
$HeatProc.WaitForExit()

# If the process failed, force error
if ( $HeatProc.ExitCode -ne 0 ) {
    Write-Error "Package process failed during file harvest stage (heat.exe)"
}

# The next step is to run the wix files through candle.exe
# which is a preprocessor to get the files into the correct
# valid XML for the WiX schema

# Define arguments passed to candle
$cargs = @(
    "-nologo",
    "-I${InstallerDirectory}", # Defines include directory to search (allows vagrant-config.wxi to be found)
    "-dVagrantSourceDir=${BuildDirectory}", # Defines value for variable (which was used in heat)
    "-out ${InstallerDirectory}\",
    "${InstallerDirectory}\vagrant-files.wxs",
    "${InstallerDirectory}\vagrant-main.wxs"
)

Write-Output "Running preprocess stage..."

# Launch the candle process
$CandleProc = Start-Process `
  -FilePath $WiXCandle `
  -ArgumentList $cargs `
  -NoNewWindow `
  -PassThru

# cache process handle so ExitCode is populated correctly
$handle = $CandleProc.Handle

# Wait for the process to complete
$CandleProc.WaitForExit()

# If the process failed, force error
if ( $CandleProc.ExitCode -ne 0 ) {
    Write-Error "Package process failed during preprocess stage (candle.exe)"
}

# The final step is to run light.exe on the Wix configuration
# files we have generated up to this point. The end result will
# be the installer package

# Define arguments passed to light
$largs = @(
    "-nologo",
    "-ext", "WixUIExtension",
    "-ext", "WixUtilExtension",
    "-spdb",
    "-v",
    "-cultures:en-us",
    "-loc", "${InstallerDirectory}\vagrant-en-us.wxl",
    "-out", ".\vagrant.msi",
    "${InstallerDirectory}\vagrant-files.wixobj",
    "${InstallerDirectory}\vagrant-main.wixobj"
)

Write-Output "Running final packaging stage..."

# Launch the light process
$LightProc = Start-Process `
  -FilePath $WiXLight `
  -ArgumentList $largs `
  -NoNewWindow `
  -PassThru

# cache process handle so ExitCode is populated correctly
$handle = $LightProc.Handle

# Wait for the process to complete
$LightProc.WaitForExit()

# If the process failed, force error
if ( $LightProc.ExitCode -ne 0 ) {
    Write-Error "Package process failed during final packaging (light.exe)"
}

# Package has been successfully built. Move it to the output
# location and this is now complete.
if ( $SubstrateArch -eq "64" ) {
    $OutputPath = "${Destination}\vagrant_${VagrantVersion}_windows_amd64.msi"
} else {
    $OutputPath = "${Destination}\vagrant_${VagrantVersion}_windows_i686.msi"
}

Move-Item -Force -Path .\vagrant.msi -Destination $OutputPath

Write-Output "Vagrant installer build complete: ${OutputPath}"
