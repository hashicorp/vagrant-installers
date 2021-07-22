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
    [string] $SignKeyPassword=$null,
    [parameter(Mandatory=$false)]
    [switch] $Disable32,
    [parameter(Mandatory=$false)]
    [switch] $Disable64
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
        [string] $Cwd,
        [parameter(Mandatory=$false, Position=3)]
        [hashtable] $Env,
        [parameter(Mandatory=$false)]
        [switch] $QuietOut,
        [parameter(Mandatory=$false)]
        [switch] $QuietErr
    )
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $ExePath
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.UseShellExecute = $false
    if($Cwd) {
        $process.StartInfo.WorkingDirectory = $Cwd
    }
    $process.StartInfo.Arguments = $Arguments
    if($Env -ne $null) {
        foreach($entry in $Env.GetEnumerator()) {
            $process.StartInfo.EnvironmentVariables.Add($entry.Name, $entry.Value)
        }
    }


    if(!$QuietOut) {
        $evO = Register-ObjectEvent -InputObject $process -Action {
            if(-not [String]::IsNullOrEmpty($Event.SourceEventArgs.Data)) {
                [Console]::WriteLine($Event.SourceEventArgs.Data)
            }
        } -EventName OutputDataReceived
    }
    if(!$QuietErr) {
        $evE = Register-ObjectEvent -InputObject $process -Action {
            if(-not [String]::IsNullOrEmpty($Event.SourceEventArgs.Data) -and !$QuietErr) {
                [Console]::Error.WriteLine($Event.SourceEventArgs.Data)
            }
        } -EventName ErrorDataReceived
    }

    $process.Start() | Out-Null
    $process.BeginErrorReadLine();
    $process.BeginOutputReadLine();

    return $process
}

$Build32 = !$Disable32
$Build64 = !$Disable64

$CurlVersion = "7.75.0"
$Libssh2Version = "1.9.0"
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
$PackageDir = [System.IO.Path]::Combine($CacheDir, "packages")

[System.IO.Directory]::CreateDirectory($CacheDir) | Out-Null
[System.IO.Directory]::CreateDirectory($OutputDir) | Out-Null
[System.IO.Directory]::CreateDirectory($PackageDir) | Out-Null

if($Build32) {
    $Stage32Dir = [System.IO.Path]::Combine($StageDir, "x32")
    $Embed32Dir = [System.IO.Path]::Combine($Stage32Dir, "embedded")
    [System.IO.Directory]::CreateDirectory($Embed32Dir) | Out-Null
}

if($Build64) {
    $Stage64Dir = [System.IO.Path]::Combine($StageDir, "x64")
    $Embed64Dir = [System.IO.Path]::Combine($Stage64Dir, "embedded")
    [System.IO.Directory]::CreateDirectory($Embed64Dir) | Out-Null
}

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

Push-Location "${CacheDir}"

$OriginalPath = $env:PATH

$env:PATH = "${PATH};C:\msys64\usr\bin"
$env:MSYSTEM = "MINGW64"

$DepProc = Create-Process bash.exe "--login -f '${RubyDepsPath}'" "${CacheDir}"
do { Start-Sleep -Seconds 1} while(!$DepProc.HasExited)

if($DepProc.ExitCode -ne 0) {
    Write-Error "Failed to install ruby build dependencies! - ${DepProc.ExitCode}"
}
$DepProc.Dispose()

if($Build32) {
    $RubyProc32 = Create-Process bash.exe "--login -f '${RubyBuilderPath}' mingw32" "${CacheDir}" -QuietOut
}
if($Build64) {
    $RubyProc64 = Create-Process bash.exe "--login -f '${RubyBuilderPath}' mingw64" "${CacheDir}" -QuietOut
}
if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$RubyProc32.HasExited)
    if($RubyProc32.ExitCode -ne 0) {
        Write-Error "Ruby 32 bit build has failed!"
    }
    $RubyProc32.Dispose()
}
if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$RubyProc64.HasExited)
    if($RubyProc64.ExitCode -ne 0) {
        Write-Error "Ruby 64 bit build has failed!"
    }
    $RubyProc64.Dispose()
}

