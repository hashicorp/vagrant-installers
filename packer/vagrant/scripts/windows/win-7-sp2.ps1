Write-Host "Downloading Windows 7 Service Pack 2"
(New-Object System.Net.WebClient).DownloadFile('https://download.windowsupdate.com/d/msdownload/update/software/updt/2016/05/windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu', 'C:\Windows\Temp\sp2.msu')
Write-Host "Installing Windows 7 Service Pack 2"
Start-Process "wusa.exe" "C:\Windows\Temp\sp2.msu /quiet /forcerestart" -Wait
