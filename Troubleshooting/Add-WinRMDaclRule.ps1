Function Add-WinRMDaclRule {
    <#
    .SYNOPSIS
    Add a Discretionary Acl rule to the root WinRM listener or individual PSSession configuration.

    .DESCRIPTION
    Add a Discretionary Acl rule to the root WinRM listener or individual PSSession configuration.

    This can be useful if you wish to give access to an individual user or group to either the root WinRM listener or
    a specific PSSession configuration that is not an Administrator.

    .PARAMETER Name
    The PSSession configuration, or 'Root' to reference the root WinRM listener, that the DACL ACE is added to. To get
    a list of PSSession configuration names, run 'Get-PSSessionConfiguration'. The default PSSession configuration for
    'Invoke-Command' and 'Enter-PSSession' is 'Microsoft.PowerShell'.

    The Root WinRM listener can be set if you wish to allow WinRM access for tools that don't use PSRemoting. This is
    typically third party WinRM libraries or people wanting to use the 'winrs' command.

    .PARAMETER Account
    The name of the account to add the DACL ACE for.

    .PARAMETER Right
    A list of rights to set on the ACE, this can one or more of the following;
        FullControl - Includes all the rights below
        Execute (Default) - Allows users to execute commands over WinRM
        Read - Allows users to read the configuration of the listener or PSSession configuration
        Write - Allows users to write the configuraiton of the listener or PSSession configuration
    
    .EXAMPLE Allow an account to execute commands over PSRemoting
    Add-WinRMDaclRule -Name Microsoft.PowerShell -Account standard-account

    .EXAMPLE Allow an account to execute command with winrs or third party WinRM libs
    Add-WinRMDaclRule -Name Root -Account standard-account

    .EXAMPLE Give execute and read access to multiple accounts and groups
    Add-WinRMDaclRule -Name Microsoft.PowerSHell -Account account, group -Right Read, Execute
    
    .NOTE
    You may need to restart the WinRM service for these changes to apply, run 'Restart-Service -Name winrm' to do so.
    If you wish to just enable a standard user account access over PSRemoting, you can also just add it to the builtin
    'Remote Management Users' group on the host in question.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param (
        [Parameter(Mandatory=$true)]
        [System.String]
        $Name,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [System.String[]]
        $Account,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [System.String[]]
        $Right = @(,'Execute')
    )

    Begin {
        if ($Name -eq 'Root') {
            Write-Verbose -Message "Getting Root WSMan SDDL"
            $sddl = (Get-Item -LiteralPath WSMan:\localhost\Service\RootSDDL).Value
        } else {
            Write-Verbose -Message "Getting PSSession SDDL for '$Name'"
            $sddl = (Get-PSSessionConfiguration -Name $Name -ErrorAction Stop).SecurityDescriptorSddl
        }
        $sd = New-Object -TypeName 'System.Security.AccessControl.CommonSecurityDescriptor' -ArgumentList @(
            $false, $false, $sddl
        )
        $accessMask = @{
            FullControl = 0x10000000
            Execute = 0x20000000
            Write = 0x40000000
            Read = 0x80000000
        }
    }

    Process {
        Write-Verbose -Message "Validating the input rights"
        $mask = 0
        foreach ($aceRight in $Right) {
            if (-not $accessMask.ContainsKey($aceRight)) {
                Write-Error -Message "Invalid access right '$aceRight' - skipping this entry, valid values are: $($accessMask.Keys)."
                return
            }
            $mask = $mask -bor $accessMask.$aceRight
        }


        foreach ($userAccount in $Account) {
            Write-Verbose -Message "Converting '$userAccount' to a Security Identifier"
            $sid = (New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $userAccount).Translate(
                [System.Security.Principal.SecurityIdentifier]
            )

            $addRule = $true
            foreach ($ace in $sd.DiscretionaryAcl.GetEnumerator()) {
                if ($ace.SecurityIdentifier -ne $sid) {
                    continue
                }
                if ($ace.AceType -ne 'AccessAllowed') {
                    continue
                }
                if ($ace.AccessMask -ne $mask) {
                    continue
                }

                $addRule = $false
                break
            }

            if ($addRule) {
                Write-Verbose -Message "Adding rule for $userAccount with rights $($Rights -join ", ")"
                $sd.DiscretionaryAcl.AddAccess(
                    [System.Security.AccessControl.AccessControlType]::Allow,
                    $sid,
                    $mask,
                    [System.Security.AccessControl.InheritanceFlags]::None,
                    [System.Security.AccessControl.PropagationFlags]::None
                )
            }
        }
    }

    End {
        $newSddl = $sd.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)
        if ($newSddl -ne $sddl -and $PSCmdlet.ShouldProcess($Name, "Add DACL entry")) {
            if ($Name -eq 'Root') {
                Set-Item -LiteralPath WSMan:\localhost\Service\RootSDDL -Value $newSddl -Force
            } else {
                Set-PSSessionConfiguration -Name $Name -SecurityDescriptorSddl $newSddl
            }
        }
    }
}