@echo ON
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "& {Set-ExecutionPolicy Bypass; Get-ExecutionPolicy}"
if exist "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" ("C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -Command "& {Set-ExecutionPolicy Bypass; Get-ExecutionPolicy}")

@echo Off
PAUSE