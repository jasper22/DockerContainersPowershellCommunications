# escape=`
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set hostname
RUN Rename-Computer -NewName "computer1" -Force

# Allow Powershell remoting:
#   Start Windows Remote Management service
#   Set WSMan
#   Enable Remoting
#   Set remote container hostname/ipaddress to Trusted List
RUN Get-Service -Name WinRM | Stop-Service; `
    Set-WSManQuickConfig -SkipNetworkProfileCheck -Force; `
    Enable-PSRemoting -SkipNetworkProfileCheck -Force; `
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force; `
    Get-Service -Name WinRM | Start-Service; `
    Write-Host "Powershell remoting configured !"

CMD ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';", "ping.exe 8.8.8.8 -t"]
