<#
.SYNOPSIS
    Creates a Vagrant installer.

.PARAMETER OutputDir
    The directory to put the outputted substrate package.
#>
Param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir
)

# Get the directory to this script
$Dir = Split-Path $script:MyInvocation.MyCommand.Path

# We need to create a temporary configuration directory because Puppet
# needs to run on a filesystem that supports NTFS.
$TmpDir = [System.IO.Path]::GetTempPath()
$TmpDir = [System.IO.Path]::Combine($TmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($TmpDir) | Out-Null

# Copy all the configuration items into the temporary directory
Get-ChildItem -Recurse "$($Dir)\config" | Copy-Item -Destination $TmpDir

# Set environmental variables for facter
$env:FACTER_param_output_dir = Resolve-Path $OutputDir

# Execute Puppet
$arguments = @(
    "apply",
    "--confdir=$TmpDir",
    "--modulepath=$($Dir)/modules",
    "--detailed-exitcodes",
    "$($Dir)/manifests/init.pp"
)

$path = "C:\Program Files (x86)\Puppet Labs\Puppet\bin\puppet.bat"

Set-Location $Dir
$result = Start-Process -NoNewWindow -Wait -ArgumentList $arguments -FilePath $path

if($result.ExitCode -ne 0 -And $result.ExitCode -ne 2){
  Exit $result.ExitCode
} else {
  Exit 0
}