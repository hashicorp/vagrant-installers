:: order of install: clearcompressionflag.exe, KB2919355, KB2932046, KB2959977, KB2937592, KB2938439, and KB2934018

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/clearcompressionflag_3104315db9d84f6a2a56b9621e89ea66a8c27604.exe', 'C:\Windows\Temp\clearcompressionflag.exe')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2919355-x64_e6f4da4d33564419065a7370865faacf9b40ff72.msu', 'C:\Windows\Temp\sp1.msu')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2932046-x64_6aee5a6e2a6729d1fbae6eac08693acd70d985.msu', 'C:\Windows\Temp\sp2.msu')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2959977-x64_574ba2d60baa13645b764f55069b74b2de866975.msu', 'C:\Windows\Temp\sp3.msu')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2937592-x64_4abc0a39c9e500c0fbe9c41282169c92315cafc2.msu', 'C:\Windows\Temp\sp4.msu')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2938439-x64_3ed1574369e36b11f37af41aa3a875a115a3eac1.msu', 'C:\Windows\Temp\sp5.msu')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/windows8.1-kb2934018-x64_234a5fc4955f81541f5bfc0d447e4fc4934efc38.msu', 'C:\Windows\Temp\sp6.msu')" <NUL

start /wait C:\Windows\Temp\clearcompressionflag.exe
start /wait wusa C:\Windows\Temp\sp1.msu /quiet /norestart
start /wait wusa C:\Windows\Temp\sp2.msu /quiet /norestart
start /wait wusa C:\Windows\Temp\sp3.msu /quiet /norestart
start /wait wusa C:\Windows\Temp\sp4.msu /quiet /norestart
start /wait wusa C:\Windows\Temp\sp5.msu /quiet /norestart
start /wait wusa C:\Windows\Temp\sp6.msu /quiet /norestart