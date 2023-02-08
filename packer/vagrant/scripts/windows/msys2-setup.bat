cmd /c "C:\msys64\usr\bin\bash.exe --login -c "pacman -S --noconfirm zip unzip base-devel""

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/mingw-w64-x86_64-openssl-1.1.1.s-1-any.pkg.tar.zst', 'C:\Windows\Temp\openssl-64.tar.zst')" <NUL
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://vagrant-public-cache.s3.amazonaws.com/mingw-w64-i686-openssl-1.1.1.s-1-any.pkg.tar.zst', 'C:\Windows\Temp\openssl-32.tar.zst')" <NUL

cmd /c "C:\msys64\usr\bin\bash.exe --login -c "pacman -U --noconfirm C:\\/Windows\\/Temp\\/openssl-64.tar.zst""
cmd /c "C:\msys64\usr\bin\bash.exe --login -c "pacman -U --noconfirm C:\\/Windows\\/Temp\\/openssl-32.tar.zst""
