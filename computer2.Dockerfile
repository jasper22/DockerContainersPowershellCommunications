# escape=`
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8
# FROM mcr.microsoft.com/powershell:lts-windowsservercore-2004

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set hostname
RUN Rename-Computer -NewName "computer2" -Force

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

RUN New-LocalUser 'dockerUser' -Password $(ConvertTo-SecureString 'pa$$word123' -AsPlainText -Force) -FullName 'Docker user' -Description 'User for Docker communication'; `
    Add-LocalGroupMember -Group 'Administrators' -Member 'dockerUser' -Verbose; `
    Add-LocalGroupMember -Group 'Remote Management Users' -Member 'dockerUser' -Verbose;

CMD ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';", "ping.exe 8.8.8.8 -t"]
