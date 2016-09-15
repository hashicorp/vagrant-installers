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

    [string]$VagrantSourceBaseURL="https://github.com/mitchellh/vagrant/archive/",

    [string]$SignKey="",
    [string]$SignKeyPassword="",
    [string]$SignPath="",

    [string]$BuildStyle="ephemeral",
    [string]$ScrubCache="no"
)

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
  Write-Host "Error: BuildStyle must be either 'ephemeral' or 'cached'"
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

Write-Host "Substrate temp dir: $($SubstrateTmpDir)"

# Unzip
If ($UseCache -eq $false) {
  Write-Host "Expanding substrate..."
  Expand-ZipFile -file $SubstratePath -destination $SubstrateTmpDir
} Else {
  Write-Host "Using cached substrate"
}

# Set the full path to the substrate
$SubstrateDir = "$($SubstrateTmpDir)"

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
    $VagrantTmpDir, "vagrant-$($VagrantRevision)")
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

Write-Host "Vagrant temp dir: $($VagrantTmpDir)"

$VagrantSourceURL = "$($VagrantSourceBaseURL)/$($VagrantRevision).zip"
$VagrantDest      = "$($VagrantTmpDir)\vagrant.zip"

# Download
If ($UseCache -eq $false) {
  Write-Host "Downloading Vagrant: $($VagrantRevision)"
  $client = New-Object System.Net.WebClient
  $client.DownloadFile($VagrantSourceURL, $VagrantDest)

  # Unzip
  Write-Host "Unzipping Vagrant"
  Expand-ZipFile -file $VagrantDest -destination $VagrantTmpDir
} Else {
  Write-Host "Using cached Vagrant download: $($VagrantRevision)"
}

# Set the full path to where Vagrant is
$VagrantSourceDir = "$($VagrantTmpDir)\vagrant-$($VagrantRevision)"

# Build gem
If ($UseCache -eq $false) {
  Write-Host "Building Vagrant Gem"
  Push-Location $VagrantSourceDir
  &"$($SubstrateDir)\embedded\bin\gem.bat" build vagrant.gemspec
  Copy-Item vagrant-*.gem -Destination vagrant.gem
  Pop-Location
} Else {
  Write-Host "Using cached build of Vagrant Gem"
}

# Determine the version
$VagrantVersionFile = Join-Path $VagrantSourceDir version.txt
if (-Not (Test-Path $VagrantVersionFile)) {
    "0.1.0" | Out-File -FilePath $VagrantVersionFile
}
$VagrantVersion=$((Get-Content $VagrantVersionFile) -creplace '\.[^0-9]+(\.[0-9]+)?$', '$1')
Write-Host "Vagrant version: $VagrantVersion"

if ($UseCache -eq $false) {
  # Install gem. We do this in a sub-shell so we don't have to worry
  # about restoring environmental variables.
  $env:SubstrateDir     = $SubstrateDir
  $env:VagrantSourceDir = $VagrantSourceDir
  powershell {
      $ErrorActionPreference = "Stop"

      Set-Location $env:VagrantSourceDir
      $EmbeddedDir  = "$($env:SubstrateDir)\embedded"
      $env:GEM_PATH = "$($EmbeddedDir)\gems"
      $env:GEM_HOME = $env:GEM_PATH
      $env:GEMRC    = "$($EmbeddedDir)\etc\gemrc"
      $env:CPPFLAGS = "-I$($EmbeddedDir)\include"
      $env:LDFLAGS  = "-L$($EmbeddedDir)\lib"
      $env:Path     ="$($EmbeddedDir)\bin;$($env:Path)"
      $env:SSL_CERT_FILE = "$($EmbeddedDir)\cacert.pem"
      &"$($EmbeddedDir)\bin\gem.bat" install vagrant.gem --no-ri --no-rdoc

      # Extensions
      &"$($EmbeddedDir)\bin\gem.bat" install vagrant-share --no-ri --no-rdoc --source "http://gems.hashicorp.com"
  }
  Remove-Item Env:SubstrateDir
  Remove-Item Env:VagrantSourceDir
} Else {
  Write-Host "Using cached installation of Vagrant Gem"
}

