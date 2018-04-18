if not exist "C:\Windows\Temp\build-tools.exe" (
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe', 'C:\Windows\Temp\build-tools.exe')" <NUL
)

start /wait C:\Windows\Temp\build-tools.exe /Passive /AdminFile A:\buildtools-adminfile.xml

setx PATH "%PATH%;C:\Program Files (x86)\Windows Kits\8.1\bin\x86\signtool.exe" /m
