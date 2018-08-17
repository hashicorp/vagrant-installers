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

$CurlVersion = "7.61.0"
$Libssh2Version = "1.8.0"
$ZlibVersion = "1.2.11"

$CurlVersionUnderscore = ($CurlVersion -Replace "\.", "_")
$CurlRemoteFilename = "curl-${CurlVersion}.zip"

$ZlibURL = "https://github.com/madler/zlib/archive/v${ZlibVersion}.zip"
$CurlURL = "https://github.com/curl/curl/releases/download/curl-${CurlVersionUnderscore}/${CurlRemoteFilename}"
$Libssh2URL = "https://github.com/libssh2/libssh2/archive/libssh2-${Libssh2Version}.zip"

# Allow HTTPS connections to work
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

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
[System.IO.Directory]::CreateDirectory($LauncherDir) | Out-Null
Copy-Item "C:\vagrant\substrate\launcher\*" -Destination $LauncherDir -Recurse

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
Copy-Item "C:\vagrant\substrate\common\gemrc" -Destination "$($Stage32Dir)\embedded\etc\gemrc"
Copy-Item "C:\vagrant\substrate\common\gemrc" -Destination "$($Stage64Dir)\embedded\etc\gemrc"

Write-Output "Install rgloader files..."
$Rgloader32Dir = [System.IO.Path]::Combine($Embed32Dir, "rgloader")
$Rgloader64Dir = [System.IO.Path]::Combine($Embed64Dir, "rgloader")

[System.IO.Directory]::CreateDirectory($Rgloader32Dir) | Out-Null
[System.IO.Directory]::CreateDirectory($Rgloader64Dir) | Out-Null

Copy-Item "C:\vagrant\substrate\common\rgloader\*" -Destination "$($Rgloader32Dir)"
Copy-Item "C:\vagrant\substrate\common\rgloader\*" -Destination "$($Rgloader64Dir)"
Copy-Item "C:\vagrant\substrate\windows\rgloader\*" -Destination "$($Rgloader32Dir)"
Copy-Item "C:\vagrant\substrate\windows\rgloader\*" -Destination "$($Rgloader64Dir)"

Write-Output "Preparing native curl build..."

$CurlBuildDir32 = [System.IO.Path]::Combine($CacheDir, "curl32")
$CurlBuildDir64 = [System.IO.Path]::Combine($CacheDir, "curl64")
[System.IO.Directory]::CreateDirectory($CurlBuildDir32) | Out-Null
[System.IO.Directory]::CreateDirectory($CurlBuildDir64) | Out-Null

Write-Output "Downloading curl..."
$CurlAsset = [System.IO.Path]::Combine($CacheDir, "curl.zip")
(New-Object System.Net.WebClient).DownloadFile("${CurlURL}", "${CurlAsset}")

Write-Output "Unpacking curl..."
$CurlUnpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${CurlAsset} -y" "${CurlBuildDir32}"
$CurlUnpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${CurlAsset} -y" "${CurlBuildDir64}"
$CurlUnpack32Proc.WaitForExit()
$CurlUnpack64Proc.WaitForExit()

Move-Item "${CurlBuildDir32}\curl-*\*" "${CurlBuildDir32}\"
Move-Item "${CurlBuildDir64}\curl-*\*" "${CurlBuildDir64}\"

Write-Output "Installing curl dependency zlib..."
$ZlibDir32 = [System.IO.Path]::Combine($CacheDir, "zlib32")
$ZlibDir64 = [System.IO.Path]::Combine($CacheDir, "zlib64")
[System.IO.Directory]::CreateDirectory($ZlibDir32)
[System.IO.Directory]::CreateDirectory($ZlibDir64)

$ZlibDepsDir32 = [System.IO.Path]::Combine($CurlBuildDir32, "deps")
$ZlibDepsIncDir32 = [System.IO.Path]::Combine($ZlibDepsDir32, "include")
$ZlibDepsLibDir32 = [System.IO.Path]::Combine($ZlibDepsDir32, "lib")
$ZlibDepsDir64 = [System.IO.Path]::Combine($CurlBuildDir64, "deps")
$ZlibDepsIncDir64 = [System.IO.Path]::Combine($ZlibDepsDir64, "include")
$ZlibDepsLibDir64 = [System.IO.Path]::Combine($ZlibDepsDir64, "lib")

