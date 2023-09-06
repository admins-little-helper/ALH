<#PSScriptInfo

.VERSION 1.2.1

.GUID d94d4ef6-0227-4c9d-9dbd-4abd93464d29

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
- Initial release

1.1.0
- Renamed function to Get-ALHDomainController because it does not query Active Directory itself
- Removed dependency for ActiveDirectory Module

1.2.0
- Cleaned up code

1.2.1
- Fixed issue #38. Using Get-CimInstance intead of Get-WmiObject to support PowerShell Core (v5.1+)

#>


<#

.DESCRIPTION
Contains function to get the currently used Domain Controller by the operating system.

#>


function Get-ALHADDSDomainController {
    <#
    .SYNOPSIS
    Returns information about AD Domain Controller.

    .DESCRIPTION
    Returns information about AD Domain Controller.

    .EXAMPLE
    Get-ALHADDSDomainController

    Get the current domain controller used by the operating system

    .EXAMPLE
    Get-ALHADDSDomainController -All

    Get the all domain controllers in the current domain

    .INPUTS
    Nothing

    .OUTPUTS
    System.DirectoryServices.ActiveDirectory.DirectoryServer

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADDSDomainController.txt
    #>

    [CmdletBinding()]
    param (
        [switch]
        $All
    )

    $Domain = (Get-CimInstance -ClassName "Win32_ComputerSystem").Domain

    if ($null -ne $Domain) {
        $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain)

        if ($All.IsPresent) {
            $DC = [System.DirectoryServices.ActiveDirectory.DomainController]::FindAll($context)
        }
        else {
            $DC = [System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($context)
        }
    }
    else {
        Write-Warning -Message "Computer is not connected to an AD Domain."
    }

    $DC
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