#--------------------------------------------------------------------
# System Plugins
#--------------------------------------------------------------------
$contents = @"
{
    "version": "1",
    "installed": {
        "vagrant-share": {
            "ruby_version": "0",
            "vagrant_version": "$($VagrantVersion)"
        }
    }
}
"@
$contents | Out-File `
    -Encoding ASCII `
    -FilePath "$($SubstrateDir)\embedded\plugins.json"

#-------------------------------------------------------------------
# Patch version info into bsdtar.exe and bsdcpio.exe with verpatch.exe
# Fix for vagrant issue #3674, MSI Upgrade 1.5 -> 1.6
#--------------------------------------------------------------------
# Download verpatch from http://ddverpatch.codeplex.com/
<#
$verpatchSourceURL = "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=ddverpatch&DownloadId=713811&FileTime=130201209882270000&Build=20907"
$verpatchDest = "$($VagrantTmpDir)\verpatch.zip"

Write-Host "Downloading verpatch 1.0.14"
(New-Object System.Net.WebClient).DownloadFile($verpatchSourceURL, $verpatchDest)

Write-Host "Unzipping verpatch"
Expand-ZipFile -file $verpatchDest -destination $VagrantTmpDir

$verpatch = "$($VagrantTmpDir)\verpatch.exe"

$bsdtar = "$($SubstrateDir)\embedded\gnuwin32\bin\bsdtar.exe"
$bsdcpio = "$($SubstrateDir)\embedded\gnuwin32\bin\bsdcpio.exe"

$version = & $bsdtar --version
$version -match '([\d.]+)'
$bsdversion = "$($matches[0]).0"

Write-Host "Patching version $bsdversion into $bsdtar"
& $verpatch $bsdtar /va $bsdversion /pv $bsdversion

Write-Host "Patching version $bsdversion into $bsdcpio"
& $verpatch $bsdcpio /va $bsdversion /pv $bsdversion

Write-Host "Done"
#>

#--------------------------------------------------------------------
# MSI
#--------------------------------------------------------------------
# Final path to output
$OutputPath = "vagrant_$($VagrantVersion).msi"

$InstallerTmpDir = [System.IO.Path]::GetTempPath()
$InstallerTmpDir = [System.IO.Path]::Combine(
    $InstallerTmpDir, [System.IO.Path]::GetRandomFileName())
[System.IO.Directory]::CreateDirectory($InstallerTmpDir) | Out-Null
[System.IO.Directory]::CreateDirectory("$($InstallerTmpDir)\assets") | Out-Null
Write-Host "Installer temp dir: $($InstallerTmpDir)"

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

# Download the C++ Runtime Redistributable package
$vcredistSourceURL = "https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe"
$vcredistDest = "$($VagrantTmpDir)\vcredist_x86.exe"

If ($UseCache -eq $false) {
  Write-Host "Downloading C++ Runtime Redistributable"
  (New-Object System.Net.WebClient).DownloadFile($vcredistSourceURL, $vcredistDest)
}

# Move runtime redistributable into our package
Copy-Item "$($vcredistDest)" -Destination "$($InstallerTmpDir)\vcredist_x86.exe"

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
       <ScheduleReboot After="InstallFinalize"><![CDATA[UILevel <> 2]]></ScheduleReboot>
     </InstallExecuteSequence>

     <!-- Include application icon for add/remove programs -->
     <Icon Id="icon.ico" SourceFile="$($InstallerTmpDir)\assets\vagrant.ico" />
     <Property Id="ARPPRODUCTICON" Value="icon.ico" />

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

Write-Host "Running heat.exe"
&$WixHeat dir $SubstrateDir `
    -nologo `
    -srd `
    -gg `
    -cg VagrantDir `
    -dr INSTALLDIR `
    -var 'var.VagrantSourceDir' `
    -out "$($InstallerTmpDir)\vagrant-files.wxs"

Write-Host "Running candle.exe"
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

Write-Host "Running light.exe"
&$WixLight `
    -nologo `
    -ext WixUIExtension `
    -ext WixUtilExtension `
    -spdb `
    -cultures:en-us `
    -loc "$($InstallerTmpDir)\vagrant-en-us.wxl" `
    -out $OutputPath `
    "$($InstallerTmpDir)\vagrant-files.wixobj" `
    "$($InstallerTmpDir)\vagrant-main.wixobj"

