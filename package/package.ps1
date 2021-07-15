<#
.SYNOPSIS
Packages a Vagrant installer from a substrate package.

.DESCRIPTION
Packages a Vagrant installer from a substrate package.

This script requires administrative privileges.

You can run this script from an old-style cmd.exe prompt using the
following:

powershell.exe -ExecutionPolicy Unrestricted -NoLogo -NoProfile -Command "& '.\package.ps1'"

.PARAMETER SubstratePath
Path to the substrate zip file.

.PARAMETER VagrantRevision
The commit revision of Vagrant to install.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SubstratePath,

    [Parameter(Mandatory=$true)]
    [string]$VagrantRevision,

    [string]$VagrantSourceBaseURL="https://github.com/hashicorp/vagrant/archive/",

    [string]$SignKey="",
    [string]$SignKeyPassword="",
    [string]$SignPath="",
    [string]$SignRequired="",

    [string]$BuildStyle="ephemeral",
    [string]$ScrubCache="no"
)

# Default build architecture to 64bit
$PackageArch = "64"

# Exit if there are any exceptions
$ErrorActionPreference = "Stop"

# Put this in a variable to make things easy later
$UpgradeCode = "1a672674-6722-4e3a-9061-8f539a8b0ed6"

# Get the directory to this script
$Dir = Split-Path $script:MyInvocation.MyCommand.Path

# Lookup the WiX binaries, these will error if they're not on the Path
$WixHeat   = Get-Command heat | Select-Object -ExpandProperty Definition
$WixCandle = Get-Command candle | Select-Object -ExpandProperty Definition
$WixLight  = Get-Command light | Select-Object -ExpandProperty Definition

If ($BuildStyle -ne "ephemeral" -And $BuildStyle -ne "cached") {
    Write-Output "Error: BuildStyle must be either 'ephemeral' or 'cached'"
    exit 1
}

$UseCache = $false

#--------------------------------------------------------------------
# Helper Functions
#--------------------------------------------------------------------
function Expand-ZipFile($file, $destination) {
    $shell = New-Object -ComObject "Shell.Application"
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}

#--------------------------------------------------------------------
# Extract Substrate
#--------------------------------------------------------------------
# We need the full path to the file
$SubstratePath = Resolve-Path $SubstratePath

# We need to create a temporary configuration directory
$SubstrateTmpDir = [System.IO.Path]::GetTempPath()
If ($BuildStyle -eq "ephemeral") {
    $SubstrateTmpDir = [System.IO.Path]::Combine(
        $SubstrateTmpDir, [System.IO.Path]::GetRandomFileName())
    [System.IO.Directory]::CreateDirectory($SubstrateTmpDir) | Out-Null
} Else {
    $SubstrateTmpDir = [System.IO.Path]::Combine(
        $SubstrateTmpDir, "vagrant-substrate-builder")
    If ($ScrubCache -eq "no") {
        [System.IO.Directory]::CreateDirectory($SubstrateTmpDir) | Out-Null
        $SubstrateDirectory = Get-ChildItem $SubstrateTmpDir
        If ($SubstrateDirectory.count -ne 0) {
            $UseCache = $true
        }
    } Else {
        [System.IO.Directory]::Delete($SubstrateTmpDir, $true)
        [System.IO.Directory]::CreateDirectory($SubstrateTmpDir) | Out-Null
    }
}

Write-Output "Substrate temp dir: ${SubstrateTmpDir}"

# Unzip
If ($UseCache -eq $false) {
    Write-Output "Expanding substrate..."
    Start-Process "C:\Program Files\7-Zip\7z.exe" "x -o${SubstrateTmpDir} ${SubstratePath}" -NoNewWindow -Wait -RedirectStandardOutput C:\Windows\Temp\unpack.log
} Else {
    Write-Output "Using cached substrate"
}

# Set the full path to the substrate
$SubstrateDir = "${SubstrateTmpDir}"

$Path32Bit = [System.IO.Path]::Combine($SubstrateDir, "embedded", "mingw32")
if (Test-Path -Path $Path32Bit) {
    Write-Output "Detected 32bit substrate. Building 32bit package."
    $PackageArch = "32"
}

