# https://serverfault.com/a/926382/123552
# root\cimv2

Param ([Parameter(Mandatory=$true,Position=0)] [string]$Namespace,
       [Parameter(Mandatory=$true,Position=1)] [ValidateSet("Add","Remove")] [string]$Operation,
       [Parameter(Mandatory=$true,Position=2)] [string] $Account,
       [Parameter(Mandatory=$false,Position=3)] [ValidateSet("EnableAccount","ExecuteMethods","FullWrite","PartialWrite","ProviderWrite","RemoteEnable","ReadSecurity","WriteSecurity")] [string[]] $Permissions=$null,
       [Parameter(Mandatory=$false)] [switch]$AllowInherit,
       [Parameter(Mandatory=$false)] [switch]$Deny,
       [Parameter(Mandatory=$false)] [string]$ComputerName=".",
       [Parameter(Mandatory=$false)] [System.Management.Automation.PSCredential]$Credential=$null)

$OBJECT_INHERIT_ACE_FLAG    = 0x1
$CONTAINER_INHERIT_ACE_FLAG = 0x2
$ACCESS_ALLOWED_ACE_TYPE    = 0x0
$ACCESS_DENIED_ACE_TYPE     = 0x1

$WBEM_ENABLE            = 0x01
$WBEM_METHOD_EXECUTE    = 0x02
$WBEM_FULL_WRITE_REP    = 0x04
$WBEM_PARTIAL_WRITE_REP = 0x08
$WBEM_WRITE_PROVIDER    = 0x10
$WBEM_REMOTE_ACCESS     = 0x20
$WBEM_RIGHT_SUBSCRIBE   = 0x40
$WBEM_RIGHT_PUBLISH     = 0x80
$READ_CONTROL           = 0x20000
$WRITE_DAC              = 0x40000
$WBEM_S_SUBJECT_TO_SDS  = 0x43003

$ErrorActionPreference = "Stop"

$InvokeParams=@{Namespace=$Namespace;Path="__systemsecurity=@";ComputerName=$ComputerName}
if ($PSBoundParameters.ContainsKey("Credential")) { $InvokeParams+= @{Credential=$Credential}}

$output = Invoke-WmiMethod @InvokeParams -Name "GetSecurityDescriptor"
if ($output.ReturnValue -ne 0) { throw "GetSecurityDescriptor failed:  $($output.ReturnValue)" }

$ACL = $output.Descriptor

if ($Account.Contains('\')) {
  $Domain=$Account.Split('\')[0]
  if (($Domain -eq ".") -or ($Domain -eq "BUILTIN")) { $Domain = $ComputerName }
  $AccountName=$Account.Split('\')[1]
}
elseif ($Account.Contains('@')) {
  $Somain=$Account.Split('@')[1].Split('.')[0]
  $AccountName=$Account.Split('@')[0]
}
else {
  $Domain = $ComputerName
  $AccountName = $Account
}

$GetParams = @{Class="Win32_Account" ;Filter="Domain='$Domain' and Name='$AccountName'"}
$Win32Account = Get-WmiObject @GetParams
if ($Win32Account -eq $null) { throw "Account was not found: $Account" }

# Add Operation
if ($Operation -eq "Add") {
  if ($Permissions -eq $null) { throw "Permissions must be specified for an add operation" }

  # Construct AccessMask
  $AccessMask=0
  $WBEM_RIGHTS_FLAGS=$WBEM_ENABLE,$WBEM_METHOD_EXECUTE,$WBEM_FULL_WRITE_REP,$WBEM_PARTIAL_WRITE_REP,$WBEM_WRITE_PROVIDER,$WBEM_REMOTE_ACCESS,$READ_CONTROL,$WRITE_DAC
  $WBEM_RIGHTS_STRINGS="EnableAccount","ExecuteMethods","FullWrite","PartialWrite","ProviderWrite","RemoteEnable","ReadSecurity","WriteSecurity"
  $PermissionTable=@{}
  for ($i=0; $i -lt $WBEM_RIGHTS_FLAGS.Count; $i++) { $PermissionTable.Add($WBEM_RIGHTS_STRINGS[$i].ToLower(), $WBEM_RIGHTS_FLAGS[$i]) }
  foreach ($Permission in $Permissions) { $AccessMask+=$PermissionTable[$Permission.ToLower()] }

  $ACE=(New-Object System.Management.ManagementClass("Win32_Ace")).CreateInstance()
  $ACE.AccessMask=$AccessMask
  # Do not use $OBJECT_INHERIT_ACE_FLAG.  There are no leaf objects here.
  if ($AllowInherit.IsPresent) { $ACE.AceFlags=$CONTAINER_INHERIT_ACE_FLAG }
  else { $ACE.AceFlags=0 }

  $Trustee=(New-Object System.Management.ManagementClass("Win32_Trustee")).CreateInstance()
  $Trustee.SidString = $Win32Account.SID
  $ACE.Trustee=$Trustee

  if ($Deny.IsPresent) { $ACE.AceType = $ACCESS_DENIED_ACE_TYPE } else { $ACE.AceType = $ACCESS_ALLOWED_ACE_TYPE }
  $ACL.DACL+=$ACE
}
#Remove Operation
else {
  if ($Permissions -ne $null) { Write-Warning "Permissions are ignored for a remove operation" }
  [System.Management.ManagementBaseObject[]]$newDACL = @()
  foreach ($ACE in $ACL.DACL) {
    if ($ACE.Trustee.SidString -ne $Win32Account.SID) { $newDACL+=$ACE }
  }
  $ACL.DACL = $newDACL
}

$SetParams=@{Name="SetSecurityDescriptor"; ArgumentList=$ACL}+$InvokeParams

$output = Invoke-WmiMethod @SetParams
if ($output.ReturnValue -ne 0) { throw "SetSecurityDescriptor failed: $($output.ReturnValue)" }