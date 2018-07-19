<#
.SYNOPSIS
    Creates a Vagrant installer.

.PARAMETER OutputDir
    The directory to put the outputted substrate package.
#>
Param(
    [parameter(Mandatory=$true)]
    [string] $OutputDir,
    [parameter(Mandatory=$false)]
    [string] $SignKeyFile=$null,
    [parameter(Mandatory=$false)]
    [string] $SignKeyPassword=$null
)

$ErrorActionPreference = "Stop"

# This is a replacement for Start-Process since it is unable to properly
# collect the ExitCode from a process once it has completed when the
# -PassThru option is used.
function Create-Process {
    param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $ExePath,
        [parameter(Mandatory=$false, Position=1)]
        [string] $Arguments,
        [parameter(Mandatory=$false, Position=2)]
        [string] $Cwd
    )
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $ExePath
    $info.RedirectStandardError = $false
    $info.RedirectStandardOutput = $false
    $info.UseShellExecute = $false
    if($Cwd) {
        $info.WorkingDirectory = $Cwd
    }
    $info.Arguments = $Arguments

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    $process.Start() | Out-Null
    return $process
}

Write-Host "Starting substrate build"

# Create required directories

Write-Output "Creating required directories for build..."

$BuildDir   = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
$CacheDir   = [System.IO.Path]::Combine($BuildDir, "cache")
$StageDir   = [System.IO.Path]::Combine($BuildDir, "staging")
$Stage32Dir = [System.IO.Path]::Combine($StageDir, "x32")
$Stage64Dir = [System.IO.Path]::Combine($StageDir, "x64")
$Embed32Dir = [System.IO.Path]::Combine($Stage32Dir, "embedded")
$Embed64Dir = [System.IO.Path]::Combine($Stage64Dir, "embedded")
$PackageDir = [System.IO.Path]::Combine($CacheDir, "packages")