# Relocate packages
Copy-Item .\ruby-build-*\*.xz -Destination "${PackageDir}"

Pop-Location

# Start the substrate build
Write-Output "Starting substrate build..."

Push-Location "${CacheDir}"

$env:MSYSTEM = "MSYS"
$SubstrateDepProc = Create-Process bash.exe "--login -f '${SubstrateDepsPath}'" -Cwd "${CacheDir}"
do { Start-Sleep -Seconds 1} while(!$SubstrateDepProc.HasExited)

if($SubstrateDepProc.ExitCode -ne 0) {
    Write-Error "Substrate dependency script has failed!"
}
$SubstrateDepProc.Dispose()

Copy-Item "$($CacheDir)\vagrant.cfg" -Destination "${SubstrateBuilderDir}\vagrant.cfg"

$SubstrateProc = Create-Process bash.exe "--login -f '${SubstrateBuilderPath}' '${PackageDir}' '${Stage32Dir}' '${Stage64Dir}'" "${SubstrateBuilderDir}" -QuietOut
do { Start-Sleep -Seconds 1} while(!$SubstrateProc.HasExited)

if($SubstrateProc.ExitCode -ne 0) {
    Write-Error "Substrate build has failed!"
}
$SubstrateProc.Dispose()

Pop-Location

# Build the launcher
Write-Output "Building vagrant launcher..."

$env:GOPATH = "C:\Windows\Temp"
$env:PATH = "C:\Program Files\Go\bin;C:\Program Files\Git\bin;${OriginalPath}"

$LauncherDepProc = Create-Process go.exe "get github.com/mitchellh/osext"
do { Start-Sleep -Seconds 1} while(!$LauncherDepProc.HasExited)

if($LauncherDepProc.ExitCode -ne 0) {
    Write-Error "Failed to install launcher dependency: osext"
}
$LauncherDepProc.Dispose()

Push-Location "${LauncherDir}"

if($Build32) {
    $Stage32Bin = [System.IO.Path]::Combine($Stage32Dir, "bin")
    [System.IO.Directory]::CreateDirectory($Stage32Bin) | Out-Null
}

if($Build64) {
    $Stage64Bin = [System.IO.Path]::Combine($Stage64Dir, "bin")
    [System.IO.Directory]::CreateDirectory($Stage64Bin) | Out-Null
}

if($Build64) {
    $LauncherProc64 = Create-Process go.exe "build -o ${Stage64Bin}\vagrant.exe main.go" "${LauncherDir}"
}

if($Build32) {
    $LauncherProc32 = Create-Process go.exe "build -o ${Stage32Bin}\vagrant.exe main.go" "${LauncherDir}" -Env @{GOARCH = "386"}
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$LauncherProc64.HasExited)
    if($LauncherProc64.ExitCode -ne 0) {
        Write-Error "Failed to build vagrant 64-bit launcher!"
    }
    $LauncherProc64.Dispose()
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$LauncherProc32.HasExited)
    if($LauncherProc32.ExitCode -ne 0) {
        Write-Error "Failed to build vagrant 32-bit launcher!"
    }
    $LauncherProc32.Dispose()
}

Pop-Location

Write-Output "Installing gemrc file..."
if($Build32) {
    $Gemrc32Dir = [System.IO.Path]::Combine($Stage32Dir, "embedded\etc")
    [System.IO.Directory]::CreateDirectory($Gemrc32Dir) | Out-Null
    Copy-Item "C:\vagrant\substrate\common\gemrc" -Destination "${Stage32Dir}\embedded\etc\gemrc"
}
if($Build64) {
    $Gemrc64Dir = [System.IO.Path]::Combine($Stage64Dir, "embedded\etc")
    [System.IO.Directory]::CreateDirectory($Gemrc64Dir) | Out-Null
    Copy-Item "C:\vagrant\substrate\common\gemrc" -Destination "${Stage64Dir}\embedded\etc\gemrc"
}

Write-Output "Preparing native curl build..."

Write-Output "Downloading curl..."

