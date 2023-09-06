<#PSScriptInfo

.VERSION 1.1.0

.GUID 1d3dc65f-9665-4e4d-abb2-c3c91875424d

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
1.0.0
Initial release

1.1.0
Cleaned up code

#>


<#

.DESCRIPTION
 Contains a function to test if there have been events logged in the last 24 hours which indicate issues in applying computer group policy.

#>


function Test-ALHGroupPolicyStatus {
    <#
    .SYNOPSIS
    Function to test if there have been events logged in the last 24 hours which indicate issues in applying computer group policy.

    .DESCRIPTION
    Function queries event log for certain events indicating issues in applying computer group policy settings. The function
    by default returns either true or false, but it can also return the events found in the eventlog (use parameter ReturnDetail).

    .PARAMETER MachinePolicy
    Repair computer group policy.

    .PARAMETER ComputerName
    Allows to specify remote computer name. By default it will run against the local computer.

    .PARAMETER Credential
    Specify credentials with necessary permissions to query the system event log on the given computer.

    .EXAMPLE
    Test-ALHGroupPolicyStatus
    Run check for computer group policy.

    .EXAMPLE
    Test-ALHGroupPolicyStatus -ComputerName MyOtherSystem
    Run check for computer group policy on remote computer named "MyOtherSystem".

    .EXAMPLE
    Test-ALHGroupPolicyStatus -ComputerName MyOtherSystem -Credential $(Get-Credential)
    Run check for computer group policy on remote computer named "MyOtherSystem" and specifying credentials.

    .NOTES
    Author:     Dieter Kochs
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHGroupPolicyStatus.txt
    #>

    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName = "$env:COMPUTERNAME",

        [switch]
        $ReturnDetails,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    try {
        $Domain = (Get-CimInstance Win32_ComputerSystem).Domain
        $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain)
        $DC = [System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($Context)
    }
    catch {
        Write-Error "No domain controller found."
    }

    if ($PSVersionTable.PSVersion -ge [System.Version]"6.0") {
        Write-Verbose -Message "Running PowerShell 6.0 or newer - need to import Windows PowerShell cmdlets."
        Import-Module Microsoft.PowerShell.Management -UseWindowsPowerShell
    }

    if ($null -ne $DC -and (Test-ComputerSecureChannel)) {
        $EventsFound = Get-ALHGroupPolicyFailureEvent -StartTime (Get-Date).AddHours(-24) -ComputerName $ComputerName -Credential $Credential

        if (($EventsFound | Measure-Object).Count -gt 0) {
            if ($ReturnDetails.IsPresent) {
                $ReturnValue = $EventsFound
            }
            else {
                $ReturnValue = $true
            }
        }
        else {
            $ReturnValue = $false
        }
    }
    else {
        Write-Verbose -Message "No DC found or no secure channel established (maybe system is offline)"
    }

    Write-Verbose -Message "Done"
    $ReturnValue
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
