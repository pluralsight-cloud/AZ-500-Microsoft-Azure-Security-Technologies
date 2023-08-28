[CmdletBinding()]
param (
    [string]
    $ConnectionString
)

# Speed up by disabling progress
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Ensure C:\Temp exists
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue

# Install IIS
try {
    Write-Verbose "START: Installing IIS"
    Add-WindowsFeature Web-Server -IncludeManagementTools
    Write-Verbose "END: Installing IIS"
}
catch {
    Write-Verbose "ERROR: Installing IIS"
    throw $_
}

# Import WebAdministration PowerShell Module
try {
    Write-Verbose "START: Import WebAdministration"
    Import-Module WebAdministration
    Write-Verbose "END: Import WebAdministration"
}
catch {
    Write-Verbose "ERROR: Import WebAdministration"
    throw $_
}

# Rename the Default Website
try {
    Write-Verbose "START: Rename the Default Website"
    Rename-Item -Path "IIS:\Sites\Default Web Site" "WebApp" -Force
    Write-Verbose "END: Rename the Default Website"
}
catch {
    Write-Verbose "ERROR: Rename the Default Website"
    throw $_
}

# Download and Install Web Deploy
try {
    Write-Verbose "START: Download Web Deploy"
    Invoke-WebRequest -Uri 'https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi' -OutFile 'C:\Temp\WebDeploy_amd64_en-US.msi'
    Start-Process -FilePath "msiexec.exe" -ArgumentList @('/i', 'C:\Temp\WebDeploy_amd64_en-US.msi', '/qn') -Wait
    Write-Verbose "END: Download Web Deploy"
}
catch {
    Write-Verbose "ERROR: Download Web Deploy"
    throw $_
}


# Download the WebApp
try {
    Write-Verbose "START: Download WebApp"
    Invoke-WebRequest -Uri 'https://github.com/pluralsight-cloud/AZ-500-Microsoft-Azure-Security-Technologies/raw/main/1347%20-%20Microsoft%20AZ-500%20Practice%20Exam/Labs/Defense%20in%20Depth/Publish.zip' -OutFile 'C:\Temp\Publish.zip'
    Expand-Archive -Path 'C:\Temp\Publish.zip' -DestinationPath 'C:\Temp\' -Force
    Write-Verbose "END: Download WebApp"
}
catch {
    Write-Verbose "ERROR: Download WebApp"
    throw $_
}

# Run the WebDeploy Package
try {
    Write-Verbose "START: Run the WebDeploy Package"
    Start-Process -FilePath 'C:\Temp\WebApp.deploy.cmd' -ArgumentList "/Y" -Wait -NoNewWindow
    Write-Verbose "END: Run the WebDeploy Package"
}
catch {
    Write-Verbose "ERROR: Run the WebDeploy Package"
    throw $_
}


# Download Application Settings
try {
    Write-Verbose "START: Download Application Settings"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pluralsight-cloud/AZ-500-Microsoft-Azure-Security-Technologies/main/1347%20-%20Microsoft%20AZ-500%20Practice%20Exam/Labs/Defense%20in%20Depth/appsettings.json" -OutFile "C:\inetpub\wwwroot\appsettings.json"
    Write-Verbose "END: Download Application Settings"
}
catch {
    Write-Verbose "ERROR: Download Application Settings"
    throw $_
}

# Inject the required application settings
try {
    Write-Verbose "START: Inject Application Settings"
    (Get-Content "C:\inetpub\wwwroot\appsettings.json") -Replace '%%ConnectionString%%', "$($ConnectionString)" | Set-Content "C:\inetpub\wwwroot\appsettings.json"
    Write-Verbose "END: Inject Application Settings"
}
catch {
    Write-Verbose "ERROR: Inject Application Settings"
    throw $_
}

# Download .Net Core IIS Hosting Bundle
try {
    Write-Verbose "START: Download .Net Core IIS Hosting Bundle"
    Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/6744eb9d-dcd4-4386-9d87-b03b70fc58ce/818fadf3f3d919c17ba845b2195bfd9b/dotnet-hosting-3.1.32-win.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
    Write-Verbose "END: Download .Net Core IIS Hosting Bundle"
}
catch {
    Write-Verbose "ERROR: Download .Net Core IIS Hosting Bundle"
    throw $_
}

# Install the .Net Core IIS Hosting Bundle
try {
    Write-Verbose "START: Install .Net Core IIS Hosting Bundle"
    Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait
    Write-Verbose "END: Install .Net Core IIS Hosting Bundle"
}
catch {
    Write-Verbose "ERROR: Install .Net Core IIS Hosting Bundle"
    throw $_
}

# Restart IIS Services
try {
    Write-Verbose "START: Restart required services"
    Stop-Service -Name was -Force
    Start-Service -Name w3svc
    Write-Verbose "END: Restart required services"
}
catch {
    Write-Verbose "ERROR: Restart required services"
    throw $_
}

#region Clean up Microsoft Edge
try {
    Write-Verbose "START: Clean up Microsoft Edge"
    # Create the Directory Tree
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge\PasswordManagerEnabled" -Force
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge\RestoreOnStartupURLs" -Force
    # Disable full-tab promotional content
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PromotionalTabsEnabled" -Value 0 -Type "DWord" -Force
    # Disable Password Manager
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge\PasswordManagerEnabled" -Name "PromotionalTabsEnabled" -Value 0 -Type "DWord" -Force
    # Disallow importing of browser settings
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ImportBrowserSettings" -Value 0 -Force
    # Disallow Microsoft News content on the new tab page
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageContentEnabled" -Value 0 -Type "DWord" -Force
    # Disallow all background types allowed for the new tab page layout
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageAllowedBackgroundTypes" -Value 3 -Type "DWord" -Force
    # Hide App Launcher on Microsoft Edge new tab page
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageAppLauncherEnabled" -Value 0 -Type "DWord" -Force
    # Disable the password manager
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PasswordManagerEnabled" -Value '0' -Force
    # Hide the First-run experience and splash screen
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Force
    # Disable sign-in
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "BrowserSignin" -Value 0 -Force
    # Disable quick links on the new tab page
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NewTabPageQuickLinksEnabled" -Value 0 -Force
    # Disable importing of favorites
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ImportFavorites" -Value 0 -Force
    Write-Verbose "END: Clean up Microsoft Edge"
}
catch {
    Write-Verbose "ERROR: Clean up Microsoft Edge"
    throw $_
}

#endregion Clean up Microsoft Edge

# Customize Windows Explorer
try {
    Write-Verbose "START: Customize Windows Explorer"
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
    Write-Verbose "END: Customize Windows Explorer"
}
catch {
    Write-Verbose "ERROR: Customize Windows Explorer"
    throw $_
}