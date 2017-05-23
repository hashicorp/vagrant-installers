<#
.SYNOPSIS
    Bootstrap the substrate

.DESCRIPTION
    Installs required software and builds substrate
#>

# http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
# http://stackoverflow.com/questions/8978052/powershell-2-0-redirection-file-handle-exception
function savepowershellfromitself {
    $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
    $objectRef = $host.GetType().GetField( "externalHostRef", $bindingFlags ).GetValue( $host )
    $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
    $consoleHost = $objectRef.GetType().GetProperty( "Value", $bindingFlags ).GetValue( $objectRef, @() )
    [void] $consoleHost.GetType().GetProperty( "IsStandardOutputRedirected", $bindingFlags ).GetValue( $consoleHost, @() )
    $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
    $field = $consoleHost.GetType().GetField( "standardOutputWriter", $bindingFlags )
    $field.SetValue( $consoleHost, [Console]::Out )
    $field2 = $consoleHost.GetType().GetField( "standardErrorWriter", $bindingFlags )
    $field2.SetValue( $consoleHost, [Console]::Out )
}

savepowershellfromitself

(New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/Git-2.13.0-64-bit.exe', 'C:\Windows\Temp\git.exe')

$result = Start-Process "C:\Windows\Temp\git.exe" "/quiet" -Wait
if($result.ExitCode -ne 0){
  Write-Error "Failed to install Git"
  Exit 1
}
Write-Host "Starting substrate build"
mkdir C:\vagrant\substrate-assets

savepowershellfromitself

Invoke-Expression "C:\vagrant\substrate\run.ps1 -OutputDir C:\vagrant\substrate-assets"