# Docker Containers Powershell communications

This is minimal reproducible sample on how to create 2 Docker container and set-up Powershell communication between them

## Setup

1. Pull files from Github: `https://github.com/jasper22/DockerContainersPowershellCommunications.git`
2. Enter to this folder from any shell
3. Run Docker compose to build all images: `docker-compose.exe build`
4. Start containers: `docker-compose.exe up`

Now you should see the that `computer2` start endless pinging of remote server and `computer1` will try to run remote command on `computer2`

Enjoy !  :wink:

P.S. If you encourage any issues please open 'Issue'