if not exist "C:\Windows\Temp\go.msi" (
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.8.1.windows-amd64.msi', 'C:\Windows\Temp\go.msi')" <NUL
)

set SEE_MASK_NOZONECHECKS=1
start /wait msiexec /qn /i C:\Windows\Temp\go.msi

powershell -Command "$CurPath = [Environment]::GetEnvironmentVariable(\"PATH\"); [Environment]::SetEnvironmentVariable(\"PATH\", \"${CurPath};C:\Go\bin\", \"Machine\")"
