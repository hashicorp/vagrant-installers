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

if($env:VAGRANT_SUBSTRATE_OUTPUT_DIR) {
    $out_dir = $env:VAGRANT_SUBSTRATE_OUTPUT_DIR
} else {
    $out_dir = "substrate-assets"
}

$SignKeyPath = "C:\vagrant\Win_CodeSigning.p12"
$SignKeyPassword = $env:SignKeyPassword
$SignKeyExists = Test-Path -LiteralPath $SignKeyPath
$SubstrateArgs = @{
    "OutputDir"="C:\vagrant\${out_dir}";
}
if($SignKeyExists -and $SignKeyPassword) {
    $SubstrateArgs["SignKeyFile"] = $SignKeyPath
    $SubstrateArgs["SignKeyPassword"] = $SignKeyPassword
}

try {
    & C:\vagrant\substrate\run.ps1 @SubstrateArgs
    if(!$?) {
        Write-Error "Substrate build failed"
        exit 1
    }
} catch {
    Write-Error "Unexpected substrate build error!"
    exit 1
}