$CurlAsset = [System.IO.Path]::Combine($CacheDir, "curl.zip")
(New-Object System.Net.WebClient).DownloadFile("${CurlURL}", "${CurlAsset}")

Write-Output "Unpacking curl..."
if($Build32) {
    $CurlBuildDir32 = [System.IO.Path]::Combine($CacheDir, "curl32")
    [System.IO.Directory]::CreateDirectory($CurlBuildDir32) | Out-Null
    $CurlUnpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${CurlAsset} -y" "${CurlBuildDir32}" -QuietOut
}
if($Build64) {
    $CurlBuildDir64 = [System.IO.Path]::Combine($CacheDir, "curl64")
    [System.IO.Directory]::CreateDirectory($CurlBuildDir64) | Out-Null
    $CurlUnpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${CurlAsset} -y" "${CurlBuildDir64}" -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$CurlUnpack32Proc.HasExited)
    if($CurlUnpack32Proc.ExitCode -ne 0) {
        Write-Error "Failed to unpack cURL for 32-bit build"
    }
    $CurlUnpack32Proc.Dispose()
    $CurlBuildDir32 = Resolve-Path -Path "${CurlBuildDir32}\curl-*"
}
if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$CurlUnpack64Proc.HasExited)
    if($CurlUnpack64Proc.ExitCode -ne 0) {
        Write-Error "Failed to unpack cURL for 64-bit build"
    }
    $CurlUnpack64Proc.Dispose()
    $CurlBuildDir64 = Resolve-Path -Path "${CurlBuildDir64}\curl-*"
}


Write-Output "Installing curl dependency zlib..."

if($Build32) {
    $ZlibDir32 = [System.IO.Path]::Combine($CacheDir, "zlib32")
    [System.IO.Directory]::CreateDirectory($ZlibDir32)

    $ZlibDepsDir32 = [System.IO.Path]::Combine($CurlBuildDir32, "deps")
    $ZlibDepsIncDir32 = [System.IO.Path]::Combine($ZlibDepsDir32, "include")
    $ZlibDepsLibDir32 = [System.IO.Path]::Combine($ZlibDepsDir32, "lib")

    [System.IO.Directory]::CreateDirectory($ZlibDepsIncDir32)
    [System.IO.Directory]::CreateDirectory($ZlibDepsLibDir32)
}
if($Build64) {
    $ZlibDir64 = [System.IO.Path]::Combine($CacheDir, "zlib64")
    [System.IO.Directory]::CreateDirectory($ZlibDir64)

    $ZlibDepsDir64 = [System.IO.Path]::Combine($CurlBuildDir64, "deps")
    $ZlibDepsIncDir64 = [System.IO.Path]::Combine($ZlibDepsDir64, "include")
    $ZlibDepsLibDir64 = [System.IO.Path]::Combine($ZlibDepsDir64, "lib")

    [System.IO.Directory]::CreateDirectory($ZlibDepsIncDir64)
    [System.IO.Directory]::CreateDirectory($ZlibDepsLibDir64)
}

Write-Output "Downloading zlib..."

$ZlibAsset = [System.IO.Path]::Combine($CacheDir, "zlib.zip")
(New-Object System.Net.WebClient).DownloadFile($ZlibURL, $ZlibAsset)

Write-Output "Unpacking zlib..."
if($Build32) {
    $ZlibUnpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${ZlibAsset} -y" "${ZlibDir32}" -QuietOut
}
if($Build64) {
    $ZlibUnpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${ZlibAsset} -y" "${ZlibDir64}" -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$ZlibUnpack32Proc.HasExited)
    if($ZlibUnpack32Proc.ExitCode -ne 0) {
        Write-Error "Failed to unpack zlib for 32-bit build"
    }
    $ZlibUnpack32Proc.Dispose()
    Move-Item "${ZlibDir32}\zlib-*\*" "${ZlibDir32}\"
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$ZlibUnpack64Proc.HasExited)
    if($ZlibUnpack64Proc.ExitCode -ne 0) {
        Write-Error "Failed to unpack zlib for 64-bit build"
    }
    $ZlibUnpack64Proc.Dispose()
    Move-Item "${ZlibDir64}\zlib-*\*" "${ZlibDir64}\"
}

