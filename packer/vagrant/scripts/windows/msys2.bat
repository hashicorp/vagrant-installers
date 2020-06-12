if not exist "C:\Windows\Temp\msys2.exe" (
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12; (New-Object System.Net.WebClient).DownloadFile('https://github.com/msys2/msys2-installer/releases/download/2020-06-02/msys2-x86_64-20200602.exe', 'C:\Windows\Temp\msys2.exe')" <NUL
)

C:\Windows\Temp\msys2.exe --script A:\msys2-install.qs

C:\msys64\usr\bin\bash.exe --login -c "pacman -R --noconfirm catgets libcatgets"
C:\msys64\usr\bin\bash.exe --login -c "pacman -Syu --noconfirm"
C:\msys64\usr\bin\bash.exe --login -c "pacman -Syu --noconfirm"
C:\msys64\usr\bin\bash.exe --login -c "pacman -S --noconfirm zip unzip"
C:\msys64\usr\bin\bash.exe --login -c "pacman -S --noconfirm base-devel"
