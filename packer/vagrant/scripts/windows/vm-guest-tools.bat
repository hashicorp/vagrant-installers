powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/tools-windows.tar', 'C:\Windows\Temp\vmware-tools.tar')" <NUL
cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\vmware-tools.tar -oC:\Windows\Temp"
FOR /r "C:\Windows\Temp" %%a in (VMware-tools-windows-*.iso) DO REN "%%~a" "windows.iso"
rd /S /Q "C:\Program Files (x86)\VMWare"

powershell -Command "Mount-DiskImage -ImagePath C:\Windows\Temp\windows.iso"

start /wait E:\setup64.exe /s /v"/qb REBOOT=R\"

powershell -Command "Dismount-DiskImage -ImagePath C:\Windows\Temp\windows.iso"