[System.IO.Directory]::CreateDirectory($ZlibDepsIncDir32)
[System.IO.Directory]::CreateDirectory($ZlibDepsLibDir32)
[System.IO.Directory]::CreateDirectory($ZlibDepsIncDir64)
[System.IO.Directory]::CreateDirectory($ZlibDepsLibDir64)

Write-Output "Downloading zlib..."

$ZlibAsset = [System.IO.Path]::Combine($CacheDir, "zlib.zip")
(New-Object System.Net.WebClient).DownloadFile($ZlibURL, $ZlibAsset)

Write-Output "Unpacking zlib..."
$ZlibUnpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${ZlibAsset} -y" "${ZlibDir32}"
$ZlibUnpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${ZlibAsset} -y" "${ZlibDir64}"
$ZlibUnpack32Proc.WaitForExit()
$ZlibUnpack64Proc.WaitForExit()

Move-Item "${ZlibDir32}\zlib-*\*" "${ZlibDir32}\"
Move-Item "${ZlibDir64}\zlib-*\*" "${ZlibDir64}\"

Write-Output "Building 32bit zlib..."

$ZlibBuilderScript = [System.IO.Path]::Combine($ZlibDir32, "zlib-builder.bat")
Copy-Item "$($CacheDir)\zlib-builder.bat" -Destination "${ZlibBuilderScript}"
$env:ZlibArch = "x86"
$ZlibBuild32Proc = Create-Process "${ZlibBuilderScript}" -Cwd "${ZlibDir32}"

Write-Output "Building 64bit zlib..."
$ZlibBuilderScript = [System.IO.Path]::Combine($ZlibDir64, "zlib-builder.bat")
Copy-Item "$($CacheDir)\zlib-builder.bat" -Destination "${ZlibBuilderScript}"
$env:ZlibArch = "x64"
$ZlibBuild64Proc = Create-Process "${ZlibBuilderScript}" -Cwd "${ZlibDir64}"

$ZlibBuild32Proc.WaitForExit()
if($ZlibBuild32Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 32-bit zlib for curl!"
}

$ZlibBuild64Proc.WaitForExit()
if($ZlibBuild64Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 64-bit zlib for curl!"
}

Push-Location "${ZlibDir32}"
Copy-Item ".\*.h" "${ZlibDepsIncDir32}\"
Copy-Item ".\zlib.lib" "${ZlibDepsLibDir32}\zlib.lib"
Copy-Item ".\zlib.lib" "${ZlibDepsLibDir32}\zlib_a.lib"
Pop-Location

Push-Location "${ZlibDir64}"
Copy-Item ".\*.h" "${ZlibDepsIncDir64}\"
Copy-Item ".\zlib.lib" "${ZlibDepsLibDir64}\zlib.lib"
Copy-Item ".\zlib.lib" "${ZlibDepsLibDir64}\zlib_a.lib"
Pop-Location

Write-Output "Installing curl dependency libssh2..."
$Libssh2Dir32 = [System.IO.Path]::Combine($CacheDir, "libssh232")
$Libssh2Dir64 = [System.IO.Path]::Combine($CacheDir, "libssh264")
[System.IO.Directory]::CreateDirectory($Libssh2Dir32)
[System.IO.Directory]::CreateDirectory($Libssh2Dir64)

$Libssh2DepsDir32 = [System.IO.Path]::Combine($CurlBuildDir32, "deps")
$Libssh2DepsIncDir32 = [System.IO.Path]::Combine($Libssh2DepsDir32, "include")
$Libssh2DepsLibDir32 = [System.IO.Path]::Combine($Libssh2DepsDir32, "lib")
$Libssh2DepsDir64 = [System.IO.Path]::Combine($CurlBuildDir64, "deps")
$Libssh2DepsIncDir64 = [System.IO.Path]::Combine($Libssh2DepsDir64, "include")
$Libssh2DepsLibDir64 = [System.IO.Path]::Combine($Libssh2DepsDir64, "lib")

[System.IO.Directory]::CreateDirectory($Libssh2DepsIncDir32)
[System.IO.Directory]::CreateDirectory($Libssh2DepsLibDir32)
[System.IO.Directory]::CreateDirectory($Libssh2DepsIncDir64)
[System.IO.Directory]::CreateDirectory($Libssh2DepsLibDir64)

Write-Output "Downloading libssh2..."
$Libssh2Asset = [System.IO.Path]::Combine($CacheDir, "libssh2.zip")
(New-Object System.Net.WebClient).DownloadFile($Libssh2URL, $Libssh2Asset)

