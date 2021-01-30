# Docker Containers Powershell communications

This is minimal reproducible sample on how to create 2 Docker Windows containers and set-up Powershell communication between them

## Setup

1. Pull files from Github: `https://github.com/jasper22/DockerContainersPowershellCommunications.git`
2. Enter to this folder from any shell
3. Run Docker compose to build all images: `docker-compose.exe build`
4. Start containers: `docker-compose.exe up`

Now you should see the that `computer2` start endless pinging of remote server and `computer1` will try to run remote command on `computer2`

Enjoy !  :wink:

### Additional resources
* [How to Configure Windows Remote PowerShell Access for Non-Privileged User Accounts](https://helpcenter.gsx.com/hc/en-us/articles/202447926-How-to-Configure-Windows-Remote-PowerShell-Access-for-Non-Privileged-User-Accounts)
* [Setting WMI user access permissions using the WMI Control Panel](https://docs.bmc.com/docs/display/public/btco100/Setting+WMI+user+access+permissions+using+the+WMI+Control+Panel)
* [Ansible: Windows Remote Management](https://cn-ansibledoc.readthedocs.io/zh_CN/latest/user_guide/windows_winrm.html)
* [Enable PSRemoting via Powershell to Use Remoting Features!](https://www.webservertalk.com/enable-psremoting-via-powershell)


P.S. If you encourage any issues please open ['Issue'](https://github.com/jasper22/DockerContainersPowershellCommunications/issues)

