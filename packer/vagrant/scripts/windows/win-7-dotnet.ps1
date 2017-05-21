Write-Host "Downloading .NET upgrade"
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe', 'C:\Windows\Temp\dotnet.exe')
Write-Host "Installing .NET upgrade"
Start-Process 'C:\Windows\Temp\dotnet.exe' '/quiet /forcerestart' -Wait