#--------------------------------------------------------------------
# Install Vagrant
#--------------------------------------------------------------------
$VagrantTmpDir = [System.IO.Path]::GetTempPath()
if ($BuildStyle -eq "ephemeral" ) {
    $VagrantTmpDir = [System.IO.Path]::Combine(
        $VagrantTmpDir, [System.IO.Path]::GetRandomFileName())
    [System.IO.Directory]::CreateDirectory($VagrantTmpDir) | Out-Null
} Else {
    $VagrantTmpDir = [System.IO.Path]::Combine(
        $VagrantTmpDir, "vagrant-${VagrantRevision}")
    If ($ScrubCache -eq "no") {
        [System.IO.Directory]::CreateDirectory($VagrantTmpDir) | Out-Null
        $VagrantDirectory = Get-ChildItem $VagrantTmpDir
        If ($VagrantDirectory.count -ne 0) {
            $UseCache = $true
        }
    } Else {
        [System.IO.Directory]::Delete($VagrantTmpDir, $true)
        [System.IO.Directory]::CreateDirectory($VagrantTmpDir) | Out-Null
    }
}

Write-Output "Vagrant temp dir: ${VagrantTmpDir}"

$VagrantSourceURL = "${VagrantSourceBaseURL)/$($VagrantRevision}.zip"
$VagrantDest      = "${VagrantTmpDir}\vagrant.zip"
$VagrantSourceDir = $VagrantTmpDir

if (-Not (Test-Path -Path "${Dir}\vagrant.gem")) {
    # Download
    If ($UseCache -eq $false) {
        Write-Output "Downloading Vagrant: ${VagrantRevision}"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($VagrantSourceURL, $VagrantDest)

        # Unzip
        Write-Output "Unzipping Vagrant"
        Expand-ZipFile -file $VagrantDest -destination $VagrantTmpDir
    } Else {
        Write-Output "Using cached Vagrant download: $($VagrantRevision)"
    }

    # Set the full path to where Vagrant is
    $VagrantSourceDir = "$($VagrantTmpDir)\vagrant-$($VagrantRevision)"

    # Build gem
    If ($UseCache -eq $false) {
        Write-Output "Building Vagrant Gem"
        Push-Location $VagrantSourceDir
        & "$($SubstrateDir)\embedded\mingw$($PackageArch)\bin\ruby.exe" "$($SubstrateDir)\embedded\mingw$($PackageArch)\bin\gem" build vagrant.gemspec
        if(!$?) {
            Write-Error "Failed to build Vagrant RubyGem"
        }
        Copy-Item vagrant-*.gem -Destination vagrant.gem
        Pop-Location
    } Else {
        Write-Output "Using cached build of Vagrant Gem"
    }
} else {
    Copy-Item "$($Dir)\vagrant.gem" -Destination "$($VagrantSourceDir)\vagrant.gem"
    Push-Location $VagrantSourceDir
    & "$($SubstrateDir)\embedded\mingw$($PackageArch)\bin\ruby.exe" "$($SubstrateDir)\embedded\mingw$($PackageArch)\bin\gem" unpack vagrant.gem
    if(!$?) {
        Write-Error "Failed to unpack Vagrant RubyGem"
    }
    Copy-Item ".\vagrant\version.txt" -Destination ".\version.txt"
    Remove-Item -Recurse -Force ".\vagrant"
    Pop-Location
}

# Determine the version
$VagrantVersionFile = Join-Path $VagrantSourceDir version.txt
if (-Not (Test-Path $VagrantVersionFile)) {
    "0.1.0" | Out-File -FilePath $VagrantVersionFile
}
$VagrantVersion=$((Get-Content $VagrantVersionFile) -creplace '\.[^0-9]+(\.[0-9]+)?$', '$1')
Write-Output "Vagrant version: $VagrantVersion"

if ($PackageArch -eq "64") {
    $MingArchDir = "x86_64-w64-mingw32"
} else {
    $MingArchDir = "i686-w64-mingw32"
}

