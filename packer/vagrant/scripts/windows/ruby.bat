if not exist "C:\Windows\Temp\ruby.exe" (
:: source download https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.6.5-1/rubyinstaller-devkit-2.6.5-1-x64.exe
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/rubyinstaller-devkit-2.6.5-1-x64.exe', 'C:\Windows\Temp\ruby.exe')" <NUL
)

start /wait C:\Windows\Temp\ruby.exe /silent

setx PATH "%PATH%;C:\Ruby26\bin" /m
