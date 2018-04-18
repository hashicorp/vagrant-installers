if not exist "C:\Windows\Temp\msys2.exe" (
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20161025.exe', 'C:\Windows\Temp\msys2.exe')" <NUL
)

C:\Windows\Temp\msys2.exe --script A:\msys2-install.qs

C:\msys64\usr\bin\bash.exe --login -c "pacman -R --noconfirm catgets libcatgets"
C:\msys64\usr\bin\bash.exe --login -c "pacman -Syu --noconfirm"
C:\msys64\usr\bin\bash.exe --login -c "pacman -Syu --noconfirm"
C:\msys64\usr\bin\bash.exe --login -c "pacman -S --noconfirm zip unzip"
C:\msys64\usr\bin\bash.exe --login -c "pacman -S --noconfirm base-devel"