if($Build32) {
    Write-Output "Building 32bit zlib..."

    $ZlibBuilderScript = [System.IO.Path]::Combine($ZlibDir32, "zlib-builder.bat")
    Copy-Item "$($CacheDir)\zlib-builder.bat" -Destination "${ZlibBuilderScript}"
    $ZlibBuild32Proc = Create-Process "${ZlibBuilderScript}" -Cwd "${ZlibDir32}" -Env @{ZlibArch = "x86"} -QuietOut
}

if($Build64) {
    Write-Output "Building 64bit zlib..."
    $ZlibBuilderScript = [System.IO.Path]::Combine($ZlibDir64, "zlib-builder.bat")
    Copy-Item "$($CacheDir)\zlib-builder.bat" -Destination "${ZlibBuilderScript}"
    $ZlibBuild64Proc = Create-Process "${ZlibBuilderScript}" -Cwd "${ZlibDir64}" -Env @{ZlibArch = "x64"} -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$ZlibBuild32Proc.HasExited)
    if($ZlibBuild32Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 32-bit zlib for curl!"
    }
    $ZlibBuild32Proc.Dispose()
    Push-Location "${ZlibDir32}"
    Copy-Item ".\*.h" "${ZlibDepsIncDir32}\"
    Copy-Item ".\zlib.lib" "${ZlibDepsLibDir32}\zlib.lib"
    Copy-Item ".\zlib.lib" "${ZlibDepsLibDir32}\zlib_a.lib"
    Pop-Location
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$ZlibBuild64Proc.HasExited)
    if($ZlibBuild64Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 64-bit zlib for curl!"
    }
    $ZlibBuild64Proc.Dispose()
    Push-Location "${ZlibDir64}"
    Copy-Item ".\*.h" "${ZlibDepsIncDir64}\"
    Copy-Item ".\zlib.lib" "${ZlibDepsLibDir64}\zlib.lib"
    Copy-Item ".\zlib.lib" "${ZlibDepsLibDir64}\zlib_a.lib"
    Pop-Location
}

Write-Output "Installing curl dependency libssh2..."

if($Build32) {
    $Libssh2Dir32 = [System.IO.Path]::Combine($CacheDir, "libssh232")
    [System.IO.Directory]::CreateDirectory($Libssh2Dir32)

    $Libssh2DepsDir32 = [System.IO.Path]::Combine($CurlBuildDir32, "deps")
    $Libssh2DepsIncDir32 = [System.IO.Path]::Combine($Libssh2DepsDir32, "include")
    $Libssh2DepsLibDir32 = [System.IO.Path]::Combine($Libssh2DepsDir32, "lib")

    [System.IO.Directory]::CreateDirectory($Libssh2DepsIncDir32)
    [System.IO.Directory]::CreateDirectory($Libssh2DepsLibDir32)
}

if($Build64) {
    $Libssh2Dir64 = [System.IO.Path]::Combine($CacheDir, "libssh264")
    [System.IO.Directory]::CreateDirectory($Libssh2Dir64)

    $Libssh2DepsDir64 = [System.IO.Path]::Combine($CurlBuildDir64, "deps")
    $Libssh2DepsIncDir64 = [System.IO.Path]::Combine($Libssh2DepsDir64, "include")
    $Libssh2DepsLibDir64 = [System.IO.Path]::Combine($Libssh2DepsDir64, "lib")

    [System.IO.Directory]::CreateDirectory($Libssh2DepsIncDir64)
    [System.IO.Directory]::CreateDirectory($Libssh2DepsLibDir64)
}

Write-Output "Downloading libssh2..."
$Libssh2Asset = [System.IO.Path]::Combine($CacheDir, "libssh2.zip")
(New-Object System.Net.WebClient).DownloadFile($Libssh2URL, $Libssh2Asset)

