<#PSScriptInfo

.VERSION 1.0.0

.GUID a198043b-d24a-4c09-b433-72f880f24cb3

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
 Contains function to get a sorted list of all AD Domain Controllers for the domain the user running the cmdlet is member in.
#>


function Get-ALHADDCInfo {
    <#
    .SYNOPSIS
        Returns a sorted list of all AD Domain Controllers for the domain the user running the cmdlet is member in.

    .DESCRIPTION
        Returns a sorted list of all AD Domain Controllers for the domain the user running the cmdlet is member in.

    .EXAMPLE
        Get-ALHADDCInfo

    .INPUTS
        Nothing

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADDCInfo.txt
    #>

    [CmdletBinding()]
    param ()

    $RequiredModules = "ActiveDirectory"

    foreach ($RequiredModule in $RequiredModules) {
        if (-not [bool](Get-Module -Name $RequiredModule)) {
            if (-not [bool](Get-Module -Name $RequiredModule -ListAvailable)) {
                Write-Warning -Message "Module $RequiredModule not found. Stopping function."
                break
            }

            Write-Verbose -Message "Importing $RequiredModule Module"
            Import-Module ActiveDirectory
        }
    }

    $ADSites = Get-ADDomainController -Filter * | `
            Select-Object -Property Name, Site, IPv4Address, Enabled, IsGlobalCatalog, IsReadOnly, OperatingSystem, @{Name = "Roles"; Expression = { $_.OperationMasterRoles -join ";" } } | `
                Sort-Object -Property Site, Name

    $ADSites
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
