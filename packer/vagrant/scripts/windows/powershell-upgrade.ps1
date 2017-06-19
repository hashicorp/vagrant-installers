Write-Host "Downloading Powershell Upgrade"
(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/7/6/E76850B8-DA6E-4FF5-8CCE-A24FC513FD16/Windows6.1-KB2506143-x64.msu', 'C:\Windows\Temp\ps-upgrade.msu')
Write-Host "Installing Powershell Upgrade"
Start-Process "C:\Windows\Temp\ps-upgrade.msu" "/quiet /forcerestart" -Wait
