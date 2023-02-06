:: source download https://github.com/hashicorp/signore/releases/download/v0.1.14/signore_0.1.14_windows_x86_64.zip
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://github.com/hashicorp/signore/releases/download/v0.1.14/signore_0.1.14_windows_x86_64.zip', 'C:\Windows\Temp\signore.zip')" <NUL

mkdir C:\signore
"C:\Program Files\7-Zip\7z.exe" x -y -o"C:\signore" C:\Windows\Temp\signore.zip

setx PATH "%PATH%;C:\signore" /m
