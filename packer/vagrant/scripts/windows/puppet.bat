if not exist "C:\Windows\Temp\puppet.msi" (
  powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('http://downloads.puppetlabs.com/windows/puppet-3.8.7.msi', 'C:\Windows\Temp\puppet.msi')" <NUL
)

:: http://docs.puppetlabs.com/pe/latest/install_windows.html
start /wait msiexec /qn /norestart /i C:\Windows\Temp\puppet.msi /log C:\Windows\Temp\puppet.log

setx PATH "%PATH%;C:\Program Files (x86)\Puppet Labs\Puppet\bin" /m
