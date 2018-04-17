if not exist "C:\Windows\Temp\MicrosoftEasyFix.msi" (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://instcache.s3.amazonaws.com/MicrosoftEasyFix51044.msi', 'C:\Windows\Temp\MicrosoftEasyFix.msi')" <NUL
)

start /wait msiexec /quiet /passive /i C:\Windows\Temp\MicrosoftEasyFix.msi