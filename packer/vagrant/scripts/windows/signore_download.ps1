[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
$cl = New-Object System.Net.WebClient
$cl.Headers["Content-Type"] = "application/json"
$cl.Headers["Authorization"] = "token ${env:HASHIBOT_TOKEN}"
$cl.DownloadFile("https://github.com/hashicorp/signore/releases/download/v0.1.14/signore_0.1.14_windows_x86_64.zip", "C:\Windows\Temp\signore.zip")
