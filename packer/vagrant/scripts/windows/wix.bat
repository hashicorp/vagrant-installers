if not exist "C:\Windows\Temp\wix.exe" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=wix&DownloadId=1587179&FileTime=131118854865270000&Build=21050', 'C:\Windows\Temp\wix.exe')" <NUL
)

powershell -Command "Start-Process 'C:\Windows\Temp\wix.exe' '/quiet /norestart' -Wait"
