if not exist "C:\Windows\Temp\ruby.exe" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.2.6.exe', 'C:\Windows\Temp\ruby.exe')" <NUL
)

C:\Windows\Temp\ruby.exe /silent

powershell -Command "$CurPath = [Environment]::GetEnvironmentVariable(\"PATH\"); [Environment]::SetEnvironmentVariable(\"PATH\", \"${CurPath};C:\Ruby22\bin\", \"Machine\")"
