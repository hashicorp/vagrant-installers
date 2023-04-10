<#
.SYNOPSIS
Packages a Vagrant installer from a substrate artifact and
Vagrant Ruby Gem

.DESCRIPTION
Builds an Windows Installer package using a Vagrant substrate
artifact and Vagrant Ruby Gem.

This script requires administrative privileges which are required
by MSI utilities invoked by WiX when running ICE modules.

.PARAMETER Substrate
Path to the substrate artifact file

.PARAMETER VagrantGem
Path to the Vagrant Ruby Gem file

.PARAMETER Destination
Directory to write installer artifact into
#>
param(
    [Parameter(Mandatory=$True)]
    [string]$Substrate,
    [Parameter(Mandatory=$True)]
    [string]$VagrantGem,
    [Parameter(Mandatory=$True)]
    [string]$Destination
)

# Make sure 7zip and WiX are available on the Path
$env:Path = "${env:Path};C:\Program Files\7-Zip"

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
#
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

# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

# Directory of this script
$ScriptDirectory = $PSScriptRoot
# Package directory
$PackageDirectory = Split-Path -Parent -Path $ScriptDirectory
$PackagePath = $PackageDirectory.FullName
# Project directory
$ProjectDirectory = Split-Path -Parent -Path $PackageDirectory
$ProjectPath = $ProjectDirectory.FullName

# Get the full path to the substrate and gem. If the paths
# are invalid, this will error
$Substrate = Resolve-Path $Substrate
$VagrantGem = Resolve-Path $VagrantGem

# Check if the destination exists, and create if it does not
if ( ! ($Destination | Test-Path) ) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
}
$Destination = Resolve-Path $Destination

# Create a directory to work within
$WorkDirectory = New-TemporaryDirectory
$WorkPath = $WorkDirectory.FullName
Push-Location $WorkDirectory

# Create a directory to create our package structure within
$BuildDirectory = New-TemporaryDirectory
$BuildPath = $BuildDirectory.FullName

# Output start with defined variables
Write-Output "Starting Vagrant install artifact build"
Write-Output "  Using Vagrant substrate: ${Substrate}"
Write-Output "  Using Vagrant gem: ${VagrantGem}"
Write-Output "  Build directory: ${BuildDirectory}"
Write-Output "  Work directory: ${WorkDirectory}"
Write-Output ""
Write-Output "-> Artifact destination: ${Destination}"
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

# Define the mingw directory and mingw architecture directory
$MingwName = "mingw${SubstrateArch}"
$MingwDirectory = "/${MingwName}"
if ( $SubstrateArch -eq "64" ) {
    $MingwArchDirectory = "${MingwDirectory}/x86_64-w64-mingw32"
} else {
    $MingwArchDirectory = "${MingwDirectory}/i686-w64-mingw32"
}

# Define some paths to make a little things cleaner
$RubyCmdPath = "${BuildPath}\embedded${MingwDirectory}\bin\ruby.exe"
$GemCmdPath = "${BuildPath}\embedded${MingwDirectory}\bin\gem"

Write-Output "Starting Vagrant gem installation process..."

# Path to embedded directory
$EmbeddedDirectory = "${BuildPath}\embedded"
$GemsDirectory = "${EmbeddedDirectory}\gems"

# Set rubygems environment variables required for install
$env:GEM_PATH = "${GemsDirectory}"
$env:GEM_HOME = $env:GEM_PATH
$env:GEMRC = "${EmbeddedDirectory}\etc\gemrc"

# Update the local Path to include executables from the substrate
$env:Path = "${EmbeddedDirectory}\${MingwName}\bin;${EmbeddedDirectory}\usr\bin;${env:Path}"

# Set build flags. These need to be set in the context of
# the running process which will have an adjusted location
# for root. The embedded directory will be the root directory.
# This is why the mingw paths are referenced from root and not
# the actual build directory they are within
$env:CFLAGS = "-I${MingwArchDirectory}/include -I${MingwDirectory}/include -I/usr/include"
$env:CPPFLAGS = $env:CFLAGS
$env:LDFLAGS = "-L${MingwArchDirectory}/lib -L${MingwDirectory}/lib -L/usr/lib"
$env:PKG_CONFIG_PATH = "${MingwDirectory}/lib/pkgconfig;/usr/lib/pkgconfig"
$env:TMPDIR = $env:TEMP
$env:TMP = $env:TEMP

# Set the path to the SSL certificate bundle for rubygems to use
$env:SSL_CERT_FILE = "${EmbeddedDirectory}\cert.pem"

# The grpc rubygem needs to be modified before its extension is
# built. Set the script to do that.
$env:RUBYGEMS_POST_EXTRACT_HOOK = "${ScriptDirectory}\grpc-extconf-fix"

# Start the install process
$GemProc = Start-Process `
  -File $RubyCmdPath `
  -ArgumentList $GemCmdPath,"install","--platform","ruby",$VagrantGem `
  -NoNewWindow `
  -PassThru
# Cache the process handle. It doesn't ever get used
# but this results in the ExitCode actually getting
# populated correctly.
$handle = $GemProc.Handle

# Wait for the process to complete
$GemProc.WaitForExit()

# If the install failed force an error
if ( $GemProc.ExitCode -ne 0 ) {
    Write-Error "Failed to install the Vagrant gem"
}

Write-Output "Creating installed artifact..."

# Create the artifact
Compress-Zipfile -SourceDirectory "${GemsDirectory}" -Destination "${WorkPath}\installed.zip"

if ( $SubstrateArch -eq "64" ) {
    $OutputPath = "${Destination}\installed_windows_x86_64.zip"
} else {
    $OutputPath = "${Destination}\installed_windows_386.zip"
}

# Place the artifact in the destination
Move-Item -Force -Path "${WorkPath}\installed.zip" -Destination $OutputPath

Write-Output "Process complete, artifact located at: ${OutputPath}"
