# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
(New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/Git-2.13.0-64-bit.exe', 'C:\Windows\Temp\git.exe')

Start-Process "C:\Windows\Temp\git.exe" "/silent" -Wait
