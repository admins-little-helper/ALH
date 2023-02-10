<#PSScriptInfo

.VERSION 1.1.0

.GUID 03501306-1af7-49b4-80ed-f3e2aa567fe2

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    1.0.0
    - Initial release

    1.1.0
    - Added parameter 'ComputerName' to support tests against remote computers
    - As a requirement for testing remote computers, the registry reads are now done by Get-ALHRegistryItem

#>


<#

.DESCRIPTION
 Contains a function to check if a computer has a reboot pending.

#>


function Test-ALHIsRebootPending {    
    <#
    .SYNOPSIS
    Check if a computer has a reboot pending.

    .DESCRIPTION
    Check if a computer has a reboot pending.

    .EXAMPLE
    Test-ALHHasPendingReboot

    Check if there is a reboot pending. Returns $true or $false

    .EXAMPLE
    Test-ALHIsRebootPending-ShowDetails

    Check if there is a reboot pending. Return details about checks and why there is a pending reboot

    .EXAMPLE
    Test-ALHIsRebootPending-Verbose

    Check if there is a reboot pending. Show verbose output.
   
    .INPUTS
    Nothing

    .OUTPUTS
    System.Boolean

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHIsRebootPending.txt
    #>
   
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [switch]
        $ShowDetails
    )
    <#
    https://adamtheautomator.com/pending-reboot-registry/
    Key	Value	Condition
    HKLM:\SOFTWARE\Microsoft\Updates	UpdateExeVolatile	Value is anything other than 0
    HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager	PendingFileRenameOperations	value exists
    HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager	PendingFileRenameOperations2	value exists
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired	NA	key exists
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending	NA	Any GUID subkeys exist
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting	NA	key exists
    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce	DVDRebootSignal	value exists
    HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending	NA	key exists
    HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress	NA	key exists
    HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending	NA	key exists
    HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts	NA	key exists
    HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon	JoinDomain	value exists
    HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon	AvoidSpnSet	value exists
    HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName	ComputerName	Value ComputerName in HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName is different

    If you have the Microsoft System Center Configuration Manager (SCCM) client installed, you may also see these methods in WMI.

    Namespace	        Class	            Property	                Value	            Product	Notes
    ROOT\ccm\ClientSDK	CCM_ClientUtilities	DetermineifRebootPending	RebootPending	    SCCM	ReturnValue needs to be 0 and this value is not null
    ROOT\ccm\ClientSDK	CCM_ClientUtilities	DetermineifRebootPending	IsHardRebootPending	SCCM	ReturnValue needs to be 0 and this value is not null
    #>

    begin {
        $PendingRebootChecks = [ordered]@{
            Registry = [ordered]@{
                'HKLM:\SOFTWARE\Microsoft\Updates'                                                              = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\Updates'
                    RegVal         = 'UpdateExeVolatile'
                    Condition      = '[int]<RegVal> -ne 0'
                    RebootRequired = $false
                }
                'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager__PendingFileRenameOperations'           = @{
                    RegKey         = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                    RegVal         = 'PendingFileRenameOperations'
                    Condition      = '$null -ne <RegVal>'
                    RebootRequired = $false
                }
                'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager__PendingFileRenameOperations2'          = @{
                    RegKey         = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
                    RegVal         = 'PendingFileRenameOperations2'
                    Condition      = '$null -ne <RegVal>'
                    RebootRequired = $false
                }
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'      = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'                    
                    RebootRequired = $false
                }
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending'                = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending'
                    RegVal         = '(Default)'
                    Condition      = '(Get-ChildItem -Path <RegKey>).PSChildName | ForEach-Object { $_ -match "(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$" }'
                    RebootRequired = $false
                }
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting' = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'
                    RebootRequired = $false
                }
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'                                       = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
                    RegVal         = 'DVDRebootSignal'
                    Condition      = '$null -ne <RegVal>'
                    RebootRequired = $false
                }
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'       = @{
                    RegKey         = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'
                    RebootRequired = $false
                }
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'    = @{
                    RegKey         = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'
                    RebootRequired = $false
                }
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'     = @{
                    RegKey         = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'
                    RebootRequired = $false        
                }
                'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts'                                  = @{
                    RegKey         = 'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts'
                    RegVal         = '(Default)'
                    Condition      = '$null -ne (Get-ALHRegistryItem -ComputerName $Computer -Path <RegKey>)'
                    RebootRequired = $false   
                }
                'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon__JoinDomain'                                  = @{
                    RegKey         = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon'
                    RegVal         = 'JoinDomain'
                    Condition      = '$null -ne <RegVal>'
                    RebootRequired = $false   
                }
                'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon__AvoidSpnSet'                                 = @{
                    RegKey         = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon'
                    RegVal         = 'AvoidSpnSet'
                    Condition      = '$null -ne <RegVal>'
                    RebootRequired = $false   
                }
                'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'                        = @{
                    RegKey         = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
                    RegVal         = 'ComputerName'
                    Condition      = '<RegVal> -ne $(Get-ALHRegistryItem -ComputerName $Computer -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -ValueName ComputerName).Data'
                    RebootRequired = $false   
                }
            }
            WMI      = [ordered]@{
                'ConfigMgr_RebootPending_1' = @{
                    NameSpace      = 'root\ccm\ClientSDK'
                    ClassName      = 'CCM_ClientUtilities'
                    Property       = 'DetermineifRebootPending'
                    Value          = 'RebootPending'
                    Note           = 'ReturnValue needs to be 0 and this value is not null'
                    RebootRequired = $false
                }
                'ConfigMgr_RebootPending_2' = @{
                    NameSpace      = 'root\ccm\ClientSDK'
                    ClassName      = 'CCM_ClientUtilities'
                    Property       = 'DetermineifRebootPending'
                    Value          = 'IsHardRebootPending'
                    Note           = 'ReturnValue needs to be 0 and this value is not null'
                    RebootRequired = $false
                }
            }
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $Result = [PSCustomObject]@{
                ComputerName   = $Computer
                RebootRequired = $null
                Details        = $PendingRebootChecks
            }

            if ((Test-Connection $Computer -Quiet -Count 1) -and (Test-Path "\\$Computer\c$")) {
                $NoCheckPerformed = $false

                foreach ($RegItem in $Result.Details.Registry.Keys) {
                    $RegKeyName = $Result.Details.Registry."$($RegItem)".RegKey
                    $RegValName = $Result.Details.Registry."$($RegItem)".RegVal
                    $RegCondition = $($Result.Details.Registry."$($RegItem)".Condition) 
                    $RegCondition = $RegCondition -replace '<RegVal>', '$RegVal'
                    $RegCondition = $RegCondition -replace '<RegKey>', '$RegKeyName'
                    $RegVal = $null
    
                    try {
                        $RegVal = Get-ALHRegistryItem -ComputerName $Computer -Path "$RegKeyname" -ValueName "$RegValName" -ErrorAction Stop
                    }
                    catch [System.Management.Automation.MethodInvocationException] {
                        if ($_.FullyQualifiedErrorId -like '*SecurityException*') {
                            Write-Error -Message "Access to remote system is denied! Skipping computer $Computer"
                            break
                        }
                    }
                    catch {
                        $_
                    }
    
                    if ($null -ne $RegVal) {
                        $RegVal = $RegVal.Data
                    }
                    Write-Verbose -Message "RegVal: $RegVal"
    
                    try {
                        if (Invoke-Expression $RegCondition -ErrorAction Stop) {
                            Write-Verbose -Message "Pending reboot detected for check $RegKeyName"
                            $Result.Details.Registry."$($RegItem)".RebootRequired = $true
                        }
                        else {
                            Write-Verbose -Message "No pending reboot detected for check $RegKeyName"
                        }
                    }
                    catch {
                        $_
                    }
                }
    
                foreach ($WmiItem in $Result.Details.WMI.Keys) {
                    Write-Verbose -Message "Getting a list of all namespaces on local computer..."
                    $WmiNamespaces = Get-CimInstance -ComputerName $Computer -Namespace root -ClassName __Namespace
    
                    if ($WmiNamespaces.Name -contains $Result.Details.WMI."$($WmiItem)".NameSpace) {
                        $WmiVal = Get-CimInstance -ComputerName $Computer -ClassName $Result.Details.WMI."$($WmiItem)".ClassName -Namespace $Result.Details.WMI."$($WmiItem)".NameSpace -Property $Result.Details.WMI."$($WmiItem)".Property -ErrorAction SilentlyContinue
                        if ($null -ne $WmiVal) {
                            if ($WmiVal -eq $Result.Details.WMI."$($WmiItem)".Value) {
                                $Result.Details.WMI."$($WmiItem)".RebootRequired = $true
                            }
                        }
                    }
                    else {
                        Write-Verbose -Message "WMI Namespace not found on local computer: $($Result.Details.WMI."$($WmiItem)".NameSpace)"
                    }
                }
            }
            else {
                Write-Error -Message "Computer is offline or access is denied: $Computer"
                $NoCheckPerformed = $true
            }
            
            $Result.RebootRequired = 
            if ($NoCheckPerformed) {
                $null
            }
            else {
                $Result.Details.Registry.Values.RebootRequired -contains $true -or $Result.Details.WMI.Values.RebootRequired -contains $true
            }

            if ($ShowDetails.IsPresent) {
                $Result
            }
            else {
                $Result | Select-Object -Property Computer, RebootRequired
            }
        }
    }
}


#region EndOfScript
<#
################################################################################
################################################################################
#
#        ______           _          __    _____           _       _   
#       |  ____|         | |        / _|  / ____|         (_)     | |  
#       | |__   _ __   __| |   ___ | |_  | (___   ___ _ __ _ _ __ | |_ 
#       |  __| | '_ \ / _` |  / _ \|  _|  \___ \ / __| '__| | '_ \| __|
#       | |____| | | | (_| | | (_) | |    ____) | (__| |  | | |_) | |_ 
#       |______|_| |_|\__,_|  \___/|_|   |_____/ \___|_|  |_| .__/ \__|
#                                                           | |        
#                                                           |_|        
################################################################################
################################################################################
# created with help of http://patorjk.com/software/taag/
#>
#endregion
