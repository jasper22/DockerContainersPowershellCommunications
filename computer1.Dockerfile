# escape=`
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8
# FROM mcr.microsoft.com/powershell:lts-windowsservercore-2004

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set hostname
RUN Rename-Computer -NewName "computer1" -Force

# Allow Powershell remoting:
#   Start Windows Remote Management service
#   Set WSMan
#   Enable Remoting
#   Set remote container hostname/ipaddress to Trusted List
RUN Set-WSManQuickConfig -SkipNetworkProfileCheck -Force; `
    Enable-PSRemoting -SkipNetworkProfileCheck -Force; `
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force; `
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true; `
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true; `
    Restart-Service WinRM; `
    Write-Host "Powershell remoting configured !"

WORKDIR /app

COPY ./computer1.ps1 .

CMD ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';", ".\\computer1.ps1"]

# $pass = 'pa$$word123' | ConvertTo-SecureString -AsPlainText -Force
# $credential = New-Object System.Management.Automation.PSCredential -ArgumentList ('dockerUser', $pass)
# Invoke-Command -ScriptBlock {Get-Process} -ComputerName computer2 -Credential $credential

# E731C818F92A\dockerUser