Start-Sleep -Seconds 3

$RemoteComputer = "computer2"
$SourceFolder = "C:\SourceFolder"
$DestinationFolder = "C:\DestinationFolder"

$Script = { param($sourceFolder, $destinationFolder)
    # Stop SQL Server so files won't be locked by it
    Write-Host -ForegroundColor Green "Stop SQL Server serice"
    Get-Service -Name MSSQLSERVER | Stop-Service

    # more commands
  }

Invoke-Command -ComputerName $RemoteComputer -ScriptBlock $Script -ArgumentList $SourceFolder, $DestinationFolder -ErrorAction Stop
Write-Host -ForegroundColor Green "Done copy files"