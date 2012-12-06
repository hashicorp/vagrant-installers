<#
.SYNOPSIS
    Creates a Vagrant installer.

.PARAMETER Revision
    The revision of Vagrant to download from GitHub and build an
    installer for.

.PARAMETER Version
    The version of Vagrant this installer will be for. This is used
    for installer metadata.

.PARAMETER DistDir
    The directory to put the outputted MSI installer.
#>
Param(
    [Parameter(Mandatory=$true)]
    [string]$Revision,

    [Parameter(Mandatory=$true)]
    [string]$Version,

    [Parameter(Mandatory=$true)]
    [string]$DistDir
)

# Set environmental variables for facter
$env:FACTER_param_vagrant_revision = $Revision
$env:FACTER_param_vagrant_version = $Version
$env:FACTER_param_dist_dir = $DistDir

# Execute Puppet
$arguments = @(
    "apply",
    "--confdir=config",
    "--modulepath=modules",
    "manifests/init.pp"
)

$path = "C:\Program Files (x86)\Puppet Labs\Puppet\bin\puppet.bat"

Start-Process -NoNewWindow -Wait -ArgumentList $arguments -FilePath $path
