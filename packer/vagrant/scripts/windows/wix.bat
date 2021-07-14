if not exist "C:\Windows\Temp\wix.exe" (
:: source download https://github.com/wixtoolset/wix3/releases/download/wix3104rtm/wix310.exe
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/wix310.exe', 'C:\Windows\Temp\wix.exe')" <NUL
)

start /wait C:\Windows\Temp\wix.exe /quiet /norestart

setx PATH "%PATH%;C:\Program Files (x86)\Wix Toolset v3.10\bin" /m