#--------------------------------------------------------------------
# Sign
#--------------------------------------------------------------------
if ($SignKey) {
    $SignTool = "signtool.exe"
    if ($SignPath) {
        $SignTool = $SignPath
    }

    &$SignTool sign `
        /t http://timestamp.digicert.com `
        /f $SignKey `
        /p $SignKeyPassword `
        $OutputPath
}

$BundleOutputPath = "vagrant_$($VagrantVersion).exe"

Copy-Item $OutputPath -Destination "$($InstallerTmpDir)\vagrant.msi"

$contents = @"
<?xml version="1.0"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"
  xmlns:bal="http://schemas.microsoft.com/wix/BalExtension"
  xmlns:util="http://schemas.microsoft.com/wix/UtilExtension">
    <Bundle Version="1.8.6" UpgradeCode="a48b8e2d-87a9-4655-8951-41c8a1b254eb">
        <BootstrapperApplicationRef Id="WixStandardBootstrapperApplication.RtfLicense">
            <bal:WixStandardBootstrapperApplication
                LicenseFile="$($InstallerTmpDir)\assets\license.rtf"
                LogoFile="$($InstallerTmpDir)\assets\burn_logo.bmp" />
        </BootstrapperApplicationRef>
        <Variable Name="InstallFolder" Type="string" Value="[WindowsVolume]HashiCorp\Vagrant" bal:Overridable="yes" />
        <util:RegistrySearch Root="HKLM" Key="SOFTWARE\Microsoft\DevDiv\VC\Servicing\9.0\RED\1033" Value="SP" Variable="vcredist" />
        <Chain>
          <ExePackage
            SourceFile="$($InstallerTmpDir)\vcredist_x86.exe"
            InstallCommand="/quiet"
            PerMachine="yes"
            Permanent="yes"
            DetectCondition="vcredist AND (vcredist >= 1)" />
          <RollbackBoundary />
          <MsiPackage SourceFile="$($InstallerTmpDir)\vagrant.msi" Compressed="yes" Vital="yes" Visible="yes">
            <MsiProperty Name="INSTALLDIR" Value="[InstallFolder]" />
          </MsiPackage>
        </Chain>
    </Bundle>
</Wix>
"@
$contents | Out-File `
    -Encoding ASCII `
    -FilePath "$($InstallerTmpDir)\vagrant-bundle.wxs"

Write-Host "Running bundle candle.exe"
$CandleArgs = @(
    "-nologo",
    "-ext WixBalExtension",
    "-ext WixUtilExtension",
    "-I$($InstallerTmpDir)",
    "-out $InstallerTmpDir\",
    "$($InstallerTmpDir)\vagrant-bundle.wxs"
)
Start-Process -NoNewWindow -Wait `
    -ArgumentList $CandleArgs -FilePath $WixCandle

Write-Host "Running bundle light.exe"
&$WixLight `
    -nologo `
    -ext WixBalExtension `
    -ext WixUtilExtension `
    -spdb `
    -cultures:en-us `
    -loc "$($InstallerTmpDir)\vagrant-en-us.wxl" `
    -out $BundleOutputPath `
    "$($InstallerTmpDir)\vagrant-bundle.wixobj"

#--------------------------------------------------------------------
# Sign
#--------------------------------------------------------------------
if ($SignKey) {
    $SignTool = "signtool.exe"
    if ($SignPath) {
        $SignTool = $SignPath
    }

    &$SignTool sign `
        /t http://timestamp.digicert.com `
        /f $SignKey `
        /p $SignKeyPassword `
        $BundleOutputPath
}

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------
Remove-Item -Recurse -Force $InstallerTmpDir

If ($BuildStyle -eq "ephemeral") {
  Remove-Item -Recurse -Force $SubstrateTmpDir
  Remove-Item -Recurse -Force $VagrantTmpDir
}

Write-Host "Installer MSI at: $($OutputPath)"
Write-Host "Installer bundled EXE at: $($BundleOutputPath)"
