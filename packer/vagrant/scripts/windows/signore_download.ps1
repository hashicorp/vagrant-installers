[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12

$file = "C:\Windows\Temp\signore.zip"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "token ${env:HASHIBOT_TOKEN}")
$headers.Add("Accept", "application/octet-stream")
$download = "https://api.github.com/repos/hashicorp/signore/releases/assets/94533456"
Invoke-WebRequest -Uri $download -Headers $headers -OutFile $file
