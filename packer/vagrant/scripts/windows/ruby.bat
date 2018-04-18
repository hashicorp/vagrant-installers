if not exist "C:\Windows\Temp\ruby.exe" (
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.2.6.exe', 'C:\Windows\Temp\ruby.exe')" <NUL
)

start /wait C:\Windows\Temp\ruby.exe /silent

setx PATH "%PATH%;C:\Ruby22\bin" /m
