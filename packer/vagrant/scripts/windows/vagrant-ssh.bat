:: vagrant public key
mkdir C:\Users\vagrant\.ssh

if exist a:\vagrant.pub (
  copy a:\vagrant.pub C:\Users\vagrant\.ssh\authorized_keys
) else (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub', 'C:\Users\vagrant\.ssh\authorized_keys')" <NUL
)

if exist "C:\Program Files\OpenSSH-Win64\ssh.exe" (
  powershell -Command "$p = 'C:\Users\vagrant\.ssh\authorized_keys'; $a = Get-Acl $p; $ar = New-Object System.Security.AccessControl.FileSystemAccessRule('NT SERVICE\sshd', 'Read', 'Allow'); $a.SetAccessRule($ar); Set-Acl $p $a"
)
