<#PSScriptInfo

.VERSION 1.1.0

.GUID c993f4be-ac1d-4744-92e5-7fd55f58daa4

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
1.0
- Initial release

1.1.0
- Cleaned up code

#>


<#

.DESCRIPTION
Contains function to get a sorted list of all AD Subnets for the domain the user running the cmdlet is member in.
#>


function Get-ALHADSubnetInfo {
    <#
    .SYNOPSIS
    Returns a sorted list of all AD Subnets for the domain the user running the cmdlet is member in.

    .DESCRIPTION
    Returns a sorted list of all AD Subnets for the domain the user running the cmdlet is member in.

    .EXAMPLE
    Get-ALHADDSSubnetInfo

    .INPUTS
    Nothing

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADSubnetInfo.txt
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

    Write-Verbose -Message "Get a list of all domain controllers in the forest"
    $DcList = (Get-ADForest).Domains | `
            ForEach-Object { Get-ADDomainController -Discover -DomainName $_ } | `
                ForEach-Object { Get-ADDomainController -Server $_ -Filter * }

    Write-Verbose -Message "Get all replication subnets from Sites & Services"
    $Subnets = Get-ADReplicationSubnet -Filter * -Properties * | Select-Object Name, Site, Location, Description

    $ResultsArray = @()
    
    foreach ($Subnet in $Subnets) {
        $SiteName = ""
        
        If ($null -ne $Subnet.Site) { $SiteName = $Subnet.Site.Split(',')[0].Trim('CN=') }
        $DcInSite = $False
        
        If ($DcList.Site -Contains $SiteName) { $DcInSite = $True }
        
        $RA = New-Object PSObject
        $RA | Add-Member -type NoteProperty -Name "Subnet" -Value $Subnet.Name
        $RA | Add-Member -type NoteProperty -Name "SiteName" -Value $SiteName
        $RA | Add-Member -type NoteProperty -Name "DcInSite" -Value $DcInSite
        $RA | Add-Member -type NoteProperty -Name "SiteLoc" -Value $Subnet.Location
        $RA | Add-Member -type NoteProperty -Name "SiteDesc" -Value $Subnet.Description
        $ResultsArray += $RA
    }
    
    $ResultsArray | Sort-Object -Property SiteName, Subnet
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