[System.IO.Directory]::CreateDirectory($CacheDir) | Out-Null
[System.IO.Directory]::CreateDirectory($Embed32Dir) | Out-Null
[System.IO.Directory]::CreateDirectory($Embed64Dir) | Out-Null
[System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
[System.IO.Directory]::CreateDirectory($PackageDir) | Out-Null

# Define the important paths

$RubyDepsPath           = [System.IO.Path]::Combine($CacheDir, "ruby_dependencies.sh")
$RubyBuilderPath        = [System.IO.Path]::Combine($CacheDir, "ruby_builder.sh")
$SubstrateDepsPath      = [System.IO.Path]::Combine($CacheDir, "substrate_dependencies.sh")
$SubstrateBuilderPath   = [System.IO.Path]::Combine($CacheDir, "substrate_builder.sh")
$SubstrateBuilderDir    = "C:\msys64\home\vagrant\styrene"
$BuilderConfig          = [System.IO.Path]::Combine($SubstrateBuilderDir, "vagrant.cfg")
$LauncherDir            = [System.IO.Path]::Combine($CacheDir, "launcher")

# Copy files into correct locations
Write-Output "Copying in required file assets..."

Copy-Item "C:\vagrant\substrate\windows\*" -Destination "$($CacheDir)" -Recurse
Copy-Item "C:\vagrant\substrate\modules\vagrant_substrate\files\launcher" -Destination "$($CacheDir)\launcher" -Recurse

# Start the Ruby build
Write-Output "Starting Ruby build..."

Push-Location "$($CacheDir)"

$OriginalPath = $env:PATH

$env:PATH = "$($PATH);C:\msys64\usr\bin"
$env:MSYSTEM = "MINGW64"

$DepProc = Create-Process bash.exe "--login -f '$($RubyDepsPath)'" "$($CacheDir)"
$DepProc.WaitForExit()

if($DepProc.ExitCode -ne 0) {
    Write-Error "Failed to install ruby build dependencies! - $($DepProc.ExitCode)"
}

$RubyProc32 = Create-Process bash.exe "--login -f '$($RubyBuilderPath)' mingw32" "$($CacheDir)"
$RubyProc64 = Create-Process bash.exe "--login -f '$($RubyBuilderPath)' mingw64" "$($CacheDir)"
$RubyProc32.WaitForExit()
$RubyProc64.WaitForExit()

if($RubyProc32.ExitCode -ne 0) {
    Write-Error "Ruby 32 bit build has failed!"
}
if($RubyProc64.ExitCode -ne 0) {
    Write-Error "Ruby 64 bit build has failed!"
}

# Relocate packages
Copy-Item .\ruby-build-*\*.xz -Destination "$($PackageDir)\"

Pop-Location

# Start the substrate build
Write-Output "Starting substrate build..."

Push-Location "$($CacheDir)"

$env:MSYSTEM = "MSYS"
$SubstrateDepProc = Create-Process bash.exe "--login -f '$($SubstrateDepsPath)'" -Cwd "$($CacheDir)"
$SubstrateDepProc.WaitForExit()

Copy-Item "$($CacheDir)\vagrant.cfg" -Destination "$($SubstrateBuilderDir)\vagrant.cfg"

$SubstrateProc = Create-Process bash.exe "--login -f '$($SubstrateBuilderPath)' '$($PackageDir)' '$($Stage32Dir)' '$($Stage64Dir)'" "$($SubstrateBuilderDir)"
$SubstrateProc.WaitForExit()

if($SubstrateProc.ExitCode -ne 0) {
    Write-Error "Substrate build has failed!"
}

Pop-Location

# Build the launcher
Write-Output "Building vagrant launcher..."

$env:GOPATH = "C:\Windows\Temp"
$env:PATH = "C:\Go\bin;C:\Program Files\Git\bin;$($OriginalPath)"

$LauncherDepProc = Create-Process go.exe "get github.com/mitchellh/osext"
$LauncherDepProc.WaitForExit()

if($LauncherDepProc.ExitCode -ne 0) {
    Write-Error "Failed to install launcher dependency: osext"
}

Push-Location "$($LauncherDir)"

$Stage32Bin = [System.IO.Path]::Combine($Stage32Dir, "bin")
$Stage64Bin = [System.IO.Path]::Combine($Stage64Dir, "bin")

[System.IO.Directory]::CreateDirectory($Stage32Bin) | Out-Null
[System.IO.Directory]::CreateDirectory($Stage64Bin) | Out-Null

$LauncherProc = Create-Process go.exe "build -o $($Stage64Bin)\vagrant.exe main.go" "$($LauncherDir)"
$LauncherProc.WaitForExit()

if($LauncherProc.ExitCode -ne 0) {
    Write-Error "Failed to build vagrant 64-bit launcher!"
}

$env:GOARCH = "386"
$LauncherProc = Create-Process go.exe "build -o $($Stage32Bin)\vagrant.exe main.go" "$($LauncherDir)"
$LauncherProc.WaitForExit()

if($LauncherProc.ExitCode -ne 0) {
    Write-Error "Failed to build vagrant 32-bit launcher!"
}

Pop-Location

Write-Output "Installing gemrc file..."
Copy-Item "$($CacheDir)\gemrc" -Destination "$($Stage32Dir)\embedded\etc\gemrc"
Copy-Item "$($CacheDir)\gemrc" -Destination "$($Stage64Dir)\embedded\etc\gemrc"

Write-Output "Install rgloader files..."
$Rgloader32Dir = [System.IO.Path]::Combine($Embed32Dir, "rgloader")
$Rgloader64Dir = [System.IO.Path]::Combine($Embed64Dir, "rgloader")

[System.IO.Directory]::CreateDirectory($Rgloader32Dir) | Out-Null
[System.IO.Directory]::CreateDirectory($Rgloader64Dir) | Out-Null

Copy-Item "$($CacheDir)\*loader*" -Destination "$($Rgloader32Dir)"
Copy-Item "$($CacheDir)\*loader*" -Destination "$($Rgloader64Dir)"

if($SignKeyFile -and !$SignKeyPassword) {
    Write-Warning "SignKey path provided but no SignKeyPassword given. Embedded binaries will be unsigned!"
} elseif(!$SignKeyFile -and $SignKeyPassword) {
    Write-Warning "SignKeyPassword provided but no SignKey path given. Embedded binaries will be unsigned!"
} elseif(!$SignKeyFile -and !$SignKeyPassword) {
    Write-Warning "SignKey and SignKeyPassword not given. Embedded binaries will be unsigned!"
} else {
    Write-Output "Signing embedded binaries..."
    $binaries = Get-ChildItem "$($StageDir)" -Filter *.exe -Recurse
    foreach($binary in $binaries) {
        $SignProc = Create-Process signtool.exe "sign /t http://timestamp.digicert.com /f $SignKeyFile /p $SignKeyPassword $($binary.FullName)"
        $SignProc.WaitForExit()
        if($SignProc.ExitCode -ne 0) {
            Write-Error "Failed to sign embedded binary @ $($binary.FullName)"
        }
    }
}

Write-Output "Compressing substrate assets..."
$Asset32Path = [System.IO.Path]::Combine($OutputDir, "substrate_windows_i686.zip")
$Asset64Path = [System.IO.Path]::Combine($OutputDir, "substrate_windows_x86_64.zip")

$Asset32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "a -r $($Asset32Path) $($Stage32Dir)\*"
$Asset64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "a -r $($Asset64Path) $($Stage64Dir)\*"

$Asset32Proc.WaitForExit()
$Asset64Proc.WaitForExit()

if($Asset32Proc.ExitCode -ne 0) {
    Write-Error "Failed to compress 32-bit substrate asset!"
}
if($Asset64Proc.ExitCode -ne 0) {
    Write-Error "Failed to compress 64-bit substrate asset!"
}

Write-Output "Cleaning up build files..."
Remove-Item "$($BuildDir)" -Force -Recurse

Write-Output "Substrate build complete."
Write-Output "  -> $($Asset32Path)"
Write-Output "  -> $($Asset64Path)"