Write-Output "Unpacking libssh2..."
$Libssh2Unpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${Libssh2Asset} -y" "${Libssh2Dir32}"
$Libssh2Unpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${Libssh2Asset} -y" "${Libssh2Dir64}"
$Libssh2Unpack32Proc.WaitForExit()
$Libssh2Unpack64Proc.WaitForExit()

Move-Item "${Libssh2Dir32}\libssh2-*\*" "${Libssh2Dir32}\"
Move-Item "${Libssh2Dir64}\libssh2-*\*" "${Libssh2Dir64}\"

Write-Output "Building libssh2..."
$Libssh2Builder32Script = [System.IO.Path]::Combine($Libssh2Dir32, "libssh2-builder.bat")
Copy-Item "$($CacheDir)\libssh2-builder.bat" -Destination "${Libssh2Builder32Script}"
$env:Libssh2Arch = "x86"
$Libssh2Build32Proc = Create-Process "${Libssh2Builder32Script}" -Cwd "${Libssh2Dir32}"
$Libssh2Builder64Script = [System.IO.Path]::Combine($Libssh2Dir64, "libssh2-builder.bat")
Copy-Item "$($CacheDir)\libssh2-builder.bat" -Destination "${Libssh2Builder64Script}"
$env:Libssh2Arch = "x64"
$Libssh2Build64Proc = Create-Process "${Libssh2Builder64Script}" -Cwd "${Libssh2Dir64}"

$Libssh2Build32Proc.WaitForExit()
if($Libssh2Build32Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 32-bit libssh2 for curl!"
}

$Libssh2Build64Proc.WaitForExit()
if($Libssh2Build64Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 64-bit libssh2 for curl!"
}

Push-Location "${Libssh2Dir32}"
Copy-Item ".\include\*" "${Libssh2DepsIncDir32}\"
Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir32}\libssh2.lib"
Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir32}\libssh2_a.lib"
Pop-Location

Push-Location "${Libssh2Dir64}"
Copy-Item ".\include\*" "${Libssh2DepsIncDir64}\"
Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir64}\libssh2.lib"
Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir64}\libssh2_a.lib"
Pop-Location

Write-Output "Building native curl..."

$CurlBuilder32 = [System.IO.Path]::Combine($CurlBuildDir32, "winbuild\builder.bat")
Copy-Item "${CacheDir}\curl-builder.bat" "${CurlBuilder32}"
$env:CurlArch = "x86"
$CurlBuild32Proc = Create-Process "${CurlBuilder32}" -Cwd "${CurlBuildDir32}\winbuild"

$CurlBuilder64 = [System.IO.Path]::Combine($CurlBuildDir64, "winbuild\builder.bat")
Copy-Item "${CacheDir}\curl-builder.bat" "${CurlBuilder64}"
$env:CurlArch = "x64"
$CurlBuild64Proc = Create-Process "${CurlBuilder64}" -Cwd "${CurlBuildDir64}\winbuild"

$CurlBuild32Proc.WaitForExit()
if($CurlBuild32Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 32-bit curl!"
}

$CurlBuild64Proc.WaitForExit()
if($CurlBuild64Proc.ExitCode -ne 0) {
    Write-Error "Failed to build 64-bit curl!"
}

Push-Location "${CurlBuildDir32}\winbuild"
[System.IO.Directory]::CreateDirectory("${Embed32Dir}\bin")
[System.IO.Directory]::CreateDirectory("${Embed32Dir}\lib")
[System.IO.Directory]::CreateDirectory("${Embed32Dir}\include\curl")
Pop-Location

Push-Location "${CurlBuildDir32}"
Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\bin\*" "${Embed32Dir}\bin\"
Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\lib\*" "${Embed32Dir}\lib\"
Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\include\curl\*" "${Embed32Dir}\include\curl\"
Copy-Item "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\vcruntime140.dll" "${Embed32Dir}\bin\"
Pop-Location

[System.IO.Directory]::CreateDirectory("${Embed64Dir}\bin")
[System.IO.Directory]::CreateDirectory("${Embed64Dir}\lib")
[System.IO.Directory]::CreateDirectory("${Embed64Dir}\include\curl")

Push-Location "${CurlBuildDir64}"
Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\bin\*" "${Embed64Dir}\bin\"
Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\lib\*" "${Embed64Dir}\lib\"
Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-winssl\include\curl\*" "${Embed64Dir}\include\curl\"
Copy-Item "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\vcruntime140.dll" "${Embed64Dir}\bin\"
Pop-Location

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
