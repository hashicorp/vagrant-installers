# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

<#
.SYNOPSIS
Creates a Vagrant installer.

.PARAMETER OutputDir
The directory to put the outputted substrate package.
#>
Param(
    [parameter(Mandatory=$true)]
    [string] $OutputDirectory,
    [parameter(Mandatory=$true)]
    [string] $LauncherDirectory
)

$ProjectSubstrateDir = $PSScriptRoot
$ProjectSubstrateDir = $ProjectSubstrateDir.Replace("\", "\\")

$ErrorActionPreference = "Stop"

# Validate the paths provided
if ( ! ($OutputDirectory | Test-Path) ) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

if ( ! ($LauncherDirectory | Test-Path) ) {
    Write-Error "Invalid launcher directory path provided"
}

# Get full paths
$outdir = Get-Item -Path $OutputDirectory
$launchdir = Get-Item -Path $LauncherDirectory
$outpath = $outdir.FullName
$launchpath = $launchdir.FullName

Write-Output "Launching substrate build process..."

# Start the build process
$build_proc = Start-Process `
  -FilePath C:\msys64\usr\bin\bash.exe `
  -ArgumentList "-l","${ProjectSubstrateDir}\\windows\\substrate-builder",$outpath,$launchpath `
  -NoNewWindow `
  -PassThru

# Cache the process handle. It doesn't ever get used
# but this results in the ExitCode actually getting
# populated correctly.
$handle = $build_proc.Handle

# Define a reasonably long time for the process to complete
$build_timeout = New-TimeSpan -Hours 2

# Now wait for it to complete
Wait-Process -Timeout $build_timeout.TotalSeconds -Id $build_proc.Id

# If it didn't complete, force an error
if ( ! $build_proc.HasExited ) {
    Write-Error "Failed to build substate within 60 minute limit"
}

# If it did complete, but failed, force an error
if ( $build_proc.ExitCode -ne 0 ) {
    $code = $build_proc.ExitCode
    Write-Error "Substrate build failed (code: ${code})"
}

# If we are still here, it was a success so we just leave!
Write-Output "Substrate builds are complete"
