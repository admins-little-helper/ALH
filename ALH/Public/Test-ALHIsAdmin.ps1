<#PSScriptInfo

.VERSION 1.0.0

.GUID 8a3d22fe-43e0-401d-93c3-7925b5bc49bd

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

#>


<#

.DESCRIPTION
 Contains a function to check if PowerShell runs with elevated permissions.

.LINK
https://github.com/admins-little-helper/ALH

#>


function Test-ALHIsAdmin {
    <#
    .SYNOPSIS
    Check if PowerShell runs with elevated permissions.

    .DESCRIPTION
    Check if PowerShell runs with elevated permissions. Also supports .NET CORE on Linux/macOS.

    .EXAMPLE
    Test-ALHIsAdmin

    Returns $true or $false.

    .INPUTS
    Nothing

    .OUTPUTS
    System.Boolean

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHIsAdmin.txt
    #>

    [OutputType([bool])]
    [CmdletBinding()]
    param ()

    if ((($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Win32NT')) -or ($PSVersionTable.PSEdition -eq 'Desktop') ) {
        Write-Verbose -Message "Running on Windows."
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    }
    elseif (($PSVersionTable.PSEdition -eq 'Core') -and ($PSVersionTable.Platform -eq 'Unix')) {
        Write-Verbose -Message "Running on Unix/Linux/macOS."
        return ((id -u) -eq 0)
    }
    else {
        Write-Warning -Message 'Unknown PowerShell Plattform (OS) and/or PowerShell Edition.'
        return
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
