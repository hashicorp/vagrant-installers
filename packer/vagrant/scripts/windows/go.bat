if not exist "C:\Windows\Temp\go.msi" (
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.10.1.windows-amd64.msi', 'C:\Windows\Temp\go.msi')" <NUL
)

set SEE_MASK_NOZONECHECKS=1
start /wait msiexec /qn /i C:\Windows\Temp\go.msi

setx PATH "%PATH%;C:\Go\bin" /m
