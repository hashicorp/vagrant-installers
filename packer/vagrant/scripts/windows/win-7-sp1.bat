echo "Downloading Windows 7 Service Pack 1"

if not exist "C:\Windows\Temp\sp1.exe" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/0/A/F/0AFB5316-3062-494A-AB78-7FB0D4461357/windows6.1-KB976932-X64.exe', 'C:\Windows\Temp\sp1.exe')" <NUL
)

echo "Installing Windows 7 Service Pack 1"

start /wait C:\Windows\Temp\sp1.exe /unattend /forcerestart