Write-Output "Unpacking libssh2..."
if($Build32) {
    $Libssh2Unpack32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${Libssh2Asset} -y" "${Libssh2Dir32}" -QuietOut
}
if($Build64) {
    $Libssh2Unpack64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "x ${Libssh2Asset} -y" "${Libssh2Dir64}" -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$Libssh2Unpack32Proc.HasExited)
    if($Libssh2Unpack32Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 32-bit libssh2"
    }
    $Libssh2Unpack32Proc.Dispose()
    Move-Item "${Libssh2Dir32}\libssh2-*\*" "${Libssh2Dir32}\"
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$Libssh2Unpack64Proc.HasExited)
    if($Libssh2Unpack64Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 64-bit libssh2"
    }
    $Libssh2Unpack64Proc.Dispose()
    Move-Item "${Libssh2Dir64}\libssh2-*\*" "${Libssh2Dir64}\"
}

if($Build32) {
    Write-Output "Building 32-bit libssh2..."
    $Libssh2Builder32Script = [System.IO.Path]::Combine($Libssh2Dir32, "libssh2-builder.bat")
    Copy-Item "${CacheDir}\libssh2-builder.bat" -Destination "${Libssh2Builder32Script}"
    $Libssh2Build32Proc = Create-Process "${Libssh2Builder32Script}" -Cwd "${Libssh2Dir32}" -Env @{Libssh2Arch = "x86"} -QuietOut
}

if($Build64) {
    Write-Output "Building 64-bit libssh2..."
    $Libssh2Builder64Script = [System.IO.Path]::Combine($Libssh2Dir64, "libssh2-builder.bat")
    Copy-Item "${CacheDir}\libssh2-builder.bat" -Destination "${Libssh2Builder64Script}"
    $Libssh2Build64Proc = Create-Process "${Libssh2Builder64Script}" -Cwd "${Libssh2Dir64}" -Env @{Libssh2Arch = "x64"} -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$Libssh2Build32Proc.HasExited)
    if($Libssh2Build32Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 32-bit libssh2 for curl!"
    }
    $Libssh2Build32Proc.Dispose()
    Push-Location "${Libssh2Dir32}"
    Copy-Item ".\include\*" "${Libssh2DepsIncDir32}\"
    Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir32}\libssh2.lib"
    Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir32}\libssh2_a.lib"
    Pop-Location
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$Libssh2Build64Proc.HasExited)
    if($Libssh2Build64Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 64-bit libssh2 for curl!"
    }
    $Libssh2Build64Proc.Dispose()
    Push-Location "${Libssh2Dir64}"
    Copy-Item ".\include\*" "${Libssh2DepsIncDir64}\"
    Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir64}\libssh2.lib"
    Copy-Item ".\Release\src\libssh2.lib" "${Libssh2DepsLibDir64}\libssh2_a.lib"
    Pop-Location
}

if($Build32) {
    Write-Output "Building native 32-bit cURL..."
    Copy-Item "${CacheDir}\curl-builder.bat" "${CurlBuildDir32}\winbuild\builder.bat"
    $CurlBuilder32 = [System.IO.Path]::Combine($CurlBuildDir32, "winbuild\builder.bat")
    $CurlBuild32Proc = Create-Process "${CurlBuilder32}" -Cwd "${CurlBuildDir32}\winbuild" -Env @{CurlArch = "x86"} -QuietOut
}

