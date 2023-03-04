# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

(New-Object System.Net.WebClient).DownloadFile('https://github.com/msys2/msys2-installer/releases/download/2020-06-02/msys2-x86_64-20200602.exe', 'C:\Windows\Temp\msys2.exe')

Start-Process "C:\Windows\Temp\msys2.exe" "--script A:\msys2-install.qs" -Wait

Start-Process "C:\msys64\usr\bin\bash.exe" "--login -c 'pacman -R --noconfirm catgets libcatgets'" -Wait
Start-Process "C:\msys64\usr\bin\bash.exe" "--login -c 'pacman -Syu --noconfirm'" -Wait
Start-Process "C:\msys64\usr\bin\bash.exe" "--login -c 'pacman -Syu --noconfirm'" -Wait
Start-Process "C:\msys64\usr\bin\bash.exe" "--login -c 'pacman -S --noconfirm zip unzip'" -Wait
Start-Process "C:\msys64\usr\bin\bash.exe" "--login -c 'pacman -S --noconfirm base-devel'" -Wait