if ($UseCache -eq $false) {
    # Install gem. We do this in a sub-shell so we don't have to worry
    # about restoring environmental variables.
    $env:PackageArch      = $PackageArch
    $env:MingArchDir      = $MingArchDir
    $env:SubstrateDir     = $SubstrateDir
    $env:VagrantSourceDir = $VagrantSourceDir
    $env:VagrantVersion   = $VagrantVersion
    powershell {
        Set-Location $env:VagrantSourceDir
        $EmbeddedDir  = "$($env:SubstrateDir)\embedded"
        $PackageArch  = $env:PackageArch
        $MingArchDir  = $env:MingArchDir
        $env:GEM_PATH = "$($EmbeddedDir)\gems\$($env:VagrantVersion)"
        $env:GEM_HOME = $env:GEM_PATH
        $env:GEMRC    = "$($EmbeddedDir)\etc\gemrc"
        $env:CPPFLAGS = "-I/mingw$($PackageArch)/$($MingArchDir)/include -I/mingw$($PackageArch)/include -I/usr/include"
        $env:CFLAGS = "-I/mingw$($PackageArch)/$($MingArchDir)/include -I/mingw$($PackageArch)/include -I/usr/include"
        $env:LDFLAGS  = "-L/mingw$($PackageArch)/lib -L/mingw$($PackageArch)/$($MingArchDir)/lib -L/usr/lib"
        $env:PKG_CONFIG_PATH = "/mingw$($PackageArch)/lib/pkgconfig:/usr/lib/pkgconfig"
        $env:Path     ="$($EmbeddedDir)\mingw$($PackageArch)\bin;$($EmbeddedDir)\bin;$($EmbeddedDir)\usr\bin;$($env:Path)"
        $env:SSL_CERT_FILE = "$($EmbeddedDir)\cacert.pem"
        & "$($EmbeddedDir)\mingw$($PackageArch)\bin\ruby.exe" "$($EmbeddedDir)\mingw$($PackageArch)\bin\gem" install vagrant.gem --no-document

        if(!$?) {
            Write-Error "Failed to install Vagrant RubyGem into packaging substrate"
        }

        $BundleDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
        [System.IO.Directory]::CreateDirectory($BundleDir) | Out-Null

        Push-Location "${env:GEM_PATH}\gems\bcrypt_pbkdf-*"
        Remove-Item "bcrypt_pbkdf.gemspec"
        Copy-Item "..\..\specifications\bcrypt_pbkdf*.gemspec" ".\bcrypt_pbkdf.gemspec"
        &"${EmbeddedDir}\mingw${PackageArch}\bin\bundle.cmd" config set --local path "${BundleDir}"
        &"${EmbeddedDir}\mingw${PackageArch}\bin\bundle.cmd" install
        &"${EmbeddedDir}\mingw${PackageArch}\bin\bundle.cmd" exec rake compile

        Remove-Item "${BundleDir}" -Force -Recurse
        Pop-Location
    }
    if(!$?) {
        Write-Error "Vagrant packaging into substrate failed"
    }
    Remove-Item Env:SubstrateDir
    Remove-Item Env:VagrantSourceDir
} Else {
    Write-Output "Using cached installation of Vagrant Gem"
}

#--------------------------------------------------------------------
# System Plugins
#--------------------------------------------------------------------
$contents = @"
{
    "version": "1",
    "installed": {
    }
}
"@
$contents | Out-File `
  -Encoding ASCII `
  -FilePath "$($SubstrateDir)\embedded\plugins.json"

#--------------------------------------------------------------------
# Manifest File
#--------------------------------------------------------------------
$contents = @"
{
    "vagrant_version": "$VagrantVersion"
}
"@
$contents | Out-File `
  -Encoding ASCII `
  -FilePath "$($SubstrateDir)\embedded\manifest.json"

#--------------------------------------------------------------------
# MSI
#--------------------------------------------------------------------
# Final path to output
if ( $PackageArch -eq "64") {
    $OutputPath = "vagrant_$($VagrantVersion)_x86_64.msi"
} else {
    $OutputPath = "vagrant_$($VagrantVersion)_i686.msi"
}