if($Build64) {
    Write-Output "Building native 64-bit cURL..."
    Copy-Item "${CacheDir}\curl-builder.bat" "${CurlBuildDir64}\winbuild\builder.bat"
    $CurlBuilder64 = [System.IO.Path]::Combine($CurlBuildDir64, "winbuild\builder.bat")
    $CurlBuild64Proc = Create-Process "${CurlBuilder64}" -Cwd "${CurlBuildDir64}\winbuild" -Env @{CurlArch = "x64"} -QuietOut
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$CurlBuild32Proc.HasExited)
    if($CurlBuild32Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 32-bit curl!"
    }
    $CurlBuild32Proc.Dispose()
    Push-Location "${CurlBuildDir32}\winbuild"
    [System.IO.Directory]::CreateDirectory("${Embed32Dir}\bin")
    [System.IO.Directory]::CreateDirectory("${Embed32Dir}\lib")
    [System.IO.Directory]::CreateDirectory("${Embed32Dir}\include\curl")
    Pop-Location

    Push-Location "${CurlBuildDir32}"
    Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\bin\*" "${Embed32Dir}\bin\"
    Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\lib\*" "${Embed32Dir}\lib\"
    Copy-Item ".\builds\libcurl-vc-x86-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\include\curl\*" "${Embed32Dir}\include\curl\"
    Copy-Item "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\vcruntime140.dll" "${Embed32Dir}\bin\"
    Pop-Location
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$CurlBuild64Proc.HasExited)
    if($CurlBuild64Proc.ExitCode -ne 0) {
        Write-Error "Failed to build 64-bit curl!"
    }
    $CurlBuild64Proc.Dispose()
    [System.IO.Directory]::CreateDirectory("${Embed64Dir}\bin")
    [System.IO.Directory]::CreateDirectory("${Embed64Dir}\lib")
    [System.IO.Directory]::CreateDirectory("${Embed64Dir}\include\curl")

    Push-Location "${CurlBuildDir64}"
    Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\bin\*" "${Embed64Dir}\bin\"
    Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\lib\*" "${Embed64Dir}\lib\"
    Copy-Item ".\builds\libcurl-vc-x64-release-static-zlib-static-ssh2-static-ipv6-sspi-schannel\include\curl\*" "${Embed64Dir}\include\curl\"
    Copy-Item "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\vcruntime140.dll" "${Embed64Dir}\bin\"
    Pop-Location
}

if($SignKeyFile -and !$SignKeyPassword) {
    Write-Warning "SignKey path provided but no SignKeyPassword given. Embedded binaries will be unsigned!"
} elseif(!$SignKeyFile -and $SignKeyPassword) {
    Write-Warning "SignKeyPassword provided but no SignKey path given. Embedded binaries will be unsigned!"
} elseif(!$SignKeyFile -and !$SignKeyPassword) {
    Write-Warning "SignKey and SignKeyPassword not given. Embedded binaries will be unsigned!"
} else {
    Write-Output "Signing embedded binaries..."
    $binaries = Get-ChildItem "${StageDir}" -Filter *.exe -Recurse
    foreach($binary in $binaries) {
        $SignProc = Create-Process signtool.exe "sign /t http://timestamp.digicert.com /f ${SignKeyFile} /p ${SignKeyPassword} ${binary.FullName}"
        do { Start-Sleep -Seconds 1} while(!$SignProc.HasExited)
        if($SignProc.ExitCode -ne 0) {
            Write-Error "Failed to sign embedded binary -> ${binary.FullName}"
        }
        $SignProc.Dispose()
    }
}

if($Build32) {
    Write-Output "Compressing 32-bit substrate assets..."
    $Asset32Path = [System.IO.Path]::Combine($OutputDir, "substrate_windows_i686.zip")
    $Asset32Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "a -r ${Asset32Path} ${Stage32Dir}\*"
}

if($Build64) {
    Write-Output "Compressing 64-bit substrate assets..."
    $Asset64Path = [System.IO.Path]::Combine($OutputDir, "substrate_windows_x86_64.zip")
    $Asset64Proc = Create-Process "C:\Program Files\7-Zip\7z.exe" "a -r ${Asset64Path} ${Stage64Dir}\*"
}

if($Build32) {
    do { Start-Sleep -Seconds 1} while(!$Asset32Proc.HasExited)
    if($Asset32Proc.ExitCode -ne 0) {
        Write-Error "Failed to compress 32-bit substrate asset!"
    }
    $Asset32Proc.Dispose()
}

if($Build64) {
    do { Start-Sleep -Seconds 1} while(!$Asset64Proc.HasExited)
    if($Asset64Proc.ExitCode -ne 0) {
        Write-Error "Failed to compress 64-bit substrate asset!"
    }
    $Asset64Proc.Dispose()
}

Write-Output "Cleaning up build files..."
Remove-Item "${BuildDir}" -Force -Recurse

Write-Output "Substrate build complete."
if($Build32) {
    Write-Output "  -> ${Asset32Path}"
}
if($Build64) {
    Write-Output "  -> ${Asset64Path}"
}
