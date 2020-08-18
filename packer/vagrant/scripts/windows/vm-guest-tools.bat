if not exist "C:\Windows\Temp\7z920-x64.msi" (
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z920-x64.msi', 'C:\Windows\Temp\7z920-x64.msi')" <NUL
    msiexec /qb /i C:\Windows\Temp\7z920-x64.msi
)

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('http://softwareupdate.vmware.com/cds/vmw-desktop/ws/15.5.6/16341506/windows/packages/tools-windows.tar', 'C:\Windows\Temp\vmware-tools.tar')" <NUL
cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\vmware-tools.tar -oC:\Windows\Temp"
FOR /r "C:\Windows\Temp" %%a in (VMware-tools-windows-*.iso) DO REN "%%~a" "windows.iso"
rd /S /Q "C:\Program Files (x86)\VMWare"

powershell -Command "Mount-DiskImage -ImagePath C:\Windows\Temp\windows.iso"

start /wait E:\setup64.exe /s /v"/qb REBOOT=R"

powershell -Command "Dismount-DiskImage -ImagePath C:\Windows\Temp\windows.iso"

rd /S /Q "C:\Windows\Temp\VMware"