$InstallerTmpDir = [System.IO.Path]::GetTempPath()
$InstallerTmpDir = [System.IO.Path]::Combine(
    $InstallerTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($InstallerTmpDir) | Out-Null
[System.IO.Directory]::CreateDirectory("$($InstallerTmpDir)\assets") | Out-Null
Write-Output "Installer temp dir: $($InstallerTmpDir)"

Copy-Item "$($Dir)\support\windows\bg_banner.bmp" `
  -Destination "$($InstallerTmpDir)\assets\bg_banner.bmp"
Copy-Item "$($Dir)\support\windows\bg_dialog.bmp" `
  -Destination "$($InstallerTmpDir)\assets\bg_dialog.bmp"
Copy-Item "$($Dir)\support\windows\license.rtf" `
  -Destination "$($InstallerTmpDir)\assets\license.rtf"
Copy-Item "$($Dir)\support\windows\burn_logo.bmp" `
  -Destination "$($InstallerTmpDir)\assets\burn_logo.bmp"
Copy-Item "$($Dir)\support\windows\vagrant.ico" `
  -Destination "$($InstallerTmpDir)\assets\vagrant.ico"
Copy-Item "$($Dir)\support\windows\vagrant-en-us.wxl" `
  -Destination "$($InstallerTmpDir)\vagrant-en-us.wxl"

$contents = @"
<?xml version="1.0" encoding="utf-8"?>
<Include>
<?define VersionNumber="$($VagrantVersion)" ?>
<?define DisplayVersionNumber="$($VagrantVersion)" ?>

<!--
Upgrade code must be unique per version installer.
This is used to determine uninstall/reinstall cases.
-->
<?define UpgradeCode="$($UpgradeCode)" ?>
</Include>
"@

$contents | Out-File `
  -Encoding ASCII `
  -FilePath "$($InstallerTmpDir)\vagrant-config.wxi"

$contents = @"
<?xml version="1.0"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi" xmlns:util="http://schemas.microsoft.com/wix/UtilExtension">
<!-- Include our wxi -->
<?include "$($InstallerTmpDir)\vagrant-config.wxi" ?>

<!-- The main product -->
<Product Id="*"
Language="!(loc.LANG)"
Name="!(loc.ProductName)"
Version="`$(var.VersionNumber)"
Manufacturer="!(loc.ManufacturerName)"
UpgradeCode="`$(var.UpgradeCode)">

<!-- Define the package information -->
<Package Compressed="yes"
InstallerVersion="200"
InstallPrivileges="elevated"
InstallScope="perMachine"
Manufacturer="!(loc.ManufacturerName)" />

<!-- Disallow installing older versions until the new version is removed -->
<!-- Note that this creates the RemoveExistingProducts action -->
<MajorUpgrade DowngradeErrorMessage="A later version of Vagrant is installed. Please remove this version first. Setup will now exit."
Schedule="afterInstallInitialize" />

<!-- The source media for the installer -->
<Media Id="1"
Cabinet="Vagrant.cab"
CompressionLevel="high"
EmbedCab="yes" />

<!-- Require Windows NT Kernel -->
<Condition Message="This application is only supported on Windows 2000 or higher.">
<![CDATA[Installed or (VersionNT >= 500)]]>
</Condition>

<!-- Some steps for our installation -->
<InstallExecuteSequence>
<ScheduleReboot After="InstallFinalize"/>
</InstallExecuteSequence>

<!-- Include application icon for add/remove programs -->
<Icon Id="icon.ico" SourceFile="$($InstallerTmpDir)\assets\vagrant.ico" />
<Property Id="ARPPRODUCTICON" Value="icon.ico" />
<Property Id="ARPHELPLINK" Value="https://www.vagrantup.com" />

<!-- Get the proper system directory -->
<SetDirectory Id="WINDOWSVOLUME" Value="[WindowsVolume]" />

<PropertyRef Id="WIX_ACCOUNT_USERS" />
<PropertyRef Id="WIX_ACCOUNT_ADMINISTRATORS" />

<!-- The directory where we'll install Vagrant -->
    <Directory Id="TARGETDIR" Name="SourceDir">
    <Directory Id="WINDOWSVOLUME">
    <Directory Id="MANUFACTURERDIR" Name="HashiCorp">
    <Directory Id="INSTALLDIR" Name="Vagrant">
    <Component Id="VagrantBin"
    Guid="{12a01bfc-ae9e-4543-8a32-47865cc03071}">
    <!--
    Add our bin dir to the PATH so people can use
    vagrant right away in the shell.
    -->
    <Environment Id="Environment"
    Name="PATH"
    Action="set"
    Part="last"
    System="yes"
    Value="[INSTALLDIR]bin" />

    <!-- Because we are not in "Program Files" we inherit
    permissions that are not desirable. Force new permissions -->
    <CreateFolder>
    <Permission GenericAll="yes" User="[WIX_ACCOUNT_ADMINISTRATORS]" />
    <Permission GenericRead="yes" GenericExecute="yes" User="[WIX_ACCOUNT_USERS]" />
    </CreateFolder>
    </Component>
    </Directory>
    </Directory>
    </Directory>
    </Directory>

    <!-- Define the features of our install -->
    <Feature Id="VagrantFeature"
    Title="!(loc.ProductName)"
    Level="1">
    <ComponentGroupRef Id="VagrantDir" />
    <ComponentRef Id="VagrantBin" />
    </Feature>

    <!-- WixUI configuration so we can have a UI -->
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLDIR" />

    <UIRef Id="VagrantUI_InstallDir" />
    <UI Id="VagrantUI_InstallDir">
    <UIRef Id="WixUI_InstallDir" />
    </UI>

    <WixVariable Id="WixUILicenseRtf" Value="$($InstallerTmpDir)\assets\license.rtf" />
    <WixVariable Id="WixUIDialogBmp" Value="$($InstallerTmpDir)\assets\bg_dialog.bmp" />
    <WixVariable Id="WixUIBannerBmp" Value="$($InstallerTmpDir)\assets\bg_banner.bmp" />
    </Product>
    </Wix>
"@

$contents | Out-File `
  -Encoding ASCII `
  -FilePath "$($InstallerTmpDir)\vagrant-main.wxs"

Write-Output "Running heat.exe"
&$WixHeat dir $SubstrateDir `
  -nologo `
  -ke `
  -sreg `
  -srd `
  -gg `
  -cg VagrantDir `
  -dr INSTALLDIR `
  -var 'var.VagrantSourceDir' `
  -out "$($InstallerTmpDir)\vagrant-files.wxs"

if(!$?) {
    Write-Output "Error: Failed running heat.exe"
    exit 1
}

Write-Output "Running candle.exe"
$CandleArgs = @(
    "-nologo",
    "-I$($InstallerTmpDir)",
    "-dVagrantSourceDir=$($SubstrateDir)",
    "-out $InstallerTmpDir\",
    "$($InstallerTmpDir)\vagrant-files.wxs",
    "$($InstallerTmpDir)\vagrant-main.wxs"
)
Start-Process -NoNewWindow -Wait `
  -ArgumentList $CandleArgs -FilePath $WixCandle

if(!$?) {
    Write-Output "Error: Failed running candle.exe"
    exit 1
}

Write-Output "Running light.exe"
&$WixLight `
  -nologo `
  -ext WixUIExtension `
  -ext WixUtilExtension `
  -spdb `
  -v `
  -cultures:en-us `
  -loc "$($InstallerTmpDir)\vagrant-en-us.wxl" `
  -out $OutputPath `
  "$($InstallerTmpDir)\vagrant-files.wixobj" `
  "$($InstallerTmpDir)\vagrant-main.wixobj"

if(!$?) {
    Write-Output "Error: Failed running light.exe"
    exit 1
}

#--------------------------------------------------------------------
# Sign
#--------------------------------------------------------------------
if ($SignKey) {
    $SignTool = "signtool.exe"
    if ($SignPath) {
        $SignTool = $SignPath
    }

    & $SignTool sign `
      /d Vagrant `
      /t http://timestamp.digicert.com `
      /f $SignKey `
      /p $SignKeyPassword `
      $OutputPath

    if(!$?) {
        Write-Output "Error: Failed to sign package"
        exit 1
    }
} else {
    if ($SignRequired -eq "1") {
        Write-Output "Error: Package signing is required but package is not signed"
        exit 1
    }
    Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    Write-Output "!      This package is unsigned        !"
    Write-Output "! Rebuild with signing key for release !"
    Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

Copy-Item $OutputPath -Destination "$($InstallerTmpDir)\vagrant.msi"

Remove-Item -Recurse -Force $InstallerTmpDir

If ($BuildStyle -eq "ephemeral") {
    Remove-Item -Recurse -Force $SubstrateTmpDir
    Remove-Item -Recurse -Force $VagrantTmpDir
}

Write-Output "Installer MSI at: $($OutputPath)"
