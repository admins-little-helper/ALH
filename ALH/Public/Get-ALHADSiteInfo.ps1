<#PSScriptInfo

.VERSION 1.1.0

.GUID 80e0cb9c-bf40-49d0-9438-26c2523e0763

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
1.0
- Initial release

1.1.0
- Cleaned up code

#>


<#

.DESCRIPTION
Contains function to get a sorted list of all AD Sites for the domain the user running the cmdlet is member in.
#>


function Get-ALHADSiteInfo {

    <#
    .SYNOPSIS
    Returns a sorted list of all AD Sites for the domain the user running the cmdlet is member in.

    .DESCRIPTION
    Returns a sorted list of all AD Sites for the domain the user running the cmdlet is member in.

    .EXAMPLE
    Get-ALHADDSSiteInfo

    .INPUTS
    Nothing

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADSiteInfo.txt
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

    $ADDSSiteInfo = Get-ADObject -Filter { objectClass -eq "siteLink" } -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -Properties * | `
            Select-Object -Property Name, `
            Cost, `
            ReplInterval, `
        @{Name = "MemberSites"; Expression = { $($(foreach ($site in $_.siteList) { (Get-ADObject -Identity $site).Name })) } }, `
            Options | `
                Sort-Object -Property Name

    $ADDSSiteInfo
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
